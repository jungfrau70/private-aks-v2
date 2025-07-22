#!/bin/bash

# 환경 변수 설정
source ./mount_env.sh

# 로그 함수 정의
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log "🚀 Azure File Share 마운트 스크립트 시작"

# 필요한 패키지 설치
log "📦 필요한 패키지 설치 중..."
sudo apt-get update > /dev/null
sudo apt-get install cifs-utils -y > /dev/null

if [ $? -ne 0 ]; then
    log "❌ 패키지 설치 실패. 다시 시도하세요."
    exit 1
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
    # MOUNT_POINT="/mnt/${SHARE_NAME}"
    MOUNT_POINT="~/fileshare"
    log "📂 기본 마운트 포인트를 사용합니다: $MOUNT_POINT"
fi

# 스토리지 키 가져오기
log "🔑 스토리지 계정 키 가져오는 중..."
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

if [ -z "$STORAGE_KEY" ]; then
    log "❌ 스토리지 키를 가져올 수 없습니다. 계정 이름과 리소스 그룹을 확인하세요."
    exit 1
fi
log "✅ 스토리지 키 가져오기 완료"

# 마운트 포인트 생성
log "📁 마운트 포인트 생성 중: $MOUNT_POINT"
sudo mkdir -p $MOUNT_POINT

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

# 파일 공유 마운트
log "🔄 파일 공유 마운트 중..."
sudo mount -t cifs //$STORAGE_ACCOUNT.file.core.windows.net/$SHARE_NAME $MOUNT_POINT -o credentials=/etc/azurefileshare.credentials,serverino,nosharesock,actimeo=30

if [ $? -ne 0 ]; then
    log "❌ 파일 공유 마운트 실패. 설정을 확인하세요."
    exit 1
fi
log "✅ 파일 공유 마운트 완료"

# 영구 마운트 설정
log "📝 영구 마운트 설정 중..."
if ! grep -q "$MOUNT_POINT" /etc/fstab; then
    echo "//$STORAGE_ACCOUNT.file.core.windows.net/$SHARE_NAME $MOUNT_POINT cifs nofail,credentials=/etc/azurefileshare.credentials,serverino,nosharesock,actimeo=30 0 0" | sudo tee -a /etc/fstab > /dev/null
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

log "🎉 Azure File Share 마운트 스크립트 완료" 