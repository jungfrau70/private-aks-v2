#!/bin/bash

# AGIC를 통한 공개 액세스 설정 스크립트
# 이 스크립트는 Application Gateway Ingress Controller를 통해 서비스에 공개 액세스를 제공하는 방법을 보여줍니다.

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP_HUB="rg-hub-aks-workshop"
RESOURCE_GROUP_SPOKE="rg-spoke-aks-workshop"
AKS_CLUSTER_NAME="aks-cluster"
APP_GATEWAY_NAME="appgw-aks"
APP_NAME="etickets"
NAMESPACE="etickets"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# AKS 자격 증명 가져오기
echo "AKS 자격 증명을 가져옵니다..."
az aks get-credentials --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --overwrite-existing

# Application Gateway 상태 확인
echo "Application Gateway 상태를 확인합니다..."
az network application-gateway show \
  --resource-group $RESOURCE_GROUP_HUB \
  --name $APP_GATEWAY_NAME \
  --query "operationalState" -o tsv

# Application Gateway 공용 IP 확인
echo "Application Gateway 공용 IP를 확인합니다..."
APP_GW_PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP_HUB \
  --name "${APP_GATEWAY_NAME}-pip" \
  --query "ipAddress" -o tsv)

echo "Application Gateway 공용 IP: $APP_GW_PUBLIC_IP"

# AGIC 상태 확인
echo "AGIC 상태를 확인합니다..."
kubectl get pods -n kube-system -l app=ingress-appgw

# AGIC 로그 확인
echo "AGIC 로그를 확인합니다..."
AGIC_POD=$(kubectl get pods -n kube-system -l app=ingress-appgw -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n kube-system $AGIC_POD

# 기존 인그레스 리소스 확인
echo "기존 인그레스 리소스를 확인합니다..."
kubectl get ingress -A

# 샘플 애플리케이션 배포 (eTickets)
echo "샘플 애플리케이션을 배포합니다..."

# 네임스페이스 생성
echo "네임스페이스를 생성합니다..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 배포 매니페스트 생성
echo "배포 매니페스트를 생성합니다..."
cat << EOF > etickets-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
spec:
  replicas: 3
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
    spec:
      containers:
      - name: $APP_NAME
        image: mcr.microsoft.com/dotnet/samples:aspnetapp
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
EOF

# 서비스 매니페스트 생성
echo "서비스 매니페스트를 생성합니다..."
cat << EOF > etickets-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
spec:
  selector:
    app: $APP_NAME
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF

# 인그레스 매니페스트 생성 (공개 액세스용)
echo "인그레스 매니페스트를 생성합니다 (공개 액세스용)..."
cat << EOF > etickets-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: "false"
    appgw.ingress.kubernetes.io/use-private-ip: "false"
    appgw.ingress.kubernetes.io/connection-draining: "true"
    appgw.ingress.kubernetes.io/connection-draining-timeout: "30"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $APP_NAME
            port:
              number: 80
EOF

# 매니페스트 적용
echo "매니페스트를 적용합니다..."
kubectl apply -f etickets-deployment.yaml
kubectl apply -f etickets-service.yaml
kubectl apply -f etickets-ingress.yaml

# 배포 상태 확인
echo "배포 상태를 확인합니다..."
kubectl rollout status deployment/$APP_NAME -n $NAMESPACE

# 인그레스 상태 확인
echo "인그레스 상태를 확인합니다..."
kubectl get ingress -n $NAMESPACE

# Application Gateway 백엔드 상태 확인
echo "Application Gateway 백엔드 상태를 확인합니다..."
az network application-gateway show-backend-health \
  --resource-group $RESOURCE_GROUP_HUB \
  --name $APP_GATEWAY_NAME \
  --output table

# 문제 해결 팁
echo "문제 해결 팁:"
echo "1. 인그레스 리소스가 올바르게 구성되었는지 확인하세요:"
echo "   - kubernetes.io/ingress.class: azure/application-gateway 주석이 있는지 확인"
echo "   - appgw.ingress.kubernetes.io/use-private-ip: \"false\" 주석이 있는지 확인"
echo ""
echo "2. Application Gateway의 상태가 정상인지 확인하세요:"
echo "   - 공용 IP가 할당되어 있는지 확인"
echo "   - 백엔드 풀이 정상적으로 구성되어 있는지 확인"
echo ""
echo "3. NSG 규칙이 HTTP/HTTPS 트래픽을 허용하는지 확인하세요:"
echo "   - 포트 80/443에 대한 인바운드 규칙이 있는지 확인"
echo ""

# NSG 규칙 확인
echo "Application Gateway 서브넷의 NSG 규칙을 확인합니다..."
APPGW_SUBNET_ID=$(az network application-gateway show \
  --resource-group $RESOURCE_GROUP_HUB \
  --name $APP_GATEWAY_NAME \
  --query "gatewayIPConfigurations[0].subnet.id" -o tsv)

NSG_NAME=$(az network nsg list \
  --resource-group $RESOURCE_GROUP_HUB \
  --query "[?contains(subnets[].id, '$APPGW_SUBNET_ID')].name" -o tsv)

if [ -n "$NSG_NAME" ]; then
  echo "NSG 규칙 목록:"
  az network nsg rule list \
    --resource-group $RESOURCE_GROUP_HUB \
    --nsg-name $NSG_NAME \
    --output table
else
  echo "Application Gateway 서브넷에 연결된 NSG를 찾을 수 없습니다."
fi

# HTTP/HTTPS 규칙이 없는 경우 추가
if [ -n "$NSG_NAME" ]; then
  HTTP_RULE=$(az network nsg rule list \
    --resource-group $RESOURCE_GROUP_HUB \
    --nsg-name $NSG_NAME \
    --query "[?destinationPortRange=='80'].name" -o tsv)
  
  if [ -z "$HTTP_RULE" ]; then
    echo "HTTP 트래픽을 허용하는 NSG 규칙을 추가합니다..."
    az network nsg rule create \
      --resource-group $RESOURCE_GROUP_HUB \
      --nsg-name $NSG_NAME \
      --name AllowHTTP \
      --priority 200 \
      --direction Inbound \
      --access Allow \
      --protocol Tcp \
      --source-address-prefix '*' \
      --source-port-range '*' \
      --destination-address-prefix '*' \
      --destination-port-range 80
  fi
  
  HTTPS_RULE=$(az network nsg rule list \
    --resource-group $RESOURCE_GROUP_HUB \
    --nsg-name $NSG_NAME \
    --query "[?destinationPortRange=='443'].name" -o tsv)
  
  if [ -z "$HTTPS_RULE" ]; then
    echo "HTTPS 트래픽을 허용하는 NSG 규칙을 추가합니다..."
    az network nsg rule create \
      --resource-group $RESOURCE_GROUP_HUB \
      --nsg-name $NSG_NAME \
      --name AllowHTTPS \
      --priority 210 \
      --direction Inbound \
      --access Allow \
      --protocol Tcp \
      --source-address-prefix '*' \
      --source-port-range '*' \
      --destination-address-prefix '*' \
      --destination-port-range 443
  fi
fi

# 애플리케이션 접속 URL
echo "애플리케이션 접속 URL:"
echo "http://$APP_GW_PUBLIC_IP/"

echo "AGIC를 통한 공개 액세스 설정이 완료되었습니다." 