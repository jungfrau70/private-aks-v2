output "bastion_id" {
  description = "Bastion ID"
  value       = local.bastion_id
}

output "bastion_name" {
  description = "Bastion 이름"
  value       = var.bastion_name
}

output "bastion_public_ip" {
  description = "Bastion 공용 IP 주소"
  value       = var.use_existing_bastion ? null : (length(azurerm_public_ip.bastion_pip) > 0 ? azurerm_public_ip.bastion_pip[0].ip_address : null)
} 