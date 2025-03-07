# 리소스 그룹 참조
data "azurerm_resource_group" "resource_group_name_hub" {
  count = var.use_existing_resource_group_hub ? 1 : 0
  name  = var.resource_group_name_hub
}

data "azurerm_resource_group" "resource_group_name_spoke" {
  count = var.use_existing_resource_group_spoke ? 1 : 0
  name  = var.resource_group_name_spoke
}

data "azurerm_resource_group" "resource_group_name_storage" {
  count = var.use_existing_resource_group_storage ? 1 : 0
  name  = var.resource_group_name_storage
}

# 로컬 변수 정의
locals {
  # 리소스 그룹 이름 (존재하면 데이터 소스에서 가져오고, 없으면 변수 사용)
  hub_rg_name     = var.use_existing_resource_group_hub ? data.azurerm_resource_group.resource_group_name_hub[0].name : var.resource_group_name_hub
  hub_rg_location = var.use_existing_resource_group_hub ? data.azurerm_resource_group.resource_group_name_hub[0].location : var.location
  
  spoke_rg_name     = var.use_existing_resource_group_spoke ? data.azurerm_resource_group.resource_group_name_spoke[0].name : var.resource_group_name_spoke
  spoke_rg_location = var.use_existing_resource_group_spoke ? data.azurerm_resource_group.resource_group_name_spoke[0].location : var.location
  
  storage_rg_name     = var.use_existing_resource_group_storage ? data.azurerm_resource_group.resource_group_name_storage[0].name : var.resource_group_name_storage
  storage_rg_location = var.use_existing_resource_group_storage ? data.azurerm_resource_group.resource_group_name_storage[0].location : var.location
  
  # 개별 리소스 존재 여부 설정
  use_existing_hub_vnet = var.use_existing_networks || var.use_existing_hub_vnet
  use_existing_spoke_vnet = var.use_existing_networks || var.use_existing_spoke_vnet
  use_existing_storage_vnet = var.use_existing_networks || var.use_existing_storage_vnet
  use_existing_endpoints_subnet = var.use_existing_networks || var.use_existing_endpoints_subnet
  use_existing_aks_subnet = var.use_existing_networks || var.use_existing_aks_subnet
  
  # 리소스 생성 여부 결정
  create_hub_vnet = !local.use_existing_hub_vnet
  create_spoke_vnet = !local.use_existing_spoke_vnet
  create_storage_vnet = !local.use_existing_storage_vnet
  create_endpoints_subnet = !local.use_existing_endpoints_subnet
  create_aks_subnet = !local.use_existing_aks_subnet
  create_storage_subnet = !local.use_existing_storage_vnet
  
  # VNet 이름 (존재하면 데이터 소스에서 가져오고, 없으면 리소스에서 가져옴)
  hub_vnet_name = local.use_existing_hub_vnet ? data.azurerm_virtual_network.hub_vnet[0].name : azurerm_virtual_network.hub_vnet[0].name
  spoke_vnet_name = local.use_existing_spoke_vnet ? data.azurerm_virtual_network.spoke_vnet[0].name : azurerm_virtual_network.spoke_vnet[0].name
  storage_vnet_name = local.use_existing_storage_vnet ? data.azurerm_virtual_network.storage_vnet[0].name : azurerm_virtual_network.storage_vnet[0].name
  
  # 태그
  tags = var.tags
}

# Hub VNet 데이터 소스
data "azurerm_virtual_network" "hub_vnet" {
  count               = var.use_existing_hub_vnet ? 1 : 0
  name                = var.hub_vnet_name
  resource_group_name = var.resource_group_name_hub
}

# Hub VNet 생성
resource "azurerm_virtual_network" "hub_vnet" {
  count               = var.use_existing_hub_vnet ? 0 : 1
  name                = var.hub_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name_hub
  address_space       = [var.hub_vnet_prefix]
  tags                = var.tags
  
  depends_on = [
    data.azurerm_resource_group.resource_group_name_hub
  ]
}

