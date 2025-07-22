#!/bin/bash

# 오류 발생 시 스크립트 중단
set -e

echo "===== 애플리케이션 배포 시작 - $(date) ====="

# 환경 변수 설정
RESOURCE_GROUP="${resource_group_name}"
AKS_CLUSTER_NAME="${aks_cluster_name}"
APP_NAME="${app_name}"
APP_NAMESPACE="${app_namespace}"

# AKS 자격 증명 가져오기
echo "AKS 자격 증명 가져오기..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --admin --overwrite-existing

# 네임스페이스 생성 (없는 경우)
echo "네임스페이스 확인/생성 중..."
kubectl get namespace $APP_NAMESPACE || kubectl create namespace $APP_NAMESPACE

# 애플리케이션 배포
echo "애플리케이션 배포 중..."
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# AGIC 상태 확인
echo "AGIC 상태 확인 중..."
AGIC_POD=$(kubectl get pods -n kube-system -l app=ingress-appgw -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$AGIC_POD" ]; then
  echo "AGIC 파드 발견: $AGIC_POD"
  kubectl describe pod $AGIC_POD -n kube-system | grep -A 5 "State:"
else
  echo "AGIC 파드를 찾을 수 없습니다. Application Gateway Ingress Controller가 설치되어 있는지 확인하세요."
fi

# Application Gateway 상태 확인
echo "Application Gateway 상태 확인 중..."
APPGW_NAME=$(az network application-gateway list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv 2>/dev/null || echo "")
if [ -n "$APPGW_NAME" ]; then
  echo "Application Gateway 발견: $APPGW_NAME"
  APPGW_STATE=$(az network application-gateway show --resource-group $RESOURCE_GROUP --name $APPGW_NAME --query "operationalState" -o tsv)
  echo "Application Gateway 상태: $APPGW_STATE"
else
  echo "Application Gateway를 찾을 수 없습니다."
fi

# Ingress 배포
echo "Ingress 배포 중..."
kubectl apply -f ingress.yaml

# 배포 상태 확인
echo "배포 상태 확인 중..."
kubectl rollout status deployment/$APP_NAME -n $APP_NAMESPACE --timeout=60s || true

echo "서비스 상태:"
kubectl get service $APP_NAME -n $APP_NAMESPACE

echo "Ingress 상태:"
kubectl get ingress $APP_NAME -n $APP_NAMESPACE

# 공용 IP 확인
if [ -n "$APPGW_NAME" ]; then
  APPGW_PIP_NAME=$(az network application-gateway show --resource-group $RESOURCE_GROUP --name $APPGW_NAME --query "frontendIPConfigurations[0].publicIPAddress.id" -o tsv | cut -d'/' -f9)
  if [ -n "$APPGW_PIP_NAME" ]; then
    PUBLIC_IP=$(az network public-ip show --resource-group $RESOURCE_GROUP --name $APPGW_PIP_NAME --query "ipAddress" -o tsv)
    echo "애플리케이션 접속 URL: http://$PUBLIC_IP"
  else
    echo "Application Gateway에 연결된 공용 IP를 찾을 수 없습니다."
  fi
fi

echo "===== 애플리케이션 배포 완료 - $(date) =====" 