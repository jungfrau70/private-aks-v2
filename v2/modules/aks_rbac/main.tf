# ACR에 대한 AKS 클러스터 접근 권한 부여
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.enable_acr_access ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.kubelet_identity_id
}

# KeyVault에 대한 AKS 클러스터 접근 권한 부여
resource "azurerm_role_assignment" "aks_keyvault_access" {
  count                = var.enable_keyvault_access ? 1 : 0
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.kubelet_identity_id
}

# Application Gateway에 대한 AKS 클러스터 접근 권한 부여 (AGIC 사용 시)
resource "azurerm_role_assignment" "aks_appgw_contributor" {
  count                = var.enable_agic_access ? 1 : 0
  scope                = var.appgw_id
  role_definition_name = "Contributor"
  principal_id         = var.agic_identity_id
} 