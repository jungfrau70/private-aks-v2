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
  description = "AKS 클러스터 Kubernetes 버전"
  type        = string
  default     = "1.26.0"
}

variable "node_count" {
  description = "AKS 클러스터 노드 수"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "AKS 클러스터 노드 VM 크기"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "vnet_id" {
  description = "AKS 클러스터가 배포될 VNet ID"
  type        = string
}

variable "subnet_id" {
  description = "AKS 클러스터가 배포될 서브넷 ID"
  type        = string
}

variable "enable_auto_scaling" {
  description = "AKS 클러스터에 자동 스케일링 활성화 여부"
  type        = bool
  default     = false
}

variable "min_count" {
  description = "AKS 클러스터 자동 스케일링 최소 노드 수"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "AKS 클러스터 자동 스케일링 최대 노드 수"
  type        = number
  default     = 5
}

variable "network_plugin" {
  description = "AKS 클러스터 네트워크 플러그인(azure, kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "AKS 클러스터 네트워크 정책(calico, azure)"
  type        = string
  default     = "calico"
}

variable "service_cidr" {
  description = "Kubernetes 서비스의 CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  description = "AKS 클러스터 DNS 서비스 IP"
  type        = string
  default     = "10.0.0.10"
}

variable "admin_group_object_ids" {
  description = "AKS 클러스터 관리자 그룹 Object ID 목록"
  type        = list(string)
  default     = []
}

variable "private_cluster_enabled" {
  description = "AKS 클러스터 프라이빗 클러스터 활성화 여부"
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "AKS 클러스터 프라이빗 DNS 영역 ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "배포 환경 (dev, test, prod 등)"
  type        = string
  default     = "dev"
}

variable "acr_id" {
  description = "AKS 클러스터가 접근할 ACR ID"
  type        = string
  default     = ""
}

variable "keyvault_id" {
  description = "AKS 클러스터가 접근할 KeyVault ID"
  type        = string
  default     = ""
}

variable "appgw_id" {
  description = "AKS 클러스터가 사용할 Application Gateway ID"
  type        = string
  default     = ""
}

variable "appgw_name" {
  description = "AGIC와 통합할 Application Gateway의 이름"
  type        = string
  default     = ""
}

variable "appgw_subnet_id" {
  description = "Application Gateway가 배포된 서브넷 ID"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "AKS 클러스터에 모니터링 활성화 여부"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "AKS 클러스터 모니터링을 위한 Log Analytics 워크스페이스 ID"
  type        = string
  default     = ""
}

variable "enable_github_actions_oidc" {
  description = "GitHub Actions OIDC 통합을 활성화할지 여부"
  type        = bool
  default     = false
}

variable "github_org" {
  description = "GitHub 조직 이름"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub 리포지토리 이름"
  type        = string
  default     = ""
}

variable "use_existing_aks" {
  description = "기존 AKS 클러스터 사용 여부"
  type        = bool
  default     = false
}

variable "enable_agic" {
  description = "AKS 클러스터에 Application Gateway Ingress Controller 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_node_public_ip" {
  description = "AKS 노드에 공용 IP 할당 여부"
  type        = bool
  default     = false
}

variable "enable_pod_security_policy" {
  description = "AKS 클러스터에 Pod 보안 정책 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_rbac" {
  description = "AKS 클러스터에 RBAC 활성화 여부"
  type        = bool
  default     = true
}

variable "load_balancer_sku" {
  description = "AKS 클러스터 로드 밸런서 SKU(standard, basic)"
  type        = string
  default     = "standard"
}

variable "outbound_type" {
  description = "AKS 클러스터 아웃바운드 트래픽 유형(loadBalancer, userDefinedRouting)"
  type        = string
  default     = "loadBalancer"
}

variable "tenant_id" {
  description = "Azure AD 테넌트 ID"
  type        = string
  default     = ""
}

variable "use_existing_aks_cluster" {
  description = "기존 AKS 클러스터를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_aks_node_pool" {
  description = "기존 AKS 노드 풀을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_aks_identity" {
  description = "기존 AKS 관리 ID를 사용할지 여부"
  type        = bool
  default     = false
}

variable "enable_aks_monitoring" {
  description = "AKS 클러스터에 모니터링 활성화 여부"
  type        = bool
  default     = true
}

variable "use_existing_private_dns_zone" {
  description = "기존 Private DNS Zone 사용 여부"
  type        = bool
  default     = false
}

variable "hub_vnet_id" {
  description = "Hub VNet ID - Private DNS Zone을 연결할 Hub VNet의 ID"
  type        = string
  default     = ""
} 