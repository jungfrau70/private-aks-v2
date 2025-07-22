variable "private_dns_zone_id" {
  description = "The resource ID of the existing Private DNS Zone for PostgreSQL Flexible Server."
  type        = string
}
variable "resource_group_name" {
  type        = string
  description = "리소스 그룹 이름"
}

variable "location" {
  type        = string
  description = "Azure 리전"
}

variable "environment" {
  type        = string
  description = "환경 (dev, prod 등)"
}

variable "subnet_id" {
  type        = string
  description = "데이터베이스 서브넷 ID"
}

variable "vnet_id" {
  type        = string
  description = "VNet ID"
}

variable "admin_username" {
  type        = string
  description = "관리자 사용자 이름"
}

variable "admin_password" {
  type        = string
  description = "관리자 비밀번호"
  sensitive   = true
}

variable "storage_mb" {
  type        = number
  description = "스토리지 크기 (MB)"
  default     = 32768
}

variable "sku_name" {
  type        = string
  description = "SKU 이름"
  default     = "GP_Standard_D2s_v3"
}

variable "tags" {
  type        = map(string)
  description = "리소스 태그"
  default     = {}
}

variable "vnet_name" {
  type        = string
  description = "The name of the virtual network"
} 

variable "subnet_name" {
  type        = string
  description = "The name of the subnet"
} 


variable "subnet_prefix" {
  type        = string
  description = "The prefix of the subnet"
} 

variable "postgresql_server_name" {
  description = "PostgreSQL 서버 이름"
  type        = string
  default     = "pgsql-hub-server-2"
}

variable "backup_retention_days" {
  description = "백업 보존 기간(일)"
  type        = number
  default     = 7
}

variable "geo_redundant_backup_enabled" {
  description = "지역 중복 백업 활성화 여부"
  type        = bool
  default     = false
}

variable "administrator_login" {
  description = "관리자 로그인 이름"
  type        = string
}

variable "administrator_login_password" {
  description = "관리자 로그인 비밀번호"
  type        = string
  sensitive   = true
}

variable "postgresql_version" {
  description = "PostgreSQL 버전"
  type        = string
  default     = "11"
}

variable "database_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "프라이빗 엔드포인트가 생성될 서브넷 ID"
  type        = string
}

variable "use_existing_postgresql" {
  description = "기존 PostgreSQL 서버 사용 여부"
  type        = bool
  default     = false
}

# 프라이빗 엔드포인트 설정
variable "enable_private_endpoints" {
  description = "프라이빗 엔드포인트 활성화 여부"
  type        = bool
  default     = true
}

variable "private_dns_zone_name_postgres" {
  description = "PostgreSQL용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.postgres.database.azure.com"
} 