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

locals {
  aks_exists = var.use_existing_aks_cluster
}

# AKS 클러스터를 위한 사용자 관리 ID
resource "azurerm_user_assigned_identity" "aks_identity" {
  count               = var.use_existing_aks_cluster ? 0 : 1
  name                = "${var.cluster_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
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
    identity_ids = [azurerm_user_assigned_identity.aks_identity[0].id]
  }

  # AGIC 통합 설정
  dynamic "ingress_application_gateway" {
    for_each = var.enable_agic && var.appgw_id != "" ? [1] : []
    content {
      gateway_id = var.appgw_id
    }
  }

  # Azure AD RBAC 설정 - 최신 방식으로 업데이트
  azure_active_directory_role_based_access_control {
    managed = true
    azure_rbac_enabled = true
    admin_group_object_ids = length(var.admin_group_object_ids) > 0 ? var.admin_group_object_ids : null
    tenant_id = var.tenant_id
  }

  # GitHub Actions 통합을 위한 OIDC 발급자 설정
  oidc_issuer_enabled = var.enable_github_actions_oidc

  # Kubelet Identity 설정은 자동으로 생성되므로 명시적으로 지정하지 않음

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
  private_dns_zone_id     = var.private_dns_zone_id != "" ? var.private_dns_zone_id : null

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

# 프라이빗 DNS 존 생성 (프라이빗 클러스터용)
resource "azurerm_private_dns_zone" "aks_dns" {
  count               = var.use_existing_aks_cluster || var.use_existing_private_dns_zone ? 0 : (var.private_cluster_enabled && var.private_dns_zone_id == "" ? 1 : 0)
  name                = "privatelink.${var.location}.azmk8s.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# 프라이빗 DNS 존과 VNet 연결
resource "azurerm_private_dns_zone_virtual_network_link" "aks_dns_link" {
  count                 = var.use_existing_aks_cluster || var.use_existing_private_dns_zone ? 0 : (var.private_cluster_enabled && var.private_dns_zone_id == "" ? 1 : 0)
  name                  = "${var.cluster_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

# Hub VNet에 Private DNS Zone 연결
resource "azurerm_private_dns_zone_virtual_network_link" "aks_dns_hub_link" {
  count                 = var.use_existing_aks_cluster || var.use_existing_private_dns_zone ? 0 : (var.private_cluster_enabled && var.private_dns_zone_id == "" && var.hub_vnet_id != "" ? 1 : 0)
  name                  = "${var.cluster_name}-hub-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.aks_dns[0].name
  virtual_network_id    = var.hub_vnet_id
  tags                  = var.tags
}

# 시스템 관리형 Private DNS Zone에 대한 Hub VNet 연결
resource "azurerm_private_dns_zone_virtual_network_link" "system_dns_hub_link" {
  count                 = var.use_existing_aks_cluster ? 0 : (var.private_cluster_enabled && var.private_dns_zone_id == "system" && var.hub_vnet_id != "" ? 1 : 0)
  name                  = "${var.cluster_name}-hub-system-dns-link"
  resource_group_name   = "MC_${var.resource_group_name}_${var.cluster_name}_${var.location}"
  private_dns_zone_name = "${azurerm_kubernetes_cluster.aks[0].private_fqdn}"
  virtual_network_id    = var.hub_vnet_id
  tags                  = var.tags

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# ACR에 대한 AKS 클러스터 접근 권한 부여
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = var.use_existing_aks_cluster ? 0 : 1
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks[0].kubelet_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

# KeyVault에 대한 AKS 클러스터 접근 권한 부여
resource "azurerm_role_assignment" "aks_keyvault_access" {
  count                = var.use_existing_aks_cluster ? 0 : 1
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks[0].kubelet_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

# Application Gateway에 대한 AKS 클러스터 접근 권한 부여 (AGIC 사용 시)
resource "azurerm_role_assignment" "aks_appgw_contributor" {
  count                = var.use_existing_aks_cluster ? 0 : (var.enable_agic ? 1 : 0)
  scope                = var.appgw_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks[0].ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  depends_on           = [azurerm_kubernetes_cluster.aks]
}

# GitHub Actions OIDC 설정 (선택 사항)
resource "azurerm_federated_identity_credential" "github_oidc" {
  count               = var.use_existing_aks_cluster ? 0 : (var.enable_github_actions_oidc && var.github_repo != "" ? 1 : 0)
  name                = "${var.cluster_name}-github-oidc"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:${var.github_repo}:ref:refs/heads/main"
  parent_id           = azurerm_user_assigned_identity.aks_identity[0].id
  depends_on          = [azurerm_user_assigned_identity.aks_identity]
} 