# AKS 워크숍 인프라 배포 가이드

이 가이드는 Azure Kubernetes Service(AKS) 워크숍을 위한 인프라를 배포하는 방법을 설명합니다.

## 사전 요구 사항

- Azure CLI 설치 및 로그인
- Terraform 설치 (v1.0.0 이상)
- Git 클라이언트

## 배포 방법

### 1. 리포지토리 클론

```bash
git clone https://github.com/yourusername/private-aks-workshop.git
cd private-aks-workshop/v2
```

### 2. 배포 스크립트 실행

배포 스크립트는 다음과 같은 기능을 제공합니다:

- **리소스 존재 여부 자동 확인**: Azure CLI를 사용하여 리소스 그룹, 가상 네트워크, 스토리지 계정, 컨테이너 레지스트리 등의 존재 여부를 직접 확인합니다.
- **설정 자동 업데이트**: 리소스 존재 여부에 따라 `terraform.tfvars` 파일의 설정을 자동으로 업데이트합니다.
- **리소스 자동 생성**: 리소스 그룹이 존재하지 않는 경우 Azure CLI를 사용하여 직접 생성합니다.
- **단계별 배포**: 의존성 문제를 방지하기 위해 리소스를 순차적으로 배포합니다.
- **오류 자동 복구**: 배포 중 오류 발생 시 자동으로 재시도하고 문제를 해결합니다.
- **ACR 이름 충돌 자동 해결**: ACR 이름이 이미 사용 중인 경우 자동으로 고유한 이름을 생성합니다.
- **개별 모듈 재배포**: 특정 모듈만 선택적으로 재배포할 수 있습니다.

배포 스크립트를 실행하려면:

```bash
chmod +x deploy.sh
./deploy.sh
```

### 3. 배포 과정

배포 스크립트는 다음 단계로 진행됩니다:

1. **Terraform 초기화**: 필요한 공급자와 모듈을 초기화합니다.
2. **Azure 리소스 존재 여부 확인**: 
   - 리소스 그룹 (Hub, Spoke, Storage)
   - 가상 네트워크 (Hub, Spoke, Storage)
   - 스토리지 계정
   - 컨테이너 레지스트리
3. **설정 자동 업데이트**: 확인 결과에 따라 다음 설정을 업데이트합니다:
   - `use_existing_resource_groups`
   - `use_existing_networks`
   - `use_existing_storage`
   - `use_existing_acr`
4. **리소스 그룹 생성**: 존재하지 않는 리소스 그룹을 Azure CLI로 생성합니다.
5. **단계별 리소스 배포**:
   - Azure AD 모듈
   - 네트워크 모듈
   - 스토리지 모듈
   - ACR 모듈
   - KeyVault 모듈
   - Application Gateway 모듈
   - 모니터링 모듈
   - Bastion 및 Jumpbox 모듈
   - AKS 클러스터 모듈
   - 데이터베이스 모듈
   - 애플리케이션 모듈
6. **전체 인프라 검증**: 모든 리소스가 올바르게 배포되었는지 확인합니다.

### 4. 개별 스크립트 실행

각 단계를 개별적으로 실행하려면:

```bash
# 1. Terraform 초기화
./scripts/01_init.sh

# 2. 리소스 그룹 확인
./scripts/02_check_resource_groups.sh

# 3. 네트워크 리소스 확인
./scripts/03_check_network_resources.sh

# 4. 스토리지 리소스 확인
./scripts/04_check_storage_resources.sh

# 5. ACR 리소스 확인
./scripts/05_check_acr_resources.sh

# 6. 모듈 배포
./scripts/06_deploy_modules.sh
```

### 5. 개별 모듈 재배포

특정 모듈만 재배포하려면:

```bash
./scripts/07_redeploy_module.sh <모듈_이름>
```

사용 가능한 모듈 이름:
- `azure_ad`: Azure AD 리소스
- `network`: 네트워크 리소스
- `storage`: 스토리지 리소스
- `central_acr`: 컨테이너 레지스트리
- `central_keyvault`: Key Vault
- `app_gateway`: Application Gateway
- `monitoring`: 모니터링 리소스
- `bastion`: Bastion 호스트
- `jumpbox`: Jumpbox VM
- `aks_clusters`: AKS 클러스터
- `database`: 데이터베이스
- `app`: 애플리케이션

예시:
```bash
./scripts/07_redeploy_module.sh central_acr
```

## "존재하면 사용하고 없으면 추가" 패턴

이 배포 스크립트는 "존재하면 사용하고 없으면 추가" 패턴을 구현합니다:

