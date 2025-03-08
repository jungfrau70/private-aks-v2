# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "storage_rg" {
  count = var.use_existing_resource_group_storage ? 1 : 0
  name  = var.resource_group_name_storage
}

# 스토리지 계정을 위한 리소스 그룹 생성
resource "azurerm_resource_group" "storage_rg" {
  count    = var.use_existing_resource_group_storage || true ? 0 : 1
  name     = var.resource_group_name_storage
  location = var.location
  tags     = var.tags
}

# 로컬 변수 정의
locals {
  resource_group_name = var.resource_group_name_storage
  resource_group_location = var.use_existing_resource_group_storage ? data.azurerm_resource_group.storage_rg[0].location : var.location
}

# 기존 스토리지 계정 데이터 소스
data "azurerm_storage_account" "storage_account" {
  count               = var.use_existing_storage_account ? 1 : 0
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name_storage
}

# 스토리지 계정 생성
resource "azurerm_storage_account" "storage_account" {
  count                    = var.use_existing_storage_account ? 0 : 1
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name_storage
  location                 = local.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  shared_access_key_enabled = true
  min_tls_version          = "TLS1_2"
  
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
  
  tags = var.tags
}

# 스토리지 계정 관련 로컬 변수
locals {
  storage_account_id = var.use_existing_storage_account ? data.azurerm_storage_account.storage_account[0].id : azurerm_storage_account.storage_account[0].id
  storage_account_name = var.use_existing_storage_account ? data.azurerm_storage_account.storage_account[0].name : azurerm_storage_account.storage_account[0].name
  storage_account_key = var.use_existing_storage_account ? data.azurerm_storage_account.storage_account[0].primary_access_key : azurerm_storage_account.storage_account[0].primary_access_key
  storage_exists = var.use_existing_storage_account
}

# 기존 파일 공유 데이터 소스
data "azurerm_storage_share" "file_share" {
  count                = var.use_existing_file_share ? 1 : 0
  name                 = var.file_share_name
  storage_account_name = local.storage_account_name
}

# 파일 공유 존재 여부 확인을 위한 로컬 변수
locals {
  # 파일 공유가 기존 파일 공유 목록에 있는지 확인
  is_existing_file_share = contains(var.existing_file_share_names, var.file_share_name) && contains(var.existing_storage_account_names, var.storage_account_name)
  # 파일 공유 존재 여부
  should_create_file_share = !var.use_existing_file_share && !local.is_existing_file_share
}

# 파일 공유 생성
resource "azurerm_storage_share" "aks_file_share" {
  count                = local.should_create_file_share ? 1 : 0
  name                 = var.file_share_name
  storage_account_name = local.storage_account_name
  quota                = 50
}

# 파일 공유 참조를 위한 로컬 변수
locals {
  file_share_name = var.file_share_name
  file_share_exists = var.use_existing_file_share || local.is_existing_file_share
}

# Terraform 상태 저장용 컨테이너
data "azurerm_storage_container" "terraform_state" {
  count                = var.use_existing_container ? 1 : 0
  name                 = var.container_name
  storage_account_name = local.storage_account_name
}

resource "azurerm_storage_container" "terraform_state" {
  count                = var.use_existing_container ? 0 : 1
  name                 = var.container_name
  storage_account_name = local.storage_account_name
  container_access_type = "private"
}

# 컨테이너 참조를 위한 로컬 변수
locals {
  container_exists = var.use_existing_container
}

# 파일 서비스를 위한 Private DNS Zone
resource "azurerm_private_dns_zone" "storage_file_dns_zone" {
  count               = var.use_existing_private_dns_zone_file ? 0 : 1
  name                = var.private_dns_zone_name_file
  resource_group_name = var.resource_group_name_storage
  tags                = var.tags
}

# Blob 서비스를 위한 Private DNS Zone
resource "azurerm_private_dns_zone" "storage_blob_dns_zone" {
  count               = var.use_existing_private_dns_zone_blob ? 0 : 1
  name                = var.private_dns_zone_name_blob
  resource_group_name = var.resource_group_name_storage
  tags                = var.tags
}

# Private DNS Zone 데이터 소스
data "azurerm_private_dns_zone" "storage_file_dns_zone" {
  count               = var.use_existing_private_dns_zone_file ? 1 : 0
  name                = var.private_dns_zone_name_file
  resource_group_name = var.resource_group_name_storage
}

data "azurerm_private_dns_zone" "storage_blob_dns_zone" {
  count               = var.use_existing_private_dns_zone_blob ? 1 : 0
  name                = var.private_dns_zone_name_blob
  resource_group_name = var.resource_group_name_storage
}

# DNS Zone ID 로컬 변수
locals {
  file_dns_zone_id = var.use_existing_private_dns_zone_file ? data.azurerm_private_dns_zone.storage_file_dns_zone[0].id : azurerm_private_dns_zone.storage_file_dns_zone[0].id
  blob_dns_zone_id = var.use_existing_private_dns_zone_blob ? data.azurerm_private_dns_zone.storage_blob_dns_zone[0].id : azurerm_private_dns_zone.storage_blob_dns_zone[0].id
}

# Private DNS Zone과 VNet 연결 (File)
resource "azurerm_private_dns_zone_virtual_network_link" "storage_file_dns_link" {
  count                 = var.use_existing_private_dns_zone_file ? 0 : 1
  name                  = "${local.storage_account_name}-file-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = var.private_dns_zone_name_file
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
  
  depends_on = [
    azurerm_private_dns_zone.storage_file_dns_zone
  ]
}

# Private DNS Zone과 VNet 연결 (Blob)
resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob_dns_link" {
  count                 = var.use_existing_private_dns_zone_blob ? 0 : 1
  name                  = "${local.storage_account_name}-blob-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = var.private_dns_zone_name_blob
  virtual_network_id    = var.virtual_network_id
  tags                  = var.tags
  
  depends_on = [
    azurerm_private_dns_zone.storage_blob_dns_zone
  ]
}

# File 서비스를 위한 Private Endpoint
resource "azurerm_private_endpoint" "storage_file_endpoint" {
  count               = var.use_existing_private_endpoint_storage ? 0 : 1
  name                = "${var.storage_account_name}-file-pe"
  location            = local.resource_group_location
  resource_group_name = var.resource_group_name_storage
  subnet_id           = var.endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.storage_account_name}-file-psc"
    private_connection_resource_id = local.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
  
  private_dns_zone_group {
    name                 = "storage-file-dns-group"
    private_dns_zone_ids = [local.file_dns_zone_id]
  }
}

# Blob 서비스를 위한 Private Endpoint
resource "azurerm_private_endpoint" "storage_blob_endpoint" {
  count               = var.use_existing_private_endpoint_storage ? 0 : 1
  name                = "${var.storage_account_name}-blob-pe"
  location            = local.resource_group_location
  resource_group_name = var.resource_group_name_storage
  subnet_id           = var.endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-psc"
    private_connection_resource_id = local.storage_account_id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  
  private_dns_zone_group {
    name                 = "storage-blob-dns-group"
    private_dns_zone_ids = [local.blob_dns_zone_id]
  }
}

# AKS에서 사용할 Storage Class 및 PV/PVC 설정을 위한 Kubernetes 매니페스트
resource "local_file" "storage_class_manifest" {
  content = templatefile("${path.module}/templates/storage-class.yaml.tpl", {
    storage_account_name = local.storage_account_name
    storage_account_key  = local.storage_account_key
    file_share_name      = local.file_share_name
  })
  filename = "${path.module}/manifests/storage-class.yaml"
} 