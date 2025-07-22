# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# AKS 클러스터를 위한 사용자 관리 ID
resource "azurerm_user_assigned_identity" "aks_identity" {
  count               = var.use_existing_aks_identity ? 0 : 1
  name                = "${var.cluster_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# GitHub Actions OIDC 설정 (선택 사항)
resource "azurerm_federated_identity_credential" "github_oidc" {
  count               = var.use_existing_aks_identity || !var.enable_github_actions_oidc || var.github_repo == "" ? 0 : 1
  name                = "${var.cluster_name}-github-oidc"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repo}:ref:refs/heads/main"
  parent_id           = azurerm_user_assigned_identity.aks_identity[0].id
  
  depends_on = [azurerm_user_assigned_identity.aks_identity]
} 