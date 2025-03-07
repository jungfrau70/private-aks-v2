#!/bin/bash

# 오류 발생 시 스크립트 중단
set -e

echo "===== Terraform 백엔드 설정 시작 ====="

# 환경 변수 설정
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
LOCATION="koreacentral"
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="tfstate$(date +%s | sha256sum | head -c 8)"
CONTAINER_NAME="tfstate"

# 리소스 그룹 생성
echo "리소스 그룹 생성 중..."
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# 스토리지 계정 생성
echo "스토리지 계정 생성 중..."
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

# 컨테이너 생성
echo "스토리지 컨테이너 생성 중..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME

# 스토리지 계정 키 가져오기
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query "[0].value" -o tsv)

# backend.conf 파일 생성
echo "backend.conf 파일 생성 중..."
cat > ../backend.conf << EOF
resource_group_name  = "$RESOURCE_GROUP_NAME"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "$CONTAINER_NAME"
key                  = "terraform.tfstate"
EOF

# main.tf 파일 업데이트
echo "main.tf 파일 업데이트 중..."
if [ -f "../main.tf" ]; then
  # 기존 파일 백업
  cp ../main.tf ../main.tf.bak
  
  # 백엔드 설정 업데이트
  sed -i '/backend "local" {/,/}/c\
  backend "azurerm" {\
    # backend.conf 파일에서 설정을 로드합니다.\
  }' ../main.tf
  
  echo "main.tf 파일이 업데이트되었습니다."
else
  echo "main.tf 파일이 존재하지 않습니다. 먼저 main.tf 파일을 생성하세요."
fi

echo "===== Terraform 백엔드 설정 완료 ====="
echo "다음 명령어로 Terraform을 초기화하세요:"
echo "terraform init -backend-config=backend.conf"
echo ""
echo "스토리지 계정 정보:"
echo "리소스 그룹: $RESOURCE_GROUP_NAME"
echo "스토리지 계정 이름: $STORAGE_ACCOUNT_NAME"
echo "컨테이너 이름: $CONTAINER_NAME" 