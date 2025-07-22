#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
LOCATION="koreacentral"
RESOURCE_GROUP_HUB="rg-hub"
ACR_NAME="centralacr"
ACR_SKU="Premium"
AKS_RESOURCE_GROUP="rg-spoke"
AKS_CLUSTER_NAME="aks-cluster"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# ACR 생성
echo "ACR 생성..."
az acr create \
  --resource-group $RESOURCE_GROUP_HUB \
  --name $ACR_NAME \
  --sku $ACR_SKU \
  --location $LOCATION \
  --admin-enabled false

# AKS 클러스터에 ACR 접근 권한 부여
echo "AKS 클러스터에 ACR 접근 권한 부여..."
AKS_IDENTITY=$(az aks show \
  --resource-group $AKS_RESOURCE_GROUP \
  --name $AKS_CLUSTER_NAME \
  --query identityProfile.kubeletidentity.objectId -o tsv)

ACR_ID=$(az acr show \
  --resource-group $RESOURCE_GROUP_HUB \
  --name $ACR_NAME \
  --query id -o tsv)

az role assignment create \
  --assignee $AKS_IDENTITY \
  --role AcrPull \
  --scope $ACR_ID

# Private Endpoint 설정
echo "Private Endpoint 설정..."
ACR_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RESOURCE_GROUP_HUB \
  --vnet-name Hub_VNET \
  --name acr-subnet \
  --query id -o tsv)

# ACR Private Endpoint 생성
az network private-endpoint create \
  --resource-group $RESOURCE_GROUP_HUB \
  --name "${ACR_NAME}-pe" \
  --vnet-name Hub_VNET \
  --subnet acr-subnet \
  --private-connection-resource-id $ACR_ID \
  --group-id registry \
  --connection-name "${ACR_NAME}-connection"

# Private DNS Zone 생성
az network private-dns zone create \
  --resource-group $RESOURCE_GROUP_HUB \
  --name "privatelink.azurecr.io"

# Private DNS Zone을 VNet에 연결
az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP_HUB \
  --zone-name "privatelink.azurecr.io" \
  --name "Hub-ACR-Link" \
  --virtual-network Hub_VNET \
  --registration-enabled false

az network private-dns link vnet create \
  --resource-group $RESOURCE_GROUP_HUB \
  --zone-name "privatelink.azurecr.io" \
  --name "Spoke-ACR-Link" \
  --virtual-network Spoke_VNET \
  --registration-enabled false

# Private Endpoint DNS 레코드 생성
PRIVATE_IP=$(az network private-endpoint show \
  --resource-group $RESOURCE_GROUP_HUB \
  --name "${ACR_NAME}-pe" \
  --query "customDnsConfigs[0].ipAddresses[0]" -o tsv)

az network private-dns record-set a create \
  --resource-group $RESOURCE_GROUP_HUB \
  --zone-name "privatelink.azurecr.io" \
  --name $ACR_NAME

az network private-dns record-set a add-record \
  --resource-group $RESOURCE_GROUP_HUB \
  --zone-name "privatelink.azurecr.io" \
  --record-set-name $ACR_NAME \
  --ipv4-address $PRIVATE_IP

az network private-dns record-set a create \
  --resource-group $RESOURCE_GROUP_HUB \
  --zone-name "privatelink.azurecr.io" \
  --name "${ACR_NAME}.${LOCATION}.data"

az network private-dns record-set a add-record \
  --resource-group $RESOURCE_GROUP_HUB \
  --zone-name "privatelink.azurecr.io" \
  --record-set-name "${ACR_NAME}.${LOCATION}.data" \
  --ipv4-address $PRIVATE_IP

echo "ACR 설정이 완료되었습니다."
echo "ACR 로그인 서버: ${ACR_NAME}.azurecr.io" 