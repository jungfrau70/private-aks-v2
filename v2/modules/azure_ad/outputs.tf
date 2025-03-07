output "users" {
  description = "생성된 Azure AD 사용자 목록"
  value = {
    operator      = length(azuread_user.operator) > 0 ? azuread_user.operator[0].id : null
    admin         = length(azuread_user.admin) > 0 ? azuread_user.admin[0].id : null
    cluster_admin = length(azuread_user.cluster_admin) > 0 ? azuread_user.cluster_admin[0].id : null
    developer     = length(azuread_user.developer) > 0 ? azuread_user.developer[0].id : null
  }
  sensitive = true
}

output "groups" {
  description = "생성된 Azure AD 그룹 목록"
  value = {
    operators     = length(azuread_group.operators) > 0 ? azuread_group.operators[0].id : null
    admins        = length(azuread_group.admins) > 0 ? azuread_group.admins[0].id : null
    cluster_admins = length(azuread_group.cluster_admins) > 0 ? azuread_group.cluster_admins[0].id : null
    developers    = length(azuread_group.developers) > 0 ? azuread_group.developers[0].id : null
  }
}

output "operators_group_id" {
  value = length(azuread_group.operators) > 0 ? azuread_group.operators[0].id : null
}

output "admins_group_id" {
  value = length(azuread_group.admins) > 0 ? azuread_group.admins[0].id : null
}

output "cluster_admins_group_id" {
  value = length(azuread_group.cluster_admins) > 0 ? azuread_group.cluster_admins[0].id : null
}

output "developers_group_id" {
  value = length(azuread_group.developers) > 0 ? azuread_group.developers[0].id : null
}

output "operator_user_id" {
  value = length(azuread_user.operator) > 0 ? azuread_user.operator[0].id : null
}

output "admin_user_id" {
  value = length(azuread_user.admin) > 0 ? azuread_user.admin[0].id : null
}

output "cluster_admin_user_id" {
  value = length(azuread_user.cluster_admin) > 0 ? azuread_user.cluster_admin[0].id : null
}

output "developer_user_id" {
  value = length(azuread_user.developer) > 0 ? azuread_user.developer[0].id : null
} 