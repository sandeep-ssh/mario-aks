terraform {
  backend "azurerm" {
    resource_group_name  = "mario-tfstate-rg"          # Replace with your resource group name
    storage_account_name = "mario12storageaccount"     # Replace with your Azure Storage Account name (must be globally unique, lowercase, no hyphens)
    container_name       = "tfstate"                   # Replace with your blob container name
    key                  = "AKS/terraform.tfstate"
  }
}
