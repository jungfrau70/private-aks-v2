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
    nano \
    cifs-utils

# Azure CLI 설치
echo "Azure CLI 설치 중..."
if ! command -v az &> /dev/null; then
    echo "Azure CLI가 설치되어 있지 않습니다. 설치를 시작합니다..."
    # 기존 설치 제거 (있을 경우)
    apt-get remove -y azure-cli
    rm -rf /etc/apt/sources.list.d/azure-cli.list
    rm -rf /etc/apt/sources.list.d/azure-cli.list.save
    
    # 새로 설치
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    
    # 설치 확인
    if ! command -v az &> /dev/null; then
        echo "Azure CLI 설치 실패. 수동 설치 방법을 시도합니다..."
        # 수동 설치 방법
        apt-get update
        apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
        mkdir -p /etc/apt/keyrings
        curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null
        chmod go+r /etc/apt/keyrings/microsoft.gpg
        echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list
        apt-get update
        apt-get install -y azure-cli
    fi
else
    echo "Azure CLI가 이미 설치되어 있습니다. 버전: $(az --version | head -n 1)"
fi

# 설치 확인
if command -v az &> /dev/null; then
    echo "✅ Azure CLI 설치 완료: $(az --version | head -n 1)"
else
    echo "❌ Azure CLI 설치 실패"
fi

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
if ! command -v docker &> /dev/null; then
    echo "Docker가 설치되어 있지 않습니다. 설치를 시작합니다..."
    # 기존 설치 제거 (있을 경우)
    apt-get remove -y docker docker-engine docker.io containerd runc
    
    # 필요한 패키지 설치
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Docker 공식 GPG 키 추가
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Docker 저장소 설정
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Docker 설치
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Docker 서비스 시작 및 활성화
    systemctl start docker
    systemctl enable docker
    
    # 사용자를 docker 그룹에 추가
    usermod -aG docker azureuser
else
    echo "Docker가 이미 설치되어 있습니다. 버전: $(docker --version)"
fi

# Docker 설치 확인
if command -v docker &> /dev/null; then
    echo "✅ Docker 설치 완료: $(docker --version)"
    echo "Docker 서비스 상태: $(systemctl is-active docker)"
    
    # Docker 서비스가 실행 중이 아니면 시작
    if [ "$(systemctl is-active docker)" != "active" ]; then
        echo "Docker 서비스가 실행 중이 아닙니다. 시작합니다..."
        systemctl start docker
        systemctl enable docker
    fi
else
    echo "❌ Docker 설치 실패"
fi

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
# MC_로 시작하지 않고 spoke를 포함하는 리소스 그룹 찾기
SPOKE_RG=$(az group list --query "[?contains(name, 'spoke') && !starts_with(name, 'MC_')].name" -o tsv)

echo "리소스 그룹: $SPOKE_RG"

# AKS 클러스터 이름 가져오기
AKS_CLUSTER_NAME=$(az aks list --resource-group $SPOKE_RG --query "[0].name" -o tsv)

echo "AKS 클러스터 이름: $AKS_CLUSTER_NAME"

# 클러스터 이름이 비어있는지 확인
if [ -z "$AKS_CLUSTER_NAME" ]; then
    echo "오류: AKS 클러스터를 찾을 수 없습니다."
    echo "사용 가능한 AKS 클러스터 목록:"
    az aks list --resource-group $SPOKE_RG --output table
    exit 1
fi

# AKS 자격 증명 가져오기
echo "AKS 자격 증명 가져오기..."
az aks get-credentials --resource-group $SPOKE_RG --name $AKS_CLUSTER_NAME --admin --overwrite-existing

# 클러스터 상태 확인
echo "클러스터 상태 확인..."
kubectl cluster-info
kubectl get nodes
EOF

chmod +x /home/azureuser/get_aks_credentials.sh
chown azureuser:azureuser /home/azureuser/get_aks_credentials.sh

# 파일 공유 마운트 스크립트 생성
echo "파일 공유 마운트 스크립트 생성 중..."
cat > /home/azureuser/mount_env.sh << 'EOF'
#!/bin/bash
# 스토리지 계정 정보
export RESOURCE_GROUP="rg-storage"
export STORAGE_ACCOUNT="sa1sharedstorage"
export SHARE_NAME="quickscripts"
export MOUNT_POINT="/home/azureuser/fileshare"
EOF

chmod +x /home/azureuser/mount_env.sh
chown azureuser:azureuser /home/azureuser/mount_env.sh

cat > /home/azureuser/mount_fileshare.sh << 'EOF'
#!/bin/bash

# 환경 변수 설정
source ./mount_env.sh

