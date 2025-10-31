# Proxmox Variables
variable "pve_token_id" {
  description = "Proxmox API Token Name."
  sensitive   = true
}

variable "pve_token_secret" {
  description = "Proxmox API Token Value."
  sensitive   = true
}

variable "pve_api_url" {
  description = "Proxmox API Endpoint, e.g. 'https://pve.example.com/api2/json'"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("(?i)^http[s]?://.*/api2/json$", var.pve_api_url))
    error_message = "Proxmox API Endpoint Invalid. Check URL - Scheme and Path required."
  }
}

variable "pve_controlplane_nodes" {
  description = "Controlplane nodes to create."
  type = list(object({
    pve_node_name    = string
    pve_datastore_id = optional(string, "local")
    hostname         = optional(string)
  }))
  default = []
}

variable "pve_worker_nodes" {
  description = "Worker nodes to create."
  type = list(object({
    pve_node_name    = string
    pve_datastore_id = optional(string, "local")
    hostname         = optional(string)
  }))
  default = []
}

# Talos Variables
variable "talos_version" {
  description = "The Talos version to use for the cluster."
  type        = string
}

variable "talos_extensions" {
  description = "A list of Talos extensions to include in the cluster."
  type        = list(string)
  default     = []
}

variable "talos_cluster_name" {
  description = "The name of the Talos cluster."
  type        = string
}

variable "talos_cluster_endpoint" {
  description = "The endpoint for the Talos cluster."
  type        = string
  default     = null
}

variable "talos_nocloud_schematic_template" {
  description = "Path to the Talos nocloud schematic template file."
  type        = string
  default     = "templates/nocloud-schematic.yaml.tftpl"
}
