# 기존 사용자 및 그룹 확인을 위한 로컬 변수
locals {
  # 그룹 및 사용자 이름 정의
  group_names = {
    operators = "AKS Operators"
    admins = "AKS Admins"
    cluster_admins = "AKS Cluster Admins"
    developers = "AKS Developers"
  }
  
  user_upns = {
    operator = "operator@${var.tenant_domain}"
    admin = "admin@${var.tenant_domain}"
    cluster_admin = "clusteradmin@${var.tenant_domain}"
    developer = "developer@${var.tenant_domain}"
  }
  
  # 사용자 및 그룹 존재 여부 설정
  operator_exists = var.use_existing_ad_users
  admin_exists = var.use_existing_ad_users
  cluster_admin_exists = var.use_existing_ad_users
  developer_exists = var.use_existing_ad_users
  
  operators_group_exists = var.use_existing_ad_groups && var.operators_group_id != ""
  admins_group_exists = var.use_existing_ad_groups && var.admins_group_id != ""
  cluster_admins_group_exists = var.use_existing_ad_groups && var.cluster_admins_group_id != ""
  developers_group_exists = var.use_existing_ad_groups && var.developers_group_id != ""
}

# 기존 사용자 데이터 소스
data "azuread_user" "operator" {
  count               = local.operator_exists ? 1 : 0
  user_principal_name = local.user_upns.operator
}

data "azuread_user" "admin" {
  count               = local.admin_exists ? 1 : 0
  user_principal_name = local.user_upns.admin
}

data "azuread_user" "cluster_admin" {
  count               = local.cluster_admin_exists ? 1 : 0
  user_principal_name = local.user_upns.cluster_admin
}

data "azuread_user" "developer" {
  count               = local.developer_exists ? 1 : 0
  user_principal_name = local.user_upns.developer
}

# 사용자가 존재하지 않을 경우에만 생성
resource "azuread_user" "operator" {
  count               = local.operator_exists ? 0 : 1
  user_principal_name = local.user_upns.operator
  display_name        = "AKS Operator"
  password            = var.user_passwords.operator
  force_password_change = true
}

resource "azuread_user" "admin" {
  count               = local.admin_exists ? 0 : 1
  user_principal_name = local.user_upns.admin
  display_name        = "AKS Admin"
  password            = var.user_passwords.admin
  force_password_change = true
}

resource "azuread_user" "cluster_admin" {
  count               = local.cluster_admin_exists ? 0 : 1
  user_principal_name = local.user_upns.cluster_admin
  display_name        = "AKS Cluster Admin"
  password            = var.user_passwords.cluster_admin
  force_password_change = true
}

resource "azuread_user" "developer" {
  count               = local.developer_exists ? 0 : 1
  user_principal_name = local.user_upns.developer
  display_name        = "AKS Developer"
  password            = var.user_passwords.developer
  force_password_change = true
}

# 기존 그룹 데이터 소스
data "azuread_group" "operators" {
  count            = local.operators_group_exists ? 1 : 0
  object_id        = var.operators_group_id
}

data "azuread_group" "admins" {
  count            = local.admins_group_exists ? 1 : 0
  object_id        = var.admins_group_id
}

data "azuread_group" "cluster_admins" {
  count            = local.cluster_admins_group_exists ? 1 : 0
  object_id        = var.cluster_admins_group_id
}

data "azuread_group" "developers" {
  count            = local.developers_group_exists ? 1 : 0
  object_id        = var.developers_group_id
}

# 그룹이 존재하지 않을 경우에만 생성
resource "azuread_group" "operators" {
  count            = local.operators_group_exists ? 0 : 1
  display_name     = local.group_names.operators
  security_enabled = true
}

resource "azuread_group" "admins" {
  count            = local.admins_group_exists ? 0 : 1
  display_name     = local.group_names.admins
  security_enabled = true
}

resource "azuread_group" "cluster_admins" {
  count            = local.cluster_admins_group_exists ? 0 : 1
  display_name     = local.group_names.cluster_admins
  security_enabled = true
}

resource "azuread_group" "developers" {
  count            = local.developers_group_exists ? 0 : 1
  display_name     = local.group_names.developers
  security_enabled = true
}

# 사용자를 그룹에 추가
resource "azuread_group_member" "operator_member" {
  count            = (!local.operator_exists || !local.operators_group_exists) ? 1 : 0
  group_object_id  = local.operators_group_exists ? data.azuread_group.operators[0].id : azuread_group.operators[0].id
  member_object_id = local.operator_exists ? data.azuread_user.operator[0].id : azuread_user.operator[0].id
}

resource "azuread_group_member" "admin_member" {
  count            = (!local.admin_exists || !local.admins_group_exists) ? 1 : 0
  group_object_id  = local.admins_group_exists ? data.azuread_group.admins[0].id : azuread_group.admins[0].id
  member_object_id = local.admin_exists ? data.azuread_user.admin[0].id : azuread_user.admin[0].id
}

resource "azuread_group_member" "cluster_admin_member" {
  count            = (!local.cluster_admin_exists || !local.cluster_admins_group_exists) ? 1 : 0
  group_object_id  = local.cluster_admins_group_exists ? data.azuread_group.cluster_admins[0].id : azuread_group.cluster_admins[0].id
  member_object_id = local.cluster_admin_exists ? data.azuread_user.cluster_admin[0].id : azuread_user.cluster_admin[0].id
}

resource "azuread_group_member" "developer_member" {
  count            = (!local.developer_exists || !local.developers_group_exists) ? 1 : 0
  group_object_id  = local.developers_group_exists ? data.azuread_group.developers[0].id : azuread_group.developers[0].id
  member_object_id = local.developer_exists ? data.azuread_user.developer[0].id : azuread_user.developer[0].id
} 