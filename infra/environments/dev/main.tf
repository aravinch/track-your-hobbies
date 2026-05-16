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