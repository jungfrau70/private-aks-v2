# 기존 PostgreSQL 서버 데이터 소스
data "azurerm_postgresql_server" "postgres" {
  count               = var.use_existing_postgresql ? 1 : 0
  name                = var.postgresql_server_name
  resource_group_name = var.resource_group_name
}

locals {
  postgres_exists = var.use_existing_postgresql && can(data.azurerm_postgresql_server.postgres[0].id)
}

# 기존 PostgreSQL Flexible 서버 데이터 소스
data "azurerm_postgresql_flexible_server" "db" {
  count               = var.use_existing_postgresql ? 1 : 0
  name                = var.postgresql_server_name
  resource_group_name = var.resource_group_name
}

locals {
  postgres_flexible_exists = var.use_existing_postgresql && can(data.azurerm_postgresql_flexible_server.db[0].id)
}

resource "azurerm_postgresql_server" "postgres" {
  count               = var.use_existing_postgresql || true ? 0 : 1
  name                = "${var.postgresql_server_name}-${formatdate("MMHHmmss", timestamp())}"  # 고유한 이름 생성 (DD 제거)
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name = "GP_Gen5_4"

  storage_mb                   = 102400
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password
  version                      = "11"
  ssl_enforcement_enabled      = true

  public_network_access_enabled = false
  
  tags = var.tags
}

resource "azurerm_postgresql_database" "db" {
  count               = local.postgres_exists || true ? 0 : 1
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = local.postgres_exists ? data.azurerm_postgresql_server.postgres[0].name : azurerm_postgresql_server.postgres[0].name
  charset             = "UTF8"
  collation           = "ko_KR.utf8"
}

resource "azurerm_private_endpoint" "postgres_pe" {
  count               = local.postgres_exists || true ? 0 : 1
  name                = "${var.postgresql_server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.postgresql_server_name}-psc"
    private_connection_resource_id = local.postgres_exists ? data.azurerm_postgresql_server.postgres[0].id : azurerm_postgresql_server.postgres[0].id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }
  
  tags = var.tags
}

# AKS에서 PostgreSQL 접속 정보를 위한 Kubernetes Secret 생성 매니페스트
resource "local_file" "postgres_secret_manifest" {
  count = local.postgres_exists ? 1 : 0
  content = templatefile("${path.module}/templates/postgres-secret.yaml.tpl", {
    postgresql_server_name     = local.postgres_exists ? data.azurerm_postgresql_server.postgres[0].name : "postgres-server"
    postgresql_admin_username  = var.administrator_login
    postgresql_admin_password  = var.administrator_login_password
    postgresql_database_name   = var.database_name
    postgresql_connection_url  = "jdbc:postgresql://${local.postgres_exists ? data.azurerm_postgresql_server.postgres[0].fqdn : "postgres-server.postgres.database.azure.com"}:5432/${var.database_name}"
  })
  filename = "${path.module}/output/postgres-secret.yaml"
}

resource "azurerm_postgresql_flexible_server" "db" {
  count               = var.use_existing_postgresql || true ? 0 : 1
  name                = var.postgresql_server_name
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "13"
  
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_login_password

  storage_mb = 32768
  sku_name   = "GP_Standard_D4s_v3"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = length(azurerm_private_dns_zone.db) > 0 ? azurerm_private_dns_zone.db[0].id : null
  public_network_access_enabled = false
  
  zone = 1

  tags = var.tags

  timeouts {
    create = "60m"
    delete = "60m"
  }

  depends_on = [
    azurerm_private_dns_zone.db,
    azurerm_private_dns_zone_virtual_network_link.db
  ]
}

resource "azurerm_private_dns_zone" "db" {
  count               = true ? 0 : 1
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "db" {
  count                 = true ? 0 : 1
  name                  = "psqlfs-link"
  private_dns_zone_name = azurerm_private_dns_zone.db[0].name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_subnet" "snet_db" {
  count                = true ? 0 : 1
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_prefix]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_private_dns_zone" "postgresql_dns_zone" {
  count               = var.use_existing_postgresql || true ? 0 : 1
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql_dns_link" {
  count                 = var.use_existing_postgresql || true ? 0 : 1
  name                  = "postgresql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = length(azurerm_private_dns_zone.postgresql_dns_zone) > 0 ? azurerm_private_dns_zone.postgresql_dns_zone[0].name : "privatelink.postgres.database.azure.com"
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "postgresql_endpoint" {
  count               = var.use_existing_postgresql || true ? 0 : 1
  name                = "${var.postgresql_server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.postgresql_server_name}-psc"
    private_connection_resource_id = local.postgres_exists ? data.azurerm_postgresql_server.postgres[0].id : azurerm_postgresql_server.postgres[0].id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }
  
  tags = var.tags
}

resource "azurerm_private_dns_a_record" "postgresql_dns_record" {
  count               = var.use_existing_postgresql || true ? 0 : 1
  name                = lower(var.postgresql_server_name)
  zone_name           = length(azurerm_private_dns_zone.postgresql_dns_zone) > 0 ? azurerm_private_dns_zone.postgresql_dns_zone[0].name : "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.postgresql_endpoint[0].private_service_connection[0].private_ip_address]
}