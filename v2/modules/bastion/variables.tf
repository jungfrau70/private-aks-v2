variable "resource_group_name" {
  description = "Bastion 호스트가 배포될 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Bastion 호스트가 배포될 위치"
  type        = string
}

variable "bastion_name" {
  description = "Bastion 호스트 이름"
  type        = string
}

variable "subnet_id" {
  description = "Bastion 호스트가 배포될 서브넷 ID"
  type        = string
}

variable "use_existing_bastion" {
  description = "기존 Bastion 호스트 사용 여부"
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

# 추가된 변수들
variable "sku" {
  description = "Bastion 호스트의 SKU"
  type        = string
  default     = "Standard"
}

variable "scale_units" {
  description = "Bastion 호스트의 스케일 유닛 수"
  type        = number
  default     = 2
}

variable "enable_copy_paste" {
  description = "Bastion 호스트에서 복사/붙여넣기 기능 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_file_copy" {
  description = "Bastion 호스트에서 파일 복사 기능 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_ip_connect" {
  description = "Bastion 호스트에서 IP 연결 기능 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_shareable_link" {
  description = "Bastion 호스트에서 공유 가능한 링크 기능 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_tunneling" {
  description = "Bastion 호스트에서 터널링 기능 활성화 여부"
  type        = bool
  default     = true
} 