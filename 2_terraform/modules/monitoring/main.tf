# 기존 Log Analytics Workspace 데이터 소스
data "azurerm_log_analytics_workspace" "workspace" {
  count               = var.use_existing_workspace ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name_hub
}

locals {
  workspace_exists = var.use_existing_workspace && length(data.azurerm_log_analytics_workspace.workspace) > 0
  workspace_id = var.use_existing_workspace ? (length(data.azurerm_log_analytics_workspace.workspace) > 0 ? data.azurerm_log_analytics_workspace.workspace[0].id : "") : (length(azurerm_log_analytics_workspace.workspace) > 0 ? azurerm_log_analytics_workspace.workspace[0].id : "")
  workspace_name = var.use_existing_workspace ? (length(data.azurerm_log_analytics_workspace.workspace) > 0 ? data.azurerm_log_analytics_workspace.workspace[0].name : "") : (length(azurerm_log_analytics_workspace.workspace) > 0 ? azurerm_log_analytics_workspace.workspace[0].name : "")
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "workspace" {
  count               = var.use_existing_workspace ? 0 : 1
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name_hub
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_analytics_workspace_retention_days
  
  tags = var.tags
}

resource "azurerm_log_analytics_solution" "container_insights" {
  count                 = var.use_existing_log_analytics_solution ? 0 : 1
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name_hub
  workspace_resource_id = azurerm_log_analytics_workspace.workspace[0].id
  workspace_name        = azurerm_log_analytics_workspace.workspace[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = var.aks_cluster_id != "" ? 1 : 0
  name                       = "aks-diagnostics"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = local.workspace_exists ? data.azurerm_log_analytics_workspace.workspace[0].id : azurerm_log_analytics_workspace.workspace[0].id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_gateway" {
  count                      = var.enable_app_gateway_monitoring ? 1 : 0
  name                       = "appgw-diagnostics"
  target_resource_id         = var.app_gateway_id
  log_analytics_workspace_id = local.workspace_exists ? data.azurerm_log_analytics_workspace.workspace[0].id : azurerm_log_analytics_workspace.workspace[0].id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# AKS 대시보드 생성
resource "azurerm_portal_dashboard" "aks_dashboard" {
  count               = var.aks_cluster_id != "" ? 1 : 0
  name                = "aks-dashboard-${var.prefix}-${var.environment}"
  resource_group_name = var.resource_group_name_hub
  location            = var.location
  tags                = var.tags
  dashboard_properties = templatefile("${path.module}/templates/aks-dashboard.json.tpl", {
    subscription_id = var.subscription_id
    resource_group_name = var.resource_group_name_hub
    aks_cluster_name = var.aks_cluster_name
    location = var.location
  })
}

# Monitor Action Group
resource "azurerm_monitor_action_group" "hub_action_group" {
  name                = var.monitor_action_group_name
  resource_group_name = var.resource_group_name_hub
  short_name         = "hubaction"
  enabled            = true
  location           = "global"

  dynamic "email_receiver" {
    for_each = var.monitor_email_receivers
    content {
      name                    = email_receiver.value.name
      email_address          = email_receiver.value.email_address
      use_common_alert_schema = email_receiver.value.use_common_alert_schema
    }
  }
}

# Azure Monitor 기본 알림 설정
resource "azurerm_monitor_metric_alert" "hub_cpu_alert" {
  count               = length(var.alert_scopes) > 0 ? 1 : 0
  name                = "hub-cpu-alert"
  resource_group_name = var.resource_group_name_hub
  scopes              = var.alert_scopes
  description         = "Hub 리소스의 CPU 사용률이 높을 때 알림"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  
  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.hub_action_group.id
  }
}

# Prometheus 데이터 수집 엔드포인트
resource "azurerm_monitor_data_collection_endpoint" "prometheus" {
  count               = var.aks_cluster_id != "" ? 1 : 0
  name                = "prom-${var.prefix}-${var.environment}-dce"
  resource_group_name = var.resource_group_name_hub
  location            = var.location
  kind                = "Linux"
}

# Prometheus 작업 영역
resource "azurerm_monitor_workspace" "prometheus" {
  count               = var.aks_cluster_id != "" ? 1 : 0
  name                = "prom-${var.prefix}-${var.environment}-ws"
  resource_group_name = var.resource_group_name_hub
  location            = var.location
}

# Prometheus 데이터 수집 규칙
resource "azurerm_monitor_data_collection_rule" "prometheus" {
  count               = var.aks_cluster_id != "" ? 1 : 0
  name                = "prom-${var.prefix}-${var.environment}-dcr"
  resource_group_name = var.resource_group_name_hub
  location            = var.location
  
  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus[0].id
      name               = "MonitoringAccount1"
    }
  }
  
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.prometheus[0].id
  
  data_flow {
    destinations = ["MonitoringAccount1"]
    streams      = ["Microsoft-PrometheusMetrics"]
  }
  
  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataCollector"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }
}

# # 클러스터 상태 메트릭 알림 - 일시적으로 주석 처리
# resource "azurerm_monitor_metric_alert" "cluster_health" {
#   name                = "${var.project_name}-cluster-health"
#   resource_group_name = var.resource_group_name_hub
#   scopes              = [azurerm_monitor_workspace.prometheus.id]
#   description         = "클러스터 CPU 사용량 알림"
  
#   criteria {
#     metric_namespace = "Microsoft.Monitor/accounts"
#     metric_name      = "InsertedMetricsCount"
#     aggregation      = "Total"
#     operator         = "GreaterThan"
#     threshold        = 90
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.hub_action_group.id
#   }
# }

# 네트워크 메트릭 알림 설정
resource "azurerm_monitor_metric_alert" "network_alert" {
  count               = var.enable_network_monitoring ? 1 : 0
  name                = "network-alert"
  resource_group_name = var.resource_group_name_hub
  scopes              = [var.vnet_id]
  description         = "네트워크 연결 문제 발생 시 알림"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  
  criteria {
    metric_namespace = "Microsoft.Network/virtualNetworks"
    metric_name      = "VNetPeering"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.hub_action_group.id
  }
} 