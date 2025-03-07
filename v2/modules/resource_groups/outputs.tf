output "hub_rg_name" {
  description = "The name of the hub resource group"
  value       = var.use_existing_resource_group_hub ? var.resource_group_name_hub : azurerm_resource_group.hub_rg[0].name
}

output "spoke_rg_name" {
  description = "The name of the spoke resource group"
  value       = var.use_existing_resource_group_spoke ? var.resource_group_name_spoke : azurerm_resource_group.spoke_rg[0].name
}

output "storage_rg_name" {
  description = "The name of the storage resource group"
  value       = var.use_existing_resource_group_storage ? var.resource_group_name_storage : azurerm_resource_group.storage_rg[0].name
}

output "hub_rg_id" {
  description = "The ID of the hub resource group"
  value       = var.use_existing_resource_group_hub ? null : azurerm_resource_group.hub_rg[0].id
}

output "spoke_rg_id" {
  description = "The ID of the spoke resource group"
  value       = var.use_existing_resource_group_spoke ? null : azurerm_resource_group.spoke_rg[0].id
}

output "storage_rg_id" {
  description = "The ID of the storage resource group"
  value       = var.use_existing_resource_group_storage ? null : azurerm_resource_group.storage_rg[0].id
} 