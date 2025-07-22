output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = local.workspace_exists ? data.azurerm_log_analytics_workspace.workspace[0].id : azurerm_log_analytics_workspace.workspace[0].id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace 이름"
  value       = local.workspace_exists ? data.azurerm_log_analytics_workspace.workspace[0].name : azurerm_log_analytics_workspace.workspace[0].name
}

output "log_analytics_workspace_primary_key" {
  description = "Log Analytics Workspace 기본 키"
  value       = local.workspace_exists ? data.azurerm_log_analytics_workspace.workspace[0].primary_shared_key : azurerm_log_analytics_workspace.workspace[0].primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_secondary_key" {
  description = "Log Analytics Workspace 보조 키"
  value       = local.workspace_exists ? data.azurerm_log_analytics_workspace.workspace[0].secondary_shared_key : azurerm_log_analytics_workspace.workspace[0].secondary_shared_key
  sensitive   = true
}

output "action_group_id" {
  description = "Monitor Action Group ID"
  value       = azurerm_monitor_action_group.hub_action_group.id
}

output "dashboard_id" {
  description = "AKS 대시보드 ID"
  value       = length(azurerm_portal_dashboard.aks_dashboard) > 0 ? azurerm_portal_dashboard.aks_dashboard[0].id : null
}

output "prometheus_workspace_id" {
  description = "Prometheus Workspace ID"
  value       = var.aks_cluster_id != "" ? (length(azurerm_monitor_workspace.prometheus) > 0 ? azurerm_monitor_workspace.prometheus[0].id : null) : null
}

output "prometheus_data_collection_endpoint_id" {
  description = "Prometheus 데이터 수집 엔드포인트 ID"
  value       = var.aks_cluster_id != "" ? (length(azurerm_monitor_data_collection_endpoint.prometheus) > 0 ? azurerm_monitor_data_collection_endpoint.prometheus[0].id : null) : null
}

output "prometheus_data_collection_rule_id" {
  description = "Prometheus 데이터 수집 규칙 ID"
  value       = var.aks_cluster_id != "" ? (length(azurerm_monitor_data_collection_rule.prometheus) > 0 ? azurerm_monitor_data_collection_rule.prometheus[0].id : null) : null
} 