# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 기존 KeyVault 데이터 소스
data "azurerm_key_vault" "keyvault" {
  count               = var.use_existing_keyvault ? 1 : 0
  name                = var.keyvault_name
  resource_group_name = var.resource_group_name
}

# KeyVault 생성
resource "azurerm_key_vault" "keyvault" {
  count                       = var.use_existing_keyvault ? 0 : 1
  name                        = var.keyvault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = var.sku_name
  enable_rbac_authorization   = var.enable_rbac_authorization
  purge_protection_enabled    = var.purge_protection_enabled
  soft_delete_retention_days  = var.soft_delete_retention_days
  
  # 네트워크 규칙 설정
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = var.allowed_ips
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }
  
  tags = var.tags
}

# KeyVault 참조를 위한 로컬 변수
locals {
  keyvault_id = var.use_existing_keyvault ? data.azurerm_key_vault.keyvault[0].id : (length(azurerm_key_vault.keyvault) > 0 ? azurerm_key_vault.keyvault[0].id : "")
  keyvault_uri = var.use_existing_keyvault ? data.azurerm_key_vault.keyvault[0].vault_uri : (length(azurerm_key_vault.keyvault) > 0 ? azurerm_key_vault.keyvault[0].vault_uri : "")
}

# Private DNS Zone 생성
resource "azurerm_private_dns_zone" "keyvault_dns" {
  count               = var.use_existing_keyvault ? 0 : 1
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Private DNS Zone과 VNet 연결
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_dns_link" {
  count                 = var.use_existing_keyvault ? 0 : 1
  name                  = "keyvault-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault_dns[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Private Endpoint 생성
resource "azurerm_private_endpoint" "keyvault_pe" {
  count               = var.use_existing_keyvault ? 0 : 1
  name                = "${var.keyvault_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.keyvault_name}-psc"
    private_connection_resource_id = local.keyvault_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "keyvault-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault_dns[0].id]
  }
}

# 데이터 소스를 통해 Azure AD 그룹 정보 가져오기
data "azuread_group" "operators" {
  count        = var.use_existing_ad_groups && var.operators_group_id != "" ? 1 : 0
  object_id    = var.operators_group_id
}

data "azuread_group" "admins" {
  count        = var.use_existing_ad_groups && var.admins_group_id != "" ? 1 : 0
  object_id    = var.admins_group_id
}

data "azuread_group" "cluster_admins" {
  count        = var.use_existing_ad_groups && var.cluster_admins_group_id != "" ? 1 : 0
  object_id    = var.cluster_admins_group_id
}

data "azuread_group" "developers" {
  count        = var.use_existing_ad_groups && var.developers_group_id != "" ? 1 : 0
  object_id    = var.developers_group_id
}

# KeyVault에 대한 RBAC 권한 부여
resource "azurerm_role_assignment" "keyvault_operators" {
  count                = var.enable_rbac_authorization && var.use_existing_ad_groups && !var.use_existing_keyvault_role_assignments ? 1 : 0
  scope                = local.keyvault_id
  role_definition_name = "Key Vault Reader"
  principal_id         = data.azuread_group.operators[0].id
  
  lifecycle {
    ignore_changes = [
      principal_id,
      scope,
      role_definition_name
    ]
  }
}

resource "azurerm_role_assignment" "keyvault_admins" {
  count                = var.enable_rbac_authorization && var.use_existing_ad_groups && !var.use_existing_keyvault_role_assignments ? 1 : 0
  scope                = local.keyvault_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azuread_group.admins[0].id
  
  lifecycle {
    ignore_changes = [
      principal_id,
      scope,
      role_definition_name
    ]
  }
}

resource "azurerm_role_assignment" "keyvault_cluster_admins" {
  count                = var.enable_rbac_authorization && var.use_existing_ad_groups && !var.use_existing_keyvault_role_assignments ? 1 : 0
  scope                = local.keyvault_id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azuread_group.cluster_admins[0].id
  
  lifecycle {
    ignore_changes = [
      principal_id,
      scope,
      role_definition_name
    ]
  }
}

resource "azurerm_role_assignment" "keyvault_developers" {
  count                = var.enable_rbac_authorization && var.use_existing_ad_groups && !var.use_existing_keyvault_role_assignments ? 1 : 0
  scope                = local.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_group.developers[0].id
  
  lifecycle {
    ignore_changes = [
      principal_id,
      scope,
      role_definition_name
    ]
  }
}

# AKS 클러스터에 KeyVault 접근 권한 부여
resource "azurerm_role_assignment" "aks_keyvault_access" {
  count                = length(var.aks_identities) > 0 && var.enable_rbac_authorization && !var.use_existing_keyvault_role_assignments ? length(var.aks_identities) : 0
  scope                = local.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_identities[count.index]
  
  lifecycle {
    ignore_changes = [
      principal_id,
      scope,
      role_definition_name
    ]
  }
}

resource "azurerm_private_dns_a_record" "keyvault_dns_record" {
  count               = var.use_existing_keyvault || var.use_existing_keyvault_private_endpoint || true ? 0 : 1
  name                = lower(var.keyvault_name)
  zone_name           = azurerm_private_dns_zone.keyvault_dns[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.keyvault_pe[0].private_service_connection[0].private_ip_address]
} 