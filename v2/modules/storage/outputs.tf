output "storage_account_id" {
  description = "스토리지 계정 ID"
  value       = local.storage_exists ? data.azurerm_storage_account.storage_account[0].id : azurerm_storage_account.storage_account[0].id
}

output "storage_account_name" {
  description = "스토리지 계정 이름"
  value       = local.storage_exists ? data.azurerm_storage_account.storage_account[0].name : azurerm_storage_account.storage_account[0].name
}

output "storage_account_primary_access_key" {
  description = "스토리지 계정 기본 액세스 키"
  value       = local.storage_exists ? data.azurerm_storage_account.storage_account[0].primary_access_key : azurerm_storage_account.storage_account[0].primary_access_key
  sensitive   = true
}

output "file_share_name" {
  description = "AKS 파일 공유 이름"
  value       = var.file_share_name
}

output "terraform_state_container_name" {
  description = "Terraform 상태 컨테이너 이름"
  value       = local.container_exists ? data.azurerm_storage_container.terraform_state[0].name : (length(azurerm_storage_container.terraform_state) > 0 ? azurerm_storage_container.terraform_state[0].name : null)
}

output "storage_class_manifest_path" {
  description = "스토리지 클래스 매니페스트 경로"
  value       = local_file.storage_class_manifest.filename
} 