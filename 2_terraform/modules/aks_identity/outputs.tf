output "identity_id" {
  description = "AKS 클러스터 사용자 관리 ID의 ID"
  value       = var.use_existing_aks_identity ? null : (length(azurerm_user_assigned_identity.aks_identity) > 0 ? azurerm_user_assigned_identity.aks_identity[0].id : null)
}

output "identity_principal_id" {
  description = "AKS 클러스터 사용자 관리 ID의 Principal ID"
  value       = var.use_existing_aks_identity ? null : (length(azurerm_user_assigned_identity.aks_identity) > 0 ? azurerm_user_assigned_identity.aks_identity[0].principal_id : null)
}

output "identity_client_id" {
  description = "AKS 클러스터 사용자 관리 ID의 Client ID"
  value       = var.use_existing_aks_identity ? null : (length(azurerm_user_assigned_identity.aks_identity) > 0 ? azurerm_user_assigned_identity.aks_identity[0].client_id : null)
}

output "github_oidc_id" {
  description = "GitHub Actions OIDC 자격 증명의 ID"
  value       = var.use_existing_aks_identity || !var.enable_github_actions_oidc || var.github_repo == "" ? null : (length(azurerm_federated_identity_credential.github_oidc) > 0 ? azurerm_federated_identity_credential.github_oidc[0].id : null)
} 