variable "create_github_repo" {
  description = "GitHub 리포지토리 생성 여부"
  type        = bool
  default     = false
}

variable "github_repo_name" {
  description = "GitHub 리포지토리 이름"
  type        = string
  default     = ""
}

variable "github_repo_description" {
  description = "GitHub 리포지토리 설명"
  type        = string
  default     = "AKS 애플리케이션 리포지토리"
}

variable "github_repo_visibility" {
  description = "GitHub 리포지토리 가시성"
  type        = string
  default     = "private"
}

variable "github_template_owner" {
  description = "GitHub 템플릿 소유자"
  type        = string
  default     = ""
}

variable "github_template_repo" {
  description = "GitHub 템플릿 리포지토리"
  type        = string
  default     = ""
}

variable "azure_credentials_json" {
  description = "Azure 서비스 주체 JSON"
  type        = string
  default     = ""
  sensitive   = true
}

variable "acr_login_server" {
  description = "애플리케이션 이미지가 저장된 ACR 로그인 서버"
  type        = string
}

variable "resource_group_name" {
  description = "애플리케이션이 배포될 리소스 그룹 이름"
  type        = string
}

variable "aks_cluster_name" {
  description = "애플리케이션이 배포될 AKS 클러스터 이름"
  type        = string
}

variable "app_name" {
  description = "애플리케이션 이름"
  type        = string
}

variable "app_image_name" {
  description = "애플리케이션 이미지 이름"
  type        = string
}

variable "app_image_tag" {
  description = "애플리케이션 이미지 태그"
  type        = string
  default     = "latest"
}

variable "app_replicas" {
  description = "애플리케이션 레플리카 수"
  type        = number
  default     = 2
}

variable "app_port" {
  description = "애플리케이션 포트"
  type        = number
  default     = 8080
}

variable "app_cpu_request" {
  description = "애플리케이션 CPU 요청"
  type        = string
  default     = "100m"
}

variable "app_memory_request" {
  description = "애플리케이션 메모리 요청"
  type        = string
  default     = "128Mi"
}

variable "app_cpu_limit" {
  description = "애플리케이션 CPU 제한"
  type        = string
  default     = "500m"
}

variable "app_memory_limit" {
  description = "애플리케이션 메모리 제한"
  type        = string
  default     = "512Mi"
}

variable "app_host" {
  description = "애플리케이션 호스트 이름"
  type        = string
}

variable "app_path" {
  description = "애플리케이션 경로"
  type        = string
  default     = "/"
}

variable "app_template_path" {
  description = "애플리케이션 템플릿 파일 경로"
  type        = string
  default     = "templates"
}

variable "app_output_path" {
  description = "애플리케이션 출력 파일 경로"
  type        = string
  default     = "output"
}

variable "app_namespace" {
  description = "애플리케이션 네임스페이스"
  type        = string
  default     = "default"
}

variable "app_source_dir" {
  description = "애플리케이션 소스 디렉토리"
  type        = string
  default     = "src"
}

variable "use_agic" {
  description = "AGIC 사용 여부"
  type        = bool
  default     = false
}

variable "replicas" {
  description = "애플리케이션 복제본 수"
  type        = number
  default     = 3
}

variable "cpu_request" {
  description = "애플리케이션 CPU 요청량"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "애플리케이션 메모리 요청량"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "애플리케이션 CPU 제한량"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "애플리케이션 메모리 제한량"
  type        = string
  default     = "512Mi"
}

variable "port" {
  description = "애플리케이션 포트"
  type        = number
  default     = 80
}

variable "enable_ingress" {
  description = "애플리케이션 Ingress 활성화 여부"
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "애플리케이션 Ingress 클래스"
  type        = string
  default     = "azure/application-gateway"
}

variable "enable_tls" {
  description = "애플리케이션 TLS 활성화 여부"
  type        = bool
  default     = false
}

variable "tls_secret_name" {
  description = "애플리케이션 TLS 시크릿 이름"
  type        = string
  default     = "app-tls-secret"
} 