#!/bin/bash

# eTickets 애플리케이션 배포
# 이 스크립트는 eTickets 애플리케이션을 AKS에 배포하는 방법을 보여줍니다.

# 변수 설정
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="rg-spoke"
AKS_CLUSTER_NAME="aks-dev"
ACR_NAME="centralacr"
NAMESPACE="etickets"
APP_NAME="etickets"
GITHUB_REPO="https://github.com/shubhamagrawal17/Tutorial.git"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# AKS 클러스터 정보 가져오기
echo "AKS 클러스터 정보를 가져옵니다..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --admin

# ACR 로그인
echo "ACR에 로그인합니다..."
az acr login --name $ACR_NAME

# 1. GitHub 리포지토리 클론
echo "GitHub 리포지토리를 클론합니다..."
git clone $GITHUB_REPO
cd Tutorial

# 2. eTickets 애플리케이션 다운로드 및 압축 해제
echo "eTickets 애플리케이션을 다운로드하고 압축을 해제합니다..."
unzip etickets-main.zip -d ./
cd etickets-main

# 3. Dockerfile 생성
echo "Dockerfile을 생성합니다..."
cat > Dockerfile << 'EOF'
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /app

# 프로젝트 파일 복사 및 복원
COPY *.csproj ./
RUN dotnet restore

# 소스 코드 복사 및 게시
COPY . ./
RUN dotnet publish -c Release -o out

# 런타임 이미지 생성
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
COPY --from=build /app/out .
ENTRYPOINT ["dotnet", "eTickets.dll"]
EOF

# 4. 이미지 빌드 및 푸시
echo "이미지를 빌드하고 ACR에 푸시합니다..."
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
docker build -t $ACR_LOGIN_SERVER/$APP_NAME:latest .
docker push $ACR_LOGIN_SERVER/$APP_NAME:latest

# 5. Kubernetes 매니페스트 생성
echo "Kubernetes 매니페스트를 생성합니다..."

# 5.1 네임스페이스 생성
kubectl create namespace $NAMESPACE 2>/dev/null || true

# 5.2 Deployment 생성
cat > k8s-deployment.yaml << EOF
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
        image: $ACR_LOGIN_SERVER/$APP_NAME:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 250m
            memory: 256Mi
        env:
        - name: ASPNETCORE_ENVIRONMENT
          value: "Production"
EOF

# 5.3 Service 생성
cat > k8s-service.yaml << EOF
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

# 5.4 Ingress 생성 - 중요: use-private-ip 설정을 false로 설정
cat > k8s-ingress.yaml << EOF
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

# 6. Kubernetes 리소스 배포
echo "Kubernetes 리소스를 배포합니다..."
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml
kubectl apply -f k8s-ingress.yaml

# 7. 배포 상태 확인
echo "배포 상태를 확인합니다..."
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE
kubectl get ingress -n $NAMESPACE

# 8. Application Gateway 공용 IP 확인
echo "Application Gateway 공용 IP를 확인합니다..."
RESOURCE_GROUP_HUB="rg-hub"
APP_GATEWAY_PIP_NAME="central-appgw-pip"
PUBLIC_IP=$(az network public-ip show --resource-group $RESOURCE_GROUP_HUB --name $APP_GATEWAY_PIP_NAME --query ipAddress -o tsv)
echo "애플리케이션에 접근하려면 다음 URL을 사용하세요: http://$PUBLIC_IP/"

# 9. GitHub Actions 워크플로우 파일 생성 (선택 사항)
echo "GitHub Actions 워크플로우 파일을 생성합니다..."
mkdir -p .github/workflows
cat > .github/workflows/deploy-etickets.yml << 'EOF'
name: Build and Deploy eTickets

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1
    
    - name: Login to ACR
      uses: docker/login-action@v1
      with:
        registry: ${{ secrets.REGISTRY_LOGIN_SERVER }}
        username: ${{ secrets.REGISTRY_USERNAME }}
        password: ${{ secrets.REGISTRY_PASSWORD }}
    
    - name: Build and push
      uses: docker/build-push-action@v2
      with:
        context: .
        push: true
        tags: ${{ secrets.REGISTRY_LOGIN_SERVER }}/etickets:${{ github.sha }}
    
    - name: Set up Kubernetes CLI
      uses: azure/setup-kubectl@v1
    
    - name: Set up Azure CLI
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Get AKS credentials
      run: az aks get-credentials --resource-group ${{ secrets.RESOURCE_GROUP }} --name ${{ secrets.AKS_CLUSTER_NAME }} --admin
    
    - name: Update Deployment
      run: |
        kubectl set image deployment/etickets etickets=${{ secrets.REGISTRY_LOGIN_SERVER }}/etickets:${{ github.sha }} -n etickets
EOF

echo "eTickets 애플리케이션 배포가 완료되었습니다."
echo "애플리케이션에 접근하려면 다음 URL을 사용하세요: http://$PUBLIC_IP/" 