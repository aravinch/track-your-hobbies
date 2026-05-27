output "app_url" {
  description = "Public URL of the App Service"
  value       = azurerm_linux_web_app.this.default_hostname
}