variable "kubelet_identity_id" {
  description = "AKS 클러스터의 Kubelet Identity ID"
  type        = string
}

variable "acr_id" {
  description = "Azure Container Registry ID"
  type        = string
  default     = ""
}

variable "keyvault_id" {
  description = "Azure Key Vault ID"
  type        = string
  default     = ""
}

variable "appgw_id" {
  description = "Application Gateway ID"
  type        = string
  default     = ""
}

variable "agic_identity_id" {
  description = "AGIC Identity ID"
  type        = string
  default     = ""
}

variable "enable_acr_access" {
  description = "ACR 접근 권한 부여 여부"
  type        = bool
  default     = true
}

variable "enable_keyvault_access" {
  description = "KeyVault 접근 권한 부여 여부"
  type        = bool
  default     = true
}

variable "enable_agic_access" {
  description = "AGIC 접근 권한 부여 여부"
  type        = bool
  default     = true
} 