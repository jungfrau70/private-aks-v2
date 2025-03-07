variable "subscription_id" {
  description = "Azure 구독 ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure 테넌트 ID"
  type        = string
}

variable "tenant_domain" {
  description = "Azure AD 테넌트 도메인"
  type        = string
}

variable "location" {
  description = "Azure 리소스 위치"
  type        = string
  default     = "koreacentral"
}

variable "prefix" {
  description = "리소스 이름 접두사"
  type        = string
  default     = "aks-workshop"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "Private AKS Workshop"
}

variable "environment" {
  description = "환경 (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "admin_password" {
  description = "관리자 비밀번호"
  type        = string
  sensitive   = true
}

# 리소스 그룹 이름
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
  default     = "rg-shared_storage"
}

# 스토리지 계정 설정
variable "storage_account_name" {
  description = "스토리지 계정 이름"
  type        = string
  default     = "sa1sharedstorage"
}

variable "file_share_name" {
  description = "파일 공유 이름"
  type        = string
  default     = "quicksciripts"
}

# Hub VNet 설정
variable "hub_vnet_name" {
  description = "Hub VNet 이름"
  type        = string
  default     = "Hub_VNET"
}

variable "hub_vnet_prefix" {
  description = "Hub VNet 주소 공간"
  type        = string
  default     = "10.0.0.0/22"
}

variable "bastion_subnet_name" {
  description = "Bastion 서브넷 이름"
  type        = string
  default     = "AzureBastionSubnet"
}

