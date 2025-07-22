variable "resource_group_name" {
  description = "Jumpbox VM이 배포될 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Jumpbox VM이 배포될 위치"
  type        = string
}

variable "jumpbox_name" {
  description = "Jumpbox VM 이름"
  type        = string
}

variable "subnet_id" {
  description = "Jumpbox VM이 배포될 서브넷 ID"
  type        = string
}

variable "vm_size" {
  description = "Jumpbox VM 크기"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "admin_username" {
  description = "Jumpbox VM 관리자 사용자 이름"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Jumpbox VM 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "script_storage_url" {
  description = "스크립트가 저장된 스토리지 URL"
  type        = string
  default     = "./scripts"
}

variable "use_existing_jumpbox" {
  description = "기존 Jumpbox VM 사용 여부"
  type        = bool
  default     = false
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "os_disk_size_gb" {
  description = "Jumpbox VM의 OS 디스크 크기(GB)"
  type        = number
  default     = 128
}

variable "os_disk_type" {
  description = "Jumpbox VM의 OS 디스크 유형"
  type        = string
  default     = "Premium_LRS"
}

variable "enable_public_ip" {
  description = "Jumpbox VM에 공용 IP 할당 여부"
  type        = bool
  default     = false
}

variable "enable_boot_diagnostics" {
  description = "Jumpbox VM에 부팅 진단 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_auto_shutdown" {
  description = "Jumpbox VM에 자동 종료 활성화 여부"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Jumpbox VM 자동 종료 시간(24시간 형식, 예: 2000)"
  type        = string
  default     = "2000"
}

variable "auto_shutdown_timezone" {
  description = "Jumpbox VM 자동 종료 시간대"
  type        = string
  default     = "Korea Standard Time"
} 