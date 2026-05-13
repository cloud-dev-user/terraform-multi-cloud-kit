output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "VNet name"
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to ID"
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "nsg_ids" {
  description = "Map of NSG name to ID"
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if enabled)"
  value       = var.enable_nat_gateway ? azurerm_nat_gateway.this[0].id : null
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.network.name
}
