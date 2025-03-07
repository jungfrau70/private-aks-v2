output "acr_id" {
  description = "ACR ID"
  value       = local.acr_id
}

output "acr_name" {
  description = "ACR 이름"
  value       = var.acr_name
}

output "acr_login_server" {
  description = "ACR 로그인 서버"
  value       = local.acr_login_server
}

output "acr_admin_username" {
  description = "Azure Container Registry 관리자 사용자 이름"
  value       = var.admin_enabled ? (local.acr_exists ? data.azurerm_container_registry.acr[0].admin_username : azurerm_container_registry.acr[0].admin_username) : null
}

output "acr_admin_password" {
  description = "Azure Container Registry 관리자 비밀번호"
  value       = var.admin_enabled ? (local.acr_exists ? data.azurerm_container_registry.acr[0].admin_password : azurerm_container_registry.acr[0].admin_password) : null
  sensitive   = true
}

output "private_endpoint_ip" {
  description = "ACR Private Endpoint IP 주소"
  value       = local.pe_exists ? null : (length(azurerm_private_endpoint.acr_pe) > 0 ? azurerm_private_endpoint.acr_pe[0].private_service_connection[0].private_ip_address : null)
} 