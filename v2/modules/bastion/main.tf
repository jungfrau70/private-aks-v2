# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 기존 Bastion 데이터 소스
data "azurerm_bastion_host" "existing" {
  count               = var.use_existing_bastion ? 1 : 0
  name                = var.bastion_name
  resource_group_name = var.resource_group_name
}

# Bastion 참조를 위한 로컬 변수
locals {
  bastion_exists = var.use_existing_bastion && length(data.azurerm_bastion_host.existing) > 0
  bastion_id = local.bastion_exists ? data.azurerm_bastion_host.existing[0].id : (length(azurerm_bastion_host.bastion) > 0 ? azurerm_bastion_host.bastion[0].id : "")
}

# Bastion을 위한 공용 IP 주소
resource "azurerm_public_ip" "bastion_pip" {
  count               = var.use_existing_bastion ? 0 : 1
  name                = "${var.bastion_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Bastion 생성
resource "azurerm_bastion_host" "bastion" {
  count               = var.use_existing_bastion ? 0 : 1
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip[0].id
  }

  # 추가된 설정 적용
  sku                    = var.sku
  scale_units            = var.scale_units
  copy_paste_enabled     = var.enable_copy_paste
  file_copy_enabled      = var.enable_file_copy
  ip_connect_enabled     = var.enable_ip_connect
  shareable_link_enabled = var.enable_shareable_link
  tunneling_enabled      = var.enable_tunneling
} 