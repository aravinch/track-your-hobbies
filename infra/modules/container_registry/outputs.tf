output "login_server" {
  description = "ACR login server URL — used to push/pull images"
  value       = azurerm_container_registry.this.login_server
}

output "admin_username" {
  value     = azurerm_container_registry.this.admin_username
  sensitive = true
}

output "admin_password" {
  value     = azurerm_container_registry.this.admin_password
  sensitive = true
}