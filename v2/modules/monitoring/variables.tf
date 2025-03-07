variable "prefix" {
  type        = string
  description = "리소스 이름 접두사"
}

variable "resource_group_name_hub" {
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

variable "project_name" {
  type        = string
  description = "프로젝트 이름"
}

variable "log_analytics_retention_days" {
  type        = number
  description = "로그 보존 기간(일)"
  default     = 30
}

variable "monitor_action_group_name" {
  type        = string
  description = "모니터링 액션 그룹 이름"
}

variable "monitor_email_receivers" {
  type = list(object({
    name                    = string
    email_address          = string
    use_common_alert_schema = bool
  }))
  description = "알림을 받을 이메일 수신자 목록"
}

variable "alert_scopes" {
  description = "알림을 적용할 리소스 ID 목록"
  type        = list(string)
  default     = []
}

variable "vnet_id" {
  description = "The ID of the Hub Virtual Network for monitoring"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics 워크스페이스 이름"
  type        = string
}

variable "log_analytics_workspace_sku" {
  description = "Log Analytics 워크스페이스 SKU"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_workspace_retention_days" {
  description = "Log Analytics 워크스페이스 데이터 보존 기간(일)"
  type        = number
  default     = 30
}

variable "aks_cluster_id" {
  description = "AKS 클러스터 ID"
  type        = string
}

variable "aks_cluster_name" {
  description = "AKS 클러스터 이름"
  type        = string
}

variable "app_gateway_id" {
  description = "Application Gateway ID"
  type        = string
  default     = null
}

variable "subscription_id" {
  description = "Azure 구독 ID"
  type        = string
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

variable "enable_app_gateway_monitoring" {
  description = "Application Gateway 모니터링을 활성화할지 여부"
  type        = bool
  default     = false
}

variable "enable_network_monitoring" {
  description = "네트워크 모니터링을 활성화할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_workspace" {
  description = "기존 Log Analytics 워크스페이스를 사용할지 여부"
  type        = bool
  default     = false
}

# 모니터링 추가 설정
variable "enable_aks_monitoring" {
  description = "AKS 모니터링을 활성화할지 여부"
  type        = bool
  default     = true
}

variable "use_existing_log_analytics_solution" {
  description = "기존 Log Analytics 솔루션을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_monitor_action_group" {
  description = "기존 모니터 액션 그룹을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_monitor_alerts" {
  description = "기존 모니터 알림을 사용할지 여부"
  type        = bool
  default     = false
} 