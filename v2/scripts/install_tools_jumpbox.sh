#!/bin/bash

# 설치 로그 파일 설정
LOGFILE="/var/log/jumpbox_tools_install.log"
exec > >(tee -a $LOGFILE) 2>&1

echo "===== Jumpbox 도구 설치 시작 - $(date) ====="

# 시스템 업데이트
echo "시스템 패키지 업데이트 중..."
apt-get update
apt-get upgrade -y

# 기본 도구 설치
echo "기본 도구 설치 중..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    git \
    unzip \
    wget \
    vim \
    nano

# Azure CLI 설치
echo "Azure CLI 설치 중..."
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# kubectl 설치
echo "kubectl 설치 중..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Helm 설치
echo "Helm 설치 중..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Docker 설치
echo "Docker 설치 중..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker azureuser

# kubectx 및 kubens 설치
echo "kubectx 및 kubens 설치 중..."
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# k9s 설치
echo "k9s 설치 중..."
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz | tar xz -C /tmp
mv /tmp/k9s /usr/local/bin/

# AKS 자격 증명 가져오기 스크립트 생성
echo "AKS 자격 증명 가져오기 스크립트 생성 중..."
cat > /home/azureuser/get_aks_credentials.sh << 'EOF'
#!/bin/bash

# 구독 ID 설정
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "구독 ID: $SUBSCRIPTION_ID"

# 리소스 그룹 및 AKS 클러스터 이름 설정
SPOKE_RG=$(az group list --query "[?contains(name, 'spoke')].name" -o tsv)
AKS_CLUSTER_NAME=$(az aks list --resource-group $SPOKE_RG --query "[0].name" -o tsv)

echo "리소스 그룹: $SPOKE_RG"
echo "AKS 클러스터 이름: $AKS_CLUSTER_NAME"

# AKS 자격 증명 가져오기
echo "AKS 자격 증명 가져오기..."
az aks get-credentials --resource-group $SPOKE_RG --name $AKS_CLUSTER_NAME --admin

# 클러스터 상태 확인
echo "클러스터 상태 확인..."
kubectl cluster-info
kubectl get nodes
EOF

chmod +x /home/azureuser/get_aks_credentials.sh
chown azureuser:azureuser /home/azureuser/get_aks_credentials.sh

# AKS 상태 확인 스크립트 생성
echo "AKS 상태 확인 스크립트 생성 중..."
cat > /home/azureuser/check_aks_status.sh << 'EOF'
#!/bin/bash

echo "===== AKS 클러스터 상태 확인 ====="

# 노드 상태 확인
echo -e "\n===== 노드 상태 ====="
kubectl get nodes -o wide

# 네임스페이스 확인
echo -e "\n===== 네임스페이스 ====="
kubectl get namespaces

# 시스템 파드 확인
echo -e "\n===== 시스템 파드 ====="
kubectl get pods -n kube-system

# 모든 네임스페이스의 파드 확인
echo -e "\n===== 모든 파드 ====="
kubectl get pods --all-namespaces

# 서비스 확인
echo -e "\n===== 서비스 ====="
kubectl get services --all-namespaces

# Ingress 확인
echo -e "\n===== Ingress ====="
kubectl get ingress --all-namespaces

# 클러스터 정보 확인
echo -e "\n===== 클러스터 정보 ====="
kubectl cluster-info

# 리소스 사용량 확인
echo -e "\n===== 리소스 사용량 ====="
kubectl top nodes
kubectl top pods --all-namespaces
EOF

chmod +x /home/azureuser/check_aks_status.sh
chown azureuser:azureuser /home/azureuser/check_aks_status.sh

# 애플리케이션 배포 스크립트 생성
echo "애플리케이션 배포 스크립트 생성 중..."
cat > /home/azureuser/deploy_app.sh << 'EOF'
#!/bin/bash

# ACR 정보 가져오기
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
HUB_RG=$(az group list --query "[?contains(name, 'hub')].name" -o tsv)
ACR_NAME=$(az acr list --resource-group $HUB_RG --query "[0].name" -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $HUB_RG --query "loginServer" -o tsv)

echo "ACR 이름: $ACR_NAME"
echo "ACR 로그인 서버: $ACR_LOGIN_SERVER"

# ACR 로그인
echo "ACR 로그인 중..."
az acr login --name $ACR_NAME

# 네임스페이스 생성
echo "네임스페이스 생성 중..."
kubectl create namespace app

# 애플리케이션 배포
echo "애플리케이션 배포 중..."
cat > deployment.yaml << EOL
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: ${ACR_LOGIN_SERVER}/demo-app:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
EOL

