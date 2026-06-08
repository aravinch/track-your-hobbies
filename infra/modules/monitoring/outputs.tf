output "instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.insights.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.insights.connection_string
  sensitive   = true
}

output "workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.workspace.id
}

output "action_group_id" {
  description = "Monitor action group ID"
  value       = azurerm_monitor_action_group.email_alert.id
}