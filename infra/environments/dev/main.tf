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

  tags = {
    environment = var.environment
    project     = "hobbies-tracker"
    managed_by  = "terraform"
  }
}