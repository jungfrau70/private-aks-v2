#!/bin/bash

# 오류 발생 시 스크립트 중단
set -e

echo "===== 애플리케이션 빌드 시작 - $(date) ====="

# 환경 변수 설정
ACR_LOGIN_SERVER="${acr_login_server}"
APP_IMAGE_NAME="${app_image_name}"
APP_IMAGE_TAG="${app_image_tag}"
APP_SOURCE_DIR="${app_source_dir}"

# 현재 디렉토리 확인
CURRENT_DIR=$(pwd)
echo "현재 디렉토리: $CURRENT_DIR"

# ACR 로그인
echo "ACR 로그인 중..."
az acr login --name $(echo $ACR_LOGIN_SERVER | cut -d '.' -f 1)

# 이미지 태그 설정 (제공되지 않은 경우 현재 날짜/시간 사용)
if [ -z "$APP_IMAGE_TAG" ]; then
  APP_IMAGE_TAG=$(date +%Y%m%d%H%M%S)
  echo "이미지 태그가 제공되지 않아 현재 시간으로 설정: $APP_IMAGE_TAG"
fi

# 애플리케이션 이미지 빌드
echo "애플리케이션 이미지 빌드 중..."
echo "이미지: $ACR_LOGIN_SERVER/$APP_IMAGE_NAME:$APP_IMAGE_TAG"
docker build -t $ACR_LOGIN_SERVER/$APP_IMAGE_NAME:$APP_IMAGE_TAG .
docker tag $ACR_LOGIN_SERVER/$APP_IMAGE_NAME:$APP_IMAGE_TAG $ACR_LOGIN_SERVER/$APP_IMAGE_NAME:latest

# ACR에 이미지 푸시
echo "이미지 푸시 중..."
docker push $ACR_LOGIN_SERVER/$APP_IMAGE_NAME:$APP_IMAGE_TAG
docker push $ACR_LOGIN_SERVER/$APP_IMAGE_NAME:latest

echo "===== 애플리케이션 빌드 완료 - $(date) ====="
echo "이미지: $ACR_LOGIN_SERVER/$APP_IMAGE_NAME:$APP_IMAGE_TAG"
echo "이미지: $ACR_LOGIN_SERVER/$APP_IMAGE_NAME:latest" 