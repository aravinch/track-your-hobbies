terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

module "resource_group" {
  source      = "../../modules/resource_group"
  name        = "rg-hobbies-${var.environment}"
  location    = var.location
  tags = {
    environment = var.environment
    project     = "hobbies-tracker"
    managed_by  = "terraform"
  }
}

module "container_registry" {
  source = "../../modules/container_registry"

  name                = "acrhobbies${var.environment}"
  resource_group_name = module.resource_group.rg_name
  location            = module.resource_group.rg_location

  tags = {
    environment = var.environment
    project     = "hobbies-tracker"
    managed_by  = "terraform"
  }
}


# SQL Logical Server (free)
# ✅ Correct — module reference
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-hobbies-${var.environment}"
  resource_group_name          = module.resource_group.rg_name        # ← fixed
  location                     = var.sql_location    # ← fixed
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  tags = {
    environment = var.environment
  }
}



# SQL Database (~$5/month — Basic tier)
resource "azurerm_mssql_database" "sql_db" {
  name      = "db-hobbies-${var.environment}"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "Basic"        # ← cost control here
  max_size_gb = 2

  tags = {
    environment = var.environment
  }
}

# Firewall rule — allow Azure services (App Service) to connect
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  environment         = var.environment
  resource_group_name = module.resource_group.rg_name
  location            = module.resource_group.rg_location
  alert_email         = var.alert_email

  tags = {
    environment = var.environment
    project     = "hobbies-tracker"
    managed_by  = "terraform"
  }
}

module "app_service" {
  source = "../../modules/app_service"

  plan_name           = "plan-hobbies-${var.environment}"
  app_name            = "app-hobbies-${var.environment}"
  resource_group_name = module.resource_group.rg_name
  location            = module.resource_group.rg_location

  docker_image      = "hobbies-tracker"
  docker_image_tag  = "v2"
  acr_login_server  = module.container_registry.login_server
  acr_username      = module.container_registry.admin_username
  acr_password      = module.container_registry.admin_password
  # ✅ NEW — pass SQL values into module
  sql_admin_username = var.sql_admin_username
  sql_admin_password = var.sql_admin_password
  sql_server_fqdn    = azurerm_mssql_server.sql_server.fully_qualified_domain_name
  sql_database_name  = "db-hobbies-${var.environment}"

  # ✅ NEW — connect to Application Insights
  appinsights_connection_string = module.monitoring.connection_string
  appinsights_instrumentation_key = module.monitoring.instrumentation_key

  tags = {
    environment = var.environment
    project     = "hobbies-tracker"
    managed_by  = "terraform"
  }
}

resource "azurerm_monitor_metric_alert" "response_time" {
  name                = "alert-response-time-${var.environment}"
  resource_group_name = module.resource_group.rg_name
  scopes              = [module.app_service.app_service_id]  # ← direct ref
  description         = "Alert when response time exceeds 3 seconds"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 3
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "http_errors" {
  name                = "alert-http-errors-${var.environment}"
  resource_group_name = module.resource_group.rg_name
  scopes              = [module.app_service.app_service_id]
  description         = "Alert when HTTP 5xx errors occur"
  severity            = 1

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }
}