1. **존재 여부 확인**: Azure CLI를 사용하여 리소스가 실제로 존재하는지 직접 확인합니다.
2. **설정 자동 업데이트**: 존재 여부에 따라 Terraform 설정을 자동으로 업데이트합니다.
3. **필요한 리소스만 생성**: 존재하지 않는 리소스만 새로 생성합니다.
4. **의존성 관리**: 리소스 간의 의존성을 고려하여 순차적으로 배포합니다.
5. **오류 자동 복구**: 배포 중 오류 발생 시 자동으로 재시도하고 문제를 해결합니다.

## 개선된 기능

### 1. ACR 이름 충돌 자동 해결
ACR 이름이 전역적으로 이미 사용 중인 경우:
- 자동으로 고유한 이름을 생성 (원래 이름 + 랜덤 문자열)
- 새 이름으로 terraform.tfvars 파일 업데이트
- 새 이름으로 배포 진행

### 2. 모듈 배포 자동 재시도
모듈 배포 실패 시:
- 최대 3번까지 자동으로 재시도
- ACR 모듈 실패 시 자동으로 기존 ACR 사용 설정
- 오류 원인에 따른 특별 처리

### 3. 개별 모듈 재배포
특정 모듈만 재배포할 수 있는 기능:
- 문제가 발생한 모듈만 선택적으로 재배포
- 이미 배포된 리소스는 보존
- 배포 시간 단축 및 위험 최소화

## 네트워크 아키텍처

이 프로젝트는 다음과 같은 네트워크 아키텍처를 구현합니다:

### 1. Hub VNet (10.0.0.0/16)
- **AzureFirewallSubnet**: 10.0.0.0/26 - Azure 방화벽용 서브넷
- **JumpboxSubnet**: 10.0.0.64/26 - 점프박스 VM용 서브넷
- **AzureBastionSubnet**: 10.0.1.0/24 - Azure Bastion 서비스용 서브넷
- **DevOps Agent 서브넷**: 10.0.1.64/26 - CI/CD 파이프라인 에이전트용 서브넷
- **ACR 서브넷**: 10.0.4.0/24 - Azure Container Registry용 서브넷

### 2. Spoke VNet (10.1.0.0/16)
- **AKS 서브넷**: 10.1.0.0/24 - AKS 클러스터용 서브넷
- **Endpoints 서브넷**: 10.1.1.0/24 - Private Endpoint용 서브넷
- **Application Gateway 서브넷**: 10.1.2.32/27 - Application Gateway용 서브넷
- **Load Balancer 서브넷**: 10.1.3.0/24 - Load Balancer용 서브넷

### 3. Storage VNet (10.2.0.0/16)
- **Storage 서브넷**: 10.2.1.0/24 - 스토리지 계정용 서브넷

### VNet Peering
- Hub VNet ↔ Spoke VNet
- Hub VNet ↔ Storage VNet
- Spoke VNet ↔ Storage VNet

## GitHub Actions를 통한 CI/CD 구성

### 1. GitHub 리포지토리 설정

애플리케이션 코드를 위한 GitHub 리포지토리를 생성하고 설정합니다:

```bash
# 1. GitHub 리포지토리 생성 (웹 인터페이스 또는 GitHub CLI 사용)
gh repo create my-aks-app --public

# 2. 리포지토리 클론
git clone https://github.com/yourusername/my-aks-app.git
cd my-aks-app

# 3. 애플리케이션 코드 추가
mkdir -p src
cp -r /path/to/private-aks-workshop/v2/modules/app/output/* .
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

시크릿 설정 방법:
1. GitHub 리포지토리 페이지에서 "Settings" 탭 클릭
2. 왼쪽 메뉴에서 "Secrets and variables" > "Actions" 클릭
3. "New repository secret" 버튼 클릭하여 각 시크릿 추가

### 3. GitHub Actions OIDC 인증 설정

Azure AD 애플리케이션 및 페더레이션 자격 증명을 설정합니다:

```bash
# 1. Azure AD 애플리케이션 등록
APP_NAME="github-actions-oidc"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP="rg-spoke-aks-workshop"  # AKS 클러스터가 있는 리소스 그룹

# 2. 애플리케이션 등록
APP_ID=$(az ad app create --display-name $APP_NAME --query appId -o tsv)

# 3. 서비스 주체 생성
SP_ID=$(az ad sp create --id $APP_ID --query id -o tsv)

# 4. 역할 할당
az role assignment create \
  --assignee $SP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP

# 5. 페더레이션 자격 증명 설정
GITHUB_ORG="yourusername"
GITHUB_REPO="my-aks-app"

