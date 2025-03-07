output "server_name" {
  value = null
}

output "server_fqdn" {
  value = null
}

output "connection_string" {
  value     = null
  sensitive = true
}

output "postgresql_server_id" {
  description = "PostgreSQL 서버 ID"
  value       = local.postgres_exists ? data.azurerm_postgresql_server.postgres[0].id : (length(azurerm_postgresql_server.postgres) > 0 ? azurerm_postgresql_server.postgres[0].id : null)
}

output "postgresql_server_name" {
  description = "PostgreSQL 서버 이름"
  value       = local.postgres_exists ? data.azurerm_postgresql_server.postgres[0].name : (length(azurerm_postgresql_server.postgres) > 0 ? azurerm_postgresql_server.postgres[0].name : null)
}

output "postgresql_server_fqdn" {
  description = "PostgreSQL 서버 FQDN"
  value       = local.postgres_exists ? data.azurerm_postgresql_server.postgres[0].fqdn : (length(azurerm_postgresql_server.postgres) > 0 ? azurerm_postgresql_server.postgres[0].fqdn : null)
}

output "postgresql_database_name" {
  description = "PostgreSQL 데이터베이스 이름"
  value       = local.postgres_exists ? var.database_name : (length(azurerm_postgresql_database.db) > 0 ? azurerm_postgresql_database.db[0].name : null)
}

output "postgresql_connection_string" {
  description = "PostgreSQL 연결 문자열"
  value       = local.postgres_exists ? "postgresql://${var.administrator_login}@${data.azurerm_postgresql_server.postgres[0].name}:${var.administrator_login_password}@${data.azurerm_postgresql_server.postgres[0].fqdn}:5432/${var.database_name}" : (length(azurerm_postgresql_server.postgres) > 0 ? "postgresql://${var.administrator_login}@${azurerm_postgresql_server.postgres[0].name}:${var.administrator_login_password}@${azurerm_postgresql_server.postgres[0].fqdn}:5432/${var.database_name}" : null)
  sensitive   = true
}

output "postgres_secret_manifest_path" {
  description = "PostgreSQL 시크릿 매니페스트 경로"
  value       = length(local_file.postgres_secret_manifest) > 0 ? local_file.postgres_secret_manifest[0].filename : null
} 