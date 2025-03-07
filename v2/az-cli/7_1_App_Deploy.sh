#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP_SPOKE="rg-spoke"
RESOURCE_GROUP_HUB="rg-hub"
AKS_CLUSTER_NAME="aks-cluster"
ACR_NAME="centralacr"
APP_NAME="etickets"
APP_VERSION="1.0.0"
NAMESPACE="etickets"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# AKS 자격 증명 가져오기
echo "AKS 자격 증명을 가져옵니다..."
az aks get-credentials --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --overwrite-existing

# ACR 로그인
echo "ACR 로그인..."
az acr login --name $ACR_NAME

# 네임스페이스 생성 (존재하지 않는 경우)
echo "네임스페이스 생성..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 샘플 애플리케이션 이미지 빌드 및 푸시
echo "샘플 애플리케이션 이미지 빌드 및 푸시..."
cat > Dockerfile << EOF
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY . .
EXPOSE 80
ENTRYPOINT ["dotnet", "etickets.dll"]
EOF

# 샘플 애플리케이션 파일 생성
mkdir -p app
cat > app/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>eTickets - 샘플 애플리케이션</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #0078d4;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>eTickets 애플리케이션</h1>
        <p>AKS에 배포된 샘플 애플리케이션입니다.</p>
        <p>호스트 이름: <strong>$(hostname)</strong></p>
        <p>현재 시간: <strong>$(date)</strong></p>
    </div>
</body>
</html>
EOF

# 이미지 빌드 및 푸시
echo "이미지 빌드 및 푸시..."
az acr build --registry $ACR_NAME --image $APP_NAME:$APP_VERSION .

# 애플리케이션 배포
echo "애플리케이션 배포..."
cat << EOF | kubectl apply -f -
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
        image: ${ACR_NAME}.azurecr.io/$APP_NAME:$APP_VERSION
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
---
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
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $APP_NAME
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: "false"
    appgw.ingress.kubernetes.io/use-private-ip: "false"
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

# 배포 상태 확인
echo "배포 상태 확인..."
kubectl rollout status deployment/$APP_NAME -n $NAMESPACE

# 서비스 및 인그레스 확인
echo "서비스 및 인그레스 확인..."
kubectl get service $APP_NAME -n $NAMESPACE
kubectl get ingress $APP_NAME -n $NAMESPACE

# Application Gateway 공용 IP 확인
echo "Application Gateway 공용 IP 확인..."
APPGW_NAME="appgw-aks"
APP_GW_PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP_SPOKE \
  --name "${APPGW_NAME}-pip" \
  --query ipAddress -o tsv)

echo "애플리케이션 접속 URL: http://$APP_GW_PUBLIC_IP/"
echo "애플리케이션 배포가 완료되었습니다." 