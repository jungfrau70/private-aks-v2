output "app_deployment_manifest_path" {
  description = "애플리케이션 배포 매니페스트 경로"
  value       = local_file.app_deployment.filename
}

output "app_service_manifest_path" {
  description = "애플리케이션 서비스 매니페스트 경로"
  value       = local_file.app_service.filename
}

output "app_ingress_manifest_path" {
  description = "애플리케이션 인그레스 매니페스트 경로"
  value       = local_file.app_ingress.filename
}

output "app_build_script_path" {
  description = "애플리케이션 빌드 스크립트 경로"
  value       = local_file.app_build_script.filename
}

output "app_deploy_script_path" {
  description = "애플리케이션 배포 스크립트 경로"
  value       = local_file.app_deploy_script.filename
}

output "github_workflow_path" {
  description = "GitHub 워크플로우 파일 경로"
  value       = local_file.github_workflow.filename
}

output "github_repo_url" {
  description = "GitHub 리포지토리 URL"
  value       = var.create_github_repo ? "https://github.com/${github_repository.app_repo[0].full_name}" : ""
}

output "kubernetes_namespace_manifest_path" {
  description = "Kubernetes 네임스페이스 매니페스트 경로"
  value       = local_file.kubernetes_namespace.filename
}

output "kubernetes_deployment_manifest_path" {
  description = "Kubernetes 디플로이먼트 매니페스트 경로"
  value       = local_file.kubernetes_deployment.filename
}

output "kubernetes_service_manifest_path" {
  description = "Kubernetes 서비스 매니페스트 경로"
  value       = local_file.kubernetes_service.filename
}

output "kubernetes_ingress_manifest_path" {
  description = "Kubernetes 인그레스 매니페스트 경로"
  value       = local_file.kubernetes_ingress.filename
} 