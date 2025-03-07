variable "tenant_domain" {
  description = "Azure AD 테넌트 도메인"
  type        = string
}

variable "admin_password" {
  description = "관리자 계정 비밀번호 (이전 버전과의 호환성을 위해 유지)"
  type        = string
  default     = "bright2n@1234"
  sensitive   = true
}

variable "user_passwords" {
  description = "사용자별 비밀번호"
  type        = object({
    operator      = string
    admin         = string
    cluster_admin = string
    developer     = string
  })
  default     = {
    operator      = "bright2n@1234"
    admin         = "bright2n@1234"
    cluster_admin = "bright2n@1234"
    developer     = "bright2n@1234"
  }
  sensitive   = true
}

variable "use_existing_ad_groups" {
  description = "기존 Azure AD 그룹을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_ad_users" {
  description = "기존 Azure AD 사용자를 사용할지 여부"
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