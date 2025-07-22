#!/bin/bash

# AKS 클러스터 및 관련 리소스를 단계적으로 적용하는 스크립트
# 의존성 문제로 인해 count 인수가 적용 단계까지 알 수 없는 경우 사용

# 변수 설정
MODULE_NAME="module.aks_clusters"
WORKING_DIR="."
TERRAFORM_VARS="-var-file=terraform.tfvars"

# 색상 설정
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 함수 정의
function apply_resource() {
  local resource=$1
  local description=$2
  
  echo -e "${YELLOW}단계: $description${NC}"
  echo -e "terraform apply $TERRAFORM_VARS -auto-approve -target=$MODULE_NAME.$resource"
  
  terraform apply $TERRAFORM_VARS -auto-approve -target=$MODULE_NAME.$resource
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}성공: $description 완료${NC}"
  else
    echo -e "${RED}실패: $description 실패${NC}"
    exit 1
  fi
  
  echo ""
}

# 작업 디렉토리로 이동
cd $WORKING_DIR

# 1. AKS 클러스터 사용자 관리 ID 생성
apply_resource "azurerm_user_assigned_identity.aks_identity" "AKS 클러스터 사용자 관리 ID 생성"

# 2. AKS 클러스터 생성
apply_resource "azurerm_kubernetes_cluster.aks" "AKS 클러스터 생성"

# 3. Private DNS Zone 생성
apply_resource "azurerm_private_dns_zone.aks_dns" "Private DNS Zone 생성"

# 4. AKS VNet에 Private DNS Zone 연결
apply_resource "azurerm_private_dns_zone_virtual_network_link.aks_dns_link" "AKS VNet에 Private DNS Zone 연결"

# 5. Hub VNet에 Private DNS Zone 연결
apply_resource "azurerm_private_dns_zone_virtual_network_link.aks_dns_hub_link" "Hub VNet에 Private DNS Zone 연결"

# 6. 시스템 관리형 Private DNS Zone에 대한 Hub VNet 연결
apply_resource "azurerm_private_dns_zone_virtual_network_link.system_dns_hub_link" "시스템 관리형 Private DNS Zone에 대한 Hub VNet 연결"

# 7. AKS API 서버의 Private DNS A 레코드 생성
apply_resource "azurerm_private_dns_a_record.aks_dns_a_record" "AKS API 서버의 Private DNS A 레코드 생성"

# 8. ACR에 대한 AKS 클러스터 접근 권한 부여
apply_resource "azurerm_role_assignment.aks_acr_pull" "ACR에 대한 AKS 클러스터 접근 권한 부여"

# 9. KeyVault에 대한 AKS 클러스터 접근 권한 부여
apply_resource "azurerm_role_assignment.aks_keyvault_access" "KeyVault에 대한 AKS 클러스터 접근 권한 부여"

# 10. Application Gateway에 대한 AKS 클러스터 접근 권한 부여
apply_resource "azurerm_role_assignment.aks_appgw_contributor" "Application Gateway에 대한 AKS 클러스터 접근 권한 부여"

# 11. GitHub Actions OIDC 설정
apply_resource "azurerm_federated_identity_credential.github_oidc" "GitHub Actions OIDC 설정"

# 최종 적용 (모든 리소스)
echo -e "${YELLOW}최종 단계: 모든 리소스 적용${NC}"
echo "terraform apply $TERRAFORM_VARS -auto-approve"

terraform apply $TERRAFORM_VARS -auto-approve

if [ $? -eq 0 ]; then
  echo -e "${GREEN}성공: 모든 리소스 적용 완료${NC}"
else
  echo -e "${RED}실패: 모든 리소스 적용 실패${NC}"
  exit 1
fi

echo -e "${GREEN}AKS 클러스터 및 관련 리소스 배포가 완료되었습니다.${NC}" 