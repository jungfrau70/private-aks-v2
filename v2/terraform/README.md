# Terraform을 사용한 Private AKS 배포 가이드

이 가이드는 Terraform을 사용하여 Private AKS 클러스터와 관련 인프라를 배포하는 방법을 설명합니다.

## 아키텍처 개요

이 Terraform 코드는 다음과 같은 Azure 리소스를 배포합니다:

1. **Private AKS Cluster**: 프라이빗 API 서버 엔드포인트를 사용하는 AKS 클러스터
2. **Private ACR**: 프라이빗 엔드포인트를 통해 접근 가능한 컨테이너 레지스트리
3. **Application Gateway**: AGIC(Application Gateway Ingress Controller)와 통합된 애플리케이션 게이트웨이
4. **Azure Virtual Network**: Hub-Spoke 네트워크 토폴로지
5. **Private DNS Zone**: 프라이빗 엔드포인트 및 AKS 클러스터용 DNS 영역
6. **Azure Storage Account**: 프라이빗 엔드포인트를 통해 접근 가능한 스토리지 계정
7. **Azure Key Vault**: 프라이빗 엔드포인트를 통해 접근 가능한 키 볼트
8. **GitHub Actions**: CI/CD 파이프라인 (Azure DevOps 대신 사용)
9. **Private Endpoint**: 프라이빗 서비스 연결
10. **VNET Peering**: Hub-Spoke 네트워크 연결
11. **Jumpbox VM**: AKS 클러스터 관리용 VM

## 사전 요구 사항

- Terraform v1.0.0 이상
- Azure CLI v2.30.0 이상
- Azure 구독
- 관리자 권한이 있는 Azure AD 계정

## 배포 단계

### 1. Azure CLI 로그인

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

### 2. Terraform 백엔드 설정

스토리지 계정을 사용하여 Terraform 상태를 저장하려면 다음 스크립트를 실행합니다:

```bash
./A_1_Terraform_Backend_Setup.sh
```

또는 로컬 백엔드를 사용하려면 `main.tf` 파일에서 백엔드 설정을 수정합니다.

### 3. RBAC 설정

AKS 클러스터 및 관련 리소스에 대한 RBAC를 설정하려면 다음 스크립트를 실행합니다:

```bash
./A_2_RBAC.sh
```

### 4. 방화벽 설정 (선택 사항)

Azure Firewall을 설정하려면 다음 스크립트를 실행합니다:

```bash
./A_3_Firewall.sh
```

### 5. Terraform 초기화 및 배포

```bash
# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan -out=tfplan

# 리소스 배포
terraform apply tfplan
```

### 6. RBAC 배포

AKS 클러스터에 RBAC를 배포하려면 다음 스크립트를 실행합니다:

```bash
./A_7_RBAC_Deployment.md
```

## GitHub Actions를 통한 애플리케이션 배포

### 1. GitHub 리포지토리 설정

애플리케이션 코드를 위한 GitHub 리포지토리를 생성하고 설정합니다:

```bash
# GitHub 리포지토리 생성 (웹 인터페이스 또는 GitHub CLI 사용)
gh repo create my-aks-app --public

# 리포지토리 클론
git clone https://github.com/yourusername/my-aks-app.git
cd my-aks-app

# 애플리케이션 코드 추가
mkdir -p src
cp -r /path/to/app/* src/
```

### 2. GitHub Actions 시크릿 설정

GitHub 리포지토리에 다음 시크릿을 설정합니다:

1. Azure 인증 정보 설정:
   - `AZURE_CLIENT_ID`: Azure AD 애플리케이션 클라이언트 ID
   - `AZURE_TENANT_ID`: Azure AD 테넌트 ID
   - `AZURE_SUBSCRIPTION_ID`: Azure 구독 ID

2. AKS 및 ACR 정보 설정:
   - `RESOURCE_GROUP`: AKS 클러스터가 배포된 리소스 그룹 이름
   - `AKS_CLUSTER_NAME`: AKS 클러스터 이름

### 3. GitHub Actions OIDC 인증 설정

Azure AD 애플리케이션 및 페더레이션 자격 증명을 설정합니다:

```bash
# Azure AD 애플리케이션 등록
APP_NAME="github-actions-oidc"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-spoke-aks-workshop"  # AKS 클러스터가 있는 리소스 그룹

# 애플리케이션 등록
APP_ID=$(az ad app create --display-name $APP_NAME --query appId -o tsv)

# 서비스 주체 생성
SP_ID=$(az ad sp create --id $APP_ID --query id -o tsv)

# 역할 할당
az role assignment create \
  --assignee $SP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP

# 페더레이션 자격 증명 설정
GITHUB_ORG="yourusername"
GITHUB_REPO="my-aks-app"

az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{\"name\":\"github-actions\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
```

### 4. GitHub Actions 워크플로우 파일 추가

GitHub 리포지토리에 워크플로우 파일을 추가합니다:

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  ACR_LOGIN_SERVER: <ACR_LOGIN_SERVER>
  IMAGE_NAME: demo-app
  RESOURCE_GROUP: ${{ secrets.RESOURCE_GROUP }}
  AKS_CLUSTER_NAME: ${{ secrets.AKS_CLUSTER_NAME }}
  NAMESPACE: app

permissions:
  id-token: write
  contents: read

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Azure Login with OIDC
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    
    - name: ACR Login
      run: |
        az acr login --name $(echo $ACR_LOGIN_SERVER | cut -d '.' -f 1)
    
    - name: Build and Push
      run: |
        IMAGE_TAG=$(date +%Y%m%d%H%M%S)
        echo "Building image: $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
        docker build -t $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG .
        docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG
        echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_ENV
    
    - name: Set AKS Context
      run: |
        az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --admin
    
    - name: Deploy to AKS
      run: |
        kubectl apply -f kubernetes/
```

## Jumpbox에서 AKS 관리

### 1. Jumpbox VM 접속

Jumpbox VM에 접속하는 방법:

```bash
# Azure Bastion을 통한 접속
az network bastion ssh \
  --resource-group <HUB_RG_NAME> \
  --name <BASTION_NAME> \
  --target-resource-id <JUMPBOX_VM_ID> \
  --auth-type password \
  --username <ADMIN_USERNAME>
```

### 2. AKS 자격 증명 가져오기

Jumpbox에서 AKS 클러스터에 접근하기 위한 자격 증명 가져오기:

```bash
# Azure 로그인
az login

# 구독 설정
az account set --subscription <SUBSCRIPTION_ID>

# AKS 자격 증명 가져오기
az aks get-credentials \
  --resource-group <SPOKE_RG_NAME> \
  --name <AKS_CLUSTER_NAME> \
  --admin
```

### 3. kubectl 명령어로 AKS 상태 확인

Jumpbox에서 다음 kubectl 명령어를 사용하여 AKS 클러스터 상태를 확인할 수 있습니다:

```bash
# 노드 상태 확인
kubectl get nodes

# 네임스페이스 확인
kubectl get namespaces

# 시스템 파드 확인
kubectl get pods -n kube-system

# 애플리케이션 파드 확인
kubectl get pods -n app

# 서비스 확인
kubectl get services -n app

# Ingress 확인
kubectl get ingress -n app

# 클러스터 상태 확인
kubectl cluster-info
```

## 문제 해결

### AGIC 관련 오류

AGIC 관련 오류가 발생하면:

```bash
# Application Gateway 상태 확인
az network application-gateway show \
  --resource-group <SPOKE_RG_NAME> \
  --name <APPGW_NAME> \
  --query "operationalState" -o tsv

# AGIC 파드 로그 확인
kubectl logs -n kube-system -l app=ingress-appgw
```

### GitHub Actions 인증 오류

GitHub Actions 인증 관련 오류가 발생하면:

```bash
# 페더레이션 자격 증명 확인
az ad app federated-credential list --id <APP_ID>

# 역할 할당 확인
az role assignment list --assignee <APP_ID> --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>
```

## 참고 자료

- [Azure Kubernetes Service (AKS) 설명서](https://docs.microsoft.com/ko-kr/azure/aks/)
- [Terraform Azure Provider 설명서](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions 설명서](https://docs.github.com/ko/actions)
- [Application Gateway Ingress Controller 설명서](https://docs.microsoft.com/ko-kr/azure/application-gateway/ingress-controller-overview) 


                terraform apply 오류 (기존 리소스가 발견되면, v2\terraform.tfvars 수정하지 말고 terraform import 하여 terraform 코드 수정하여 해결 필요)