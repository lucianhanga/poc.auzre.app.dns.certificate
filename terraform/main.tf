terraform {

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>4.1"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name   = "palceholder" 
    storage_account_name  = "palceholder"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}


provider "azurerm" {
  # Configuration options
  features {
    # manualy purge it
    /*
      az keyvault purge \
          --name kv-docbuletine7 \
          --location westeurope
    */
    key_vault {
      purge_soft_delete_on_destroy    = true # wthe resource is deprovisioned, the resource is purged
      recover_soft_deleted_key_vaults = true # This is required to recover the key vault
    }    
  }
#  subscription_id = var.subscription_id
}
