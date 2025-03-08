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

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "use_existing_private_dns_zone" {
  description = "기존 Private DNS Zone 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_private_dns_zone_aks" {
  description = "기존 AKS Private DNS Zone 사용 여부"
  type        = bool
  default     = false
}

variable "vnet_id" {
  description = "AKS 클러스터가 배포될 VNet ID"
  type        = string
}

variable "hub_vnet_id" {
  description = "Hub VNet ID"
  type        = string
  default     = ""
}

variable "private_dns_zone_id" {
  description = "Private DNS Zone ID"
  type        = string
  default     = ""
}

variable "aks_cluster_id" {
  description = "AKS 클러스터 ID"
  type        = string
}

variable "private_fqdn" {
  description = "AKS 클러스터의 Private FQDN"
  type        = string
  default     = ""
}

variable "use_existing_hub_vnet_link" {
  description = "기존 Hub VNet 링크 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_aks_dns_hub_link" {
  description = "기존 AKS DNS Hub VNet 링크 사용 여부"
  type        = bool
  default     = false
}

variable "use_system_dns_zone" {
  description = "시스템 관리형 DNS Zone 사용 여부"
  type        = bool
  default     = false
}

variable "use_hub_vnet_link" {
  description = "Hub VNet 링크 사용 여부"
  type        = bool
  default     = true
}

variable "use_static_ip" {
  description = "정적 IP 주소 사용 여부"
  type        = bool
  default     = true
}

variable "static_ip" {
  description = "AKS API 서버의 정적 IP 주소"
  type        = string
  default     = "10.1.0.4"
}

variable "skip_nic_lookup" {
  description = "네트워크 인터페이스 조회 건너뛰기 여부"
  type        = bool
  default     = true
}

variable "skip_dns_record" {
  description = "DNS 레코드 생성 건너뛰기 여부"
  type        = bool
  default     = true
}

variable "nic_id_suffix" {
  description = "AKS API 서버 NIC ID의 접미사"
  type        = string
  default     = "b0e62b70-fdab-4994-a1d2-f3cbdbadbbab"
}

variable "api_server_ip" {
  description = "AKS API 서버의 IP 주소 (동적으로 조회된 값)"
  type        = string
  default     = ""
} 