cat > service.yaml << EOL
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: app
spec:
  selector:
    app: demo-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOL

cat > ingress.yaml << EOL
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app
  namespace: app
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: demo-app
            port:
              number: 80
EOL

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

echo "애플리케이션 배포 완료!"
echo "배포 상태 확인 중..."
kubectl get pods -n app
kubectl get service -n app
kubectl get ingress -n app
EOF

chmod +x /home/azureuser/deploy_app.sh
chown azureuser:azureuser /home/azureuser/deploy_app.sh

# .bashrc에 유용한 별칭 추가
echo "유용한 별칭 추가 중..."
cat >> /home/azureuser/.bashrc << 'EOF'

# Kubernetes 별칭
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgi='kubectl get ingress'
alias kgn='kubectl get nodes'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias ka='kubectl apply -f'
alias kns='kubens'
alias kctx='kubectx'

# Azure 별칭
alias azl='az login'
alias azs='az account show'
alias azaks='az aks'

# 유용한 함수
kpf() {
  kubectl port-forward "$1" "${2:-8080}:${3:-80}"
}

# 환영 메시지
echo "===== AKS 워크숍 Jumpbox ====="
echo "다음 스크립트를 사용하여 AKS 클러스터에 접근할 수 있습니다:"
echo "  - ./get_aks_credentials.sh: AKS 자격 증명 가져오기"
echo "  - ./check_aks_status.sh: AKS 클러스터 상태 확인"
echo "  - ./deploy_app.sh: 데모 애플리케이션 배포"
echo "  - ./aks_check.sh: AKS 클러스터 상세 점검 및 로깅"
echo "================================"
EOF

# 소유권 설정
chown azureuser:azureuser /home/azureuser/.bashrc

# AKS 점검 스크립트 생성
echo "AKS 점검 스크립트 생성 중..."
cat > /home/azureuser/aks_check.sh << 'EOF'
#!/bin/bash

# 스크립트 실행 경로 확인
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# 로그 파일 설정
export LOG_DIR="${SCRIPT_DIR}/logs"

# 로그 디렉토리 변수 확인
if [ -z "$LOG_DIR" ]; then
    echo "⚠️ 로그 디렉토리 변수가 비어 있습니다. 기본값으로 './logs'를 사용합니다."
    export LOG_DIR="./logs"
fi

# 로그 디렉토리 존재 여부 확인 및 생성
if [ ! -d "$LOG_DIR" ]; then
    echo "📁 로그 디렉토리($LOG_DIR)가 존재하지 않습니다. 생성합니다..."
    mkdir -p "$LOG_DIR"
    if [ $? -eq 0 ]; then
        echo "✅ 로그 디렉토리 생성 완료: $LOG_DIR"
    else
        echo "❌ 로그 디렉토리 생성 실패! 권한을 확인하세요."
        # 대체 로그 디렉토리 시도
        export LOG_DIR="/tmp/aks_check_logs"
        echo "🔄 대체 로그 디렉토리를 시도합니다: $LOG_DIR"
        mkdir -p "$LOG_DIR"
        if [ $? -eq 0 ]; then
            echo "✅ 대체 로그 디렉토리 생성 완료: $LOG_DIR"
        else
            echo "❌ 대체 로그 디렉토리 생성도 실패했습니다. 로그 파일 없이 진행합니다."
            export LOG_DIR=""
        fi
    fi
else
    echo "✅ 로그 디렉토리가 이미 존재합니다: $LOG_DIR"
fi

# 타임스탬프 생성
export TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 로그 파일 경로 설정
if [ -n "$LOG_DIR" ]; then
    export LOG_FILE="$LOG_DIR/aks_check_$TIMESTAMP.log"
    echo "📝 로그 파일 경로: $LOG_FILE"
else
    export LOG_FILE=""
    echo "⚠️ 로그 파일을 생성할 수 없습니다. 화면에만 출력합니다."
fi

