output "rg_name" {
  description = "Resource group name — used by other modules"
  value       = azurerm_resource_group.rg.name
}

output "rg_location" {
  description = "Resource group location — used by other modules"
  value       = azurerm_resource_group.rg.location
}