output "appgw_id" {
  description = "Application Gateway ID"
  value       = local.appgw_id
}

output "appgw_name" {
  description = "Application Gateway 이름"
  value       = var.appgw_name
}

output "appgw_public_ip" {
  description = "Application Gateway 공용 IP 주소"
  value       = local.appgw_exists ? null : (length(azurerm_public_ip.appgw_pip) > 0 ? azurerm_public_ip.appgw_pip[0].ip_address : null)
}

output "appgw_fqdn" {
  description = "Application Gateway 공용 IP의 FQDN"
  value       = local.appgw_exists ? null : (length(azurerm_public_ip.appgw_pip) > 0 ? azurerm_public_ip.appgw_pip[0].fqdn : null)
}

output "appgw_backend_pool_id" {
  description = "Application Gateway 기본 백엔드 풀 ID"
  value       = local.appgw_exists ? (
    length(data.azurerm_application_gateway.existing) > 0 ? 
    try([for pool in data.azurerm_application_gateway.existing[0].backend_address_pool : pool.id if pool.name == "default-backend-pool"][0], null) : null
  ) : (
    length(azurerm_application_gateway.appgw) > 0 ? 
    try([for pool in azurerm_application_gateway.appgw[0].backend_address_pool : pool.id if pool.name == "defaultBackendPool"][0], null) : null
  )
}

output "appgw_http_settings_id" {
  description = "Application Gateway 기본 HTTP 설정 ID"
  value       = local.appgw_exists ? (
    length(data.azurerm_application_gateway.existing) > 0 ? 
    try([for setting in data.azurerm_application_gateway.existing[0].backend_http_settings : setting.id if setting.name == "default-http-settings"][0], null) : null
  ) : (
    length(azurerm_application_gateway.appgw) > 0 ? 
    try([for setting in azurerm_application_gateway.appgw[0].backend_http_settings : setting.id if setting.name == "defaultHttpSettings"][0], null) : null
  )
}

output "appgw_frontend_ip_configuration_id" {
  description = "Application Gateway 프론트엔드 IP 구성 ID"
  value       = local.appgw_exists ? data.azurerm_application_gateway.existing[0].frontend_ip_configuration[0].id : (length(azurerm_application_gateway.appgw) > 0 ? azurerm_application_gateway.appgw[0].frontend_ip_configuration[0].id : null)
}

output "github_actions_identity_id" {
  description = "GitHub Actions 통합을 위한 사용자 관리 ID"
  value       = var.enable_github_actions && var.github_repo != "" ? azurerm_user_assigned_identity.github_actions_identity[0].id : null
}

output "github_actions_identity_principal_id" {
  description = "GitHub Actions 통합을 위한 사용자 관리 ID의 Principal ID"
  value       = var.enable_github_actions && var.github_repo != "" ? azurerm_user_assigned_identity.github_actions_identity[0].principal_id : null
}

output "github_actions_identity_client_id" {
  description = "GitHub Actions 통합을 위한 사용자 관리 ID의 Client ID"
  value       = var.enable_github_actions && var.github_repo != "" ? azurerm_user_assigned_identity.github_actions_identity[0].client_id : null
} 