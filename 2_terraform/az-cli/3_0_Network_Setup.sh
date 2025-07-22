#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
LOCATION="koreacentral"
RESOURCE_GROUP_HUB="rg-hub"
RESOURCE_GROUP_SPOKE="rg-spoke"
RESOURCE_GROUP_STORAGE="rg-shared_storage"

# Hub VNet 설정
HUB_VNET_NAME="Hub_VNET"
HUB_VNET_PREFIX="10.0.0.0/22"
BASTION_SUBNET_NAME="AzureBastionSubnet"
BASTION_SUBNET_PREFIX="10.0.0.128/26"
FW_SUBNET_NAME="AzureFirewallSubnet"
FW_SUBNET_PREFIX="10.0.0.0/26"
JUMPBOX_SUBNET_NAME="JumpboxSubnet"
JUMPBOX_SUBNET_PREFIX="10.0.0.64/26"
ACR_SUBNET_NAME="acr-subnet"
ACR_SUBNET_PREFIX="10.0.1.0/26"
AGENT_SUBNET_NAME="agent-subnet"
AGENT_SUBNET_PREFIX="10.0.1.64/26"

# Spoke VNet 설정
SPOKE_VNET_NAME="Spoke_VNET"
SPOKE_VNET_PREFIX="10.1.0.0/22"
AKS_SUBNET_NAME="aks-subnet"
AKS_SUBNET_PREFIX="10.1.0.0/24"
ENDPOINTS_SUBNET_NAME="endpoints-subnet"
ENDPOINTS_SUBNET_PREFIX="10.1.1.16/28"
LOADBALANCER_SUBNET_NAME="loadbalancer-subnet"
LOADBALANCER_SUBNET_PREFIX="10.1.1.0/28"
APPGW_SUBNET_NAME="app-gw-subnet"
APPGW_SUBNET_PREFIX="10.1.2.0/24"

# Storage VNet 설정
STORAGE_VNET_NAME="Storage_VNET"
STORAGE_VNET_PREFIX="10.2.0.0/22"
STORAGE_SUBNET_NAME="StorageSubnet"
STORAGE_SUBNET_PREFIX="10.2.0.0/24"

# NSG 이름
BASTION_NSG_NAME="Bastion_NSG"
JUMPBOX_NSG_NAME="Jumpbox_NSG"
STORAGE_NSG_NAME="Storage_NSG"
AKS_NSG_NAME="Aks_NSG"
ENDPOINTS_NSG_NAME="Endpoints_NSG"
LOADBALANCER_NSG_NAME="Loadbalancer_NSG"
APPGW_NSG_NAME="Appgw_NSG"
ACR_NSG_NAME="Acr_NSG"
AGENT_NSG_NAME="Agent_NSG"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# 리소스 그룹 생성
echo "리소스 그룹 생성..."
az group create --name $RESOURCE_GROUP_HUB --location $LOCATION
az group create --name $RESOURCE_GROUP_SPOKE --location $LOCATION
az group create --name $RESOURCE_GROUP_STORAGE --location $LOCATION

# Hub VNet 및 서브넷 생성
echo "Hub VNet 및 서브넷 생성..."
az network vnet create \
  --resource-group $RESOURCE_GROUP_HUB \
  --name $HUB_VNET_NAME \
  --address-prefix $HUB_VNET_PREFIX \
  --subnet-name $FW_SUBNET_NAME \
  --subnet-prefix $FW_SUBNET_PREFIX

# Bastion 서브넷 생성
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP_HUB \
  --vnet-name $HUB_VNET_NAME \
  --name $BASTION_SUBNET_NAME \
  --address-prefix $BASTION_SUBNET_PREFIX

# Jumpbox 서브넷 생성
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP_HUB \
  --vnet-name $HUB_VNET_NAME \
  --name $JUMPBOX_SUBNET_NAME \
  --address-prefix $JUMPBOX_SUBNET_PREFIX

