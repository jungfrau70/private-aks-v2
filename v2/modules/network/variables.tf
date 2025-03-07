variable "location" {
  description = "리소스 배포 위치"
  type        = string
  default     = "koreacentral"
}

variable "resource_group_name_hub" {
  description = "Hub 리소스 그룹 이름"
  type        = string
  default     = "rg-hub"
}

variable "resource_group_name_spoke" {
  description = "Spoke 리소스 그룹 이름"
  type        = string
  default     = "rg-spoke"
}

variable "resource_group_name_storage" {
  description = "Storage 리소스 그룹 이름"
  type        = string
  default     = "rg-storage"
}

# Hub VNet 변수
variable "hub_vnet_name" {
  description = "Hub VNet 이름"
  type        = string
  default     = "Hub_VNET"
}

variable "hub_vnet_prefix" {
  description = "Hub VNet 주소 공간"
  type        = string
  default     = "10.0.0.0/16"
}

variable "bastion_subnet_name" {
  description = "Bastion 서브넷 이름"
  type        = string
  default     = "AzureBastionSubnet"
}

variable "bastion_subnet_prefix" {
  description = "Bastion 서브넷 주소 공간"
  type        = string
  default     = "10.0.1.0/24"
}

variable "fw_subnet_name" {
  description = "Firewall 서브넷 이름"
  type        = string
  default     = "AzureFirewallSubnet"
}

variable "fw_subnet_prefix" {
  description = "Firewall 서브넷 주소 범위"
  type        = string
  default     = "10.0.0.0/26"
}

variable "jumpbox_subnet_name" {
  description = "Jumpbox 서브넷 이름"
  type        = string
  default     = "JumpboxSubnet"
}

variable "jumpbox_subnet_prefix" {
  description = "Jumpbox 서브넷 주소 공간"
  type        = string
  default     = "10.0.0.64/26"
}

# Spoke VNet 변수
variable "spoke_vnet_name" {
  description = "Spoke VNet 이름"
  type        = string
  default     = "Spoke_VNET"
}

variable "spoke_vnet_prefix" {
  description = "Spoke VNet 주소 공간"
  type        = string
  default     = "10.1.0.0/16"
}

# Storage VNet 변수
variable "storage_vnet_name" {
  description = "Storage VNet 이름"
  type        = string
  default     = "Storage_VNET"
}

variable "storage_vnet_prefix" {
  description = "Storage VNet 주소 공간"
  type        = string
  default     = "10.2.0.0/16"
}

variable "storage_subnet_name" {
  description = "Storage 서브넷 이름"
  type        = string
  default     = "snet-storage"
}

variable "storage_subnet_prefix" {
  description = "Storage 서브넷 주소 범위"
  type        = string
  default     = "10.2.1.0/24"
}

variable "storage_nsg_name" {
  description = "Storage NSG 이름"
  type        = string
  default     = "Storage-NSG"
}

variable "aks_subnet_name" {
  description = "AKS 서브넷 이름"
  type        = string
  default     = "aks-subnet"
}

variable "aks_subnet_prefix" {
  description = "AKS 서브넷 주소 공간"
  type        = string
  default     = "10.1.0.0/24"
}

variable "endpoints_subnet_name" {
  description = "Private Endpoints 서브넷 이름"
  type        = string
  default     = "endpoints-subnet"
}

variable "endpoints_subnet_prefix" {
  description = "Private Endpoints 서브넷 주소 공간"
  type        = string
  default     = "10.1.1.0/24"
}

variable "loadbalancer_subnet_name" {
  description = "Load Balancer 서브넷 이름"
  type        = string
  default     = "snet-loadbalancer"
}

variable "loadbalancer_subnet_prefix" {
  description = "Load Balancer 서브넷 주소 범위"
  type        = string
  default     = "10.1.3.0/24"
}

variable "appgw_subnet_name" {
  description = "Application Gateway 서브넷 이름"
  type        = string
  default     = "app-gw-subnet"
}

variable "appgw_subnet_prefix" {
  description = "Application Gateway 서브넷 주소 공간"
  type        = string
  default     = "10.1.2.32/27"
}

# NSG 이름 변수
variable "bastion_nsg_name" {
  description = "Bastion NSG 이름"
  type        = string
  default     = "Bastion-NSG"
}

variable "jumpbox_nsg_name" {
  description = "Jumpbox NSG 이름"
  type        = string
  default     = "Jumpbox-NSG"
}

variable "aks_nsg_name" {
  description = "AKS NSG 이름"
  type        = string
  default     = "Aks-NSG"
}