# 로그 함수 정의
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log "🚀 Azure File Share 마운트 스크립트 시작"

# 필요한 패키지 설치
log "📦 필요한 패키지 확인 중..."
if ! dpkg -l | grep -q cifs-utils; then
    log "cifs-utils 설치 중..."
    sudo apt-get update > /dev/null
    sudo apt-get install cifs-utils -y > /dev/null
    if [ $? -ne 0 ]; then
        log "❌ 패키지 설치 실패. 다시 시도하세요."
        exit 1
    fi
fi
log "✅ 패키지 설치 완료"

# 환경 변수 설정
if [ -z "$STORAGE_ACCOUNT" ] || [ -z "$SHARE_NAME" ]; then
    log "⚠️ 스토리지 계정 또는 공유 이름이 설정되지 않았습니다."
    
    # 사용자 입력 요청
    read -p "스토리지 계정 이름을 입력하세요: " STORAGE_ACCOUNT
    read -p "파일 공유 이름을 입력하세요: " SHARE_NAME
    read -p "리소스 그룹 이름을 입력하세요: " RESOURCE_GROUP
    
    if [ -z "$STORAGE_ACCOUNT" ] || [ -z "$SHARE_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
        log "❌ 필수 정보가 누락되었습니다."
        exit 1
    fi
fi

# 마운트 포인트 설정
if [ -z "$MOUNT_POINT" ]; then
    MOUNT_POINT="/home/azureuser/fileshare"
    log "📂 기본 마운트 포인트를 사용합니다: $MOUNT_POINT"
fi

# 스토리지 계정 존재 여부 확인
log "🔍 스토리지 계정 확인 중..."
STORAGE_EXISTS=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "name" -o tsv 2>/dev/null)
if [ -z "$STORAGE_EXISTS" ]; then
    log "❌ 스토리지 계정($STORAGE_ACCOUNT)이 존재하지 않습니다."
    log "💡 사용 가능한 스토리지 계정 목록:"
    az storage account list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table
    
    # 사용자 입력으로 스토리지 계정 재설정
    read -p "사용할 스토리지 계정 이름을 입력하세요: " STORAGE_ACCOUNT
    read -p "스토리지 계정의 리소스 그룹을 입력하세요: " RESOURCE_GROUP
    
    if [ -z "$STORAGE_ACCOUNT" ] || [ -z "$RESOURCE_GROUP" ]; then
        log "❌ 필수 정보가 누락되었습니다."
        exit 1
    fi
fi

# 스토리지 키 가져오기
log "🔑 스토리지 계정 키 가져오는 중..."
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

if [ -z "$STORAGE_KEY" ]; then
    log "❌ 스토리지 키를 가져올 수 없습니다. 계정 이름과 리소스 그룹을 확인하세요."
    exit 1
fi
log "✅ 스토리지 키 가져오기 완료"

# 파일 공유 존재 여부 확인
log "🔍 파일 공유 확인 중..."
SHARE_EXISTS=$(az storage share exists --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY --name $SHARE_NAME --query "exists" -o tsv)
if [ "$SHARE_EXISTS" != "true" ]; then
    log "⚠️ 파일 공유($SHARE_NAME)가 존재하지 않습니다. 생성합니다..."
    az storage share create --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY --name $SHARE_NAME
    if [ $? -ne 0 ]; then
        log "❌ 파일 공유 생성 실패. 권한을 확인하세요."
        exit 1
    fi
    log "✅ 파일 공유 생성 완료"
fi

# 마운트 포인트 생성
log "📁 마운트 포인트 생성 중: $MOUNT_POINT"
sudo mkdir -p $MOUNT_POINT
sudo chown azureuser:azureuser $MOUNT_POINT

# 자격 증명 파일 생성
log "🔐 자격 증명 파일 생성 중..."
echo "username=$STORAGE_ACCOUNT" | sudo tee /etc/azurefileshare.credentials > /dev/null
echo "password=$STORAGE_KEY" | sudo tee -a /etc/azurefileshare.credentials > /dev/null
sudo chmod 600 /etc/azurefileshare.credentials
log "✅ 자격 증명 파일 생성 완료"

# 기존 마운트 확인 및 해제
if mount | grep -q "$MOUNT_POINT"; then
    log "⚠️ 이미 마운트된 파일 공유가 있습니다. 해제 중..."
    sudo umount $MOUNT_POINT
fi

# 현재 사용자의 UID와 GID 가져오기
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# 파일 공유 마운트
log "🔄 파일 공유 마운트 중..."
sudo mount -t cifs "//$STORAGE_ACCOUNT.file.core.windows.net/$SHARE_NAME" "$MOUNT_POINT" -o "vers=3.0,credentials=/etc/azurefileshare.credentials,serverino,nosharesock,actimeo=30,uid=$USER_ID,gid=$GROUP_ID"

