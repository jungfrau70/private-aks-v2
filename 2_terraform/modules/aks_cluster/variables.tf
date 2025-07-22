variable "resource_group_name" {
  description = "AKS 클러스터가 배포될 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "AKS 클러스터가 배포될 위치"
  type        = string
}

variable "cluster_name" {
  description = "AKS 클러스터 이름"
  type        = string
}

variable "kubernetes_version" {
  description = "AKS 클러스터의 Kubernetes 버전"
  type        = string
  default     = "1.25.6"
}

variable "node_count" {
  description = "AKS 클러스터의 노드 수"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "AKS 클러스터 노드의 VM 크기"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "subnet_id" {
  description = "AKS 클러스터가 배포될 서브넷 ID"
  type        = string
}

variable "enable_auto_scaling" {
  description = "AKS 클러스터의 자동 확장 활성화 여부"
  type        = bool
  default     = false
}

variable "min_count" {
  description = "자동 확장 시 최소 노드 수"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "자동 확장 시 최대 노드 수"
  type        = number
  default     = 3
}

variable "enable_node_public_ip" {
  description = "노드에 공용 IP 할당 여부"
  type        = bool
  default     = false
}

variable "identity_id" {
  description = "AKS 클러스터에 할당할 사용자 관리 ID의 ID"
  type        = string
}

variable "enable_agic" {
  description = "Application Gateway Ingress Controller 활성화 여부"
  type        = bool
  default     = false
}

variable "appgw_id" {
  description = "Application Gateway ID"
  type        = string
  default     = ""
}

variable "admin_group_object_ids" {
  description = "AKS 클러스터 관리자 그룹 Object ID 목록"
  type        = list(string)
  default     = []
}

variable "tenant_id" {
  description = "Azure AD 테넌트 ID"
  type        = string
}

variable "enable_github_actions_oidc" {
  description = "GitHub Actions OIDC 인증 활성화 여부"
  type        = bool
  default     = false
}

variable "network_plugin" {
  description = "AKS 클러스터의 네트워크 플러그인"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "AKS 클러스터의 네트워크 정책"
  type        = string
  default     = "azure"
}

variable "load_balancer_sku" {
  description = "AKS 클러스터의 로드 밸런서 SKU"
  type        = string
  default     = "standard"
}

variable "outbound_type" {
  description = "AKS 클러스터의 아웃바운드 트래픽 유형"
  type        = string
  default     = "loadBalancer"
}

variable "service_cidr" {
  description = "Kubernetes 서비스의 CIDR 범위"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "Kubernetes DNS 서비스의 IP 주소"
  type        = string
  default     = "10.0.0.10"
}

variable "private_cluster_enabled" {
  description = "Private 클러스터 활성화 여부"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID"
  type        = string
  default     = ""
}

variable "enable_rbac" {
  description = "RBAC 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "모니터링 활성화 여부"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "use_existing_aks_cluster" {
  description = "기존 AKS 클러스터 사용 여부"
  type        = bool
  default     = false
} 