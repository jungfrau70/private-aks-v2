output "cluster_id" {
  description = "AKS 클러스터 ID"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].id : null
}

output "cluster_name" {
  description = "AKS 클러스터 이름"
  value       = var.cluster_name
}

output "kube_config" {
  description = "Kubeconfig 내용"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].kube_config_raw : null
  sensitive   = true
}

output "host" {
  description = "Kubernetes API 서버 호스트"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].kube_config[0].host : null
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 인코딩된 클라이언트 인증서"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].kube_config[0].client_certificate : null
  sensitive   = true
}

output "client_key" {
  description = "Base64 인코딩된 클라이언트 키"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].kube_config[0].client_key : null
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 인코딩된 클러스터 CA 인증서"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].kube_config[0].cluster_ca_certificate : null
  sensitive   = true
}

output "node_resource_group" {
  description = "AKS 클러스터 노드 리소스 그룹"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].node_resource_group : null
}

output "kubelet_identity" {
  description = "AKS Kubelet Identity"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].kubelet_identity[0] : null
}

output "oidc_issuer_url" {
  description = "AKS OIDC 발급자 URL"
  value       = local.aks_exists ? data.azurerm_kubernetes_cluster.existing[0].oidc_issuer_url : null
}

output "identity" {
  description = "AKS 클러스터 관리 ID"
  value       = local.aks_exists ? null : null
}

output "environment" {
  description = "AKS 클러스터 환경"
  value       = var.environment
} 