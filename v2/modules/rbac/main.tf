# 데이터 소스
data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id
}

# 1. 구독 수준 권한 설정
# 모든 그룹에 Reader 권한 부여
resource "azurerm_role_assignment" "operators_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = var.operators_group_id
  
  lifecycle {
    ignore_changes = [
      scope,
      principal_id,
      role_definition_name
    ]
  }
}

resource "azurerm_role_assignment" "admins_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = var.admins_group_id
  
  lifecycle {
    ignore_changes = [
      scope,
      principal_id,
      role_definition_name
    ]
  }
}

resource "azurerm_role_assignment" "cluster_admins_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = var.cluster_admins_group_id
  
  lifecycle {
    ignore_changes = [
      scope,
      principal_id,
      role_definition_name
    ]
  }
}

resource "azurerm_role_assignment" "developers_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = var.developers_group_id
  
  lifecycle {
    ignore_changes = [
      scope,
      principal_id,
      role_definition_name
    ]
  }
}

# 추가 권한 부여
resource "azurerm_role_assignment" "cluster_admins_aks_admin" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = var.cluster_admins_group_id
}

# 2. AKS 클러스터에 대한 특정 역할 할당
resource "azurerm_role_assignment" "operators_aks_reader" {
  count               = var.aks_cluster_id != "" && var.aks_cluster_id != null && length(var.aks_cluster_id) > 0 ? 1 : 0
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.operators_group_id
}

resource "azurerm_role_assignment" "admins_aks_contributor" {
  count               = var.aks_cluster_id != "" && var.aks_cluster_id != null && length(var.aks_cluster_id) > 0 ? 1 : 0
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Contributor Role"
  principal_id         = var.admins_group_id
}

resource "azurerm_role_assignment" "cluster_admins_aks_owner" {
  count               = var.aks_cluster_id != "" && var.aks_cluster_id != null && length(var.aks_cluster_id) > 0 ? 1 : 0
  scope                = var.aks_cluster_id
  role_definition_name = "Owner"
  principal_id         = var.cluster_admins_group_id
}

resource "azurerm_role_assignment" "developers_aks_dev" {
  count               = var.aks_cluster_id != "" && var.aks_cluster_id != null && length(var.aks_cluster_id) > 0 ? 1 : 0
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.developers_group_id
}

# 3. 스토리지 계정에 대한 RBAC 권한 설정
resource "azurerm_role_assignment" "operators_storage_reader" {
  count               = var.storage_account_id != "" && var.storage_account_id != null && length(var.storage_account_id) > 0 ? 1 : 0
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.operators_group_id
}

resource "azurerm_role_assignment" "admins_storage_contributor" {
  count               = var.storage_account_id != "" && var.storage_account_id != null && length(var.storage_account_id) > 0 ? 1 : 0
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.admins_group_id
}

resource "azurerm_role_assignment" "cluster_admins_storage_owner" {
  count               = var.storage_account_id != "" && var.storage_account_id != null && length(var.storage_account_id) > 0 ? 1 : 0
  scope                = var.storage_account_id
  role_definition_name = "Owner"
  principal_id         = var.cluster_admins_group_id
}

resource "azurerm_role_assignment" "developers_storage_contributor" {
  count               = var.storage_account_id != "" && var.storage_account_id != null && length(var.storage_account_id) > 0 ? 1 : 0
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.developers_group_id
}

# 4. ACR에 대한 RBAC 권한 설정
resource "azurerm_role_assignment" "operators_acr_reader" {
  count               = var.acr_id != "" && var.acr_id != null && length(var.acr_id) > 0 ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.operators_group_id
}

resource "azurerm_role_assignment" "admins_acr_contributor" {
  count               = var.acr_id != "" && var.acr_id != null && length(var.acr_id) > 0 ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = var.admins_group_id
}

resource "azurerm_role_assignment" "cluster_admins_acr_owner" {
  count               = var.acr_id != "" && var.acr_id != null && length(var.acr_id) > 0 ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "Owner"
  principal_id         = var.cluster_admins_group_id
}

