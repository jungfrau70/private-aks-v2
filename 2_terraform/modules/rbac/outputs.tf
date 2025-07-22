output "k8s_rbac_script_path" {
  description = "Kubernetes RBAC 설정 스크립트 경로"
  value       = local_file.k8s_rbac_script.filename
}

output "azure_rbac_assignments" {
  description = "Azure RBAC 할당 목록"
  value = {
    subscription = {
      operators     = azurerm_role_assignment.operators_reader.id
      admins        = azurerm_role_assignment.admins_reader.id
      cluster_admins = azurerm_role_assignment.cluster_admins_reader.id
      developers    = azurerm_role_assignment.developers_reader.id
    }
    aks = {
      operators     = length(azurerm_role_assignment.operators_aks_reader) > 0 ? azurerm_role_assignment.operators_aks_reader[0].id : null
      admins        = length(azurerm_role_assignment.admins_aks_contributor) > 0 ? azurerm_role_assignment.admins_aks_contributor[0].id : null
      cluster_admins = length(azurerm_role_assignment.cluster_admins_aks_owner) > 0 ? azurerm_role_assignment.cluster_admins_aks_owner[0].id : null
      developers    = length(azurerm_role_assignment.developers_aks_dev) > 0 ? azurerm_role_assignment.developers_aks_dev[0].id : null
    }
    storage = {
      operators     = length(azurerm_role_assignment.operators_storage_reader) > 0 ? azurerm_role_assignment.operators_storage_reader[0].id : null
      admins        = length(azurerm_role_assignment.admins_storage_contributor) > 0 ? azurerm_role_assignment.admins_storage_contributor[0].id : null
      cluster_admins = length(azurerm_role_assignment.cluster_admins_storage_owner) > 0 ? azurerm_role_assignment.cluster_admins_storage_owner[0].id : null
      developers    = length(azurerm_role_assignment.developers_storage_contributor) > 0 ? azurerm_role_assignment.developers_storage_contributor[0].id : null
    }
    acr = {
      operators     = length(azurerm_role_assignment.operators_acr_reader) > 0 ? azurerm_role_assignment.operators_acr_reader[0].id : null
      admins        = length(azurerm_role_assignment.admins_acr_contributor) > 0 ? azurerm_role_assignment.admins_acr_contributor[0].id : null
      cluster_admins = length(azurerm_role_assignment.cluster_admins_acr_owner) > 0 ? azurerm_role_assignment.cluster_admins_acr_owner[0].id : null
      developers    = length(azurerm_role_assignment.developers_acr_push) > 0 ? azurerm_role_assignment.developers_acr_push[0].id : null
    }
    keyvault = {
      operators     = length(azurerm_role_assignment.operators_kv_reader) > 0 ? azurerm_role_assignment.operators_kv_reader[0].id : null
      admins        = length(azurerm_role_assignment.admins_kv_contributor) > 0 ? azurerm_role_assignment.admins_kv_contributor[0].id : null
      cluster_admins = length(azurerm_role_assignment.cluster_admins_kv_admin) > 0 ? azurerm_role_assignment.cluster_admins_kv_admin[0].id : null
      developers    = length(azurerm_role_assignment.developers_kv_secrets) > 0 ? azurerm_role_assignment.developers_kv_secrets[0].id : null
    }
  }
}