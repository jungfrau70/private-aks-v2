output "keyvault_id" {
  description = "KeyVault ID"
  value       = local.keyvault_id
}

output "keyvault_name" {
  description = "KeyVault 이름"
  value       = var.keyvault_name
}

output "keyvault_uri" {
  description = "KeyVault URI"
  value       = local.keyvault_uri
}

output "private_endpoint_id" {
  description = "KeyVault Private Endpoint ID"
  value       = length(azurerm_private_endpoint.keyvault_pe) > 0 ? azurerm_private_endpoint.keyvault_pe[0].id : null
}

output "private_endpoint_ip" {
  description = "KeyVault Private Endpoint IP 주소"
  value       = length(azurerm_private_endpoint.keyvault_pe) > 0 ? azurerm_private_endpoint.keyvault_pe[0].private_service_connection[0].private_ip_address : null
}

output "private_dns_zone_id" {
  description = "KeyVault Private DNS Zone ID"
  value       = length(azurerm_private_dns_zone.keyvault_dns) > 0 ? azurerm_private_dns_zone.keyvault_dns[0].id : null
}

output "private_dns_zone_name" {
  description = "KeyVault Private DNS Zone 이름"
  value       = length(azurerm_private_dns_zone.keyvault_dns) > 0 ? azurerm_private_dns_zone.keyvault_dns[0].name : null
} 