# ACR 서브넷 생성
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP_HUB \
  --vnet-name $HUB_VNET_NAME \
  --name $ACR_SUBNET_NAME \
  --address-prefix $ACR_SUBNET_PREFIX

# Agent 서브넷 생성
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP_HUB \
  --vnet-name $HUB_VNET_NAME \
  --name $AGENT_SUBNET_NAME \
  --address-prefix $AGENT_SUBNET_PREFIX

# Spoke VNet 및 서브넷 생성
echo "Spoke VNet 및 서브넷 생성..."
az network vnet create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $SPOKE_VNET_NAME \
  --address-prefix $SPOKE_VNET_PREFIX \
  --subnet-name $AKS_SUBNET_NAME \
  --subnet-prefix $AKS_SUBNET_PREFIX

# Endpoints 서브넷 생성
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --vnet-name $SPOKE_VNET_NAME \
  --name $ENDPOINTS_SUBNET_NAME \
  --address-prefix $ENDPOINTS_SUBNET_PREFIX

# Loadbalancer 서브넷 생성
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --vnet-name $SPOKE_VNET_NAME \
  --name $LOADBALANCER_SUBNET_NAME \
  --address-prefix $LOADBALANCER_SUBNET_PREFIX

# AppGW 서브넷 생성
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --vnet-name $SPOKE_VNET_NAME \
  --name $APPGW_SUBNET_NAME \
  --address-prefix $APPGW_SUBNET_PREFIX

# Storage VNet 및 서브넷 생성
echo "Storage VNet 및 서브넷 생성..."
az network vnet create \
  --resource-group $RESOURCE_GROUP_STORAGE \
  --name $STORAGE_VNET_NAME \
  --address-prefix $STORAGE_VNET_PREFIX \
  --subnet-name $STORAGE_SUBNET_NAME \
  --subnet-prefix $STORAGE_SUBNET_PREFIX

# VNet Peering 설정
echo "VNet Peering 설정..."

# Hub to Spoke Peering
az network vnet peering create \
  --name Hub-to-Spoke \
  --resource-group $RESOURCE_GROUP_HUB \
  --vnet-name $HUB_VNET_NAME \
  --remote-vnet $SPOKE_VNET_NAME \
  --remote-vnet-resource-group $RESOURCE_GROUP_SPOKE \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Spoke to Hub Peering
az network vnet peering create \
  --name Spoke-to-Hub \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --vnet-name $SPOKE_VNET_NAME \
  --remote-vnet $HUB_VNET_NAME \
  --remote-vnet-resource-group $RESOURCE_GROUP_HUB \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Hub to Storage Peering
az network vnet peering create \
  --name Hub-to-Storage \
  --resource-group $RESOURCE_GROUP_HUB \
  --vnet-name $HUB_VNET_NAME \
  --remote-vnet $STORAGE_VNET_NAME \
  --remote-vnet-resource-group $RESOURCE_GROUP_STORAGE \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Storage to Hub Peering
az network vnet peering create \
  --name Storage-to-Hub \
  --resource-group $RESOURCE_GROUP_STORAGE \
  --vnet-name $STORAGE_VNET_NAME \
  --remote-vnet $HUB_VNET_NAME \
  --remote-vnet-resource-group $RESOURCE_GROUP_HUB \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Spoke to Storage Peering
az network vnet peering create \
  --name Spoke-to-Storage \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --vnet-name $SPOKE_VNET_NAME \
  --remote-vnet $STORAGE_VNET_NAME \
  --remote-vnet-resource-group $RESOURCE_GROUP_STORAGE \
  --allow-vnet-access \
  --allow-forwarded-traffic

# Storage to Spoke Peering
az network vnet peering create \
  --name Storage-to-Spoke \
  --resource-group $RESOURCE_GROUP_STORAGE \
  --vnet-name $STORAGE_VNET_NAME \
  --remote-vnet $SPOKE_VNET_NAME \
  --remote-vnet-resource-group $RESOURCE_GROUP_SPOKE \
  --allow-vnet-access \
  --allow-forwarded-traffic

echo "네트워크 설정이 완료되었습니다." 