# 기존 Hub NSG 데이터 소스 - 존재 여부 확인 로직 수정
data "azurerm_network_security_group" "bastion_nsg" {
  count               = var.use_existing_hub_vnet ? 1 : 0
  name                = var.bastion_nsg_name
  resource_group_name = local.hub_rg_name
}

# Hub NSG 생성
resource "azurerm_network_security_group" "bastion_nsg" {
  count               = var.use_existing_hub_vnet ? 0 : 1
  name                = var.bastion_nsg_name
  location            = local.hub_rg_location
  resource_group_name = local.hub_rg_name
  tags                = var.tags
  
  # 참고: 이 NSG는 Azure Bastion 서비스에 필요한 규칙을 포함하고 있지만,
  # Azure Bastion 서브넷에 직접 연결하지는 않습니다.
  # Azure Bastion 서비스는 자체적으로 필요한 규칙을 관리합니다.
}

# Bastion NSG 규칙 - HTTPS 인바운드
resource "azurerm_network_security_rule" "bastion_https_inbound" {
  count                       = var.use_existing_networks ? 0 : 1
  name                        = "AllowHttpsInbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = local.hub_rg_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

# Bastion NSG 규칙 - Gateway Manager 인바운드
resource "azurerm_network_security_rule" "bastion_gateway_manager_inbound" {
  count                       = var.use_existing_networks ? 0 : 1
  name                        = "AllowGatewayManagerInbound"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = local.hub_rg_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

# Bastion NSG 규칙 - Load Balancer 인바운드
resource "azurerm_network_security_rule" "bastion_loadbalancer_inbound" {
  count                       = var.use_existing_networks ? 0 : 1
  name                        = "AllowLoadBalancerInbound"
  priority                    = 140
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = local.hub_rg_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

# Bastion NSG 규칙 - Host Communication 인바운드
resource "azurerm_network_security_rule" "bastion_host_communication_inbound" {
  count                       = var.use_existing_networks ? 0 : 1
  name                        = "AllowBastionHostCommunication"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "5701"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = local.hub_rg_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

# Bastion NSG 규칙 - SSH RDP 아웃바운드
resource "azurerm_network_security_rule" "bastion_ssh_rdp_outbound" {
  count                       = var.use_existing_networks ? 0 : 1
  name                        = "AllowSshRdpOutbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "3389"]
  source_address_prefix       = "*"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = local.hub_rg_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

# Bastion NSG 규칙 - Azure Cloud 아웃바운드
resource "azurerm_network_security_rule" "bastion_azure_cloud_outbound" {
  count                       = var.use_existing_networks ? 0 : 1
  name                        = "AllowAzureCloudOutbound"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = local.hub_rg_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

# Bastion NSG 규칙 - Host Communication 아웃바운드
resource "azurerm_network_security_rule" "bastion_host_communication_outbound" {
  count                       = var.use_existing_networks ? 0 : 1
  name                        = "AllowBastionCommunication"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["8080", "5701"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = local.hub_rg_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

# Bastion NSG 규칙 - Get Session Info 아웃바운드
resource "azurerm_network_security_rule" "bastion_get_session_info" {
  count                       = var.use_existing_networks ? 0 : 1
  name                        = "AllowGetSessionInformation"
  priority                    = 130
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = local.hub_rg_name
  network_security_group_name = azurerm_network_security_group.bastion_nsg[0].name
}

# Jumpbox NSG 생성
resource "azurerm_network_security_group" "jumpbox_nsg" {
  count               = var.use_existing_networks ? 0 : 1
  name                = var.jumpbox_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name_hub
  tags                = var.tags
}

# Storage NSG 생성
resource "azurerm_network_security_group" "storage_nsg" {
  count               = var.use_existing_networks ? 0 : 1
  name                = var.storage_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name_storage
  tags                = var.tags
}

# Hub VNet 서브넷 생성
# Bastion 서브넷
resource "azurerm_subnet" "bastion_subnet" {
  count                = var.use_existing_hub_vnet ? 0 : 1
  name                 = var.bastion_subnet_name
  resource_group_name  = local.hub_rg_name
  virtual_network_name = local.hub_vnet_name
  address_prefixes     = [var.bastion_subnet_prefix]
  
  depends_on = [
    azurerm_virtual_network.hub_vnet
  ]
}

# Firewall 서브넷 생성
resource "azurerm_subnet" "fw_subnet" {
  count                = var.use_existing_hub_vnet ? 0 : 1
  name                 = var.fw_subnet_name
  resource_group_name  = local.hub_rg_name
  virtual_network_name = local.hub_vnet_name
  address_prefixes     = [var.fw_subnet_prefix]
  
  depends_on = [
    azurerm_virtual_network.hub_vnet
  ]
}

# Jumpbox 서브넷 생성
resource "azurerm_subnet" "jumpbox_subnet" {
  count                = var.use_existing_hub_vnet ? 0 : 1
  name                 = var.jumpbox_subnet_name
  resource_group_name  = local.hub_rg_name
  virtual_network_name = local.hub_vnet_name
  address_prefixes     = [var.jumpbox_subnet_prefix]
  
  depends_on = [
    azurerm_virtual_network.hub_vnet
  ]
}

# Spoke VNet 생성
resource "azurerm_virtual_network" "spoke_vnet" {
  count               = var.use_existing_spoke_vnet ? 0 : 1
  name                = var.spoke_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name_spoke
  address_space       = [var.spoke_vnet_prefix]
  tags                = var.tags
  
  depends_on = [
    data.azurerm_resource_group.resource_group_name_spoke
  ]
}

# Spoke VNet 데이터 소스
data "azurerm_virtual_network" "spoke_vnet" {
  count               = var.use_existing_spoke_vnet ? 1 : 0
  name                = var.spoke_vnet_name
  resource_group_name = var.resource_group_name_spoke
}

# Storage VNet 생성
resource "azurerm_virtual_network" "storage_vnet" {
  count               = var.use_existing_storage_vnet ? 0 : 1
  name                = var.storage_vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name_storage
  address_space       = [var.storage_vnet_prefix]
  tags                = var.tags
  
  depends_on = [
    data.azurerm_resource_group.resource_group_name_storage
  ]
}

# Storage VNet 데이터 소스
data "azurerm_virtual_network" "storage_vnet" {
  count               = var.use_existing_storage_vnet ? 1 : 0
  name                = var.storage_vnet_name
  resource_group_name = var.resource_group_name_storage
}

# Storage 서브넷 생성
resource "azurerm_subnet" "storage_subnet" {
  count                = var.use_existing_storage_vnet ? 0 : 1
  name                 = var.storage_subnet_name
  resource_group_name  = local.storage_rg_name
  virtual_network_name = local.storage_vnet_name
  address_prefixes     = [var.storage_subnet_prefix]
  
  depends_on = [
    azurerm_virtual_network.storage_vnet
  ]
}

# AKS NSG 생성
resource "azurerm_network_security_group" "aks_nsg" {
  count               = var.use_existing_networks ? 0 : 1
  name                = var.aks_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name_spoke
  tags                = var.tags
}

# Endpoints NSG 생성
resource "azurerm_network_security_group" "endpoints_nsg" {
  count               = var.use_existing_networks ? 0 : 1
  name                = var.endpoints_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name_spoke
  tags                = var.tags
}

# Load Balancer NSG 생성
resource "azurerm_network_security_group" "loadbalancer_nsg" {
  count               = var.use_existing_networks ? 0 : 1
  name                = var.loadbalancer_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name_spoke
  tags                = var.tags
}

# Application Gateway NSG 생성
resource "azurerm_network_security_group" "appgw_nsg" {
  count               = var.use_existing_networks ? 0 : 1
  name                = var.appgw_nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name_spoke
  tags                = var.tags
}

# AppGW NSG 규칙 생성
resource "azurerm_network_security_rule" "appgw_internet_inbound" {
  count                     = var.use_existing_networks ? 0 : 1
  name                        = "Allow-Internet-Inbound-HTTP-HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name_spoke
  network_security_group_name = azurerm_network_security_group.appgw_nsg[0].name
}

resource "azurerm_network_security_rule" "appgw_gateway_manager_inbound" {
  count                     = var.use_existing_networks ? 0 : 1
  name                        = "Allow-GatewayManager-Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name_spoke
  network_security_group_name = azurerm_network_security_group.appgw_nsg[0].name
}

# AKS 서브넷 생성
resource "azurerm_subnet" "aks_subnet" {
  count                = var.use_existing_spoke_vnet ? 0 : 1
  name                 = var.aks_subnet_name
  resource_group_name  = local.spoke_rg_name
  virtual_network_name = local.spoke_vnet_name
  address_prefixes     = [var.aks_subnet_prefix]
  
  # KeyVault 서비스 엔드포인트 추가
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.ContainerRegistry"]
  
  depends_on = [
    azurerm_virtual_network.spoke_vnet
  ]
}

# DB 서브넷 생성
resource "azurerm_subnet" "db_subnet" {
  count                = var.use_existing_spoke_vnet ? 0 : 1
  name                 = var.db_subnet_name
  resource_group_name  = local.spoke_rg_name
  virtual_network_name = local.spoke_vnet_name
  address_prefixes     = [var.db_subnet_prefix]
  
  # 서비스 엔드포인트 추가
  service_endpoints    = ["Microsoft.Sql"]
  
  # 프라이빗 엔드포인트 네트워크 정책 비활성화
  # private_endpoint_network_policies_enabled = false
  
  depends_on = [
    azurerm_virtual_network.spoke_vnet
  ]
}

# AKS 서브넷 데이터 소스
data "azurerm_subnet" "aks_subnet" {
  count                = var.use_existing_aks_subnet ? 1 : 0
  name                 = var.aks_subnet_name
  resource_group_name  = var.resource_group_name_spoke
  virtual_network_name = var.use_existing_spoke_vnet ? data.azurerm_virtual_network.spoke_vnet[0].name : azurerm_virtual_network.spoke_vnet[0].name
}

# Endpoints 서브넷 생성
resource "azurerm_subnet" "endpoints_subnet" {
  count                = var.use_existing_spoke_vnet ? 0 : 1
  name                 = var.endpoints_subnet_name
  resource_group_name  = local.spoke_rg_name
  virtual_network_name = local.spoke_vnet_name
  address_prefixes     = [var.endpoints_subnet_prefix]
  
  # 프라이빗 엔드포인트 네트워크 정책 비활성화
  # private_endpoint_network_policies_enabled = false
  
  depends_on = [
    azurerm_virtual_network.spoke_vnet
  ]
}

# Endpoints 서브넷 데이터 소스
data "azurerm_subnet" "endpoints_subnet" {
  count                = var.use_existing_endpoints_subnet ? 1 : 0
  name                 = var.endpoints_subnet_name
  resource_group_name  = var.resource_group_name_spoke
  virtual_network_name = var.use_existing_spoke_vnet ? data.azurerm_virtual_network.spoke_vnet[0].name : azurerm_virtual_network.spoke_vnet[0].name
}

# Load Balancer 서브넷 생성
resource "azurerm_subnet" "loadbalancer_subnet" {
  count                = var.use_existing_spoke_vnet ? 0 : 1
  name                 = var.loadbalancer_subnet_name
  resource_group_name  = local.spoke_rg_name
  virtual_network_name = local.spoke_vnet_name
  address_prefixes     = [var.loadbalancer_subnet_prefix]
  
  depends_on = [
    azurerm_virtual_network.spoke_vnet
  ]
}

# Application Gateway 서브넷 생성
resource "azurerm_subnet" "appgw_subnet" {
  count                = var.use_existing_spoke_vnet ? 0 : 1
  name                 = var.appgw_subnet_name
  resource_group_name  = local.spoke_rg_name
  virtual_network_name = local.spoke_vnet_name
  address_prefixes     = [var.appgw_subnet_prefix]
  
  depends_on = [
    azurerm_virtual_network.spoke_vnet
  ]
}

# ACR NSG 생성
resource "azurerm_network_security_group" "acr_nsg" {
  count               = var.use_existing_hub_vnet ? 0 : 1
  name                = var.acr_nsg_name
  location            = var.location
  resource_group_name = local.hub_rg_name
  tags                = var.tags
  
  depends_on = [
    data.azurerm_resource_group.resource_group_name_hub
  ]
}

# ACR 서브넷 생성
resource "azurerm_subnet" "acr_subnet" {
  count                = var.use_existing_hub_vnet ? 0 : 1
  name                 = var.acr_subnet_name
  resource_group_name  = local.hub_rg_name
  virtual_network_name = local.hub_vnet_name
  address_prefixes     = [var.acr_subnet_prefix]
  
  # 서비스 엔드포인트 추가
  service_endpoints    = ["Microsoft.ContainerRegistry"]
  
  depends_on = [
    azurerm_virtual_network.hub_vnet
  ]
}

# ACR 서브넷-NSG 연결
resource "azurerm_subnet_network_security_group_association" "acr_nsg_association" {
  count                     = var.use_existing_hub_vnet ? 0 : 1
  subnet_id                 = azurerm_subnet.acr_subnet[0].id
  network_security_group_id = azurerm_network_security_group.acr_nsg[0].id
  
  depends_on = [
    azurerm_subnet.acr_subnet,
    azurerm_network_security_group.acr_nsg
  ]
}

# DevOps Agent NSG 생성
resource "azurerm_network_security_group" "agent_nsg" {
  count               = var.use_existing_hub_vnet ? 0 : 1
  name                = var.agent_nsg_name
  location            = var.location
  resource_group_name = local.hub_rg_name
  tags                = var.tags
  
  depends_on = [
    data.azurerm_resource_group.resource_group_name_hub
  ]
}

# DevOps Agent 서브넷 생성
resource "azurerm_subnet" "agent_subnet" {
  count                = var.use_existing_hub_vnet ? 0 : 1
  name                 = var.agent_subnet_name
  resource_group_name  = local.hub_rg_name
  virtual_network_name = local.hub_vnet_name
  address_prefixes     = [var.agent_subnet_prefix]
  
  depends_on = [
    azurerm_virtual_network.hub_vnet
  ]
}

# Agent 서브넷-NSG 연결
resource "azurerm_subnet_network_security_group_association" "agent_nsg_association" {
  count                     = var.use_existing_hub_vnet ? 0 : 1
  subnet_id                 = azurerm_subnet.agent_subnet[0].id
  network_security_group_id = azurerm_network_security_group.agent_nsg[0].id
  
  depends_on = [
    azurerm_subnet.agent_subnet,
    azurerm_network_security_group.agent_nsg
  ]
}

# Jumpbox 서브넷-NSG 연결
resource "azurerm_subnet_network_security_group_association" "jumpbox_nsg_association" {
  count                     = var.use_existing_hub_vnet ? 0 : 1
  subnet_id                 = azurerm_subnet.jumpbox_subnet[0].id
  network_security_group_id = azurerm_network_security_group.jumpbox_nsg[0].id
  
  depends_on = [
    azurerm_subnet.jumpbox_subnet,
    azurerm_network_security_group.jumpbox_nsg
  ]
}

# AKS 서브넷-NSG 연결
resource "azurerm_subnet_network_security_group_association" "aks_nsg_association" {
  count                     = var.use_existing_spoke_vnet ? 0 : 1
  subnet_id                 = azurerm_subnet.aks_subnet[0].id
  network_security_group_id = azurerm_network_security_group.aks_nsg[0].id
  
  depends_on = [
    azurerm_subnet.aks_subnet,
    azurerm_network_security_group.aks_nsg
  ]
}

# Endpoints 서브넷-NSG 연결
resource "azurerm_subnet_network_security_group_association" "endpoints_nsg_association" {
  count                     = var.use_existing_spoke_vnet ? 0 : 1
  subnet_id                 = azurerm_subnet.endpoints_subnet[0].id
  network_security_group_id = azurerm_network_security_group.endpoints_nsg[0].id
  
  depends_on = [
    azurerm_subnet.endpoints_subnet,
    azurerm_network_security_group.endpoints_nsg
  ]
}

# Load Balancer 서브넷-NSG 연결
resource "azurerm_subnet_network_security_group_association" "loadbalancer_nsg_association" {
  count                     = var.use_existing_spoke_vnet ? 0 : 1
  subnet_id                 = azurerm_subnet.loadbalancer_subnet[0].id
  network_security_group_id = azurerm_network_security_group.loadbalancer_nsg[0].id
  
  depends_on = [
    azurerm_subnet.loadbalancer_subnet,
    azurerm_network_security_group.loadbalancer_nsg
  ]
}

# Application Gateway 서브넷-NSG 연결
resource "azurerm_subnet_network_security_group_association" "appgw_nsg_association" {
  count                     = var.use_existing_spoke_vnet ? 0 : 1
  subnet_id                 = azurerm_subnet.appgw_subnet[0].id
  network_security_group_id = azurerm_network_security_group.appgw_nsg[0].id
  
  depends_on = [
    azurerm_subnet.appgw_subnet,
    azurerm_network_security_group.appgw_nsg
  ]
}

# VNet Peering 생성 - 로컬 변수를 사용하여 VNet ID 참조
# 1. Hub to Spoke Peering
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                        = var.use_existing_networks ? 0 : 1
  name                         = "hub-to-spoke"
  resource_group_name          = local.hub_rg_name
  virtual_network_name         = var.use_existing_networks ? data.azurerm_virtual_network.hub_vnet[0].name : azurerm_virtual_network.hub_vnet[0].name
  remote_virtual_network_id    = var.use_existing_networks ? data.azurerm_virtual_network.spoke_vnet[0].id : azurerm_virtual_network.spoke_vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  
  depends_on = [
    azurerm_virtual_network.hub_vnet,
    azurerm_virtual_network.spoke_vnet,
    azurerm_subnet.bastion_subnet,
    azurerm_subnet.jumpbox_subnet,
    azurerm_subnet.aks_subnet,
    azurerm_subnet.appgw_subnet,
    azurerm_subnet_network_security_group_association.aks_nsg_association,
    azurerm_subnet_network_security_group_association.appgw_nsg_association
  ]
}

# 2. Spoke to Hub Peering
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                        = var.use_existing_networks ? 0 : 1
  name                         = "spoke-to-hub"
  resource_group_name          = local.spoke_rg_name
  virtual_network_name         = var.use_existing_networks ? data.azurerm_virtual_network.spoke_vnet[0].name : azurerm_virtual_network.spoke_vnet[0].name
  remote_virtual_network_id    = var.use_existing_networks ? data.azurerm_virtual_network.hub_vnet[0].id : azurerm_virtual_network.hub_vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  
  depends_on = [
    azurerm_virtual_network.hub_vnet,
    azurerm_virtual_network.spoke_vnet,
    azurerm_subnet.bastion_subnet,
    azurerm_subnet.jumpbox_subnet,
    azurerm_subnet.aks_subnet,
    azurerm_subnet.appgw_subnet,
    azurerm_subnet_network_security_group_association.aks_nsg_association,
    azurerm_subnet_network_security_group_association.appgw_nsg_association,
    azurerm_virtual_network_peering.hub_to_spoke
  ]
}

# 3. Hub to Storage Peering
resource "azurerm_virtual_network_peering" "hub_to_storage" {
  count                        = var.use_existing_networks ? 0 : 1
  name                         = "hub-to-storage"
  resource_group_name          = local.hub_rg_name
  virtual_network_name         = var.use_existing_networks ? data.azurerm_virtual_network.hub_vnet[0].name : azurerm_virtual_network.hub_vnet[0].name
  remote_virtual_network_id    = var.use_existing_networks ? data.azurerm_virtual_network.storage_vnet[0].id : azurerm_virtual_network.storage_vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  
  depends_on = [
    azurerm_virtual_network.hub_vnet,
    azurerm_virtual_network.storage_vnet,
    azurerm_subnet.bastion_subnet,
    azurerm_subnet.jumpbox_subnet,
    azurerm_subnet.storage_subnet,
    azurerm_virtual_network_peering.hub_to_spoke,
    azurerm_virtual_network_peering.spoke_to_hub
  ]
}

# 4. Storage to Hub Peering
resource "azurerm_virtual_network_peering" "storage_to_hub" {
  count                        = var.use_existing_networks ? 0 : 1
  name                         = "storage-to-hub"
  resource_group_name          = local.storage_rg_name
  virtual_network_name         = var.use_existing_networks ? data.azurerm_virtual_network.storage_vnet[0].name : azurerm_virtual_network.storage_vnet[0].name
  remote_virtual_network_id    = var.use_existing_networks ? data.azurerm_virtual_network.hub_vnet[0].id : azurerm_virtual_network.hub_vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  
  depends_on = [
    azurerm_virtual_network.hub_vnet,
    azurerm_virtual_network.storage_vnet,
    azurerm_subnet.bastion_subnet,
    azurerm_subnet.jumpbox_subnet,
    azurerm_subnet.storage_subnet,
    azurerm_virtual_network_peering.hub_to_storage
  ]
}

# 5. Spoke to Storage Peering
resource "azurerm_virtual_network_peering" "spoke_to_storage" {
  count                        = var.use_existing_networks ? 0 : 1
  name                         = "spoke-to-storage"
  resource_group_name          = local.spoke_rg_name
  virtual_network_name         = var.use_existing_networks ? data.azurerm_virtual_network.spoke_vnet[0].name : azurerm_virtual_network.spoke_vnet[0].name
  remote_virtual_network_id    = var.use_existing_networks ? data.azurerm_virtual_network.storage_vnet[0].id : azurerm_virtual_network.storage_vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  
  depends_on = [
    azurerm_virtual_network.spoke_vnet,
    azurerm_virtual_network.storage_vnet,
    azurerm_subnet.aks_subnet,
    azurerm_subnet.appgw_subnet,
    azurerm_subnet.storage_subnet,
    azurerm_virtual_network_peering.hub_to_spoke,
    azurerm_virtual_network_peering.spoke_to_hub,
    azurerm_virtual_network_peering.hub_to_storage,
    azurerm_virtual_network_peering.storage_to_hub
  ]
}

# 6. Storage to Spoke Peering
resource "azurerm_virtual_network_peering" "storage_to_spoke" {
  count                        = var.use_existing_networks ? 0 : 1
  name                         = "storage-to-spoke"
  resource_group_name          = local.storage_rg_name
  virtual_network_name         = var.use_existing_networks ? data.azurerm_virtual_network.storage_vnet[0].name : azurerm_virtual_network.storage_vnet[0].name
  remote_virtual_network_id    = var.use_existing_networks ? data.azurerm_virtual_network.spoke_vnet[0].id : azurerm_virtual_network.spoke_vnet[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  
  depends_on = [
    azurerm_virtual_network.spoke_vnet,
    azurerm_virtual_network.storage_vnet,
    azurerm_subnet.aks_subnet,
    azurerm_subnet.appgw_subnet,
    azurerm_subnet.storage_subnet,
    azurerm_virtual_network_peering.spoke_to_storage
  ]
} 