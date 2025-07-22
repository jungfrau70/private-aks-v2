# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 기존 AKS 클러스터 데이터 소스
data "azurerm_kubernetes_cluster" "existing" {
  count               = var.use_existing_aks_cluster ? 1 : 0
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}

# AKS 클러스터 생성
resource "azurerm_kubernetes_cluster" "aks" {
  count               = var.use_existing_aks_cluster ? 0 : 1
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.vm_size
    vnet_subnet_id      = var.subnet_id
    enable_auto_scaling = var.enable_auto_scaling
    min_count           = var.enable_auto_scaling ? var.min_count : null
    max_count           = var.enable_auto_scaling ? var.max_count : null
    enable_node_public_ip = var.enable_node_public_ip
    type                = "VirtualMachineScaleSets"
  }

  # 관리 ID 설정
  identity {
    type = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # AGIC 통합 설정
  dynamic "ingress_application_gateway" {
    for_each = var.enable_agic && var.appgw_id != "" ? [1] : []
    content {
      gateway_id = var.appgw_id
    }
  }

  # Azure AD RBAC 설정
  azure_active_directory_role_based_access_control {
    managed             = true
    azure_rbac_enabled  = true
    admin_group_object_ids = length(var.admin_group_object_ids) > 0 ? var.admin_group_object_ids : null
    tenant_id           = var.tenant_id
  }

  # GitHub Actions 통합을 위한 OIDC 발급자 설정
  oidc_issuer_enabled = var.enable_github_actions_oidc

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    load_balancer_sku  = var.load_balancer_sku
    outbound_type      = var.outbound_type
    service_cidr       = var.service_cidr
    dns_service_ip     = var.dns_service_ip
  }

  # 프라이빗 클러스터 설정
  private_cluster_enabled = var.private_cluster_enabled
  private_dns_zone_id     = var.private_dns_zone_id == "System" || var.private_dns_zone_id == "None" ? var.private_dns_zone_id : (var.private_dns_zone_id != "" ? var.private_dns_zone_id : null)

  # RBAC 설정
  role_based_access_control_enabled = var.enable_rbac

  # 모니터링 설정
  dynamic "oms_agent" {
    for_each = var.enable_monitoring && var.log_analytics_workspace_id != "" ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
} 