# Log Analytics Workspace — stores all logs
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "law-hobbies-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"   # pay per GB ingested
  retention_in_days   = 30            # keep logs 30 days
  tags                = var.tags
}

# Application Insights — APM tool
resource "azurerm_application_insights" "insights" {
  name                = "appi-hobbies-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.workspace.id
  application_type    = "web"
  tags                = var.tags
}





# Action Group — who gets notified
resource "azurerm_monitor_action_group" "email_alert" {
  name                = "ag-hobbies-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "hobbies"

  email_receiver {
    name          = "DevOps Engineer"
    email_address = var.alert_email
  }
}