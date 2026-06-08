output "app_url" {
  description = "Public URL of the App Service"
  value       = azurerm_linux_web_app.this.default_hostname
}

output "app_service_id" {
  description = "App Service resource ID"
  value       = azurerm_linux_web_app.this.id
}