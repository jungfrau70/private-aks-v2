variable "resource_group_name" {
  description = "DevOps Agent가 배포될 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "DevOps Agent가 배포될 Azure 지역"
  type        = string
}

variable "agent_pool_name" {
  description = "DevOps Agent 풀 이름"
  type        = string
}

variable "subnet_id" {
  description = "DevOps Agent VM이 배포될 서브넷 ID"
  type        = string
}

variable "vnet_id" {
  description = "DevOps Agent가 배포될 VNet ID"
  type        = string
  default     = ""
}

variable "vm_name" {
  description = "DevOps Agent VM 이름"
  type        = string
}

variable "vm_size" {
  description = "DevOps Agent VM 크기"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "instance_count" {
  description = "DevOps Agent 인스턴스 수"
  type        = number
  default     = 2
}

variable "admin_username" {
  description = "DevOps Agent VM 관리자 사용자 이름"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "DevOps Agent VM 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "enable_auto_scaling" {
  description = "자동 확장 활성화 여부"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "자동 확장 최소 인스턴스 수"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "자동 확장 최대 인스턴스 수"
  type        = number
  default     = 5
}

variable "scale_out_threshold" {
  description = "스케일 아웃 CPU 임계값(%)"
  type        = number
  default     = 75
}

variable "scale_in_threshold" {
  description = "스케일 인 CPU 임계값(%)"
  type        = number
  default     = 25
}

variable "organization_url" {
  description = "Azure DevOps 조직 URL"
  type        = string
}

variable "pat_token" {
  description = "Azure DevOps PAT 토큰"
  type        = string
  sensitive   = true
}

variable "script_storage_url" {
  description = "스크립트가 저장된 스토리지 URL"
  type        = string
  default     = "./scripts"
}

variable "nsg_name" {
  description = "DevOps Agent NSG 이름"
  type        = string
  default     = "Agent_NSG"
}

variable "tags" {
  description = "DevOps Agent 리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "use_vmss" {
  description = "VM Scale Set 사용 여부"
  type        = bool
  default     = true
} 