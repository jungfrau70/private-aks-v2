# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 기존 ACR 데이터 소스
data "azurerm_container_registry" "acr" {
  count               = var.use_existing_acr ? 1 : 0
  name                = var.acr_name
  resource_group_name = var.resource_group_name
}

# 기존 Private Endpoint 데이터 소스
data "azurerm_private_endpoint_connection" "acr_pe" {
  count               = var.use_existing_acr ? 1 : 0
  name                = "${var.acr_name}-pe"
  resource_group_name = var.resource_group_name
}

locals {
  acr_exists = var.use_existing_acr && can(data.azurerm_container_registry.acr[0].id)
  pe_exists = var.use_existing_acr && can(data.azurerm_private_endpoint_connection.acr_pe[0].id)
  acr_id = var.use_existing_acr ? data.azurerm_container_registry.acr[0].id : (length(azurerm_container_registry.acr) > 0 ? azurerm_container_registry.acr[0].id : "")
  acr_login_server = var.use_existing_acr ? data.azurerm_container_registry.acr[0].login_server : (length(azurerm_container_registry.acr) > 0 ? azurerm_container_registry.acr[0].login_server : "")
}

# ACR 생성
resource "azurerm_container_registry" "acr" {
  count               = var.use_existing_acr ? 0 : 1
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  
  # Premium SKU에서만 사용 가능한 기능
  dynamic "network_rule_set" {
    for_each = var.sku == "Premium" ? [1] : []
    content {
      default_action = "Deny"
      
      # 0.0.0.0/0 대신 특정 공용 IP 범위만 허용
      ip_rule {
        action   = "Allow"
        ip_range = var.allowed_cidr != "0.0.0.0/0" ? var.allowed_cidr : "1.1.1.1/32" # 기본값 변경
      }
    }
  }
  
  # 지역 복제 설정 (Premium SKU에서만 사용 가능)
  dynamic "georeplications" {
    for_each = var.sku == "Premium" && length(var.georeplication_locations) > 0 ? var.georeplication_locations : []
    content {
      location = georeplications.value
      zone_redundancy_enabled = true
    }
  }
  
  tags = var.tags
}

# ACR Private Endpoint 생성
resource "azurerm_private_endpoint" "acr_pe" {
  count               = var.use_existing_acr ? 0 : 1
  name                = "${var.acr_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.acr_name}-psc"
    private_connection_resource_id = local.acr_id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr_dns[0].id]
  }
}

# Private DNS Zone 생성
resource "azurerm_private_dns_zone" "acr_dns" {
  count               = var.use_existing_acr ? 0 : 1
  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone과 VNet 연결
resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link" {
  count                 = var.use_existing_acr ? 0 : 1
  name                  = "acr-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Private DNS A 레코드
resource "azurerm_private_dns_a_record" "acr_dns_record" {
  count               = var.use_existing_acr || var.use_existing_acr_private_endpoint || true ? 0 : 1
  name                = lower(var.acr_name)
  zone_name           = azurerm_private_dns_zone.acr_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.acr_pe[0].private_service_connection[0].private_ip_address]
}

# AKS 클러스터에 ACR Pull 권한 부여
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = length(var.aks_cluster_ids)
  scope                = local.acr_exists ? data.azurerm_container_registry.acr[0].id : azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_cluster_ids[count.index]
} 