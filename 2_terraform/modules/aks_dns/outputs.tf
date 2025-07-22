output "private_dns_zone_id" {
  description = "AKS 클러스터의 Private DNS Zone ID"
  value       = var.use_existing_private_dns_zone ? null : (length(azurerm_private_dns_zone.aks_dns) > 0 ? azurerm_private_dns_zone.aks_dns[0].id : null)
}

output "private_dns_zone_name" {
  description = "AKS 클러스터의 Private DNS Zone 이름"
  value       = var.use_existing_private_dns_zone ? null : (length(azurerm_private_dns_zone.aks_dns) > 0 ? azurerm_private_dns_zone.aks_dns[0].name : null)
}

output "private_endpoint_ip" {
  description = "AKS 클러스터의 Private Endpoint IP 주소 (자동 생성된 Private Endpoint)"
  value       = var.use_existing_private_dns_zone_aks ? null : local.api_server_ip
}

output "hub_vnet_dns_link" {
  description = "Hub VNet DNS 링크 정보"
  value       = var.use_existing_private_dns_zone || var.use_existing_hub_vnet_link || var.hub_vnet_id == "" ? null : (length(azurerm_private_dns_zone_virtual_network_link.aks_dns_hub_link) > 0 ? azurerm_private_dns_zone_virtual_network_link.aks_dns_hub_link[0].id : null)
}

output "system_dns_hub_link" {
  description = "시스템 DNS Zone에 대한 Hub VNet 링크 정보"
  value       = var.use_system_dns_zone && var.hub_vnet_id != "" && !var.use_existing_hub_vnet_link ? (length(azurerm_private_dns_zone_virtual_network_link.system_dns_hub_link) > 0 ? azurerm_private_dns_zone_virtual_network_link.system_dns_hub_link[0].id : null) : null
}

output "api_server_nic_id" {
  description = "AKS API 서버의 NIC ID"
  value       = null
}

output "api_server_private_ip" {
  description = "AKS API 서버의 Private IP"
  value       = var.use_existing_private_dns_zone_aks ? null : local.api_server_ip
}

output "dns_a_record_id" {
  description = "AKS API 서버의 DNS A 레코드 ID (클러스터 FQDN용)"
  value       = var.use_existing_private_dns_zone || var.use_existing_private_dns_zone_aks || var.skip_dns_record ? null : (length(azurerm_private_dns_a_record.aks_dns_a_record) > 0 ? azurerm_private_dns_a_record.aks_dns_a_record[0].id : null)
}

output "kube_apiserver_record_id" {
  description = "AKS API 서버의 DNS A 레코드 ID (kube-apiserver용)"
  value       = var.use_existing_private_dns_zone || var.use_existing_private_dns_zone_aks || var.skip_dns_record ? null : (length(azurerm_private_dns_a_record.aks_kube_apiserver_record) > 0 ? azurerm_private_dns_a_record.aks_kube_apiserver_record[0].id : null)
} 