#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP_HUB="rg-hub"
RESOURCE_GROUP_SPOKE="rg-spoke"
AKS_CLUSTER_NAME="aks-cluster"
ACR_NAME="<your-acr-name>"
VNET_HUB_NAME="vnet-hub"
VNET_SPOKE_NAME="vnet-spoke"
APPGW_NAME="appgw"
LOG_ANALYTICS_WORKSPACE="aks-logs"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# 1단계: 리소스 그룹 검증
echo "1단계: 리소스 그룹 검증..."
echo "Hub 리소스 그룹 확인: $RESOURCE_GROUP_HUB"
az group show --name $RESOURCE_GROUP_HUB -o table

echo "Spoke 리소스 그룹 확인: $RESOURCE_GROUP_SPOKE"
az group show --name $RESOURCE_GROUP_SPOKE -o table

# 2단계: 네트워크 검증
echo "2단계: 네트워크 검증..."
echo "Hub VNet 확인: $VNET_HUB_NAME"
az network vnet show --resource-group $RESOURCE_GROUP_HUB --name $VNET_HUB_NAME -o table

echo "Spoke VNet 확인: $VNET_SPOKE_NAME"
az network vnet show --resource-group $RESOURCE_GROUP_SPOKE --name $VNET_SPOKE_NAME -o table

echo "VNet Peering 확인:"
az network vnet peering list --resource-group $RESOURCE_GROUP_HUB --vnet-name $VNET_HUB_NAME -o table
az network vnet peering list --resource-group $RESOURCE_GROUP_SPOKE --vnet-name $VNET_SPOKE_NAME -o table

# 3단계: ACR 검증
echo "3단계: ACR 검증..."
echo "ACR 확인: $ACR_NAME"
az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP_HUB -o table

echo "ACR 이미지 확인:"
az acr repository list --name $ACR_NAME -o table

# 4단계: AKS 클러스터 검증
echo "4단계: AKS 클러스터 검증..."
echo "AKS 클러스터 확인: $AKS_CLUSTER_NAME"
az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME -o table

# AKS 자격 증명 가져오기
az aks get-credentials --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --overwrite-existing

echo "AKS 노드 확인:"
kubectl get nodes -o wide

echo "AKS 네임스페이스 확인:"
kubectl get namespaces

echo "AKS 파드 확인:"
kubectl get pods --all-namespaces

# 5단계: AGIC 검증
echo "5단계: AGIC 검증..."
echo "Application Gateway 확인: $APPGW_NAME"
az network application-gateway show --resource-group $RESOURCE_GROUP_SPOKE --name $APPGW_NAME -o table

echo "AGIC 애드온 확인:"
az aks addon show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --addon ingress-appgw -o table

echo "Ingress 리소스 확인:"
kubectl get ingress --all-namespaces

# 6단계: 모니터링 검증
echo "6단계: 모니터링 검증..."
echo "Log Analytics 워크스페이스 확인: $LOG_ANALYTICS_WORKSPACE"
az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP_SPOKE --workspace-name $LOG_ANALYTICS_WORKSPACE -o table

echo "AKS 모니터링 애드온 확인:"
az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --query addonProfiles.omsagent -o table

echo "Prometheus & Grafana 확인:"
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# 7단계: 애플리케이션 검증
echo "7단계: 애플리케이션 검증..."
echo "애플리케이션 파드 확인:"
kubectl get pods -n app

echo "애플리케이션 서비스 확인:"
kubectl get svc -n app

echo "애플리케이션 Ingress 확인:"
kubectl get ingress -n app

# 애플리케이션 접근 URL 가져오기
APP_IP=$(az network public-ip show --resource-group $RESOURCE_GROUP_SPOKE --name appgw-pip --query ipAddress -o tsv)
echo "애플리케이션 접근 URL: http://$APP_IP"

echo "모든 검증이 완료되었습니다." 