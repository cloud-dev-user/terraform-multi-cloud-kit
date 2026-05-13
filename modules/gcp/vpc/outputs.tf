output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.this.self_link
}

output "subnet_self_links" {
  description = "Map of subnet name to self link"
  value       = { for k, v in google_compute_subnetwork.this : k => v.self_link }
}

output "subnet_ids" {
  description = "Map of subnet name to ID"
  value       = { for k, v in google_compute_subnetwork.this : k => v.id }
}
