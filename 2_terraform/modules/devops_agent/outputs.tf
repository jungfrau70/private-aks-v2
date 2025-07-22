output "vmss_id" {
  description = "DevOps Agent VM Scale Set ID"
  value       = local.agent_vm_exists ? null : (var.use_vmss ? azurerm_linux_virtual_machine_scale_set.agent_vmss[0].id : null)
}

output "vmss_name" {
  description = "DevOps Agent VM Scale Set 이름"
  value       = local.agent_vm_exists ? null : (var.use_vmss ? azurerm_linux_virtual_machine_scale_set.agent_vmss[0].name : null)
}

output "vm_id" {
  description = "DevOps Agent VM ID"
  value       = local.agent_vm_exists ? data.azurerm_virtual_machine.agent_vm[0].id : (var.use_vmss ? null : azurerm_linux_virtual_machine.agent_vm[0].id)
}

output "vm_name" {
  description = "DevOps Agent VM 이름"
  value       = local.agent_vm_exists ? data.azurerm_virtual_machine.agent_vm[0].name : (var.use_vmss ? null : azurerm_linux_virtual_machine.agent_vm[0].name)
}

output "agent_pool_name" {
  description = "DevOps Agent 풀 이름"
  value       = var.agent_pool_name
}

output "instance_count" {
  description = "DevOps Agent 인스턴스 수"
  value       = var.instance_count
}

output "auto_scaling_enabled" {
  description = "자동 확장 활성화 여부"
  value       = var.enable_auto_scaling
}

output "min_count" {
  description = "자동 확장 최소 인스턴스 수"
  value       = var.enable_auto_scaling ? var.min_count : null
}

output "max_count" {
  description = "자동 확장 최대 인스턴스 수"
  value       = var.enable_auto_scaling ? var.max_count : null
} 