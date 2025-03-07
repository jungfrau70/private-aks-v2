variable "resource_group_name_storage" {
  description = "스토리지 계정이 배포될 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "스토리지 계정이 배포될 Azure 지역"
  type        = string
}

variable "storage_account_name" {
  description = "스토리지 계정 이름"
  type        = string
}

variable "file_share_name" {
  description = "파일 공유 이름"
  type        = string
}

variable "allowed_ips" {
  description = "스토리지 계정에 접근 가능한 IP 주소 목록"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Private Endpoint를 생성할 서브넷 ID 목록"
  type        = list(string)
  default     = []
}

variable "private_endpoint_subnet_id" {
  description = "프라이빗 엔드포인트를 위한 서브넷 ID"
  type        = string
  default     = ""
}

variable "tags" {
  description = "스토리지 계정에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "use_existing_resource_group_hub" {
  description = "기존 Hub 리소스 그룹 사용 여부"
  type        = bool
  default     = true
}

variable "use_existing_resource_group_spoke" {
  description = "기존 Spoke 리소스 그룹 사용 여부"
  type        = bool
  default     = true
}

variable "use_existing_resource_group_storage" {
  description = "기존 Storage 리소스 그룹 사용 여부"
  type        = bool
  default     = true
}

variable "use_existing_storage" {
  description = "Whether to use existing storage resources"
  type        = bool
  default     = false
}

variable "use_existing_storage_account" {
  description = "Whether to use an existing storage account"
  type        = bool
  default     = false
}

variable "use_existing_file_share" {
  description = "Whether to use an existing file share"
  type        = bool
  default     = false
}

variable "use_existing_container" {
  description = "Whether to use an existing container"
  type        = bool
  default     = false
}

variable "use_existing_private_endpoint" {
  description = "Whether to use an existing private endpoint"
  type        = bool
  default     = false
}

variable "use_existing_private_dns_zone_blob" {
  description = "Whether to use an existing private DNS zone for blob storage"
  type        = bool
  default     = false
}

variable "use_existing_private_dns_zone_file" {
  description = "Whether to use an existing private DNS zone for file storage"
  type        = bool
  default     = false
}

variable "endpoints_subnet_id" {
  description = "The ID of the endpoints subnet"
  type        = string
}

variable "virtual_network_id" {
  description = "The ID of the virtual network"
  type        = string
}

# 추가 스토리지 설정
variable "container_name" {
  description = "Blob Storage 컨테이너 이름"
  type        = string
  default     = "aks-workshop-container"
}

variable "blob_name" {
  description = "Blob 이름"
  type        = string
  default     = "aks-workshop-blob"
}

# 프라이빗 엔드포인트 설정
variable "enable_private_endpoints" {
  description = "프라이빗 엔드포인트 활성화 여부"
  type        = bool
  default     = true
}

variable "private_dns_zone_name_blob" {
  description = "Blob Storage용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.blob.core.windows.net"
}

variable "private_dns_zone_name_file" {
  description = "파일 스토리지용 Private DNS 영역 이름"
  type        = string
  default     = "privatelink.file.core.windows.net"
}

# 기존 파일 공유 감지를 위한 변수
variable "existing_file_share_names" {
  description = "이미 존재하는 파일 공유 이름 목록"
  type        = list(string)
  default     = []
}

variable "existing_storage_account_names" {
  description = "이미 존재하는 스토리지 계정 이름 목록"
  type        = list(string)
  default     = []
} 