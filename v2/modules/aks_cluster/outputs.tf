output "cluster_id" {
  description = "AKS 클러스터의 ID"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].id : (length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].id : null)
}

output "cluster_name" {
  description = "AKS 클러스터의 이름"
  value       = var.cluster_name
}

output "kube_config" {
  description = "AKS 클러스터의 kubeconfig"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].kube_config_raw : (length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].kube_config_raw : null)
  sensitive   = true
}

output "host" {
  description = "Kubernetes API 서버 호스트"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].kube_config[0].host : null
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 인코딩된 클라이언트 인증서"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].kube_config[0].client_certificate : null
  sensitive   = true
}

output "client_key" {
  description = "Base64 인코딩된 클라이언트 키"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].kube_config[0].client_key : null
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 인코딩된 클러스터 CA 인증서"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].kube_config[0].cluster_ca_certificate : null
  sensitive   = true
}

output "node_resource_group" {
  description = "AKS 클러스터 노드 리소스 그룹"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].node_resource_group : (length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].node_resource_group : null)
}

output "kubelet_identity" {
  description = "AKS 클러스터의 Kubelet Identity"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].kubelet_identity[0].object_id : (length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].kubelet_identity[0].object_id : null)
}

output "oidc_issuer_url" {
  description = "AKS OIDC 발급자 URL"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].oidc_issuer_url : (length(azurerm_kubernetes_cluster.aks) > 0 ? azurerm_kubernetes_cluster.aks[0].oidc_issuer_url : null)
}

output "private_fqdn" {
  description = "AKS 클러스터의 Private FQDN"
  value       = var.use_existing_aks_cluster ? data.azurerm_kubernetes_cluster.existing[0].private_fqdn : (length(azurerm_kubernetes_cluster.aks) > 0 && var.private_cluster_enabled ? azurerm_kubernetes_cluster.aks[0].private_fqdn : null)
}

output "agic_identity_id" {
  description = "AGIC Identity ID"
  value       = var.enable_agic && var.appgw_id != "" && length(azurerm_kubernetes_cluster.aks) > 0 ? try(azurerm_kubernetes_cluster.aks[0].ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id, null) : null
} 