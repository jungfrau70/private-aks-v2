output "jumpbox_id" {
  description = "생성된 Jumpbox VM의 ID"
  value       = local.jumpbox_exists ? data.azurerm_virtual_machine.existing[0].id : azurerm_linux_virtual_machine.jumpbox[0].id
}

output "jumpbox_name" {
  description = "Jumpbox VM 이름"
  value       = local.jumpbox_exists ? data.azurerm_virtual_machine.existing[0].name : azurerm_linux_virtual_machine.jumpbox[0].name
}

output "jumpbox_private_ip" {
  description = "Jumpbox VM 프라이빗 IP 주소"
  value       = local.jumpbox_exists ? null : azurerm_network_interface.jumpbox_nic[0].private_ip_address
}

output "jumpbox_admin_username" {
  description = "Jumpbox VM 관리자 사용자 이름"
  value       = local.jumpbox_exists ? null : azurerm_linux_virtual_machine.jumpbox[0].admin_username
} 