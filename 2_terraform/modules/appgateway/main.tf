# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 기존 Application Gateway 데이터 소스
data "azurerm_application_gateway" "existing" {
  count               = var.use_existing_app_gateway ? 1 : 0
  name                = var.appgw_name
  resource_group_name = var.resource_group_name
}

# Application Gateway 참조를 위한 로컬 변수
locals {
  appgw_exists = var.use_existing_app_gateway
}

# Application Gateway를 위한 공용 IP 주소
resource "azurerm_public_ip" "appgw_pip" {
  count               = var.use_existing_app_gateway ? 0 : 1
  name                = "${var.appgw_name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.domain_name_label != "" ? var.domain_name_label : null
  tags                = var.tags
}

# Application Gateway 생성
resource "azurerm_application_gateway" "appgw" {
  count               = var.use_existing_app_gateway ? 0 : 1
  name                = var.appgw_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
    capacity = var.capacity
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_port {
    name = "httpsPort"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.appgw_pip[0].id
  }

  frontend_ip_configuration {
    name                          = "appGwPrivateFrontendIp"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
  }

  backend_address_pool {
    name = "defaultBackendPool"
  }

  backend_http_settings {
    name                  = "defaultHttpSettings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "defaultListener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "defaultRule"
    rule_type                  = "Basic"
    http_listener_name         = "defaultListener"
    backend_address_pool_name  = "defaultBackendPool"
    backend_http_settings_name = "defaultHttpSettings"
    priority                   = 100
  }

  # AGIC 통합을 위한 관리 ID 설정
  dynamic "identity" {
    for_each = var.enable_agic ? [1] : []
    content {
      type = "UserAssigned"
      identity_ids = [
        azurerm_user_assigned_identity.appgw_identity[0].id
      ]
    }
  }

  # WAF 구성 (WAF_v2 SKU에서만 사용 가능)
  dynamic "waf_configuration" {
    for_each = var.sku_tier == "WAF_v2" ? [1] : []
    content {
      enabled                  = true
      firewall_mode            = "Prevention"
      rule_set_type            = "OWASP"
      rule_set_version         = "3.2"
      file_upload_limit_mb     = 100
      max_request_body_size_kb = 128
    }
  }
}

# Application Gateway 참조를 위한 로컬 변수
locals {
  appgw_id = var.use_existing_app_gateway ? data.azurerm_application_gateway.existing[0].id : (length(azurerm_application_gateway.appgw) > 0 ? azurerm_application_gateway.appgw[0].id : "")
}

# Application Gateway용 관리 ID 생성 (AGIC 통합용)
resource "azurerm_user_assigned_identity" "appgw_identity" {
  count               = var.use_existing_app_gateway || !var.enable_agic ? 0 : 1
  name                = "${var.appgw_name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# AKS 클러스터에 Application Gateway 기여자 역할 할당
resource "azurerm_role_assignment" "aks_appgw_contributor" {
  for_each             = var.enable_agic ? toset(var.aks_identities) : []
  scope                = var.use_existing_app_gateway ? data.azurerm_application_gateway.existing[0].id : azurerm_application_gateway.appgw[0].id
  role_definition_name = "Contributor"
  principal_id         = each.value
}

# GitHub Actions 통합을 위한 사용자 관리 ID
resource "azurerm_user_assigned_identity" "github_actions_identity" {
  count               = var.enable_github_actions && var.github_repo != "" && !var.use_existing_app_gateway ? 1 : 0
  name                = "${var.appgw_name}-github-identity"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  tags                = var.tags
}

# GitHub Actions 통합을 위한 Federated Identity Credential 생성
resource "azurerm_federated_identity_credential" "github_actions" {
  count               = var.enable_github_actions && var.github_repo != "" && !var.use_existing_app_gateway ? 1 : 0
  name                = "${var.appgw_name}-github-actions"
  resource_group_name = data.azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.github_actions_identity[0].id
  subject             = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
}

# GitHub Actions 사용자 관리 ID에 Application Gateway 기여자 역할 할당
resource "azurerm_role_assignment" "github_actions_appgw_contributor" {
  count                = var.enable_github_actions && var.github_repo != "" ? 1 : 0
  scope                = var.use_existing_app_gateway ? data.azurerm_application_gateway.existing[0].id : azurerm_application_gateway.appgw[0].id
  role_definition_name = "Contributor"
  principal_id         = var.enable_github_actions && var.github_repo != "" && !var.use_existing_app_gateway ? azurerm_user_assigned_identity.github_actions_identity[0].principal_id : ""
} 