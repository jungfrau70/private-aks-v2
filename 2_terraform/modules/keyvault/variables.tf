variable "resource_group_name" {
  description = "KeyVault가 배포될 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "KeyVault가 배포될 Azure 지역"
  type        = string
}

variable "keyvault_name" {
  description = "KeyVault 이름"
  type        = string
}

variable "tenant_id" {
  description = "Azure 테넌트 ID"
  type        = string
}

variable "sku_name" {
  description = "KeyVault SKU 이름 (standard 또는 premium)"
  type        = string
  default     = "standard"
}

variable "purge_protection_enabled" {
  description = "KeyVault 삭제 방지 활성화 여부"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "KeyVault 소프트 삭제 보존 기간(일)"
  type        = number
  default     = 7
}

variable "enable_rbac_authorization" {
  description = "RBAC 인증 활성화 여부"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "KeyVault Private Endpoint를 위한 서브넷 ID"
  type        = string
  default     = ""
}

variable "vnet_id" {
  description = "KeyVault Private Endpoint를 위한 VNet ID"
  type        = string
  default     = ""
}

variable "allowed_subnet_ids" {
  description = "KeyVault에 접근 가능한 서브넷 ID 목록"
  type        = list(string)
  default     = []
}

variable "allowed_ips" {
  description = "KeyVault에 접근 가능한 IP 주소 목록"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "KeyVault에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "aks_identities" {
  description = "KeyVault에 접근 권한을 부여할 AKS 클러스터 Managed Identity ID 목록"
  type        = list(string)
  default     = []
}

variable "use_existing_keyvault" {
  description = "기존 KeyVault 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_ad_groups" {
  description = "기존 Azure AD 그룹 사용 여부"
  type        = bool
  default     = false
}

variable "operators_group_id" {
  description = "기존 AKS Operators 그룹 ID"
  type        = string
  default     = ""
}

variable "admins_group_id" {
  description = "기존 AKS Admins 그룹 ID"
  type        = string
  default     = ""
}

variable "cluster_admins_group_id" {
  description = "기존 AKS Cluster Admins 그룹 ID"
  type        = string
  default     = ""
}

variable "developers_group_id" {
  description = "기존 AKS Developers 그룹 ID"
  type        = string
  default     = ""
}

# 프라이빗 엔드포인트 설정
variable "enable_private_endpoints" {
  description = "프라이빗 엔드포인트 활성화 여부"
  type        = bool
  default     = true
}

variable "private_dns_zone_name_kv" {
  description = "KeyVault용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.vaultcore.azure.net"
}

# 키볼트 액세스 정책 설정
variable "enable_keyvault_access_policy" {
  description = "KeyVault 액세스 정책 활성화 여부"
  type        = bool
  default     = true
}

variable "keyvault_admin_object_ids" {
  description = "KeyVault 관리자 Object ID 목록"
  type        = list(string)
  default     = []
}

variable "use_existing_keyvault_private_endpoint" {
  description = "기존 KeyVault 프라이빗 엔드포인트 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_keyvault_role_assignments" {
  description = "기존 KeyVault 역할 할당을 사용할지 여부"
  type        = bool
  default     = false
} 