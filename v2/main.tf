terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0"
  
  # Azure Storage 백엔드 사용
  backend "azurerm" {
    # 설정은 backend.conf 파일에서 제공
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

# 데이터 소스
data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

# 변수 정의
locals {
  # 기본 설정 - 모두 변수에서 가져옴
  location = var.location
  tenant_domain = var.tenant_domain
  
  # 네트워크 설정
  hub_vnet_name = var.hub_vnet_name
  hub_vnet_prefix = var.hub_vnet_prefix
  spoke_vnet_name = var.spoke_vnet_name
  spoke_vnet_prefix = var.spoke_vnet_prefix
  storage_vnet_name = var.storage_vnet_name
  storage_vnet_prefix = var.storage_vnet_prefix
  
  # 리소스 그룹 이름
  hub_rg_name = var.resource_group_name_hub
  spoke_rg_name = var.resource_group_name_spoke
  storage_rg_name = var.resource_group_name_storage
  
  # 환경별 태그 설정
  common_tags = merge(var.tags, {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.environment
  })

  # 리소스 그룹 생성 또는 참조
  hub_rg_exists    = var.use_existing_resource_group_hub
  spoke_rg_exists  = var.use_existing_resource_group_spoke
  storage_rg_exists = var.use_existing_resource_group_storage

  # 네트워크 모듈에 추가 설정 전달
  network_additional_settings = {
    enable_hub_spoke_peering = var.enable_hub_spoke_peering
    enable_hub_storage_peering = var.enable_hub_storage_peering
    enable_spoke_storage_peering = var.enable_spoke_storage_peering
    enable_azure_firewall = var.enable_azure_firewall
    fw_name = var.fw_name
    fw_policy_name = var.fw_policy_name
    enable_internal_lb = var.enable_internal_lb
    loadbalancer_name = var.loadbalancer_name
  }

  # 스토리지 모듈에 추가 설정 전달
  storage_additional_settings = {
    container_name = var.container_name
    blob_name = var.blob_name
    enable_private_endpoints = var.enable_private_endpoints
    private_dns_zone_name_blob = var.private_dns_zone_name_blob
    private_dns_zone_name_file = var.private_dns_zone_name_file
  }

  # KeyVault 모듈에 추가 설정 전달
  keyvault_additional_settings = {
    enable_keyvault_access_policy = var.enable_keyvault_access_policy
    keyvault_admin_object_ids = var.keyvault_admin_object_ids
    private_dns_zone_name_kv = var.private_dns_zone_name_kv
  }

  # 모니터링 모듈에 추가 설정 전달
  monitoring_additional_settings = {
    enable_aks_monitoring = var.enable_aks_monitoring
    enable_app_gateway_monitoring = var.enable_app_gateway_monitoring
    enable_network_monitoring = var.enable_network_monitoring
    alert_scopes = var.alert_scopes
  }

  # RBAC 모듈을 위한 빈 리소스 ID 설정
  empty_storage_account_id = ""
  empty_acr_id = ""
  empty_keyvault_id = ""
  empty_aks_cluster_id = ""
}

# 리소스 그룹 모듈 추가
module "resource_groups" {
  source = "./modules/resource_groups"
  
  use_existing_resource_group_hub = var.use_existing_resource_group_hub
  use_existing_resource_group_spoke = var.use_existing_resource_group_spoke
  use_existing_resource_group_storage = var.use_existing_resource_group_storage
  resource_group_name_hub      = var.resource_group_name_hub
  resource_group_name_spoke    = var.resource_group_name_spoke
  resource_group_name_storage  = var.resource_group_name_storage
  location                     = var.location
  tags                         = local.common_tags
}

# 1. Azure AD 사용자 및 그룹 모듈
module "azure_ad" {
  source = "./modules/azure_ad"
  
  tenant_domain = var.tenant_domain
  admin_password = var.admin_password
  use_existing_ad_groups = var.use_existing_ad_groups
  use_existing_ad_users = var.use_existing_ad_users
  operators_group_id = var.operators_group_id
  admins_group_id = var.admins_group_id
  cluster_admins_group_id = var.cluster_admins_group_id
  developers_group_id = var.developers_group_id
}

# 2. Azure Storage 모듈
module "storage" {
  source = "./modules/storage"
  count  = var.deploy_storage ? 1 : 0

  resource_group_name_storage = module.resource_groups.storage_rg_name
  location                = var.location
  storage_account_name    = var.storage_account_name
  file_share_name         = var.file_share_name
  container_name          = var.container_name
  private_dns_zone_name_blob = var.private_dns_zone_name_blob
  private_dns_zone_name_file = var.private_dns_zone_name_file
  endpoints_subnet_id     = module.network.endpoints_subnet_id
  virtual_network_id      = module.network.storage_vnet_id
  use_existing_storage    = var.use_existing_storage
  use_existing_storage_account = var.use_existing_storage_account
  use_existing_file_share = var.use_existing_file_share
  use_existing_container  = var.use_existing_container
  use_existing_private_endpoint = var.use_existing_private_endpoint
  use_existing_private_dns_zone_blob = var.use_existing_private_dns_zone_blob
  use_existing_private_dns_zone_file = var.use_existing_private_dns_zone_file
  use_existing_resource_group_hub = var.use_existing_resource_group_hub
  use_existing_resource_group_spoke = var.use_existing_resource_group_spoke
  use_existing_resource_group_storage = var.use_existing_resource_group_storage
  # 기존 파일 공유 감지를 위한 변수 추가
  existing_file_share_names = var.existing_file_share_names
  existing_storage_account_names = var.existing_storage_account_names
  tags                    = var.tags

  depends_on = [
    module.resource_groups,
    module.network
  ]
}

# 3. 네트워크 모듈
module "network" {
  source = "./modules/network"

  # 리소스 그룹 정보
  resource_group_name_hub     = module.resource_groups.hub_rg_name
  resource_group_name_spoke   = module.resource_groups.spoke_rg_name
  resource_group_name_storage = module.resource_groups.storage_rg_name
  location                   = var.location
  use_existing_resource_group_hub = var.use_existing_resource_group_hub
  use_existing_resource_group_spoke = var.use_existing_resource_group_spoke
  use_existing_resource_group_storage = var.use_existing_resource_group_storage

  # 네트워크 설정
  use_existing_networks      = var.use_existing_networks
  use_existing_hub_vnet      = var.use_existing_hub_vnet
  use_existing_spoke_vnet    = var.use_existing_spoke_vnet
  use_existing_storage_vnet  = var.use_existing_storage_vnet
  use_existing_endpoints_subnet = var.use_existing_endpoints_subnet
  use_existing_aks_subnet    = var.use_existing_aks_subnet
  
  # Hub VNet 설정
  hub_vnet_name              = var.hub_vnet_name
  hub_vnet_prefix            = var.hub_vnet_prefix
  bastion_subnet_name        = var.bastion_subnet_name
  bastion_subnet_prefix      = var.bastion_subnet_prefix
  bastion_nsg_name           = var.bastion_nsg_name
  fw_subnet_name             = var.fw_subnet_name
  fw_subnet_prefix           = var.fw_subnet_prefix
  jumpbox_subnet_name        = var.jumpbox_subnet_name
  jumpbox_subnet_prefix      = var.jumpbox_subnet_prefix
  jumpbox_nsg_name           = var.jumpbox_nsg_name
  acr_subnet_name            = var.acr_subnet_name
  acr_subnet_prefix          = var.acr_subnet_prefix
  acr_nsg_name               = var.acr_nsg_name
  agent_subnet_name          = var.agent_subnet_name
  agent_subnet_prefix        = var.agent_subnet_prefix
  agent_nsg_name             = var.agent_nsg_name

  # Spoke VNet 설정
  spoke_vnet_name            = var.spoke_vnet_name
  spoke_vnet_prefix          = var.spoke_vnet_prefix
  aks_subnet_name            = var.aks_subnet_name
  aks_subnet_prefix          = var.aks_subnet_prefix
  aks_nsg_name               = var.aks_nsg_name
  endpoints_subnet_name      = var.endpoints_subnet_name
  endpoints_subnet_prefix    = var.endpoints_subnet_prefix
  endpoints_nsg_name         = var.endpoints_nsg_name
  loadbalancer_subnet_name   = var.loadbalancer_subnet_name
  loadbalancer_subnet_prefix = var.loadbalancer_subnet_prefix
  loadbalancer_nsg_name      = var.loadbalancer_nsg_name
  appgw_subnet_name          = var.appgw_subnet_name
  appgw_subnet_prefix        = var.appgw_subnet_prefix
  appgw_nsg_name             = var.appgw_nsg_name

  # Storage VNet 설정
  storage_vnet_name          = var.storage_vnet_name
  storage_vnet_prefix        = var.storage_vnet_prefix
  storage_subnet_name        = var.storage_subnet_name
  storage_subnet_prefix      = var.storage_subnet_prefix
  storage_nsg_name           = var.storage_nsg_name

  # 태그
  tags                       = local.common_tags

  # 리소스 그룹 모듈에 의존성 추가
  depends_on = [module.resource_groups]
}

# 4. ACR 모듈
module "central_acr" {
  source = "./modules/acr"
  
  resource_group_name = module.resource_groups.hub_rg_name
  location = var.location
  acr_name = var.acr_name
  sku = var.acr_sku
  admin_enabled = var.acr_admin_enabled
  subnet_id = module.network.endpoints_subnet_id
  vnet_id = module.network.hub_vnet_id
  use_existing_acr = var.use_existing_acr
  use_existing_acr_private_endpoint = var.use_existing_acr_private_endpoint
  
  tags = local.common_tags
  
  depends_on = [
    module.resource_groups,
    module.network
  ]
}

# 5. KeyVault 모듈
module "central_keyvault" {
  source = "./modules/keyvault"
  
  resource_group_name = module.resource_groups.hub_rg_name
  location = var.location
  keyvault_name = var.keyvault_name
  tenant_id = var.tenant_id
  sku_name = var.keyvault_sku
  enable_rbac_authorization = true
  subnet_id = module.network.endpoints_subnet_id
  vnet_id = module.network.hub_vnet_id
  allowed_subnet_ids = [
    module.network.aks_subnet_id
  ]
  use_existing_keyvault = var.use_existing_keyvault
  use_existing_ad_groups = var.use_existing_ad_groups
  operators_group_id = var.operators_group_id
  admins_group_id = var.admins_group_id
  cluster_admins_group_id = var.cluster_admins_group_id
  developers_group_id = var.developers_group_id
  use_existing_keyvault_private_endpoint = var.use_existing_keyvault_private_endpoint
  use_existing_keyvault_role_assignments = true
  
  # 추가된 설정
  enable_keyvault_access_policy = var.enable_keyvault_access_policy
  keyvault_admin_object_ids = var.keyvault_admin_object_ids
  private_dns_zone_name_kv = var.private_dns_zone_name_kv
  
  tags = local.common_tags
  
  # additional_settings = local.keyvault_additional_settings
  
  depends_on = [
    module.resource_groups,
    module.network,
    module.azure_ad
  ]
}

# 6. Application Gateway 모듈
module "app_gateway" {
  source = "./modules/appgateway"
  
  resource_group_name = module.resource_groups.spoke_rg_name
  location = var.location
  appgw_name = var.appgw_name
  subnet_id = module.network.appgw_subnet_id
  sku_name = var.appgw_sku
  enable_agic = var.enable_agic
  use_existing_app_gateway = var.use_existing_app_gateway
  use_existing_app_gateway_public_ip = var.use_existing_app_gateway_public_ip
  use_existing_app_gateway_waf_policy = var.use_existing_app_gateway_waf_policy
  
  tags = local.common_tags
  
  depends_on = [
    module.resource_groups,
    module.network
  ]
}

# 7. Bastion 모듈
module "bastion" {
  source = "./modules/bastion"
  
  resource_group_name = module.resource_groups.hub_rg_name
  location = var.location
  bastion_name = var.bastion_name
  subnet_id = module.network.bastion_subnet_id
  use_existing_bastion = var.use_existing_bastion
  
  # 추가된 설정
  sku = var.bastion_sku
  scale_units = var.bastion_scale_units
  enable_copy_paste = var.enable_copy_paste
  enable_file_copy = var.enable_file_copy
  enable_ip_connect = var.enable_ip_connect
  enable_shareable_link = var.enable_shareable_link
  enable_tunneling = var.enable_tunneling
  
  tags = local.common_tags
  
  depends_on = [
    module.resource_groups,
    module.network
  ]
}

# 8. Jumpbox 모듈
module "jumpbox" {
  source = "./modules/jumpbox"
  
  resource_group_name = module.resource_groups.hub_rg_name
  location            = var.location
  jumpbox_name        = var.jumpbox_name
  subnet_id           = module.network.jumpbox_subnet_id
  admin_username      = var.jumpbox_admin_username
  admin_password      = var.jumpbox_admin_password
  use_existing_jumpbox = var.use_existing_jumpbox
  
  # 추가된 설정
  vm_size = var.jumpbox_vm_size
  os_disk_size_gb = var.jumpbox_os_disk_size_gb
  os_disk_type = var.jumpbox_os_disk_type
  enable_public_ip = var.enable_public_ip
  enable_boot_diagnostics = var.enable_boot_diagnostics
  enable_auto_shutdown = var.enable_auto_shutdown
  auto_shutdown_time = var.auto_shutdown_time
  auto_shutdown_timezone = var.auto_shutdown_timezone
  
  tags                = local.common_tags
  
  depends_on = [
    module.resource_groups,
    module.network
  ]
}

# 9. DevOps Agent 모듈 (Azure DevOps를 사용하는 경우에만 배포)
module "devops_agent" {
  source = "./modules/devops_agent"
  count  = 0  # Azure DevOps를 사용하지 않으므로 비활성화
  
  resource_group_name = module.resource_groups.hub_rg_name
  location = var.location
  agent_pool_name = var.devops_agent_pool_name
  vm_name = "${var.devops_agent_pool_name}-vm"
  vm_size = var.devops_agent_vm_size
  admin_username = var.devops_agent_admin_username
  admin_password = var.devops_agent_admin_password
  organization_url = var.devops_organization_url
  pat_token = var.devops_pat_token
  subnet_id = module.network.agent_subnet_id
  
  tags = local.common_tags
  
  depends_on = [
    module.resource_groups,
    module.network
  ]
}

# 10. AKS 클러스터 모듈 (여러 클러스터 지원)
module "aks_clusters" {
  source = "./modules/aks"
  
  for_each = var.aks_clusters
  
  resource_group_name = module.resource_groups.spoke_rg_name
  location = var.location
  cluster_name = each.value.name
  kubernetes_version = each.value.kubernetes_version
  node_count = each.value.node_count
  vm_size = each.value.vm_size
  vnet_id = module.network.spoke_vnet_id
  subnet_id = module.network.aks_subnet_id
  acr_id = module.central_acr.acr_id != "" ? module.central_acr.acr_id : null
  keyvault_id = module.central_keyvault.keyvault_id != "" ? module.central_keyvault.keyvault_id : null
  appgw_id = module.app_gateway.appgw_id != "" ? module.app_gateway.appgw_id : null
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  tenant_id = var.tenant_id
  admin_group_object_ids = var.keyvault_admin_object_ids
  
  # 추가된 설정
  use_existing_aks = each.value.use_existing_aks
  use_existing_aks_cluster = var.use_existing_aks_cluster
  use_existing_aks_node_pool = var.use_existing_aks_node_pool
  use_existing_aks_identity = var.use_existing_aks_identity
  use_existing_private_dns_zone = true
  enable_agic = var.enable_agic
  enable_monitoring = var.enable_monitoring
  enable_aks_monitoring = var.enable_aks_monitoring
  private_cluster_enabled = var.private_cluster_enabled
  enable_auto_scaling = var.enable_auto_scaling
  min_count = var.min_count
  max_count = var.max_count
  enable_node_public_ip = var.enable_node_public_ip
  enable_pod_security_policy = var.enable_pod_security_policy
  enable_rbac = var.enable_rbac
  network_plugin = var.network_plugin
  network_policy = var.network_policy
  load_balancer_sku = var.load_balancer_sku
  outbound_type = var.outbound_type
  private_dns_zone_id = var.private_dns_zone_id
  
  # Hub VNet ID 추가
  hub_vnet_id = module.network.hub_vnet_id
  
  tags = local.common_tags
  
  depends_on = [
    module.resource_groups,
    module.network,
    module.central_acr,
    module.central_keyvault,
    module.app_gateway,
    module.monitoring
  ]
}

# 모니터링 모듈
module "monitoring" {
  source = "./modules/monitoring"
  
  prefix = "aks"
  resource_group_name_hub = module.resource_groups.hub_rg_name
  location = var.location
  environment = var.environment
  project_name = var.project_name
  
  log_analytics_workspace_name = var.log_analytics_workspace_name
  log_analytics_workspace_sku = var.log_analytics_sku
  log_analytics_workspace_retention_days = var.log_analytics_retention_days
  use_existing_workspace = var.use_existing_log_analytics
  use_existing_log_analytics_solution = var.use_existing_log_analytics_solution
  use_existing_monitor_action_group = var.use_existing_monitor_action_group
  use_existing_monitor_alerts = var.use_existing_monitor_alerts
  
  monitor_action_group_name = var.monitor_action_group_name
  monitor_email_receivers = var.monitor_email_receivers
  
  # AKS 클러스터 ID와 이름은 출력 변수에 의존하므로 빈 문자열로 설정
  aks_cluster_id = ""
  aks_cluster_name = ""
  app_gateway_id = module.app_gateway.appgw_id
  vnet_id = module.network.hub_vnet_id
  subscription_id = data.azurerm_subscription.current.subscription_id
  
  # 추가된 설정
  enable_aks_monitoring = var.enable_aks_monitoring
  enable_app_gateway_monitoring = var.enable_app_gateway_monitoring
  enable_network_monitoring = var.enable_network_monitoring
  alert_scopes = var.alert_scopes
  
  tags = local.common_tags
  
  depends_on = [
    module.resource_groups,
    module.network,
    module.app_gateway
  ]
}

# 데이터베이스 모듈
module "database" {
  source = "./modules/database"
  
  resource_group_name = module.resource_groups.spoke_rg_name
  location = var.location
  environment = var.environment
  vnet_name = var.spoke_vnet_name
  subnet_name = var.db_subnet_name
  subnet_prefix = var.db_subnet_prefix
  postgresql_server_name = var.db_server_name
  database_name = var.db_name
  administrator_login = var.db_admin_username
  administrator_login_password = var.db_admin_password
  admin_username = var.db_admin_username
  admin_password = var.db_admin_password
  vnet_id = module.network.spoke_vnet_id
  subnet_id = module.network.db_subnet_id
  private_endpoint_subnet_id = module.network.endpoints_subnet_id
  use_existing_postgresql = var.use_existing_postgresql
  
  # 추가된 설정
  private_dns_zone_name_postgres = var.private_dns_zone_name_postgres
  sku_name = var.db_sku_name
  storage_mb = var.db_storage_mb
  
  tags = local.common_tags
  
  depends_on = [
    module.resource_groups,
    module.network,
    module.monitoring
  ]
}

# 애플리케이션 배포 모듈
module "app" {
  source = "./modules/app"
  count  = 0  # 템플릿 파일 오류로 인해 비활성화
  
  resource_group_name = module.resource_groups.spoke_rg_name
  aks_cluster_name = try(module.aks_clusters["cluster1"].cluster_name, "")
  acr_login_server = module.central_acr.acr_login_server
  app_name = var.app_name
  app_image_name = var.app_image_name
  app_image_tag = var.app_image_tag
  app_host = var.app_host
  
  # 추가된 설정 - 변수 이름 수정
  replicas = var.app_replicas
  cpu_request = var.app_cpu_request
  memory_request = var.app_memory_request
  cpu_limit = var.app_cpu_limit
  memory_limit = var.app_memory_limit
  port = var.app_port
  enable_ingress = var.enable_ingress
  ingress_class = var.ingress_class
  enable_tls = var.enable_tls
  tls_secret_name = var.tls_secret_name
  
  depends_on = [
    module.resource_groups,
    module.network,
    module.aks_clusters,
    module.central_acr,
    module.central_keyvault,
    module.database,
    module.app_gateway,
    module.monitoring
  ]
}

# RBAC 모듈 추가
module "rbac" {
  source = "./modules/rbac"
  
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  
  # 그룹 ID
  operators_group_id = module.azure_ad.operators_group_id
  admins_group_id = module.azure_ad.admins_group_id
  cluster_admins_group_id = module.azure_ad.cluster_admins_group_id
  developers_group_id = module.azure_ad.developers_group_id
  
  # 리소스 ID - 빈 문자열 전달
  aks_cluster_id = local.empty_aks_cluster_id
  storage_account_id = local.empty_storage_account_id
  acr_id = local.empty_acr_id
  keyvault_id = local.empty_keyvault_id
  
  # 기존 리소스 사용 여부
  use_existing_keyvault_rbac = var.use_existing_keyvault_rbac
  
  # Kubernetes RBAC 설정
  kubeconfig_path = "~/.kube/config"
  developer_namespace = "development"
  
  depends_on = [
    module.resource_groups,
    module.network,
    module.azure_ad,
    module.storage,
    module.central_acr,
    module.central_keyvault,
    module.monitoring
  ]
} 