if [ $? -ne 0 ]; then
    log "⚠️ 첫 번째 마운트 시도 실패. SMB 버전을 변경하여 다시 시도합니다..."
    sudo mount -t cifs "//$STORAGE_ACCOUNT.file.core.windows.net/$SHARE_NAME" "$MOUNT_POINT" -o "vers=2.1,credentials=/etc/azurefileshare.credentials,serverino,nosharesock,actimeo=30,uid=$USER_ID,gid=$GROUP_ID"
    
    if [ $? -ne 0 ]; then
        log "❌ 파일 공유 마운트 실패. 설정을 확인하세요."
        log "💡 디버그 정보:"
        log "  - 스토리지 계정: $STORAGE_ACCOUNT"
        log "  - 파일 공유: $SHARE_NAME"
        log "  - 마운트 포인트: $MOUNT_POINT"
        exit 1
    fi
fi
log "✅ 파일 공유 마운트 완료"

# 영구 마운트 설정
log "📝 영구 마운트 설정 중..."
if ! grep -q "$MOUNT_POINT" /etc/fstab; then
    echo "//$STORAGE_ACCOUNT.file.core.windows.net/$SHARE_NAME $MOUNT_POINT cifs nofail,vers=3.0,credentials=/etc/azurefileshare.credentials,serverino,nosharesock,actimeo=30,uid=$USER_ID,gid=$GROUP_ID 0 0" | sudo tee -a /etc/fstab > /dev/null
    log "✅ /etc/fstab에 마운트 정보 추가 완료"
else
    log "⚠️ 이미 /etc/fstab에 마운트 정보가 있습니다."
fi

# 마운트 확인
log "🔍 마운트 상태 확인 중..."
if df -h | grep -q "$MOUNT_POINT"; then
    MOUNT_INFO=$(df -h | grep "$MOUNT_POINT")
    log "✅ 파일 공유가 성공적으로 마운트되었습니다:"
    log "   $MOUNT_INFO"
    log "📂 마운트 포인트: $MOUNT_POINT"
else
    log "❌ 마운트 확인 실패. 수동으로 확인하세요."
    exit 1
fi

# 소유권 확인
log "👤 마운트된 파일 공유의 소유권 확인 중..."
OWNER_INFO=$(ls -ld $MOUNT_POINT)
log "   $OWNER_INFO"

# 현재 사용자 정보 출력
CURRENT_USER=$(whoami)
log "👤 현재 사용자: $CURRENT_USER (UID: $USER_ID, GID: $GROUP_ID)"

log "🎉 Azure File Share 마운트 스크립트 완료"
EOF

chmod +x /home/azureuser/mount_fileshare.sh
chown azureuser:azureuser /home/azureuser/mount_fileshare.sh

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
echo "  - ./mount_fileshare.sh: Azure 파일 공유 마운트"
echo "================================"
EOF

# 소유권 설정
chown azureuser:azureuser /home/azureuser/.bashrc

# 파일 공유 마운트 자동 실행 (선택적)
# su - azureuser -c "/home/azureuser/mount_fileshare.sh"

# 설치된 도구 확인 및 요약
echo "===== 설치된 도구 확인 ====="
echo "Azure CLI: $(command -v az &> /dev/null && az --version | head -n 1 || echo '설치되지 않음')"
echo "Docker: $(command -v docker &> /dev/null && docker --version || echo '설치되지 않음')"
echo "kubectl: $(command -v kubectl &> /dev/null && kubectl version --client || echo '설치되지 않음')"
echo "Helm: $(command -v helm &> /dev/null && helm version --short || echo '설치되지 않음')"
echo "kubectx: $(command -v kubectx &> /dev/null && echo '설치됨' || echo '설치되지 않음')"
echo "kubens: $(command -v kubens &> /dev/null && echo '설치됨' || echo '설치되지 않음')"
echo "k9s: $(command -v k9s &> /dev/null && k9s version --short || echo '설치되지 않음')"

# Docker 서비스 상태 확인
echo "Docker 서비스 상태: $(systemctl is-active docker)"

# 사용자 그룹 확인
echo "azureuser의 그룹: $(groups azureuser | grep -q docker && echo 'docker 그룹에 포함됨' || echo 'docker 그룹에 포함되지 않음')"

# 설치 완료 메시지
echo "===== Jumpbox 도구 설치 완료 - $(date) ====="
echo "주의: Docker 그룹 권한을 적용하려면 VM을 재부팅하거나 사용자가 다시 로그인해야 합니다."
echo "VM 재부팅 명령어: sudo reboot" 