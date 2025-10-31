terraform {
  required_version = ">=1.12"
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }

    talos = {
      source = "siderolabs/talos"
    }
  }
}
