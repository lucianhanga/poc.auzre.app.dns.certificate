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
          --name <keyvalut-name> \
          --location westeurope
    */
    key_vault {
      purge_soft_delete_on_destroy    = true # wthe resource is deprovisioned, the resource is purged
      recover_soft_deleted_key_vaults = true # This is required to recover the key vault
    }    
  }
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  subscription_id = var.subscription_id
}
