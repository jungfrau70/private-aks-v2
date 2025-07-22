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

variable "use_existing_aks_identity" {
  description = "기존 AKS 사용자 관리 ID 사용 여부"
  type        = bool
  default     = false
}

variable "enable_github_actions_oidc" {
  description = "GitHub Actions OIDC 인증 활성화 여부"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub 리포지토리 (형식: 'organization/repo')"
  type        = string
  default     = ""
} 