az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{\"name\":\"github-actions\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

# 6. 필요한 정보 출력
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
```

### 4. GitHub Actions 워크플로우 파일 추가

GitHub 리포지토리에 워크플로우 파일을 추가합니다:

```bash
# 워크플로우 디렉토리 생성
mkdir -p .github/workflows

# 워크플로우 파일 복사
cp github-workflow.yml .github/workflows/deploy.yml

# 변경 사항 커밋 및 푸시
git add .
git commit -m "Add GitHub Actions workflow"
git push
```

## 애플리케이션 배포 및 AGIC 구성

### 1. 애플리케이션 이미지 빌드 및 ACR 푸시

애플리케이션 이미지를 빌드하고 ACR에 푸시하는 방법:

```bash
# 1. ACR 로그인
az acr login --name <ACR_NAME>

# 2. 애플리케이션 이미지 빌드
cd v2/modules/app/output
chmod +x app-build.sh
./app-build.sh
```

또는 다음 명령어로 직접 빌드 및 푸시:

```bash
# ACR 정보 가져오기
ACR_NAME=$(terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)

# 이미지 빌드 및 푸시
cd <애플리케이션_소스_디렉토리>
docker build -t ${ACR_LOGIN_SERVER}/demo-app:latest .
docker push ${ACR_LOGIN_SERVER}/demo-app:latest
```

### 2. Kubernetes 매니페스트 배포

애플리케이션 배포를 위한 Kubernetes 매니페스트 파일은 `v2/modules/app/output` 디렉토리에 자동으로 생성됩니다. 다음 명령어로 배포할 수 있습니다:

```bash
# 1. AKS 자격 증명 가져오기
az aks get-credentials --resource-group <SPOKE_RG_NAME> --name <AKS_CLUSTER_NAME> --admin

# 2. 네임스페이스 생성
kubectl apply -f v2/modules/app/output/namespace.yaml

# 3. 애플리케이션 배포
kubectl apply -f v2/modules/app/output/deployment.yaml
kubectl apply -f v2/modules/app/output/service.yaml

# 4. Ingress 배포 (AGIC 사용)
kubectl apply -f v2/modules/app/output/ingress.yaml
```

또는 제공된 스크립트를 사용하여 배포:

```bash
cd v2/modules/app/output
chmod +x app-deploy.sh
./app-deploy.sh
```

### 3. AGIC 구성 확인

AGIC(Application Gateway Ingress Controller)가 올바르게 구성되었는지 확인:

```bash
# Ingress 리소스 확인
kubectl get ingress -n app

# Application Gateway 상태 확인
az network application-gateway show \
  --resource-group <SPOKE_RG_NAME> \
  --name <APPGW_NAME> \
  --query "operationalState" -o tsv
```

### 4. 공중망에서 서비스 접근

Application Gateway의 공용 IP를 통해 서비스에 접근할 수 있습니다:

```bash
# Application Gateway 공용 IP 확인
APPGW_PUBLIC_IP=$(az network public-ip show \
  --resource-group <SPOKE_RG_NAME> \
  --name <APPGW_PIP_NAME> \
  --query "ipAddress" -o tsv)

echo "애플리케이션 URL: http://$APPGW_PUBLIC_IP"
```

또는 DNS 이름을 사용하는 경우:

```bash
echo "애플리케이션 URL: http://<APP_HOST>"
```

로컬 PC의 웹 브라우저에서 위 URL로 접속하여 애플리케이션에 접근할 수 있습니다.

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

또는 공용 IP가 있는 경우 SSH로 직접 접속:

```bash
ssh <ADMIN_USERNAME>@<JUMPBOX_PUBLIC_IP>
```

### 2. Jumpbox에 필요한 도구 설치

Jumpbox VM에는 배포 시 자동으로 다음 도구가 설치됩니다:
- Azure CLI
- kubectl
- helm
- Docker CLI

수동으로 설치해야 하는 경우:

```bash
# Azure CLI 설치
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# kubectl 설치
sudo az aks install-cli

# Helm 설치
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Docker CLI 설치
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
```

### 3. AKS 자격 증명 가져오기

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

### 4. kubectl 명령어로 AKS 상태 확인

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

# 리소스 사용량 확인
kubectl top nodes
kubectl top pods -n app
```

### 5. 애플리케이션 로그 확인

배포된 애플리케이션의 로그를 확인하는 방법:

```bash
# 파드 이름 확인
POD_NAME=$(kubectl get pods -n app -l app=demo-app -o jsonpath='{.items[0].metadata.name}')

# 파드 로그 확인
kubectl logs -f $POD_NAME -n app
```

### 6. 애플리케이션 디버깅

애플리케이션 문제 해결을 위한 명령어:

```bash
# 파드 세부 정보 확인
kubectl describe pod $POD_NAME -n app

# 파드 내부 셸 접속
kubectl exec -it $POD_NAME -n app -- /bin/sh

# 서비스 엔드포인트 확인
kubectl get endpoints -n app
```

## 문제 해결

### 리소스 그룹 오류

리소스 그룹 관련 오류가 발생하면:

```bash
# 리소스 그룹 수동 생성
az group create --name rg-hub-aks-workshop --location koreacentral
az group create --name rg-spoke-aks-workshop --location koreacentral
az group create --name rg-shared_storage --location koreacentral
```

### 네트워크 오류

네트워크 관련 오류가 발생하면:

```bash
# terraform.tfvars 파일에서 설정 변경
use_existing_networks = false
```

### ACR 이름 충돌 오류

ACR 이름 충돌 오류가 발생하면:

```bash
# ACR 리소스 확인 스크립트 실행
./scripts/05_check_acr_resources.sh

# 또는 ACR 모듈만 재배포
./scripts/07_redeploy_module.sh central_acr
```

### 서브넷 주소 범위 오류

서브넷 주소 범위가 VNet 범위를 벗어나는 오류가 발생하면:

```bash
# 다음 파일에서 서브넷 주소 범위 확인 및 수정
v2/modules/network/variables.tf
```

주요 서브넷 주소 범위:
- AzureFirewallSubnet: 10.0.0.0/26 (Hub VNet 내)
- LoadBalancer 서브넷: 10.1.3.0/24 (Spoke VNet 내)
- ACR 서브넷: 10.0.4.0/24 (Hub VNet 내)

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

### Jumpbox 접속 오류

Jumpbox 접속 관련 오류가 발생하면:

```bash
# NSG 규칙 확인
az network nsg rule list \
  --resource-group <HUB_RG_NAME> \
  --nsg-name <JUMPBOX_NSG_NAME> \
  --output table

# Bastion 상태 확인
az network bastion show \
  --resource-group <HUB_RG_NAME> \
  --name <BASTION_NAME> \
  --query "provisioningState" -o tsv
```

## 배포 후 확인

배포가 완료된 후 다음 명령어로 리소스를 확인할 수 있습니다:

```bash
# 리소스 그룹 목록 확인
az group list --output table

# AKS 클러스터 확인
az aks list --output table

# AKS 클러스터 자격 증명 가져오기
az aks get-credentials --resource-group rg-spoke-aks-workshop --name aks-cluster1

# 클러스터 상태 확인
kubectl get nodes
kubectl get pods --all-namespaces
```

## 리소스 정리

더 이상 필요하지 않은 경우 다음 명령어로 리소스를 정리할 수 있습니다:

```bash
terraform destroy -auto-approve
```

## 참고 사항

- 이 배포 스크립트는 리소스 그룹을 먼저 확인하고 생성한 후 다른 리소스를 배포합니다.
- 기존 리소스를 최대한 재사용하여 불필요한 삭제와 재생성을 방지합니다.
- 모든 리소스는 태그를 통해 관리되며, 필요에 따라 `terraform.tfvars` 파일에서 태그를 수정할 수 있습니다.
- 서브넷 주소 범위는 각 VNet의 주소 공간 내에 있어야 합니다.
- 배포 중 오류가 발생하면 자동으로 재시도하고 문제를 해결합니다.
- ACR 이름 충돌이 발생하면 자동으로 고유한 이름을 생성합니다.
- 특정 모듈만 선택적으로 재배포할 수 있습니다.

# AKS 클러스터 및 Private Link 설정

이 프로젝트는 Azure Kubernetes Service(AKS)와 Private Link를 사용하여 보안이 강화된 쿠버네티스 환경을 구축하는 Terraform 코드를 제공합니다.

## 주요 기능

- Private AKS 클러스터 배포
- Private DNS Zone 자동 구성
- Hub-Spoke 네트워크 구조 지원
- Application Gateway Ingress Controller(AGIC) 통합
- Azure Container Registry(ACR) 통합
- Key Vault 통합
- GitHub Actions OIDC 인증 지원

## 사전 요구 사항

- Terraform v1.0.0 이상
- Azure CLI
- Azure 구독

## 사용 방법

### 일반적인 배포 방법

```bash
# 초기화
terraform init

# 계획 확인
terraform plan -var-file=terraform.tfvars

# 배포
terraform apply -var-file=terraform.tfvars
```

### 단계적 배포 방법 (의존성 문제 해결)

Terraform에서 count 인수가 적용 단계까지 알 수 없는 값에 의존하는 경우, 다음과 같이 단계적으로 배포할 수 있습니다.

```bash
# 스크립트 실행 권한 부여
chmod +x apply-aks.sh  # Linux/Mac
# 또는
attrib +x apply-aks.sh  # Windows

# 스크립트 실행
./apply-aks.sh
```

이 스크립트는 다음 순서로 리소스를 배포합니다:

1. AKS 클러스터 사용자 관리 ID
2. AKS 클러스터
3. Private DNS Zone
4. AKS VNet에 Private DNS Zone 연결
5. Hub VNet에 Private DNS Zone 연결
6. 시스템 관리형 Private DNS Zone에 대한 Hub VNet 연결
7. AKS API 서버의 Private DNS A 레코드
8. ACR에 대한 AKS 클러스터 접근 권한
9. KeyVault에 대한 AKS 클러스터 접근 권한
10. Application Gateway에 대한 AKS 클러스터 접근 권한
11. GitHub Actions OIDC 설정

## 모듈 구성

- `aks`: AKS 클러스터 및 관련 리소스
- `network`: VNet, 서브넷, NSG 등 네트워크 리소스
- `acr`: Azure Container Registry
- `keyvault`: Azure Key Vault
- `appgw`: Application Gateway

## 변수 설정

`terraform.tfvars` 파일에서 다음 변수를 설정할 수 있습니다:

- `cluster_name`: AKS 클러스터 이름
- `resource_group_name`: 리소스 그룹 이름
- `location`: 리전
- `private_cluster_enabled`: Private 클러스터 활성화 여부
- `private_dns_zone_id`: 기존 Private DNS Zone ID (비워두면 자동 생성)
- `hub_vnet_id`: Hub VNet ID (Hub-Spoke 구조 사용 시)

## 문제 해결

### count 인수 오류

다음과 같은 오류가 발생하는 경우:

```
Error: Invalid count argument
The "count" value depends on resource attributes that cannot be determined until apply...
```

`apply-aks.sh` 스크립트를 사용하여 단계적으로 배포하세요.

### Private DNS Zone 연결 문제

Private DNS Zone 연결에 문제가 있는 경우:

1. AKS 클러스터가 성공적으로 생성되었는지 확인
2. Private DNS Zone이 올바르게 생성되었는지 확인
3. VNet 링크가 올바르게 구성되었는지 확인

```bash
# DNS Zone 확인
az network private-dns zone list -g <resource_group> -o table

# VNet 링크 확인
az network private-dns link vnet list -g <resource_group> -z <dns_zone_name> -o table
```

# 자동 단계적 적용 기능

이 프로젝트는 Terraform의 `count` 인수 의존성 문제를 자동으로 해결하는 기능을 제공합니다. 이 기능은 다음과 같이 작동합니다:

1. `terraform apply` 명령을 실행하면 Terraform이 리소스를 생성하려고 시도합니다.
2. 의존성 문제가 발생하면 내장된 스크립트가 자동으로 리소스를 순차적으로 적용합니다.
3. 이 과정은 사용자 개입 없이 자동으로 진행됩니다.

## 자동 단계적 적용 활성화/비활성화

`terraform.tfvars` 파일에서 다음 변수를 설정하여 자동 단계적 적용 기능을 제어할 수 있습니다:

```hcl
auto_apply_script = true  # 활성화
# 또는
auto_apply_script = false  # 비활성화
```

기본값은 `true`로 설정되어 있어 의존성 문제가 발생하면 자동으로 해결합니다.

## 작동 방식

자동 단계적 적용 기능은 Terraform의 `null_resource`와 `local-exec` 프로비저너를 사용하여 구현되었습니다. 이 기능은 다음 단계로 리소스를 순차적으로 적용합니다:

1. AKS 클러스터 사용자 관리 ID
2. AKS 클러스터
3. Private DNS Zone
4. AKS VNet에 Private DNS Zone 연결
5. Hub VNet에 Private DNS Zone 연결
6. 시스템 관리형 Private DNS Zone에 대한 Hub VNet 연결
7. AKS API 서버의 Private DNS A 레코드
8. ACR에 대한 AKS 클러스터 접근 권한
9. KeyVault에 대한 AKS 클러스터 접근 권한
10. Application Gateway에 대한 AKS 클러스터 접근 권한
11. GitHub Actions OIDC 설정

이 기능은 Windows와 Linux/Mac 환경 모두에서 작동합니다.

