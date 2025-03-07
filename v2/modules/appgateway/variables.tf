variable "resource_group_name" {
  description = "Application Gateway가 배포될 리소스 그룹 이름"
  type        = string
}

variable "location" {
  description = "Application Gateway가 배포될 위치"
  type        = string
}

variable "appgw_name" {
  description = "Application Gateway 이름"
  type        = string
}

variable "subnet_id" {
  description = "Application Gateway가 배포될 서브넷 ID"
  type        = string
}

variable "sku_name" {
  description = "Application Gateway SKU 이름"
  type        = string
  default     = "Standard_v2"
}

variable "sku_tier" {
  description = "Application Gateway SKU 티어"
  type        = string
  default     = "Standard_v2"
}

variable "capacity" {
  description = "Application Gateway 인스턴스 수"
  type        = number
  default     = 2
}

variable "availability_zones" {
  description = "Application Gateway 가용성 영역"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "enable_agic" {
  description = "Application Gateway Ingress Controller 활성화 여부"
  type        = bool
  default     = true
}

variable "user_assigned_identity_id" {
  description = "Application Gateway에 할당할 사용자 관리 ID"
  type        = string
  default     = ""
}

variable "aks_identities" {
  description = "Application Gateway에 접근 권한을 부여할 AKS 클러스터 Managed Identity ID 목록"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "use_existing_app_gateway" {
  description = "기존 Application Gateway 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_app_gateway_public_ip" {
  description = "기존 애플리케이션 게이트웨이 공용 IP를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_app_gateway_waf_policy" {
  description = "기존 애플리케이션 게이트웨이 WAF 정책을 사용할지 여부"
  type        = bool
  default     = false
}

variable "domain_name_label" {
  description = "Application Gateway 공용 IP의 도메인 이름 레이블"
  type        = string
  default     = ""
}

variable "private_ip_address" {
  description = "Application Gateway의 프라이빗 IP 주소"
  type        = string
  default     = "10.1.2.10"
}

variable "enable_waf" {
  description = "WAF(Web Application Firewall) 활성화 여부"
  type        = bool
  default     = false
}

variable "waf_mode" {
  description = "WAF 모드 (Detection 또는 Prevention)"
  type        = string
  default     = "Detection"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF 모드는 'Detection' 또는 'Prevention'이어야 합니다."
  }
}

variable "enable_github_actions" {
  description = "GitHub Actions 통합 활성화 여부"
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

variable "github_branch" {
  description = "GitHub 브랜치 이름"
  type        = string
  default     = "main"
} 