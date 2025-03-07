# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 기존 Jumpbox VM 데이터 소스
data "azurerm_virtual_machine" "existing" {
  count               = var.use_existing_jumpbox ? 1 : 0
  name                = var.jumpbox_name
  resource_group_name = var.resource_group_name
}

locals {
  jumpbox_exists = var.use_existing_jumpbox
}

# Jumpbox VM을 위한 NIC
resource "azurerm_network_interface" "jumpbox_nic" {
  count               = var.use_existing_jumpbox ? 0 : 1
  name                = "${var.jumpbox_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    # 공용 IP 설정 (선택적)
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.jumpbox_pip[0].id : null
  }
}

# 공용 IP 생성 (선택적)
resource "azurerm_public_ip" "jumpbox_pip" {
  count               = var.use_existing_jumpbox || !var.enable_public_ip ? 0 : 1
  name                = "${var.jumpbox_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Jumpbox VM 생성
resource "azurerm_linux_virtual_machine" "jumpbox" {
  count               = var.use_existing_jumpbox ? 0 : 1
  name                = var.jumpbox_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.jumpbox_nic[0].id]
  tags                = var.tags

  # 추가된 설정 적용
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  
  # Provider 버그 방지를 위한 lifecycle 설정
  lifecycle {
    ignore_changes = [
      zone,
      dedicated_host_id,
      capacity_reservation_group_id,
      user_data,
      edge_zone,
      encryption_at_host_enabled,
      eviction_policy,
      license_type,
      virtual_machine_scale_set_id,
      dedicated_host_group_id,
      proximity_placement_group_id,
      vtpm_enabled,
      custom_data,
      secure_boot_enabled,
      source_image_id,
      availability_set_id,
      reboot_setting,
      boot_diagnostics,
      os_disk
    ]
  }

  # 부팅 진단 설정
  dynamic "boot_diagnostics" {
    for_each = var.enable_boot_diagnostics ? [1] : []
    content {
      storage_account_uri = null # Managed Storage 사용
    }
  }

  # 초기 설정 스크립트
  custom_data = base64encode(file("${path.root}/scripts/install_tools_jumpbox.sh"))
}

# 자동 종료 설정 (선택적)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "jumpbox_shutdown" {
  count                = var.use_existing_jumpbox || !var.enable_auto_shutdown ? 0 : 1
  virtual_machine_id   = azurerm_linux_virtual_machine.jumpbox[0].id
  location             = var.location
  enabled              = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone             = var.auto_shutdown_timezone
  notification_settings {
    enabled = false
  }
} 