# 로그 함수 정의
log() {
    echo "$1"
    if [ -n "$LOG_FILE" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
    fi
}

log "🚀 AKS 클러스터 점검 시작"
if [ -n "$LOG_FILE" ]; then
    log "(로그 파일: $LOG_FILE)"
fi

# 환경 변수 파일 경로 설정
export ENV_FILE="${SCRIPT_DIR}/env/.env"

# 환경 변수 파일 존재 여부 확인
if [ ! -f "$ENV_FILE" ]; then
    log "❌ 환경 변수 파일($ENV_FILE)을 찾을 수 없습니다. 파일을 확인하세요."
    exit 1
fi

log "📂 환경 변수 파일($ENV_FILE) 발견, 로드 중..."

# 환경 변수 로드
set -a  # 모든 변수를 export로 설정
source "$ENV_FILE"
set +a

# 필수 환경 변수 검증
export REQUIRED_VARS=("RESOURCE_GROUP" "AKS_CLUSTER" "NAMESPACE")
export MISSING_VARS=()

for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        MISSING_VARS+=("$VAR")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    log "❌ 다음 필수 환경 변수가 설정되지 않았습니다:"
    for VAR in "${MISSING_VARS[@]}"; do
        log "   - $VAR"
    done
    log "환경 변수 파일($ENV_FILE)을 확인하고 필수 변수를 설정하세요."
    exit 1
fi

# 환경 변수 정보 출력
log "✅ 환경 변수 파일 로드 완료"
log "📌 AKS 클러스터 정보:"
log "   - 리소스 그룹: $RESOURCE_GROUP"
log "   - 클러스터 이름: $AKS_CLUSTER"
log "   - 네임스페이스: $NAMESPACE"

# Azure 인증 정보 출력 (민감 정보는 마스킹)
if [ -n "$AZURE_TENANT_ID" ]; then
    log "   - 테넌트 ID: $AZURE_TENANT_ID"
fi

if [ -n "$AZURE_CLIENT_ID" ]; then
    log "   - 클라이언트 ID: $AZURE_CLIENT_ID"
fi

if [ -n "$AZURE_CLIENT_SECRET" ]; then
    # 클라이언트 시크릿은 보안을 위해 마스킹
    log "   - 클라이언트 시크릿: ********"
fi

if [ -n "$AZURE_SUBSCRIPTION_ID" ]; then
    log "   - 구독 ID: $AZURE_SUBSCRIPTION_ID"
fi

# Azure 로그인 상태 확인
log "🔍 Azure 로그인 상태 확인 중..."
az account show > /dev/null 2>&1
export LOGIN_STATUS=$?

# 로그인 로직
if [ $LOGIN_STATUS -ne 0 ]; then
    log "🔄 Azure 로그인이 필요합니다."
    if [ -n "$AZURE_CLIENT_ID" ] && [ -n "$AZURE_CLIENT_SECRET" ] && [ -n "$AZURE_TENANT_ID" ]; then
        # Service Principal 로그인
        log "🔑 Service Principal을 사용하여 로그인 시도 중..."
        az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            log "❌ Azure 로그인 실패! Service Principal 정보를 확인하세요."
            exit 1
        else
            log "✅ Azure 로그인 성공! (Service Principal)"
        fi
    else
        # 일반 로그인
        log "🔑 대화형 로그인 시도 중..."
        if [ -n "$AZURE_TENANT_ID" ]; then
            az login --tenant "$AZURE_TENANT_ID" > /dev/null 2>&1
        else
            az login > /dev/null 2>&1
        fi
        
        if [ $? -ne 0 ]; then
            log "❌ Azure 로그인 실패!"
            exit 1
        else
            log "✅ Azure 로그인 성공! (대화형)"
        fi
    fi
else
    log "✅ 이미 Azure에 로그인되어 있습니다."
    # 현재 로그인된 계정 정보 표시
    export CURRENT_ACCOUNT=$(az account show --query "[name,user.name]" -o tsv)
    log "   👤 현재 계정: $CURRENT_ACCOUNT"
fi

# 구독 설정
if [ -n "$AZURE_SUBSCRIPTION_ID" ]; then
    # 현재 구독 확인
    export CURRENT_SUBSCRIPTION=$(az account show --query "id" -o tsv)
    
    if [ "$CURRENT_SUBSCRIPTION" != "$AZURE_SUBSCRIPTION_ID" ]; then
        log "🔄 구독 변경 중: $AZURE_SUBSCRIPTION_ID"
        az account set --subscription "$AZURE_SUBSCRIPTION_ID" > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            log "❌ 구독 설정 실패! 구독 ID를 확인하세요."
            exit 1
        else
            log "✅ 구독 설정 완료: $AZURE_SUBSCRIPTION_ID"
        fi
    else
        log "✅ 이미 올바른 구독이 설정되어 있습니다: $AZURE_SUBSCRIPTION_ID"
    fi
fi

# AKS 클러스터 인증
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing --admin > /dev/null 2>&1
if [ $? -ne 0 ]; then
    log "❌ AKS 인증 실패! 클러스터 정보를 확인하세요."
    exit 1
fi

log "✅ AKS 인증 완료."

# 🔹 1. AKS RBAC 활성화 여부 확인
log "🔍 AKS RBAC 상태 확인 중..."
export RBAC_ENABLED=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --query "enableRBAC" -o tsv)
if [ "$RBAC_ENABLED" == "true" ]; then
    log "✅ RBAC 활성화됨"
