#!/bin/bash

# GitHub Actions와 AKS 통합 설정
# 이 스크립트는 GitHub Actions를 사용하여 AKS에 애플리케이션을 배포하는 방법을 보여줍니다.

# 변수 설정
SUBSCRIPTION_ID="your-subscription-id"
RESOURCE_GROUP="rg-spoke"
AKS_CLUSTER_NAME="aks-dev"
ACR_NAME="centralacr"
GITHUB_REPO="your-org/your-repo"
GITHUB_TOKEN="your-github-token"
GITHUB_RUNNER_NAME="aks-runner"

# 1. Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# 2. AKS 클러스터 정보 가져오기
echo "AKS 클러스터 정보를 가져옵니다..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --admin

# 3. ACR 로그인
echo "ACR에 로그인합니다..."
az acr login --name $ACR_NAME

# 4. GitHub Actions에서 사용할 서비스 주체 생성
echo "GitHub Actions에서 사용할 서비스 주체를 생성합니다..."
SP_JSON=$(az ad sp create-for-rbac --name "github-actions-aks" --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth)

# 5. GitHub 리포지토리에 시크릿 추가 방법 안내
echo "GitHub 리포지토리에 다음 시크릿을 추가하세요:"
echo "AZURE_CREDENTIALS: $SP_JSON"
echo "REGISTRY_LOGIN_SERVER: $(az acr show --name $ACR_NAME --query loginServer -o tsv)"
echo "REGISTRY_USERNAME: $(az acr credential show --name $ACR_NAME --query username -o tsv)"
echo "REGISTRY_PASSWORD: $(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"
echo "AKS_CLUSTER_NAME: $AKS_CLUSTER_NAME"

# 6. GitHub Actions 워크플로우 파일 생성 안내
echo "GitHub Actions 워크플로우 파일을 생성하세요. 예시:"
cat << 'EOF'
# .github/workflows/deploy-to-aks.yml
name: Build and Deploy to AKS

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
        tags: ${{ secrets.REGISTRY_LOGIN_SERVER }}/myapp:${{ github.sha }}
    
    - name: Set up Kubernetes CLI
      uses: azure/setup-kubectl@v1
    
    - name: Set up Azure CLI
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Get AKS credentials
      run: az aks get-credentials --resource-group ${{ secrets.RESOURCE_GROUP }} --name ${{ secrets.AKS_CLUSTER_NAME }} --admin
    
    - name: Deploy to AKS
      run: |
        # 이미지 태그 업데이트
        sed -i "s|image:.*|image: ${{ secrets.REGISTRY_LOGIN_SERVER }}/myapp:${{ github.sha }}|g" kubernetes/deployment.yaml
        
        # 배포 적용
        kubectl apply -f kubernetes/deployment.yaml
        kubectl apply -f kubernetes/service.yaml
        kubectl apply -f kubernetes/ingress.yaml
EOF

# 7. 자체 호스팅 GitHub Actions 러너 설정 (선택 사항)
echo "자체 호스팅 GitHub Actions 러너를 설정하려면 다음 단계를 따르세요:"
echo "1. GitHub 리포지토리 > Settings > Actions > Runners > New self-hosted runner로 이동"
echo "2. 운영 체제를 선택하고 제공된 지침을 따르세요."
echo "3. 러너를 설정한 후 GitHub Actions 워크플로우에서 다음과 같이 사용하세요:"
cat << 'EOF'
jobs:
  build-and-deploy:
    runs-on: self-hosted
    # 나머지 워크플로우 구성...
EOF

# 8. AGIC 문제 해결을 위한 공용 IP 설정
echo "AGIC 문제 해결을 위한 공용 IP 설정..."
cat << 'EOF'
# AGIC를 통해 서비스에 공개적으로 접근할 수 있도록 하려면 다음 단계를 따르세요:

# 1. Application Gateway가 공용 IP를 사용하는지 확인
PUBLIC_IP=$(az network public-ip show --resource-group rg-hub --name central-appgw-pip --query ipAddress -o tsv)
echo "Application Gateway 공용 IP: $PUBLIC_IP"

# 2. 인그레스 리소스 예시:
cat > ingress.yaml << 'EOFINGRESS'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
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
            name: my-app-service
            port:
              number: 80
EOFINGRESS

# 3. 인그레스 리소스 적용
kubectl apply -f ingress.yaml

# 4. 인그레스 상태 확인
kubectl get ingress my-app-ingress

# 5. 문제 해결 팁:
# - Application Gateway 상태 확인
az network application-gateway show --resource-group rg-hub --name central-appgw --query operationalState -o tsv

# - Application Gateway 백엔드 상태 확인
az network application-gateway show-backend-health --resource-group rg-hub --name central-appgw

# - AGIC 로그 확인
kubectl logs -n kube-system -l app=ingress-azure
EOF

echo "GitHub Actions 통합 및 AGIC 설정이 완료되었습니다." 