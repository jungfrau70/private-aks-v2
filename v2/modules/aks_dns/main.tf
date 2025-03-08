# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# AKS 클러스터 데이터 소스
data "azurerm_kubernetes_cluster" "aks" {
  count               = var.use_existing_private_dns_zone_aks || var.skip_dns_record ? 0 : 1
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}

# AKS 관리 리소스 그룹 데이터 소스
data "azurerm_resource_group" "aks_node_rg" {
  count = var.use_existing_private_dns_zone_aks || var.skip_dns_record ? 0 : 1
  name  = data.azurerm_kubernetes_cluster.aks[0].node_resource_group
}

locals {
  # API 서버 IP 주소 결정
  # 1. var.api_server_ip가 설정되어 있으면 해당 값 사용
  # 2. 그렇지 않으면 var.static_ip 사용
  api_server_ip = var.api_server_ip != "" ? var.api_server_ip : var.static_ip
}

# AKS 클러스터를 위한 Private DNS Zone 생성
resource "azurerm_private_dns_zone" "aks_dns" {
  count               = var.use_existing_private_dns_zone ? 0 : 1
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# AKS VNet에 Private DNS Zone 연결
resource "azurerm_private_dns_zone_virtual_network_link" "aks_dns_link" {
  count                 = var.use_existing_private_dns_zone ? 0 : 1
  name                  = "${var.cluster_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
  registration_enabled  = false
  
  depends_on = [azurerm_private_dns_zone.aks_dns]
}

# Hub VNet에 Private DNS Zone 연결
resource "azurerm_private_dns_zone_virtual_network_link" "aks_dns_hub_link" {
  count                 = var.use_existing_private_dns_zone || var.use_existing_hub_vnet_link ? 0 : 1
  name                  = "${var.cluster_name}-hub-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns[0].name
  virtual_network_id    = var.hub_vnet_id
  tags                  = var.tags
  registration_enabled  = false
  
  depends_on = [azurerm_private_dns_zone.aks_dns]
}

# 시스템 관리형 Private DNS Zone에 대한 Hub VNet 연결
# 이미 연결되어 있을 수 있으므로 use_existing_hub_vnet_link 변수를 사용하여 제어
resource "azurerm_private_dns_zone_virtual_network_link" "system_dns_hub_link" {
  count                 = var.use_system_dns_zone && !var.use_existing_hub_vnet_link ? 1 : 0
  name                  = "${var.cluster_name}-hub-system-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = "privatelink.${var.location}.azmk8s.io"
  virtual_network_id    = var.hub_vnet_id
  tags                  = var.tags
  registration_enabled  = false
}

# AKS API 서버의 Private DNS A 레코드 생성 (클러스터 FQDN용)
resource "azurerm_private_dns_a_record" "aks_dns_a_record" {
  count               = var.use_existing_private_dns_zone || var.use_existing_private_dns_zone_aks || var.skip_dns_record ? 0 : 1
  name                = try(join(".", slice(split(".", var.private_fqdn), 0, 2)), "api")
  zone_name           = azurerm_private_dns_zone.aks_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [local.api_server_ip]
  
  depends_on = [
    azurerm_private_dns_zone.aks_dns,
    data.azurerm_kubernetes_cluster.aks
  ]
}

# AKS API 서버의 Private DNS A 레코드 생성 (kube-apiserver용)
resource "azurerm_private_dns_a_record" "aks_kube_apiserver_record" {
  count               = var.use_existing_private_dns_zone || var.use_existing_private_dns_zone_aks || var.skip_dns_record ? 0 : 1
  name                = "kube-apiserver.nic.${var.nic_id_suffix}"
  zone_name           = azurerm_private_dns_zone.aks_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [local.api_server_ip]
  
  depends_on = [
    azurerm_private_dns_zone.aks_dns,
    data.azurerm_kubernetes_cluster.aks
  ]
} 