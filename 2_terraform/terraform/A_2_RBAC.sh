#!/bin/bash

# 오류 발생 시 스크립트 중단
set -e

echo "===== Azure AD RBAC 설정 시작 ====="

# Microsoft Graph 스코프 로그인 권장 안내
echo "※ Microsoft Graph API 권한을 위해 다음 명령으로 먼저 로그인하세요:"
echo "  az login --scope https://graph.microsoft.com//.default"
echo ""

# 환경 변수 설정
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
LOCATION="koreacentral"
RESOURCE_GROUP_HUB="rg-hub-aks-workshop"
RESOURCE_GROUP_SPOKE="rg-spoke-aks-workshop"
AKS_CLUSTER_NAME="private-aks"

# 그룹 생성 함수
create_ad_group() {
  local GROUP_NAME=$1
  local GROUP_ID

  echo "[$GROUP_NAME] 그룹 확인 중..."
  GROUP_ID=$(az ad group show --group "$GROUP_NAME" --query id -o tsv 2>/dev/null || true)

  if [ -z "$GROUP_ID" ]; then
    echo "[$GROUP_NAME] 그룹이 존재하지 않으므로 생성합니다..."
    GROUP_ID=$(az ad group create --display-name "$GROUP_NAME" --mail-nickname "$GROUP_NAME" --query id -o tsv)
    echo "[$GROUP_NAME] 그룹 생성 완료 → ID: $GROUP_ID"
  else
    echo "[$GROUP_NAME] 그룹이 이미 존재합니다 → ID: $GROUP_ID"
  fi

  echo "$GROUP_ID"
}

# 그룹 생성 및 ID 저장
AKS_ADMIN_GROUP_ID=$(create_ad_group "aks-admin-group")
AKS_DEV_GROUP_ID=$(create_ad_group "aks-dev-group")
AKS_OPS_GROUP_ID=$(create_ad_group "aks-ops-group")
ACR_ADMIN_GROUP_ID=$(create_ad_group "acr-admin-group")
KV_ADMIN_GROUP_ID=$(create_ad_group "kv-admin-group")

# terraform.tfvars 파일 업데이트
echo ""
echo "terraform.tfvars 파일 업데이트 중..."

TFVARS_FILE="../terraform.tfvars"
EXAMPLE_FILE="../terraform.tfvars.example"

# sed 명령어 구성 (Git Bash 및 WSL 대응)
function sed_in_place() {
  local pattern=$1
  local file=$2
  sed -i.bak "$pattern" "$file"
}

if [ -f "$TFVARS_FILE" ]; then
  cp "$TFVARS_FILE" "${TFVARS_FILE}.bak"

  sed_in_place "s|aks_admin_group_object_ids = \[\]|aks_admin_group_object_ids = [\"$AKS_ADMIN_GROUP_ID\"]|g" "$TFVARS_FILE"
  sed_in_place "s|aks_dev_group_object_ids = \[\]|aks_dev_group_object_ids = [\"$AKS_DEV_GROUP_ID\"]|g" "$TFVARS_FILE"
  sed_in_place "s|aks_ops_group_object_ids = \[\]|aks_ops_group_object_ids = [\"$AKS_OPS_GROUP_ID\"]|g" "$TFVARS_FILE"
  sed_in_place "s|acr_admin_group_object_ids = \[\]|acr_admin_group_object_ids = [\"$ACR_ADMIN_GROUP_ID\"]|g" "$TFVARS_FILE"
  sed_in_place "s|keyvault_admin_object_ids = \[\]|keyvault_admin_object_ids = [\"$KV_ADMIN_GROUP_ID\"]|g" "$TFVARS_FILE"

  echo "terraform.tfvars 파일이 업데이트되었습니다."

elif [ -f "$EXAMPLE_FILE" ]; then
  cp "$EXAMPLE_FILE" "$TFVARS_FILE"

  sed_in_place "s|aks_admin_group_object_ids = \[\]|aks_admin_group_object_ids = [\"$AKS_ADMIN_GROUP_ID\"]|g" "$TFVARS_FILE"
  sed_in_place "s|aks_dev_group_object_ids = \[\]|aks_dev_group_object_ids = [\"$AKS_DEV_GROUP_ID\"]|g" "$TFVARS_FILE"
  sed_in_place "s|aks_ops_group_object_ids = \[\]|aks_ops_group_object_ids = [\"$AKS_OPS_GROUP_ID\"]|g" "$TFVARS_FILE"
  sed_in_place "s|acr_admin_group_object_ids = \[\]|acr_admin_group_object_ids = [\"$ACR_ADMIN_GROUP_ID\"]|g" "$TFVARS_FILE"
  sed_in_place "s|keyvault_admin_object_ids = \[\]|keyvault_admin_object_ids = [\"$KV_ADMIN_GROUP_ID\"]|g" "$TFVARS_FILE"

  echo "terraform.tfvars 파일이 샘플로부터 생성되고 업데이트되었습니다."

else
  echo "❌ terraform.tfvars 또는 .example 파일이 존재하지 않습니다. 샘플 파일을 먼저 생성하세요."
  exit 1
fi

echo ""
echo "===== Azure AD RBAC 설정 완료 ====="
echo "다음 그룹 Object ID를 기록해두세요:"
echo "- AKS 관리자:   $AKS_ADMIN_GROUP_ID"
echo "- AKS 개발자:   $AKS_DEV_GROUP_ID"
echo "- AKS 운영자:   $AKS_OPS_GROUP_ID"
echo "- ACR 관리자:   $ACR_ADMIN_GROUP_ID"
echo "- KeyVault 관리자: $KV_ADMIN_GROUP_ID"
