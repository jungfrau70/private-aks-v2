#!/bin/bash

# 필요한 변수 설정
RESOURCE_GROUP_NAME="rg-terraform-state"
STORAGE_ACCOUNT_NAME="tfstatea8dd06d1"
CONTAINER_NAME="tfstate"
LOCATION="koreacentral"

# 리소스 그룹 생성 (존재하지 않는 경우)
echo "리소스 그룹 생성 중..."
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION --tags "purpose=terraform-state" --output none

# 스토리지 계정 생성 (존재하지 않는 경우)
echo "스토리지 계정 생성 중..."
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob \
  --output none

# 스토리지 계정 키 가져오기
echo "스토리지 계정 키 가져오는 중..."
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# 컨테이너 생성 (존재하지 않는 경우)
echo "Blob 컨테이너 생성 중..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --account-key $ACCOUNT_KEY \
  --output none

# backend.conf 파일 생성
echo "backend.conf 파일 생성 중..."
cat > ../backend.conf << EOF
resource_group_name  = "$RESOURCE_GROUP_NAME"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "$CONTAINER_NAME"
key                  = "terraform.tfstate"
EOF

echo "Terraform 백엔드 설정 완료!" 