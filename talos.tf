provider "talos" {}

locals {
  controlplane_initial_ips = [
    for _, response in data.http.controlplane_initial_ips :
    [for interface in jsondecode(response.response_body)["data"]["result"] :
      interface["ip-addresses"][0]["ip-address"] if interface["name"] == "eth0"
    ][0]
  ]
  worker_initial_ips = [
    for _, response in data.http.worker_initial_ips :
    [for interface in jsondecode(response.response_body)["data"]["result"] :
      interface["ip-addresses"][0]["ip-address"] if interface["name"] == "eth0"
    ][0]
  ]
  controlplane_final_ips = [
    for _, response in data.http.controlplane_final_ips :
    [for interface in jsondecode(response.response_body)["data"]["result"] :
      interface["ip-addresses"][0]["ip-address"] if interface["name"] == "eth0"
    ][0]
  ]
  worker_final_ips = [
    for _, response in data.http.worker_final_ips :
    [for interface in jsondecode(response.response_body)["data"]["result"] :
      interface["ip-addresses"][0]["ip-address"] if interface["name"] == "eth0"
    ][0]
  ]
  cluster_endpoint = var.talos_cluster_endpoint != null ? var.talos_cluster_endpoint : "https://${local.controlplane_final_ips[0]}:6443"
}

resource "talos_image_factory_schematic" "nocloud" {
  schematic = templatefile(var.talos_nocloud_schematic_template, {
    talos_extensions = var.talos_extensions
  })
}

data "talos_image_factory_urls" "nocloud" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.nocloud.id
  platform      = "nocloud"
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "controlplane_initial" {
  machine_type     = "controlplane"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = var.talos_cluster_endpoint != null ? var.talos_cluster_endpoint : "https://placeholder:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

resource "talos_machine_configuration_apply" "controlplane_initial" {
  for_each = { for i, ip in local.controlplane_initial_ips : i => ip }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane_initial.machine_configuration
  node                        = each.value

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.nocloud.urls["installer"]
        }
      }
    })
  ]
}

data "talos_machine_configuration" "controlplane_final" {
  machine_type     = "controlplane"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

resource "talos_machine_configuration_apply" "controlplane_final" {
  for_each = { for i, ip in local.controlplane_final_ips : i => ip }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane_final.machine_configuration
  node                        = each.value

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.nocloud.urls["installer"]
        }
      }
    })
  ]
}

data "talos_machine_configuration" "worker" {
  machine_type     = "worker"
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = { for i, ip in local.worker_initial_ips : i => ip }

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = data.talos_image_factory_urls.nocloud.urls["installer"]
        }
      }
    })
  ]
}

resource "talos_machine_bootstrap" "this" {
  depends_on           = [talos_machine_configuration_apply.controlplane_final]
  node                 = local.controlplane_final_ips[0]
  client_configuration = talos_machine_secrets.this.client_configuration
}

data "talos_client_configuration" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = local.worker_final_ips
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane_final_ips[0]
}