variable "bastion_subnet_prefix" {
  description = "Bastion 서브넷 주소 공간"
  type        = string
  default     = "10.0.0.128/26"
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

# Spoke VNet 설정
variable "spoke_vnet_name" {
  description = "Spoke VNet 이름"
  type        = string
  default     = "Spoke_VNET"
}

variable "spoke_vnet_prefix" {
  description = "Spoke VNet 주소 공간"
  type        = string
  default     = "10.1.0.0/22"
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

variable "endpoints_subnet_name" {
  description = "Private Endpoints 서브넷 이름"
  type        = string
  default     = "endpoints-subnet"
}

variable "endpoints_subnet_prefix" {
  description = "Private Endpoints 서브넷 주소 공간"
  type        = string
  default     = "10.1.1.16/28"
}

variable "loadbalancer_subnet_name" {
  description = "Load Balancer 서브넷 이름"
  type        = string
  default     = "loadbalancer-subnet"
}

variable "loadbalancer_subnet_prefix" {
  description = "Load Balancer 서브넷 주소 범위"
  type        = string
  default     = "10.1.1.0/28"
}

variable "appgw_subnet_name" {
  description = "Application Gateway 서브넷 이름"
  type        = string
  default     = "app-gw-subnet"
}

variable "appgw_subnet_prefix" {
  description = "Application Gateway 서브넷 주소 공간"
  type        = string
  default     = "10.1.2.0/24"
}

# Storage VNet 설정
variable "storage_vnet_name" {
  description = "Storage VNet 이름"
  type        = string
  default     = "Storage_VNET"
}

variable "storage_vnet_prefix" {
  description = "Storage VNet 주소 공간"
  type        = string
  default     = "10.2.0.0/22"
}

variable "storage_subnet_name" {
  description = "Storage 서브넷 이름"
  type        = string
  default     = "StorageSubnet"
}

variable "storage_subnet_prefix" {
  description = "Storage 서브넷 주소 범위"
  type        = string
  default     = "10.2.0.0/24"
}

# NSG 이름
variable "bastion_nsg_name" {
  description = "Bastion NSG 이름"
  type        = string
  default     = "Bastion_NSG"
}

variable "jumpbox_nsg_name" {
  description = "Jumpbox NSG 이름"
  type        = string
  default     = "Jumpbox_NSG"
}

variable "storage_nsg_name" {
  description = "Storage NSG 이름"
  type        = string
  default     = "Storage_NSG"
}

variable "aks_nsg_name" {
  description = "AKS NSG 이름"
  type        = string
  default     = "Aks_NSG"
}

variable "endpoints_nsg_name" {
  description = "Private Endpoints NSG 이름"
  type        = string
  default     = "Endpoints_NSG"
}

variable "loadbalancer_nsg_name" {
  description = "Load Balancer NSG 이름"
  type        = string
  default     = "Loadbalancer_NSG"
}

variable "appgw_nsg_name" {
  description = "Application Gateway NSG 이름"
  type        = string
  default     = "Appgw_NSG"
}

variable "acr_nsg_name" {
  description = "ACR NSG 이름"
  type        = string
  default     = "Acr_NSG"
}

variable "agent_nsg_name" {
  description = "DevOps Agent NSG 이름"
  type        = string
  default     = "Agent_NSG"
}

# 모니터링 설정
variable "log_analytics_workspace_name" {
  description = "Log Analytics 워크스페이스 이름"
  type        = string
  default     = "law-aks-workshop"
}

variable "log_analytics_sku" {
  description = "Log Analytics 워크스페이스 SKU"
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_days" {
  description = "Log Analytics 워크스페이스 데이터 보존 기간(일)"
  type        = number
  default     = 30
}

variable "use_existing_workspace" {
  description = "기존 Log Analytics 워크스페이스 사용 여부"
  type        = bool
  default     = true
}

variable "monitor_action_group_name" {
  description = "모니터링 알림 그룹 이름"
  type        = string
  default     = "ag-aks-workshop"
}

variable "monitor_email_receivers" {
  description = "모니터링 알림 수신자 이메일 목록"
  type = list(object({
    name                    = string
    email_address           = string
    use_common_alert_schema = bool
  }))
  default = [
    {
      name                    = "admin"
      email_address           = "admin@example.com"
      use_common_alert_schema = true
    }
  ]
}

# AKS 클러스터 설정
variable "aks_clusters" {
  description = "배포할 AKS 클러스터 목록"
  type = map(object({
    name                = string
    kubernetes_version  = string
    node_count          = number
    vm_size             = string
    os_disk_size_gb     = optional(number, 128)
    max_pods            = optional(number, 110)
    network_plugin      = optional(string, "azure")
    network_policy      = optional(string, "azure")
    load_balancer_sku   = optional(string, "standard")
    enable_auto_scaling = optional(bool, true)
    min_count           = optional(number, 1)
    max_count           = optional(number, 5)
    availability_zones  = optional(list(string), ["1", "2", "3"])
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
    use_existing_aks    = optional(bool, true)
  }))
  default = {
    "cluster1" = {
      name                = "aks-cluster1"
      kubernetes_version  = "1.26.6"
      node_count          = 3
      vm_size             = "Standard_DS2_v2"
      os_disk_size_gb     = 128
      max_pods            = 110
      network_plugin      = "azure"
      network_policy      = "azure"
      load_balancer_sku   = "standard"
      enable_auto_scaling = true
      min_count           = 1
      max_count           = 5
      availability_zones  = ["1", "2", "3"]
      node_labels         = { "environment" = "dev" }
      node_taints         = []
      use_existing_aks    = true
    }
  }
}

# 중앙 ACR 설정
variable "acr_name" {
  description = "Azure Container Registry 이름"
  type        = string
  default     = "centralacr"
}

variable "acr_sku" {
  description = "Azure Container Registry SKU"
  type        = string
  default     = "Premium"
}

variable "acr_admin_enabled" {
  description = "Azure Container Registry 관리자 계정 활성화 여부"
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

# 중앙 KeyVault 설정
variable "keyvault_name" {
  description = "Azure Key Vault 이름"
  type        = string
  default     = "central-keyvault"
}

variable "keyvault_sku" {
  description = "Azure Key Vault SKU"
  type        = string
  default     = "standard"
}

# Application Gateway 설정
variable "appgw_name" {
  description = "Application Gateway 이름"
  type        = string
  default     = "central-appgw"
}

variable "appgw_sku" {
  description = "Application Gateway SKU"
  type        = string
  default     = "Standard_v2"
}

# Bastion 설정
variable "bastion_name" {
  description = "Azure Bastion 이름"
  type        = string
  default     = "central-bastion"
}

# Jumpbox 설정
variable "jumpbox_name" {
  description = "Jumpbox VM 이름"
  type        = string
  default     = "central-jumpbox"
}

variable "jumpbox_vm_size" {
  description = "Jumpbox VM 크기"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "jumpbox_admin_username" {
  description = "Jumpbox VM 관리자 사용자 이름"
  type        = string
  default     = "azureuser"
}

variable "jumpbox_admin_password" {
  description = "Jumpbox VM 관리자 비밀번호"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
}

# DevOps Agent 설정
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

variable "devops_agent_pool_name" {
  description = "Azure DevOps Agent Pool 이름"
  type        = string
  default     = "central-agent-pool"
}

variable "devops_agent_vm_size" {
  description = "Azure DevOps Agent VM 크기"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "devops_agent_admin_username" {
  description = "Azure DevOps Agent VM 관리자 사용자 이름"
  type        = string
  default     = "azureuser"
}

variable "devops_agent_admin_password" {
  description = "Azure DevOps Agent VM 관리자 비밀번호"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
}

variable "devops_organization_url" {
  description = "Azure DevOps 조직 URL"
  type        = string
  default     = "https://dev.azure.com/your-organization"
}

variable "devops_pat_token" {
  description = "Azure DevOps Personal Access Token"
  type        = string
  sensitive   = true
  default     = "your-pat-token"
}

variable "use_azure_devops" {
  description = "Azure DevOps 사용 여부"
  type        = bool
  default     = false
}

# 데이터베이스 설정
variable "db_server_name" {
  description = "PostgreSQL 서버 이름"
  type        = string
  default     = "pgsql-server"
}

variable "db_name" {
  description = "PostgreSQL 데이터베이스 이름"
  type        = string
  default     = "aks-workshop-db"
}

variable "db_admin_username" {
  description = "PostgreSQL 관리자 사용자 이름"
  type        = string
  default     = "pgadmin"
}

variable "db_admin_password" {
  description = "PostgreSQL 관리자 비밀번호"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd1234!"
}

variable "db_sku_name" {
  description = "PostgreSQL SKU 이름"
  type        = string
  default     = "GP_Gen5_2"
}

variable "db_storage_mb" {
  description = "PostgreSQL 스토리지 크기(MB)"
  type        = number
  default     = 5120
}

# 애플리케이션 배포 설정
variable "deploy_applications" {
  description = "애플리케이션 배포 여부"
  type        = bool
  default     = true
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

variable "use_existing_storage" {
  description = "기존 스토리지 계정 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_file_share" {
  description = "기존 파일 공유 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_container" {
  description = "기존 Blob 컨테이너 사용 여부"
  type        = bool
  default     = false
}

# 기존 파일 공유 감지를 위한 변수
variable "existing_file_share_names" {
  description = "이미 존재하는 파일 공유 이름 목록"
  type        = list(string)
  default     = []
}

variable "existing_storage_account_names" {
  description = "이미 존재하는 스토리지 계정 이름 목록"
  type        = list(string)
  default     = []
}

variable "use_existing_private_endpoint" {
  description = "기존 Private Endpoint 사용 여부"
  type        = bool
  default     = false
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

variable "use_existing_acr" {
  description = "기존 ACR 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_keyvault" {
  description = "기존 KeyVault 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_appgw" {
  description = "기존 Application Gateway 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_bastion" {
  description = "기존 Bastion 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_jumpbox" {
  description = "기존 Jumpbox 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_postgresql" {
  description = "기존 PostgreSQL 서버 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_ad_groups" {
  description = "기존 Azure AD 그룹을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_ad_users" {
  description = "기존 Azure AD 사용자를 사용할지 여부"
  type        = bool
  default     = false
}

variable "operators_group_id" {
  description = "기존 AKS Operators 그룹 ID"
  type        = string
  default     = ""
}

variable "admins_group_id" {
  description = "기존 AKS Admins 그룹 ID"
  type        = string
  default     = ""
}

variable "cluster_admins_group_id" {
  description = "기존 AKS Cluster Admins 그룹 ID"
  type        = string
  default     = ""
}

variable "developers_group_id" {
  description = "기존 AKS Developers 그룹 ID"
  type        = string
  default     = ""
}

# 태그
variable "tags" {
  description = "리소스에 적용할 태그"
  type        = map(string)
  default     = {}
}

# 애플리케이션 모듈 설정
variable "app_name" {
  description = "애플리케이션 이름"
  type        = string
  default     = "aks-workshop-app"
}

variable "app_image_name" {
  description = "애플리케이션 이미지 이름"
  type        = string
  default     = "aks-workshop-app"
}

variable "app_image_tag" {
  description = "애플리케이션 이미지 태그"
  type        = string
  default     = "latest"
}

variable "app_host" {
  description = "애플리케이션 호스트 이름"
  type        = string
  default     = "app.example.com"
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

# 프라이빗 엔드포인트 설정
variable "enable_private_endpoints" {
  description = "프라이빗 엔드포인트 활성화 여부"
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

# 추가 스토리지 설정
variable "container_name" {
  description = "Blob Storage 컨테이너 이름"
  type        = string
  default     = "aks-workshop-container"
}

variable "blob_name" {
  description = "Blob 이름"
  type        = string
  default     = "aks-workshop-blob"
}

# 키볼트 액세스 정책 설정
variable "enable_keyvault_access_policy" {
  description = "Key Vault 액세스 정책 활성화 여부"
  type        = bool
  default     = true
}

variable "keyvault_admin_object_ids" {
  description = "Key Vault 관리자 Object ID 목록"
  type        = list(string)
  default     = []
}

# 모니터링 추가 설정
variable "enable_aks_monitoring" {
  description = "AKS 모니터링 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_app_gateway_monitoring" {
  description = "Application Gateway 모니터링 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_network_monitoring" {
  description = "네트워크 모니터링 활성화 여부"
  type        = bool
  default     = false
}

variable "alert_scopes" {
  description = "모니터링 알림 범위"
  type        = list(string)
  default     = []
}

# Bastion 모듈 추가 설정
variable "bastion_sku" {
  description = "Bastion 호스트의 SKU"
  type        = string
  default     = "Standard"
}

variable "bastion_scale_units" {
  description = "Bastion 호스트의 스케일 유닛 수"
  type        = number
  default     = 2
}

variable "enable_copy_paste" {
  description = "Bastion 호스트에서 복사/붙여넣기 기능 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_file_copy" {
  description = "Bastion 호스트에서 파일 복사 기능 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_ip_connect" {
  description = "Bastion 호스트에서 IP 연결 기능 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_shareable_link" {
  description = "Bastion 호스트에서 공유 가능한 링크 기능 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_tunneling" {
  description = "Bastion 호스트에서 터널링 기능 활성화 여부"
  type        = bool
  default     = true
}

# Jumpbox 모듈 추가 설정
variable "jumpbox_os_disk_size_gb" {
  description = "Jumpbox VM의 OS 디스크 크기(GB)"
  type        = number
  default     = 128
}

variable "jumpbox_os_disk_type" {
  description = "Jumpbox VM의 OS 디스크 유형"
  type        = string
  default     = "Premium_LRS"
}

variable "enable_public_ip" {
  description = "Jumpbox VM에 공용 IP 할당 여부"
  type        = bool
  default     = false
}

variable "enable_boot_diagnostics" {
  description = "Jumpbox VM에 부팅 진단 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_auto_shutdown" {
  description = "Jumpbox VM에 자동 종료 활성화 여부"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Jumpbox VM 자동 종료 시간(24시간 형식, 예: 2000)"
  type        = string
  default     = "2000"
}

variable "auto_shutdown_timezone" {
  description = "Jumpbox VM 자동 종료 시간대"
  type        = string
  default     = "Korea Standard Time"
}

# AKS 모듈 추가 설정
variable "enable_agic" {
  description = "AKS 클러스터에 Application Gateway Ingress Controller 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "AKS 클러스터에 모니터링 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_private_cluster" {
  description = "AKS 클러스터를 프라이빗으로 설정 여부"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "AKS 클러스터에 자동 스케일링 활성화 여부"
  type        = bool
  default     = false
}

variable "min_count" {
  description = "AKS 클러스터 자동 스케일링 최소 노드 수"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "AKS 클러스터 자동 스케일링 최대 노드 수"
  type        = number
  default     = 5
}

variable "enable_node_public_ip" {
  description = "AKS 노드에 공용 IP 할당 여부"
  type        = bool
  default     = false
}

variable "enable_pod_security_policy" {
  description = "AKS 클러스터에 Pod 보안 정책 활성화 여부"
  type        = bool
  default     = false
}

variable "enable_rbac" {
  description = "AKS 클러스터에 RBAC 활성화 여부"
  type        = bool
  default     = true
}

variable "network_plugin" {
  description = "AKS 클러스터 네트워크 플러그인(azure, kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "AKS 클러스터 네트워크 정책(calico, azure)"
  type        = string
  default     = "calico"
}

variable "load_balancer_sku" {
  description = "AKS 클러스터 로드 밸런서 SKU(standard, basic)"
  type        = string
  default     = "standard"
}

variable "outbound_type" {
  description = "AKS 클러스터 아웃바운드 트래픽 유형(loadBalancer, userDefinedRouting)"
  type        = string
  default     = "loadBalancer"
}

variable "private_cluster_enabled" {
  description = "AKS 클러스터 프라이빗 클러스터 활성화 여부"
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "AKS 클러스터 프라이빗 DNS 영역 ID"
  type        = string
  default     = ""
}

# 애플리케이션 모듈 추가 설정
variable "app_replicas" {
  description = "애플리케이션 복제본 수"
  type        = number
  default     = 3
}

variable "app_cpu_request" {
  description = "애플리케이션 CPU 요청량"
  type        = string
  default     = "100m"
}

variable "app_memory_request" {
  description = "애플리케이션 메모리 요청량"
  type        = string
  default     = "128Mi"
}

variable "app_cpu_limit" {
  description = "애플리케이션 CPU 제한량"
  type        = string
  default     = "500m"
}

variable "app_memory_limit" {
  description = "애플리케이션 메모리 제한량"
  type        = string
  default     = "512Mi"
}

variable "app_port" {
  description = "애플리케이션 포트"
  type        = number
  default     = 80
}

variable "enable_ingress" {
  description = "애플리케이션 Ingress 활성화 여부"
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "애플리케이션 Ingress 클래스"
  type        = string
  default     = "azure/application-gateway"
}

variable "enable_tls" {
  description = "애플리케이션 TLS 활성화 여부"
  type        = bool
  default     = false
}

variable "tls_secret_name" {
  description = "애플리케이션 TLS 시크릿 이름"
  type        = string
  default     = "app-tls-secret"
}

variable "use_existing_database" {
  description = "기존 데이터베이스 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_log_analytics" {
  description = "기존 Log Analytics 워크스페이스 사용 여부"
  type        = bool
  default     = false
}

variable "use_existing_storage_account" {
  description = "기존 스토리지 계정을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_private_dns_zone_blob" {
  description = "기존 Blob 스토리지용 Private DNS Zone을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_private_dns_zone_file" {
  description = "기존 File 스토리지용 Private DNS Zone을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_acr_private_endpoint" {
  description = "기존 ACR Private Endpoint를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_keyvault_private_endpoint" {
  description = "Whether to use an existing KeyVault Private Endpoint"
  type        = bool
  default     = false
}

variable "deploy_storage" {
  description = "Whether to deploy the storage module"
  type        = bool
  default     = true
}

# AKS 클러스터 관련 세분화된 변수
variable "use_existing_aks_cluster" {
  description = "기존 AKS 클러스터를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_aks_node_pool" {
  description = "기존 AKS 노드 풀을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_aks_identity" {
  description = "기존 AKS 관리 ID를 사용할지 여부"
  type        = bool
  default     = false
}

# 모니터링 리소스 관련 세분화된 변수
variable "use_existing_log_analytics_solution" {
  description = "기존 Log Analytics 솔루션을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_monitor_action_group" {
  description = "기존 모니터 액션 그룹을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_monitor_alerts" {
  description = "기존 모니터 알림을 사용할지 여부"
  type        = bool
  default     = false
}

# 애플리케이션 게이트웨이 관련 세분화된 변수
variable "use_existing_app_gateway" {
  description = "기존 애플리케이션 게이트웨이를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_app_gateway_public_ip" {
  description = "기존 애플리케이션 게이트웨이 공용 IP를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_app_gateway_waf_policy" {
  description = "기존 애플리케이션 게이트웨이 WAF 정책을 사용할지 여부"
  type        = bool
  default     = false
}

# 배스천 및 점프박스 관련 세분화된 변수
variable "use_existing_bastion_public_ip" {
  description = "기존 배스천 공용 IP를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_jumpbox_public_ip" {
  description = "기존 점프박스 공용 IP를 사용할지 여부"
  type        = bool
  default     = false
}

# 데이터베이스 관련 세분화된 변수
variable "use_existing_postgresql_private_endpoint" {
  description = "기존 PostgreSQL 프라이빗 엔드포인트를 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_postgresql_private_dns_zone" {
  description = "기존 PostgreSQL 프라이빗 DNS 영역을 사용할지 여부"
  type        = bool
  default     = false
}

variable "use_existing_keyvault_rbac" {
  description = "KeyVault에 대한 RBAC 권한이 이미 존재하는지 여부"
  type        = bool
  default     = true
}