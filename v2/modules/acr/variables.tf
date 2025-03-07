variable "resource_group_name" {
  description = "ACR이 배포될 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "ACR이 배포될 Azure 지역"
  type        = string
}

variable "acr_name" {
  description = "ACR 이름"
  type        = string
}

variable "admin_enabled" {
  description = "관리자 계정 활성화 여부"
  type        = bool
  default     = false
}

variable "sku" {
  description = "ACR SKU (Basic, Standard, Premium)"
  type        = string
  default     = "Premium"
}

variable "geo_replication" {
  description = "지역 복제 위치 목록 (Premium SKU에서만 사용 가능)"
  type        = list(string)
  default     = []
}

variable "georeplication_locations" {
  description = "지역 복제 위치 목록 (Premium SKU에서만 사용 가능)"
  type        = list(string)
  default     = []
}

variable "allowed_cidr" {
  description = "ACR에 접근 가능한 CIDR 블록"
  type        = string
  default     = "0.0.0.0/0"
}

variable "subnet_id" {
  description = "ACR Private Endpoint를 위한 서브넷 ID"
  type        = string
  default     = ""
}

variable "vnet_id" {
  description = "ACR Private Endpoint를 위한 VNet ID"
  type        = string
  default     = ""
}

variable "aks_cluster_ids" {
  description = "ACR에 접근할 AKS 클러스터 ID 목록"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "ACR에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "use_existing_acr" {
  description = "기존 ACR 사용 여부"
  type        = bool
  default     = false
}

# 프라이빗 엔드포인트 설정
variable "enable_private_endpoints" {
  description = "프라이빗 엔드포인트 활성화 여부"
  type        = bool
  default     = true
}

variable "private_dns_zone_name_acr" {
  description = "ACR용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.azurecr.io"
}

variable "use_existing_acr_private_endpoint" {
  description = "기존 ACR 프라이빗 엔드포인트 사용 여부"
  type        = bool
  default     = false
} 