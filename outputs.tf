output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "machine_secrets" {
  value     = yamlencode(talos_machine_secrets.this.machine_secrets)
  sensitive = true
}

output "controlplane_ips" {
  description = "IP addresses of the controlplane nodes."
  value       = local.controlplane_final_ips
}

output "worker_ips" {
  description = "IP addresses of the worker nodes."
  value       = local.worker_final_ips
}

output "endpoint" {
  description = "The Talos cluster endpoint."
  value       = local.cluster_endpoint
}
