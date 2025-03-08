output "acr_pull_role_id" {
  description = "ACR Pull 역할 할당 ID"
  value       = length(azurerm_role_assignment.aks_acr_pull) > 0 ? azurerm_role_assignment.aks_acr_pull[0].id : null
}

output "keyvault_access_role_id" {
  description = "Key Vault 접근 역할 할당 ID"
  value       = length(azurerm_role_assignment.aks_keyvault_access) > 0 ? azurerm_role_assignment.aks_keyvault_access[0].id : null
}

output "appgw_contributor_role_id" {
  description = "Application Gateway Contributor 역할 할당 ID"
  value       = length(azurerm_role_assignment.aks_appgw_contributor) > 0 ? azurerm_role_assignment.aks_appgw_contributor[0].id : null
} 