resource "azurerm_role_assignment" "developers_acr_push" {
  count               = var.acr_id != "" && var.acr_id != null && length(var.acr_id) > 0 ? 1 : 0
  scope                = var.acr_id
  role_definition_name = "AcrPush"
  principal_id         = var.developers_group_id
}

# 5. KeyVault에 대한 RBAC 권한 설정
resource "azurerm_role_assignment" "operators_kv_reader" {
  count               = var.keyvault_id != "" && var.keyvault_id != null && length(var.keyvault_id) > 0 && var.use_existing_keyvault_rbac == false ? 1 : 0
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Reader"
  principal_id         = var.operators_group_id
  
  lifecycle {
    ignore_changes = [
      scope,
      principal_id,
      role_definition_name,
      id
    ]
  }
}

resource "azurerm_role_assignment" "admins_kv_contributor" {
  count               = var.keyvault_id != "" && var.keyvault_id != null && length(var.keyvault_id) > 0 && var.use_existing_keyvault_rbac == false ? 1 : 0
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admins_group_id
  
  lifecycle {
    ignore_changes = [
      scope,
      principal_id,
      role_definition_name
    ]
  }
}

resource "azurerm_role_assignment" "cluster_admins_kv_admin" {
  count               = var.keyvault_id != "" && var.keyvault_id != null && length(var.keyvault_id) > 0 && var.use_existing_keyvault_rbac == false ? 1 : 0
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.cluster_admins_group_id
  
  lifecycle {
    ignore_changes = [
      scope,
      principal_id,
      role_definition_name,
      id
    ]
  }
}

resource "azurerm_role_assignment" "developers_kv_secrets" {
  count               = var.keyvault_id != "" && var.keyvault_id != null && length(var.keyvault_id) > 0 && var.use_existing_keyvault_rbac == false ? 1 : 0
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.developers_group_id
  
  lifecycle {
    ignore_changes = [
      scope,
      principal_id,
      role_definition_name
    ]
  }
}

# 6. Kubernetes RBAC 설정을 위한 로컬 실행 스크립트
resource "local_file" "k8s_rbac_script" {
  filename = "${path.module}/setup_k8s_rbac.sh"
  content  = <<-EOT
#!/bin/bash

# Kubernetes RBAC 설정 스크립트
echo "Kubernetes RBAC 권한 설정 시작..."

# 네임스페이스 생성
kubectl create namespace ${var.developer_namespace} --dry-run=client -o yaml | kubectl apply -f -

# ClusterRole 및 Role 생성
cat <<EOF | kubectl apply -f -
---
# AKS Admins를 위한 ClusterRole (이미 cluster-admin이 있으므로 생략 가능)
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: aks-admins-cluster-admin
subjects:
- kind: Group
  name: ${var.admins_group_id}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
# AKS Developers를 위한 Role (특정 네임스페이스에 한정)
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: namespace-admin
  namespace: ${var.developer_namespace}
rules:
- apiGroups: ["", "extensions", "apps", "networking.k8s.io", "batch"]
  resources: ["*"]
  verbs: ["*"]
---
# AKS Developers를 위한 RoleBinding
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: developers-namespace-admin
  namespace: ${var.developer_namespace}
subjects:
- kind: Group
  name: ${var.developers_group_id}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: namespace-admin
  apiGroup: rbac.authorization.k8s.io
---
# AKS Operators를 위한 ClusterRole (읽기 전용)
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-reader
rules:
- apiGroups: ["", "extensions", "apps", "networking.k8s.io", "batch"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
---
# AKS Operators를 위한 ClusterRoleBinding
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: operators-cluster-reader
subjects:
- kind: Group
  name: ${var.operators_group_id}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-reader
  apiGroup: rbac.authorization.k8s.io
EOF

echo "Kubernetes RBAC 권한 설정 완료!"
EOT

  # 파일 권한 설정
  file_permission = "0755"
}

# 스크립트 실행을 위한 null_resource
resource "null_resource" "setup_k8s_rbac" {
  triggers = {
    script_content = local_file.k8s_rbac_script.content
  }

  provisioner "local-exec" {
    command = "echo '스크립트를 수동으로 실행하세요: ${local_file.k8s_rbac_script.filename}'"
  }
} 