variable "endpoints_nsg_name" {
  description = "Private Endpoints NSG 이름"
  type        = string
  default     = "Endpoints-NSG"
}

variable "loadbalancer_nsg_name" {
  description = "Load Balancer NSG 이름"
  type        = string
  default     = "Loadbalancer-NSG"
}

variable "appgw_nsg_name" {
  description = "Application Gateway NSG 이름"
  type        = string
  default     = "Appgw-NSG"
}

# 기존 리소스 사용 여부
variable "use_existing_resource_group_hub" {
  description = "기존 Hub 리소스 그룹 사용 여부"
  type        = bool
  default     = true
}

variable "use_existing_resource_group_spoke" {
  description = "기존 Spoke 리소스 그룹 사용 여부"
  type        = bool
  default     = true
}

variable "use_existing_resource_group_storage" {
  description = "기존 Storage 리소스 그룹 사용 여부"
  type        = bool
  default     = true
}

variable "use_existing_networks" {
  description = "기존 네트워크 리소스를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_hub_vnet" {
  description = "기존 Hub VNet을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_spoke_vnet" {
  description = "기존 Spoke VNet을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_storage_vnet" {
  description = "기존 Storage VNet을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_endpoints_subnet" {
  description = "기존 Endpoints 서브넷을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_aks_subnet" {
  description = "기존 AKS 서브넷을 사용할지 여부"
  type        = bool
  default     = false
}

variable "acr_subnet_name" {
  description = "ACR 서브넷 이름"
  type        = string
  default     = "acr-subnet"
}

variable "acr_subnet_prefix" {
  description = "ACR 서브넷 주소 범위"
  type        = string
  default     = "10.0.1.0/26"
}

variable "acr_nsg_name" {
  description = "ACR NSG 이름"
  type        = string
  default     = "Acr_NSG"
}

variable "agent_subnet_name" {
  description = "DevOps Agent 서브넷 이름"
  type        = string
  default     = "agent-subnet"
}

variable "agent_subnet_prefix" {
  description = "DevOps Agent 서브넷 주소 공간"
  type        = string
  default     = "10.0.1.64/26"
}

variable "agent_nsg_name" {
  description = "DevOps Agent NSG 이름"
  type        = string
  default     = "Agent-NSG"
}

variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

# 네트워크 피어링 설정
variable "enable_hub_spoke_peering" {
  description = "Hub와 Spoke VNet 간 피어링 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_hub_storage_peering" {
  description = "Hub와 Storage VNet 간 피어링 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_spoke_storage_peering" {
  description = "Spoke와 Storage VNet 간 피어링 활성화 여부"
  type        = bool
  default     = true
}

# 방화벽 설정
variable "enable_azure_firewall" {
  description = "Azure Firewall 활성화 여부"
  type        = bool
  default     = false
}

variable "fw_name" {
  description = "Azure Firewall 이름"
  type        = string
  default     = "central-firewall"
}

variable "fw_policy_name" {
  description = "Azure Firewall 정책 이름"
  type        = string
  default     = "central-firewall-policy"
}

# 로드 밸런서 설정
variable "enable_internal_lb" {
  description = "내부 로드 밸런서 활성화 여부"
  type        = bool
  default     = false
}

variable "loadbalancer_name" {
  description = "내부 로드 밸런서 이름"
  type        = string
  default     = "internal-lb"
}

# 프라이빗 엔드포인트 설정
variable "enable_private_endpoints" {
  description = "프라이빗 엔드포인트를 사용할지 여부"
  type        = bool
  default     = true
}

variable "private_dns_zone_name_blob" {
  description = "Blob Storage용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.blob.core.windows.net"
}

variable "private_dns_zone_name_file" {
  description = "File Storage용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.file.core.windows.net"
}

variable "private_dns_zone_name_acr" {
  description = "ACR용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.azurecr.io"
}

variable "private_dns_zone_name_kv" {
  description = "Key Vault용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.vaultcore.azure.net"
}

variable "private_dns_zone_name_postgres" {
  description = "PostgreSQL용 프라이빗 DNS 존 이름"
  type        = string
  default     = "privatelink.postgres.database.azure.com"
}

variable "db_subnet_name" {
  description = "데이터베이스 서브넷 이름"
  type        = string
  default     = "db-subnet"
}

variable "db_subnet_prefix" {
  description = "데이터베이스 서브넷 주소 공간"
  type        = string
  default     = "10.1.1.32/28"
} 