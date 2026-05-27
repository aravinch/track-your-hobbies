output "resource_group_name" {
  description = "The resource group created for dev"
  value       = module.resource_group.rg_name
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.container_registry.login_server
}
output "app_url" {
  description = "Public URL of the hobbies tracker"
  value       = module.app_service.app_url
}