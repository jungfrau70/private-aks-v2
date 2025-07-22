#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
LOCATION="koreacentral"
RESOURCE_GROUP_SPOKE="rg-spoke"
AKS_CLUSTER_NAME="aks-cluster"
AKS_SUBNET_NAME="aks-subnet"
KUBERNETES_VERSION="1.26.0"
NODE_COUNT=3
VM_SIZE="Standard_DS2_v2"
ADMIN_GROUP_ID="<your-admin-group-id>"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# AKS 서브넷 ID 가져오기
AKS_SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --vnet-name Spoke_VNET \
  --name $AKS_SUBNET_NAME \
  --query id -o tsv)

# AKS 클러스터 생성 (Azure AD 통합 및 Private 클러스터)
echo "AKS 클러스터 생성..."
az aks create \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $AKS_CLUSTER_NAME \
  --location $LOCATION \
  --kubernetes-version $KUBERNETES_VERSION \
  --node-count $NODE_COUNT \
  --node-vm-size $VM_SIZE \
  --network-plugin azure \
  --vnet-subnet-id $AKS_SUBNET_ID \
  --docker-bridge-address 172.17.0.1/16 \
  --dns-service-ip 10.3.0.10 \
  --service-cidr 10.3.0.0/24 \
  --enable-managed-identity \
  --enable-private-cluster \
  --private-dns-zone System \
  --enable-aad \
  --aad-admin-group-object-ids $ADMIN_GROUP_ID \
  --enable-azure-rbac \
  --tags environment=dev purpose=workshop

# AKS 자격 증명 가져오기
echo "AKS 자격 증명 가져오기..."
az aks get-credentials \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $AKS_CLUSTER_NAME \
  --admin

# 클러스터 상태 확인
echo "클러스터 상태 확인..."
kubectl get nodes

# Azure Monitor 활성화
echo "Azure Monitor 활성화..."
az aks enable-addons \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $AKS_CLUSTER_NAME \
  --addons monitoring

# AGIC 활성화
echo "AGIC 활성화..."
APPGW_ID=$(az network application-gateway show \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name appgw-aks \
  --query id -o tsv)

az aks enable-addons \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name $AKS_CLUSTER_NAME \
  --addons ingress-appgw \
  --appgw-id $APPGW_ID

echo "AKS 클러스터 설정이 완료되었습니다." 