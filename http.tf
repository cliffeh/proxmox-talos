# NB wel'l wait 10s after VM creation before querying for IPs to give the guest agent time to start
resource "time_sleep" "first_boot" {
  depends_on = [
    proxmox_virtual_environment_vm.controlplanes,
    proxmox_virtual_environment_vm.workers,
  ]

  create_duration = "10s"
}

data "http" "controlplane_initial_ips" {
  depends_on = [time_sleep.first_boot]
  for_each   = proxmox_virtual_environment_vm.controlplanes

  url = "${var.pve_api_url}/nodes/${each.value.node_name}/qemu/${each.value.vm_id}/agent/network-get-interfaces"

  request_headers = {
    Authorization = "PVEAPIToken=${var.pve_token_id}=${var.pve_token_secret}"
  }
}

data "http" "worker_initial_ips" {
  depends_on = [time_sleep.first_boot]
  for_each   = proxmox_virtual_environment_vm.workers

  url = "${var.pve_api_url}/nodes/${each.value.node_name}/qemu/${each.value.vm_id}/agent/network-get-interfaces"

  request_headers = {
    Authorization = "PVEAPIToken=${var.pve_token_id}=${var.pve_token_secret}"
  }
}

# NB we'll wait again after config application/reboot
resource "time_sleep" "controlplane_config_apply" {
  depends_on = [talos_machine_configuration_apply.controlplane_initial]

  create_duration = "10s"
}

resource "time_sleep" "worker_config_apply" {
  depends_on = [talos_machine_configuration_apply.worker]

  create_duration = "10s"
}

data "http" "controlplane_final_ips" {
  depends_on = [time_sleep.controlplane_config_apply]
  for_each   = proxmox_virtual_environment_vm.controlplanes

  url = "${var.pve_api_url}/nodes/${each.value.node_name}/qemu/${each.value.vm_id}/agent/network-get-interfaces"

  request_headers = {
    Authorization = "PVEAPIToken=${var.pve_token_id}=${var.pve_token_secret}"
  }
}

data "http" "worker_final_ips" {
  depends_on = [time_sleep.worker_config_apply]
  for_each   = proxmox_virtual_environment_vm.workers

  url = "${var.pve_api_url}/nodes/${each.value.node_name}/qemu/${each.value.vm_id}/agent/network-get-interfaces"

  request_headers = {
    Authorization = "PVEAPIToken=${var.pve_token_id}=${var.pve_token_secret}"
  }
}
