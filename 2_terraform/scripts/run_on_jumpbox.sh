#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] 오류:${NC} $1"
}

success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] 성공:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] 주의:${NC} $1"
}

# 변수 설정
RESOURCE_GROUP="rg-hub"
JUMPBOX_VM_NAME="central-jumpbox"
SCRIPT_PATH="$(pwd)/install_tools_jumpbox.sh"
REMOTE_SCRIPT_PATH="/home/azureuser/install_tools_jumpbox.sh"

# 스크립트 존재 여부 확인
if [ ! -f "$SCRIPT_PATH" ]; then
    error "설치 스크립트를 찾을 수 없습니다: $SCRIPT_PATH"
    exit 1
fi

# 리소스 그룹 및 VM 이름 확인
log "리소스 그룹 및 VM 이름 확인 중..."
if [ -z "$RESOURCE_GROUP" ] || [ -z "$JUMPBOX_VM_NAME" ]; then
    warning "리소스 그룹 또는 VM 이름이 설정되지 않았습니다."
    read -p "리소스 그룹 이름을 입력하세요: " RESOURCE_GROUP
    read -p "Jumpbox VM 이름을 입력하세요: " JUMPBOX_VM_NAME
fi

# VM 존재 여부 확인
log "VM 존재 여부 확인 중..."
VM_EXISTS=$(az vm show --resource-group $RESOURCE_GROUP --name $JUMPBOX_VM_NAME --query "name" -o tsv 2>/dev/null)
if [ -z "$VM_EXISTS" ]; then
    error "VM을 찾을 수 없습니다: $JUMPBOX_VM_NAME"
    log "사용 가능한 VM 목록:"
    az vm list --resource-group $RESOURCE_GROUP --query "[].name" -o tsv
    exit 1
fi
success "VM 확인 완료: $JUMPBOX_VM_NAME"

# 스크립트 업로드
log "설치 스크립트 업로드 중..."
az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $JUMPBOX_VM_NAME \
  --command-id RunShellScript \
  --scripts "cat > $REMOTE_SCRIPT_PATH << 'EOL'
$(cat $SCRIPT_PATH)
EOL
chmod +x $REMOTE_SCRIPT_PATH"

if [ $? -ne 0 ]; then
    error "스크립트 업로드 실패"
    exit 1
fi
success "스크립트 업로드 완료"

# 스크립트 실행
log "설치 스크립트 실행 중... (이 작업은 몇 분 정도 소요될 수 있습니다)"
az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $JUMPBOX_VM_NAME \
  --command-id RunShellScript \
  --scripts "sudo bash $REMOTE_SCRIPT_PATH"

if [ $? -ne 0 ]; then
    error "스크립트 실행 실패"
    exit 1
fi
success "스크립트 실행 완료"

# 설치 확인
log "설치 확인 중..."
az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $JUMPBOX_VM_NAME \
  --command-id RunShellScript \
  --scripts "command -v az && command -v docker && command -v kubectl"

if [ $? -ne 0 ]; then
    warning "일부 도구가 설치되지 않았을 수 있습니다. 로그를 확인하세요."
else
    success "모든 도구가 설치되었습니다."
fi

# VM 재부팅 (선택적)
read -p "VM을 재부팅하시겠습니까? (y/n): " REBOOT
if [[ "$REBOOT" == "y" || "$REBOOT" == "Y" ]]; then
    log "VM 재부팅 중..."
    az vm restart --resource-group $RESOURCE_GROUP --name $JUMPBOX_VM_NAME
    success "VM 재부팅 완료"
fi

log "Jumpbox VM 설정이 완료되었습니다."
log "SSH 접속 명령어: ssh azureuser@<JUMPBOX_IP>" 