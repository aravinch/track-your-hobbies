terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatehobbies"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}