else
    log "⚠️ RBAC 비활성화! 보안 강화를 위해 RBAC을 활성화하는 것이 좋습니다."
fi

# 🔹 2. Azure Monitor 활성화 여부 확인
log "🔍 Azure Monitor 상태 확인 중..."
export MONITOR_ENABLED=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --query "addonProfiles.azureMonitorProfile.enabled" -o tsv)
if [ "$MONITOR_ENABLED" == "true" ]; then
    log "✅ Azure Monitor 활성화됨"
else
    log "⚠️ Azure Monitor 비활성화! 클러스터 모니터링을 위해 활성화 권장."
fi

# 🔹 3. 컨테이너 모니터링 활성화 여부 및 설정 정보 확인
log "🔍 컨테이너 모니터링 상태 확인 중..."
export CONTAINER_MONITORING=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --query "addonProfiles.omsAgent.enabled" -o tsv)
if [ "$CONTAINER_MONITORING" == "true" ]; then
    export LOG_WORKSPACE=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --query "addonProfiles.omsAgent.config.logAnalyticsWorkspaceResourceID" -o tsv)
    log "✅ 컨테이너 모니터링 활성화됨 (Log Analytics Workspace: $LOG_WORKSPACE)"
else
    log "⚠️ 컨테이너 모니터링 비활성화! 로그 분석을 위해 활성화 권장."
fi

# 🔹 4. API 서버 로그 확인 (최근 10개)
log "🔍 API 서버 로그 조회 중..."
export API_SERVER_LOGS=$(kubectl logs -n kube-system -l component=kube-apiserver --tail=10 2>&1)
if [ $? -eq 0 ]; then
    log "✅ API 서버 로그 (최근 10개):"
    # API 서버 로그를 한 줄씩 로깅
    echo "$API_SERVER_LOGS" | while IFS= read -r line; do
        log "   $line"
    done
else
    log "⚠️ API 서버 로그를 가져올 수 없습니다. 대체 방법: AKS Diagnostics 사용"
    log "   👉 az aks diagnose --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER"
fi

# 🔹 5. 어플리케이션 Pod 로그 확인 (최근 10개)
log "🔍 어플리케이션 Pod 로그 조회 중..."
export POD_NAME=$(kubectl get pods -n "$NAMESPACE" --no-headers -o custom-columns=":metadata.name" | head -n 1)
if [ -z "$POD_NAME" ]; then
    log "⚠️ Pod를 찾을 수 없습니다. 네임스페이스($NAMESPACE)를 확인하세요."
else
    export POD_LOGS=$(kubectl logs "$POD_NAME" -n "$NAMESPACE" --tail=10 2>&1)
    if [ $? -eq 0 ]; then
        log "✅ Pod ($POD_NAME) 로그 (최근 10개):"
        # Pod 로그를 한 줄씩 로깅
        echo "$POD_LOGS" | while IFS= read -r line; do
            log "   $line"
        done
    else
        log "⚠️ Pod 로그를 가져올 수 없습니다. 대체 방법: Azure Monitor를 사용하여 로그 분석 가능."
    fi
fi

log "✅ 모든 점검 완료!"
if [ -n "$LOG_FILE" ]; then
    log "📝 로그 파일이 다음 위치에 저장되었습니다: $LOG_FILE"
fi
EOF

# env 디렉토리 생성 및 .env 파일 생성
mkdir -p /home/azureuser/env
cat > /home/azureuser/env/.env << 'EOF'
# AKS 클러스터 정보
RESOURCE_GROUP="your-aks-resource-group"
AKS_CLUSTER="your-aks-cluster-name"
NAMESPACE="default"

# Azure 인증 정보 (선택적)
# AZURE_TENANT_ID="your-tenant-id"
# AZURE_CLIENT_ID="your-client-id"
# AZURE_CLIENT_SECRET="your-client-secret"
# AZURE_SUBSCRIPTION_ID="your-subscription-id"
EOF

chmod +x /home/azureuser/aks_check.sh
chown azureuser:azureuser /home/azureuser/aks_check.sh
chown -R azureuser:azureuser /home/azureuser/env

# 환영 메시지에 aks_check.sh 스크립트 추가
echo "===== Jumpbox 도구 설치 완료 - $(date) =====" 