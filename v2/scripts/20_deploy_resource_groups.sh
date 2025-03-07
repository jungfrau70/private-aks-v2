#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# Windows Git Bash 환경에서 경로 변환 방지
export MSYS_NO_PATHCONV=1

echo -e "\n${yellow}리소스 그룹 배포 작업을 시작합니다...${nc}"

# Azure CLI 로그인 상태 확인
echo -e "Azure CLI 로그인 상태 확인 중..."
subscription_id=$(az account show --query id -o tsv 2>/dev/null)
if [ -z "$subscription_id" ]; then
  echo -e "${red}Azure CLI에 로그인되어 있지 않습니다. 로그인을 진행합니다...${nc}"
  az login
  subscription_id=$(az account show --query id -o tsv)
fi
echo -e "구독 ID: ${subscription_id}"

# 테라폼 초기화
echo -e "${cyan}테라폼 초기화 중...${nc}"
terraform init -upgrade

# 리소스 그룹 모듈만 배포
echo -e "${cyan}리소스 그룹 모듈 배포 중...${nc}"
terraform apply -target=module.resource_groups -auto-approve

# 배포 결과 확인
if [ $? -eq 0 ]; then
  echo -e "${green}리소스 그룹 배포가 성공적으로 완료되었습니다.${nc}"
  
  # 리소스 그룹 이름 가져오기
  hub_rg=$(grep "resource_group_name_hub" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')
  spoke_rg=$(grep "resource_group_name_spoke" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')
  storage_rg=$(grep "resource_group_name_storage" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')
  
  # 리소스 그룹 존재 여부 확인
  hub_rg_exists=$(az group exists --name "$hub_rg" --output tsv)
  spoke_rg_exists=$(az group exists --name "$spoke_rg" --output tsv)
  storage_rg_exists=$(az group exists --name "$storage_rg" --output tsv)
  
  echo -e "\n${yellow}리소스 그룹 배포 후 존재 여부:${nc}"
  echo -e "Hub 리소스 그룹 존재 여부: ${hub_rg_exists}"
  echo -e "Spoke 리소스 그룹 존재 여부: ${spoke_rg_exists}"
  echo -e "Storage 리소스 그룹 존재 여부: ${storage_rg_exists}"
  
  # 모든 리소스 그룹이 존재하는지 확인
  if [ "$hub_rg_exists" == "true" ] && [ "$spoke_rg_exists" == "true" ] && [ "$storage_rg_exists" == "true" ]; then
    echo -e "${green}모든 리소스 그룹이 성공적으로 생성되었습니다.${nc}"
  else
    echo -e "${red}일부 리소스 그룹이 생성되지 않았습니다. 수동으로 확인해주세요.${nc}"
  fi
else
  echo -e "${red}리소스 그룹 배포 중 오류가 발생했습니다.${nc}"
fi

echo -e "\n${yellow}리소스 그룹 배포 작업이 완료되었습니다.${nc}" 