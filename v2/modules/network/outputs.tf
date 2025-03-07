output "hub_vnet_id" {
  description = "Hub VNet ID"
  value       = var.use_existing_networks ? (length(data.azurerm_virtual_network.hub_vnet) > 0 ? data.azurerm_virtual_network.hub_vnet[0].id : null) : (length(azurerm_virtual_network.hub_vnet) > 0 ? azurerm_virtual_network.hub_vnet[0].id : null)
}

output "hub_vnet_name" {
  description = "Hub VNet 이름"
  value       = var.use_existing_networks ? (length(data.azurerm_virtual_network.hub_vnet) > 0 ? data.azurerm_virtual_network.hub_vnet[0].name : null) : (length(azurerm_virtual_network.hub_vnet) > 0 ? azurerm_virtual_network.hub_vnet[0].name : null)
}

output "hub_rg_name" {
  description = "Hub 리소스 그룹 이름"
  value       = var.resource_group_name_hub
}

output "spoke_vnet_id" {
  description = "Spoke VNet ID"
  value       = var.use_existing_networks ? (length(data.azurerm_virtual_network.spoke_vnet) > 0 ? data.azurerm_virtual_network.spoke_vnet[0].id : null) : (length(azurerm_virtual_network.spoke_vnet) > 0 ? azurerm_virtual_network.spoke_vnet[0].id : null)
}

output "spoke_vnet_name" {
  description = "Spoke VNet 이름"
  value       = var.use_existing_networks ? (length(data.azurerm_virtual_network.spoke_vnet) > 0 ? data.azurerm_virtual_network.spoke_vnet[0].name : null) : (length(azurerm_virtual_network.spoke_vnet) > 0 ? azurerm_virtual_network.spoke_vnet[0].name : null)
}

output "spoke_rg_name" {
  description = "Spoke 리소스 그룹 이름"
  value       = var.resource_group_name_spoke
}

output "bastion_subnet_id" {
  description = "Bastion 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.bastion_subnet[0].id
}

output "fw_subnet_id" {
  description = "Firewall 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.fw_subnet[0].id
}

output "jumpbox_subnet_id" {
  description = "Jumpbox 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.jumpbox_subnet[0].id
}

output "aks_subnet_id" {
  description = "AKS 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.aks_subnet[0].id
}

output "endpoints_subnet_id" {
  description = "Private Endpoint 서브넷 ID"
  value       = var.use_existing_networks ? (length(data.azurerm_subnet.endpoints_subnet) > 0 ? data.azurerm_subnet.endpoints_subnet[0].id : "") : (length(azurerm_subnet.endpoints_subnet) > 0 ? azurerm_subnet.endpoints_subnet[0].id : "")
}

output "loadbalancer_subnet_id" {
  description = "Load Balancer 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.loadbalancer_subnet[0].id
}

output "appgw_subnet_id" {
  description = "Application Gateway 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.appgw_subnet[0].id
}

output "storage_vnet_id" {
  description = "Storage VNet ID"
  value       = var.use_existing_networks ? (length(data.azurerm_virtual_network.storage_vnet) > 0 ? data.azurerm_virtual_network.storage_vnet[0].id : null) : (length(azurerm_virtual_network.storage_vnet) > 0 ? azurerm_virtual_network.storage_vnet[0].id : null)
}

output "storage_vnet_name" {
  description = "Storage VNet 이름"
  value       = var.use_existing_networks ? (length(data.azurerm_virtual_network.storage_vnet) > 0 ? data.azurerm_virtual_network.storage_vnet[0].name : null) : (length(azurerm_virtual_network.storage_vnet) > 0 ? azurerm_virtual_network.storage_vnet[0].name : null)
}

output "storage_rg_name" {
  description = "Storage 리소스 그룹 이름"
  value       = var.resource_group_name_storage
}

output "storage_subnet_id" {
  description = "Storage 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.storage_subnet[0].id
}

# ACR VNet 출력
# output "acr_vnet_id" {
#   description = "ACR VNet ID"
#   value       = var.use_existing_networks ? data.azurerm_virtual_network.acr_vnet[0].id : azurerm_virtual_network.acr_vnet[0].id
# }

# ACR 서브넷 출력
output "acr_subnet_id" {
  description = "ACR 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.acr_subnet[0].id
}

# DevOps Agent VNet 출력
# output "agent_vnet_id" {
#   description = "DevOps Agent VNet ID"
#   value       = var.use_existing_networks ? data.azurerm_virtual_network.agent_vnet[0].id : azurerm_virtual_network.agent_vnet[0].id
# }

output "agent_subnet_id" {
  description = "DevOps Agent 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.agent_subnet[0].id
}

output "db_subnet_id" {
  description = "Database 서브넷 ID"
  value       = var.use_existing_networks ? null : azurerm_subnet.db_subnet[0].id
} 