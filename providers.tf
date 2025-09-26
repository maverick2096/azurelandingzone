terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Optional remote backend (uncomment & fill)
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "tfstate-rg"
#     storage_account_name = "tfstateacct001"
#     container_name       = "tfstate"
#     key                  = "core-expanded/dev.tfstate"
#   }
# }
