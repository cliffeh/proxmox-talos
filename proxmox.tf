provider "proxmox" {
  endpoint  = var.pve_api_url
  api_token = "${var.pve_token_id}=${var.pve_token_secret}"
  insecure  = true
}

locals {
  images = {
    for i, node in concat(var.pve_controlplane_nodes, var.pve_worker_nodes) :
    "${node.pve_node_name}-${node.pve_datastore_id}" => {
      pve_node_name    = node.pve_node_name
      pve_datastore_id = node.pve_datastore_id
    }...
  }
  controlplanes = {
    for i, node in var.pve_controlplane_nodes :
    i => {
      pve_node_name = node.pve_node_name
      pve_image     = "${node.pve_node_name}-${node.pve_datastore_id}"
      hostname      = node.hostname != null ? node.hostname : "${var.talos_cluster_name}-cp-${i}"
    }
  }
  workers = {
    for i, node in var.pve_worker_nodes :
    i => {
      pve_node_name = node.pve_node_name
      pve_image     = "${node.pve_node_name}-${node.pve_datastore_id}"
      hostname      = node.hostname != null ? node.hostname : "${var.talos_cluster_name}-worker-${i}"
    }
  }
}

# NB these images are big and take a while to download
resource "proxmox_virtual_environment_download_file" "talos_nocloud_image" {
  for_each = local.images

  content_type        = "iso"
  overwrite_unmanaged = true # danger!
  node_name           = each.value[0].pve_node_name
  datastore_id        = each.value[0].pve_datastore_id
  url                 = data.talos_image_factory_urls.nocloud.urls["iso"]
  file_name           = "talos-nocloud-${var.talos_version}-${talos_image_factory_schematic.nocloud.id}.iso"
}

resource "proxmox_virtual_environment_vm" "controlplanes" {
  for_each = local.controlplanes

  node_name     = each.value.pve_node_name
  name          = each.value.hostname
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_nocloud_image["${each.value.pve_image}"].id
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  # NB default disk size is 8G
  disk {
    interface = "scsi0"
    iothread  = true
  }

  memory {
    dedicated = 4096
    floating  = 4096 # set equal to dedicated to enable ballooning
  }

  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_vm" "workers" {
  for_each = local.workers

  node_name     = each.value.pve_node_name
  name          = each.value.hostname
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
  }

  cdrom {
    file_id = proxmox_virtual_environment_download_file.talos_nocloud_image["${each.value.pve_image}"].id
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  # NB default disk size is 8G
  disk {
    interface = "scsi0"
    iothread  = true
  }

  memory {
    dedicated = 2048
    floating  = 2048 # set equal to dedicated to enable ballooning
  }

  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }
}
