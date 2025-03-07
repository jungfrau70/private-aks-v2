#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP_SPOKE="rg-spoke"
AKS_CLUSTER_NAME="aks-cluster"
APPGW_NAME="appgw-aks"
APPGW_SUBNET_NAME="app-gw-subnet"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# AKS 자격 증명 가져오기
echo "AKS 자격 증명을 가져옵니다..."
az aks get-credentials --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --overwrite-existing

# Application Gateway 서브넷 ID 가져오기
APPGW_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --vnet-name Spoke_VNET \
  --name $APPGW_SUBNET_NAME \
  --query id -o tsv)

# Application Gateway 공용 IP 생성
echo "Application Gateway 공용 IP 생성..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name "${APPGW_NAME}-pip" \
  --allocation-method Static \
  --sku Standard

# Application Gateway 생성
echo "Application Gateway 생성..."
az network application-gateway create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $APPGW_NAME \
  --sku Standard_v2 \
  --public-ip-address "${APPGW_NAME}-pip" \
  --vnet-name Spoke_VNET \
  --subnet $APPGW_SUBNET_NAME \
  --priority 100

# Application Gateway ID 가져오기
APPGW_ID=$(az network application-gateway show \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $APPGW_NAME \
  --query id -o tsv)

# AKS에 AGIC 애드온 활성화
echo "AKS에 AGIC 애드온 활성화..."
az aks enable-addons \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $AKS_CLUSTER_NAME \
  --addons ingress-appgw \
  --appgw-id $APPGW_ID

# AKS 관리 ID에 Application Gateway 기여자 권한 부여
echo "AKS 관리 ID에 Application Gateway 기여자 권한 부여..."
AKS_IDENTITY=$(az aks show \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $AKS_CLUSTER_NAME \
  --query identityProfile.kubeletidentity.objectId -o tsv)

az role assignment create \
  --assignee $AKS_IDENTITY \
  --role "Contributor" \
  --scope $APPGW_ID

# AGIC 상태 확인
echo "AGIC 상태 확인..."
kubectl get pods -n kube-system -l app=ingress-appgw

# Application Gateway 공용 IP 확인
echo "Application Gateway 공용 IP 확인..."
APP_GW_PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name "${APPGW_NAME}-pip" \
  --query ipAddress -o tsv)

echo "Application Gateway 공용 IP: $APP_GW_PUBLIC_IP"
echo "AGIC 설정이 완료되었습니다." 