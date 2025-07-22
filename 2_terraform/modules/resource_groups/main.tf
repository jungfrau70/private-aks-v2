resource "azurerm_resource_group" "hub_rg" {
  count    = var.use_existing_resource_group_hub ? 0 : 1
  name     = var.resource_group_name_hub
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "spoke_rg" {
  count    = var.use_existing_resource_group_spoke ? 0 : 1
  name     = var.resource_group_name_spoke
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "storage_rg" {
  count    = var.use_existing_resource_group_storage ? 0 : 1
  name     = var.resource_group_name_storage
  location = var.location
  tags     = var.tags
} 