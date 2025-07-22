

resource "azurerm_postgresql_flexible_server" "db" {
  count               = var.use_existing_postgresql ? 0 : 1
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
  private_dns_zone_id = var.private_dns_zone_id
  public_network_access_enabled = false
  zone = 1
  tags = var.tags
  timeouts {
    create = "60m"
    delete = "60m"
  }
}





resource "azurerm_private_endpoint" "postgresql_endpoint" {
  count               = var.use_existing_postgresql ? 0 : 1
  name                = "${var.postgresql_server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.postgresql_server_name}-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.db[0].id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }
  
  tags = var.tags
}

resource "azurerm_private_dns_a_record" "postgresql_dns_record" {
  count               = var.use_existing_postgresql ? 0 : 1
  name                = lower(var.postgresql_server_name)
  zone_name           = var.private_dns_zone_name_postgres
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.postgresql_endpoint[0].private_service_connection[0].private_ip_address]
}