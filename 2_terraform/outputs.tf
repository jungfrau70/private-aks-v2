output "azure_ad_users" {
  description = "생성된 Azure AD 사용자"
  value       = module.azure_ad.users
}

output "azure_ad_groups" {
  description = "생성된 Azure AD 그룹"
  value       = module.azure_ad.groups
}

output "storage_account_name" {
  description = "스토리지 계정 이름"
  value       = var.deploy_storage ? module.storage[0].storage_account_name : null
}

output "file_share_name" {
  description = "파일 공유 이름"
  value       = var.deploy_storage ? module.storage[0].file_share_name : null
}

output "hub_vnet_id" {
  description = "Hub VNet ID"
  value       = module.network.hub_vnet_id
}

output "spoke_vnet_id" {
  description = "Spoke VNet ID"
  value       = module.network.spoke_vnet_id
}

output "acr_id" {
  description = "ACR ID"
  value       = module.central_acr.acr_id
}

output "acr_name" {
  description = "ACR 이름"
  value       = module.central_acr.acr_name
}

output "acr_login_server" {
  description = "ACR 로그인 서버"
  value       = module.central_acr.acr_login_server
}

output "devops_agent_pool_name" {
  description = "DevOps Agent 풀 이름"
  value       = var.use_azure_devops ? module.devops_agent[0].agent_pool_name : null
}

output "aks_clusters" {
  description = "AKS 클러스터 정보"
  value       = {
    for k, v in module.aks_cluster : k => {
      id                 = v.cluster_id
      name               = v.cluster_name
      resource_group     = module.resource_groups.spoke_rg_name
      private_fqdn       = v.private_fqdn
      kubelet_identity   = v.kubelet_identity
      node_resource_group = v.node_resource_group
    }
  }
}

output "aks_cluster_ids" {
  description = "AKS 클러스터 ID 목록"
  value       = { for k, v in module.aks_cluster : k => v.cluster_id }
}

output "aks_cluster_names" {
  description = "AKS 클러스터 이름 목록"
  value       = { for k, v in module.aks_cluster : k => v.cluster_name }
}

output "aks_cluster_kubeconfig_commands" {
  description = "AKS 클러스터 kubeconfig 명령어 목록"
  value       = { for k, v in module.aks_cluster : k => "az aks get-credentials --resource-group ${module.resource_groups.spoke_rg_name} --name ${v.cluster_name}" }
}

output "keyvault_id" {
  description = "KeyVault ID"
  value       = module.central_keyvault.keyvault_id
}

output "keyvault_name" {
  description = "KeyVault 이름"
  value       = module.central_keyvault.keyvault_name
}

output "keyvault_uri" {
  description = "KeyVault URI"
  value       = module.central_keyvault.keyvault_uri
}

output "appgw_id" {
  description = "Application Gateway ID"
  value       = module.app_gateway.appgw_id
}

output "appgw_name" {
  description = "Application Gateway 이름"
  value       = module.app_gateway.appgw_name
}

output "appgw_public_ip" {
  description = "Application Gateway 공용 IP 주소"
  value       = module.app_gateway.appgw_public_ip
}

output "bastion_id" {
  description = "Bastion ID"
  value       = module.bastion.bastion_id
}

output "bastion_public_ip" {
  description = "Bastion 공용 IP 주소"
  value       = module.bastion.bastion_public_ip
}

output "jumpbox_id" {
  description = "Jumpbox VM ID"
  value       = module.jumpbox.jumpbox_id
}

output "jumpbox_private_ip" {
  description = "Jumpbox VM 프라이빗 IP 주소"
  value       = module.jumpbox.jumpbox_private_ip
}

output "devops_agent_id" {
  description = "DevOps Agent VM Scale Set ID"
  value       = var.use_azure_devops ? module.devops_agent[0].vmss_id : null
} 