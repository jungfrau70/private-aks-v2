#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP_SPOKE="rg-spoke"
AKS_CLUSTER_NAME="aks-cluster"
ACR_NAME="centralacr"
GITHUB_ORG="<your-github-org>"
GITHUB_REPO="<your-github-repo>"
GITHUB_BRANCH="main"
APP_NAME="etickets"
NAMESPACE="etickets"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# AKS 자격 증명 가져오기
echo "AKS 자격 증명을 가져옵니다..."
az aks get-credentials --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --overwrite-existing

# GitHub Actions를 위한 서비스 주체 생성
echo "GitHub Actions를 위한 서비스 주체를 생성합니다..."
SP_JSON=$(az ad sp create-for-rbac --name "sp-github-actions-aks" --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_SPOKE \
  --sdk-auth)

# 서비스 주체 정보 출력
echo "서비스 주체가 생성되었습니다. 다음 정보를 GitHub 시크릿으로 저장하세요:"
echo "AZURE_CREDENTIALS 시크릿에 다음 JSON을 저장하세요:"
echo $SP_JSON

# GitHub 시크릿 설정 안내
echo "GitHub 리포지토리에 다음 시크릿을 추가하세요:"
echo "1. AZURE_CREDENTIALS: 위에서 생성된 서비스 주체 JSON"
echo "2. ACR_LOGIN_SERVER: $(az acr show --name $ACR_NAME --query loginServer -o tsv)"
echo "3. RESOURCE_GROUP: $RESOURCE_GROUP_SPOKE"
echo "4. AKS_CLUSTER_NAME: $AKS_CLUSTER_NAME"

# GitHub Actions 워크플로우 파일 생성
echo "GitHub Actions 워크플로우 파일을 생성합니다..."
mkdir -p .github/workflows
cat << EOF > .github/workflows/aks-deploy.yml
name: Build and Deploy to AKS

on:
  push:
    branches: [ $GITHUB_BRANCH ]
  pull_request:
    branches: [ $GITHUB_BRANCH ]
  workflow_dispatch:

env:
  ACR_NAME: $ACR_NAME
  AKS_CLUSTER_NAME: $AKS_CLUSTER_NAME
  RESOURCE_GROUP: $RESOURCE_GROUP_SPOKE
  NAMESPACE: $NAMESPACE
  APP_NAME: $APP_NAME
  IMAGE_NAME: $APP_NAME
  IMAGE_TAG: \${{ github.sha }}

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1
    
    - name: Log in to ACR
      uses: azure/docker-login@v1
      with:
        login-server: \${{ secrets.ACR_LOGIN_SERVER }}
        username: \${{ secrets.AZURE_CLIENT_ID }}
        password: \${{ secrets.AZURE_CLIENT_SECRET }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v2
      with:
        context: .
        push: true
        tags: \${{ secrets.ACR_LOGIN_SERVER }}/\${{ env.IMAGE_NAME }}:\${{ env.IMAGE_TAG }}
    
    - name: Set up kubectl
      uses: azure/setup-kubectl@v1
    
    - name: Set up Azure CLI
      uses: azure/login@v1
      with:
        creds: \${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Get AKS credentials
      run: |
        az aks get-credentials --resource-group \${{ env.RESOURCE_GROUP }} --name \${{ env.AKS_CLUSTER_NAME }} --overwrite-existing
    
    - name: Create namespace if not exists
      run: |
        kubectl create namespace \${{ env.NAMESPACE }} --dry-run=client -o yaml | kubectl apply -f -
    
    - name: Deploy to AKS
      run: |
        # 배포 매니페스트 생성
        cat << EOF > deployment.yaml
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: \${{ env.APP_NAME }}
          namespace: \${{ env.NAMESPACE }}
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: \${{ env.APP_NAME }}
          template:
            metadata:
              labels:
                app: \${{ env.APP_NAME }}
            spec:
              containers:
              - name: \${{ env.APP_NAME }}
                image: \${{ secrets.ACR_LOGIN_SERVER }}/\${{ env.IMAGE_NAME }}:\${{ env.IMAGE_TAG }}
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
        cat << EOF > service.yaml
        apiVersion: v1
        kind: Service
        metadata:
          name: \${{ env.APP_NAME }}
          namespace: \${{ env.NAMESPACE }}
        spec:
          selector:
            app: \${{ env.APP_NAME }}
          ports:
          - port: 80
            targetPort: 80
          type: ClusterIP
        EOF
        
        # 인그레스 매니페스트 생성
        cat << EOF > ingress.yaml
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
          name: \${{ env.APP_NAME }}
          namespace: \${{ env.NAMESPACE }}
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
                    name: \${{ env.APP_NAME }}
                    port:
                      number: 80
        EOF
        
        # 매니페스트 적용
        kubectl apply -f deployment.yaml
        kubectl apply -f service.yaml
        kubectl apply -f ingress.yaml
        
        # 배포 상태 확인
        kubectl rollout status deployment/\${{ env.APP_NAME }} -n \${{ env.NAMESPACE }}
EOF

echo "GitHub Actions 워크플로우 파일이 생성되었습니다: .github/workflows/aks-deploy.yml"
echo "이 파일을 GitHub 리포지토리에 추가하세요." 