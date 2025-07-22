#!/bin/bash

# AGIC 문제 해결 및 공중망 사용자 접근 설정
# 이 스크립트는 AGIC를 통해 공중망 사용자가 서비스에 접근할 수 있도록 설정하는 방법을 보여줍니다.

# 변수 설정
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP_HUB="rg-hub"
RESOURCE_GROUP_SPOKE="rg-spoke"
AKS_CLUSTER_NAME="aks-dev"
APP_GATEWAY_NAME="central-appgw"
APP_GATEWAY_PIP_NAME="central-appgw-pip"
NAMESPACE="default"
APP_NAME="etickets"  # 애플리케이션 이름

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# AKS 클러스터 정보 가져오기
echo "AKS 클러스터 정보를 가져옵니다..."
az aks get-credentials --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --admin

# 1. Application Gateway 상태 확인
echo "Application Gateway 상태를 확인합니다..."
APPGW_STATE=$(az network application-gateway show --resource-group $RESOURCE_GROUP_HUB --name $APP_GATEWAY_NAME --query operationalState -o tsv)
echo "Application Gateway 상태: $APPGW_STATE"

# 2. Application Gateway 공용 IP 확인
echo "Application Gateway 공용 IP를 확인합니다..."
PUBLIC_IP=$(az network public-ip show --resource-group $RESOURCE_GROUP_HUB --name $APP_GATEWAY_PIP_NAME --query ipAddress -o tsv)
echo "Application Gateway 공용 IP: $PUBLIC_IP"

# 3. AGIC 상태 확인
echo "AGIC 상태를 확인합니다..."
kubectl get pods -n kube-system -l app=ingress-azure

# 4. AGIC 로그 확인
echo "AGIC 로그를 확인합니다..."
AGIC_POD=$(kubectl get pods -n kube-system -l app=ingress-azure -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n kube-system $AGIC_POD | tail -n 50

# 5. 기존 인그레스 리소스 확인
echo "기존 인그레스 리소스를 확인합니다..."
kubectl get ingress --all-namespaces

# 6. 샘플 애플리케이션 배포 (eTickets 애플리케이션)
echo "샘플 애플리케이션을 배포합니다..."

# 6.1 네임스페이스 생성
kubectl create namespace $NAMESPACE 2>/dev/null || true

# 6.2 Deployment 생성
cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
spec:
  replicas: 2
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

kubectl apply -f deployment.yaml

# 6.3 Service 생성
cat > service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: $APP_NAME
EOF

kubectl apply -f service.yaml

# 6.4 Ingress 생성 - 중요: use-private-ip 설정을 false로 설정
cat > ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $APP_NAME-ingress
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

kubectl apply -f ingress.yaml

# 7. 인그레스 상태 확인
echo "인그레스 상태를 확인합니다..."
kubectl get ingress -n $NAMESPACE

# 8. Application Gateway 백엔드 상태 확인
echo "Application Gateway 백엔드 상태를 확인합니다..."
az network application-gateway show-backend-health --resource-group $RESOURCE_GROUP_HUB --name $APP_GATEWAY_NAME -o table

# 9. 문제 해결 팁
echo "문제 해결 팁:"
echo "1. 인그레스 리소스에 'appgw.ingress.kubernetes.io/use-private-ip: \"false\"' 주석이 있는지 확인하세요."
echo "2. Application Gateway가 공용 IP를 사용하는지 확인하세요."
echo "3. NSG 규칙이 Application Gateway로의 인바운드 트래픽을 허용하는지 확인하세요."
echo "4. 애플리케이션에 접근하려면 다음 URL을 사용하세요: http://$PUBLIC_IP/"
echo "5. DNS 이름을 설정하려면 다음 명령을 실행하세요:"
echo "   az network public-ip update --resource-group $RESOURCE_GROUP_HUB --name $APP_GATEWAY_PIP_NAME --dns-name your-dns-name"

# 10. 추가 문제 해결을 위한 NSG 규칙 확인
echo "NSG 규칙을 확인합니다..."
APPGW_NSG_NAME="Appgw_NSG"
az network nsg rule list --resource-group $RESOURCE_GROUP_HUB --nsg-name $APPGW_NSG_NAME -o table

# 11. 필요한 경우 NSG 규칙 추가
echo "필요한 경우 다음 명령으로 NSG 규칙을 추가하세요:"
cat << 'EOF'
az network nsg rule create \
  --resource-group rg-hub \
  --nsg-name Appgw_NSG \
  --name AllowHTTPInbound \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 80

az network nsg rule create \
  --resource-group rg-hub \
  --nsg-name Appgw_NSG \
  --name AllowHTTPSInbound \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-range 443
EOF

echo "AGIC 설정 및 문제 해결이 완료되었습니다."
echo "애플리케이션에 접근하려면 다음 URL을 사용하세요: http://$PUBLIC_IP/" 