#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# KeyVault 리소스 체크 시작
echo -e "\n${yellow}KeyVault 리소스 존재 여부 확인 중...${nc}"

# Azure CLI 로그인 상태 확인
echo -e "${yellow}Azure CLI 로그인 상태 확인 중...${nc}"
az account show &>/dev/null
if [ $? -ne 0 ]; then
  echo -e "${red}Azure CLI에 로그인되어 있지 않습니다. 로그인을 진행합니다.${nc}"
  az login
  if [ $? -ne 0 ]; then
    echo -e "${red}Azure CLI 로그인에 실패했습니다. 스크립트를 종료합니다.${nc}"
    exit 1
  fi
fi

# 구독 ID 가져오기
subscription_id=$(grep "subscription_id" terraform.tfvars | cut -d'"' -f2)
echo -e "${yellow}구독 ID: $subscription_id${nc}"

# 구독 설정
az account set --subscription "$subscription_id"
if [ $? -ne 0 ]; then
  echo -e "${red}구독 설정에 실패했습니다. 스크립트를 종료합니다.${nc}"
  exit 1
fi

# 리소스 그룹 이름 가져오기
hub_rg=$(grep "resource_group_name_hub" terraform.tfvars | cut -d'"' -f2)

# 리소스 그룹 존재 여부 확인
hub_rg_exists=$(az group exists --name "$hub_rg")

# KeyVault 이름 가져오기
keyvault_name=$(grep "keyvault_name" terraform.tfvars | cut -d'"' -f2)

# KeyVault 존재 여부 확인
keyvault_exists=false
keyvault_private_endpoint_exists=false

if [[ "$hub_rg_exists" == "true" ]]; then
  keyvault_check=$(MSYS_NO_PATHCONV=1 az keyvault list --resource-group "$hub_rg" --query "[?name=='$keyvault_name'].name" -o tsv 2>/dev/null)
  
  if [[ -n "$keyvault_check" ]]; then
    echo -e "${green}KeyVault($keyvault_name)가 존재합니다. use_existing_keyvault = true로 설정합니다.${nc}"
    sed -i "s/use_existing_keyvault = .*/use_existing_keyvault = true/" terraform.tfvars
    keyvault_exists=true
    
    # KeyVault Private Endpoint 존재 여부 확인
    keyvault_private_endpoint_check=$(MSYS_NO_PATHCONV=1 az network private-endpoint list --resource-group "$hub_rg" --query "[?contains(name, '$keyvault_name')].name" -o tsv 2>/dev/null)
    
    if [[ -n "$keyvault_private_endpoint_check" ]]; then
      echo -e "${green}KeyVault Private Endpoint가 존재합니다. use_existing_keyvault_private_endpoint = true로 설정합니다.${nc}"
      sed -i "s/use_existing_keyvault_private_endpoint = .*/use_existing_keyvault_private_endpoint = true/" terraform.tfvars
      keyvault_private_endpoint_exists=true
    else
      echo -e "${yellow}KeyVault Private Endpoint가 존재하지 않습니다. use_existing_keyvault_private_endpoint = false로 설정합니다.${nc}"
      sed -i "s/use_existing_keyvault_private_endpoint = .*/use_existing_keyvault_private_endpoint = false/" terraform.tfvars
    fi
  else
    echo -e "${yellow}KeyVault($keyvault_name)가 존재하지 않습니다. use_existing_keyvault = false로 설정합니다.${nc}"
    sed -i "s/use_existing_keyvault = .*/use_existing_keyvault = false/" terraform.tfvars
    sed -i "s/use_existing_keyvault_private_endpoint = .*/use_existing_keyvault_private_endpoint = false/" terraform.tfvars
  fi
else
  echo -e "${yellow}Hub 리소스 그룹이 존재하지 않아 KeyVault를 확인할 수 없습니다.${nc}"
  sed -i "s/use_existing_keyvault = .*/use_existing_keyvault = false/" terraform.tfvars
  sed -i "s/use_existing_keyvault_private_endpoint = .*/use_existing_keyvault_private_endpoint = false/" terraform.tfvars
fi

# KeyVault 리소스 존재 여부 요약
echo -e "\n${yellow}KeyVault 리소스 존재 여부 요약:${nc}"
echo -e "KeyVault 존재 여부: $keyvault_exists"
echo -e "KeyVault 프라이빗 엔드포인트 존재 여부: $keyvault_private_endpoint_exists"
echo -e "KeyVault 리소스 확인 완료" 