variable "subscription_id" {
  description = "Azure 구독 ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD 테넌트 ID"
  type        = string
}

# 그룹 ID
variable "operators_group_id" {
  description = "AKS Operators 그룹 ID"
  type        = string
}

variable "admins_group_id" {
  description = "AKS Admins 그룹 ID"
  type        = string
}

variable "cluster_admins_group_id" {
  description = "AKS Cluster Admins 그룹 ID"
  type        = string
}

variable "developers_group_id" {
  description = "AKS Developers 그룹 ID"
  type        = string
}

# 리소스 ID
variable "aks_cluster_id" {
  description = "AKS 클러스터 리소스 ID"
  type        = string
  default     = ""
}

variable "storage_account_id" {
  description = "스토리지 계정 리소스 ID"
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry 리소스 ID"
  type        = string
}

variable "keyvault_id" {
  description = "KeyVault 리소스 ID"
  type        = string
}

# Kubernetes RBAC 설정을 위한 변수
variable "kubeconfig_path" {
  description = "Kubernetes 구성 파일 경로"
  type        = string
  default     = "~/.kube/config"
}

variable "developer_namespace" {
  description = "개발자에게 할당할 네임스페이스"
  type        = string
  default     = "development"
}

variable "use_existing_keyvault_rbac" {
  description = "KeyVault에 대한 RBAC 권한이 이미 존재하는지 여부"
  type        = bool
  default     = false
} 