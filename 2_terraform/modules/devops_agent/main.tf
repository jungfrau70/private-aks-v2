# 리소스 그룹 데이터 소스
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# 기존 DevOps Agent VM 데이터 소스
data "azurerm_virtual_machine" "agent_vm" {
  count               = 1
  name                = var.vm_name
  resource_group_name = var.resource_group_name
}

locals {
  agent_vm_exists = can(data.azurerm_virtual_machine.agent_vm[0].id)
}

# DevOps Agent를 위한 NSG
resource "azurerm_network_security_group" "agent_nsg" {
  count               = local.agent_vm_exists ? 0 : 1
  name                = "devops-agent-nsg"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # GitHub Actions 통신을 위한 아웃바운드 규칙
  security_rule {
    name                       = "AllowGitHubOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = var.tags
}

# NSG와 서브넷 연결
resource "azurerm_subnet_network_security_group_association" "agent_nsg_association" {
  count                = local.agent_vm_exists ? 0 : 1
  subnet_id            = var.subnet_id
  network_security_group_id = azurerm_network_security_group.agent_nsg[0].id
}

# DevOps Agent VM Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "agent_vmss" {
  count               = local.agent_vm_exists ? 0 : var.use_vmss ? 1 : 0
  name                = "devops-agent-vmss"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  sku                 = var.vm_size
  instances           = var.instance_count
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "agent-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id
    }
  }

  extension {
    name                 = "CustomScript"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.1"

    settings = jsonencode({
      "fileUris" = ["${var.script_storage_url}/install_tools_devops_agent.sh"],
      "commandToExecute" = "bash install_tools_devops_agent.sh"
    })
  }

  dynamic "automatic_instance_repair" {
    for_each = var.enable_auto_scaling ? [1] : []
    content {
      enabled = true
      grace_period = "PT30M"
    }
  }

  tags = var.tags
}

# 자동 확장 설정
resource "azurerm_monitor_autoscale_setting" "agent_autoscale" {
  count               = local.agent_vm_exists ? 0 : (var.enable_auto_scaling && var.use_vmss ? 1 : 0)
  name                = "devops-agent-autoscale"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.agent_vmss[0].id

  profile {
    name = "DefaultProfile"

    capacity {
      default = var.instance_count
      minimum = var.min_count
      maximum = var.max_count
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.agent_vmss[0].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.agent_vmss[0].id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.tags
}

# DevOps Agent 네트워크 인터페이스
resource "azurerm_network_interface" "agent_nic" {
  count               = local.agent_vm_exists ? 0 : (var.use_vmss ? 0 : 1)
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# DevOps Agent VM 생성
resource "azurerm_linux_virtual_machine" "agent_vm" {
  count               = local.agent_vm_exists ? 0 : (var.use_vmss ? 0 : 1)
  name                = var.vm_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.agent_nic[0].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = var.tags
} 