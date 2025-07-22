#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# Storage 네트워크 리소스 체크 시작
echo -e "\n${yellow}Storage 네트워크 리소스 존재 여부 확인 중...${nc}"

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

# terraform.tfvars 파일에서 변수 값 가져오기
storage_rg=$(grep "storage_rg" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
storage_vnet=$(grep "storage_vnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
storage_subnet=$(grep "storage_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "storagesubnet")
storage_nsg=$(grep "storage_nsg_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "storage_nsg")

# 리소스 그룹 존재 여부 확인
echo -e "\n${yellow}Storage 리소스 그룹 확인 중...${nc}"
storage_rg_exists=$(az group exists --name $storage_rg)
echo -e "Storage 리소스 그룹(${storage_rg}) 존재 여부: ${storage_rg_exists}"

# Storage 네트워크 리소스 존재 여부 확인
storage_vnet_exists=false
storage_subnet_exists=false
storage_nsg_exists=false

# Storage VNet 확인
if [ "$storage_rg_exists" == "true" ]; then
  storage_vnet_check=$(az network vnet list --resource-group $storage_rg --query "[?name=='$storage_vnet'].name" -o tsv)
  if [ -n "$storage_vnet_check" ]; then
    storage_vnet_exists=true
    echo -e "${green}Storage VNet(${storage_vnet}) 존재함: ${storage_vnet_check}${nc}"
    
    # Storage 서브넷 확인
    storage_subnet_check=$(az network vnet subnet list --resource-group $storage_rg --vnet-name $storage_vnet --query "[?name=='$storage_subnet'].name" -o tsv)
    if [ -n "$storage_subnet_check" ]; then
      storage_subnet_exists=true
      echo -e "${green}Storage 서브넷(${storage_subnet}) 존재함: ${storage_subnet_check}${nc}"
    else
      echo -e "${yellow}Storage 서브넷(${storage_subnet}) 존재하지 않음${nc}"
    fi
    
    # Storage NSG 확인
    storage_nsg_check=$(az network nsg list --resource-group $storage_rg --query "[?name=='$storage_nsg'].name" -o tsv)
    if [ -n "$storage_nsg_check" ]; then
      storage_nsg_exists=true
      echo -e "${green}Storage NSG(${storage_nsg}) 존재함: ${storage_nsg_check}${nc}"
    else
      echo -e "${yellow}Storage NSG(${storage_nsg}) 존재하지 않음${nc}"
    fi
  else
    echo -e "${yellow}Storage VNet(${storage_vnet}) 존재하지 않음${nc}"
  fi
else
  echo -e "${yellow}Storage 리소스 그룹이 존재하지 않아 Storage 네트워크 리소스를 확인할 수 없습니다.${nc}"
fi

# Storage 네트워크 리소스 설정 업데이트
echo -e "\n${yellow}Storage 네트워크 리소스 설정을 업데이트합니다...${nc}"

# Storage VNet 존재 여부에 따라 변수 설정
if [ "$storage_vnet_exists" == "true" ]; then
  echo -e "${green}Storage VNet이 존재합니다. use_existing_storage_vnet = true로 설정합니다.${nc}"
  sed -i "s/use_existing_storage_vnet = .*/use_existing_storage_vnet = true/" terraform.tfvars
  
  # Storage VNet이 존재하면 use_existing_networks도 true로 설정
  echo -e "${green}Storage VNet이 존재하므로 use_existing_networks = true로 설정합니다.${nc}"
  sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
else
  echo -e "${yellow}Storage VNet이 존재하지 않습니다. use_existing_storage_vnet = false로 설정합니다.${nc}"
  sed -i "s/use_existing_storage_vnet = .*/use_existing_storage_vnet = false/" terraform.tfvars
fi

# 설정 일관성 확인
echo -e "\n${yellow}Storage 네트워크 설정 일관성 확인 중...${nc}"

# terraform.tfvars 파일에서 현재 설정 값 가져오기
use_existing_networks=$(grep "use_existing_networks" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')
use_existing_storage_vnet=$(grep "use_existing_storage_vnet" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')

echo -e "현재 설정 값:"
echo -e "use_existing_networks = ${use_existing_networks}"
echo -e "use_existing_storage_vnet = ${use_existing_storage_vnet}"

# 설정 일관성 확인 및 수정
if [ "$use_existing_storage_vnet" == "true" ] && [ "$use_existing_networks" != "true" ]; then
  echo -e "${red}설정 불일치 감지: use_existing_storage_vnet이 true인데 use_existing_networks가 true가 아닙니다.${nc}"
  echo -e "${yellow}use_existing_networks를 true로 변경합니다...${nc}"
  sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
  echo -e "${green}설정이 업데이트되었습니다: use_existing_networks = true${nc}"
else
  echo -e "${green}Storage 네트워크 설정이 일관적입니다.${nc}"
fi

# Storage 네트워크 리소스 존재 여부 요약
echo -e "\n${yellow}Storage 네트워크 리소스 존재 여부 요약:${nc}"
echo -e "Storage VNet 존재 여부: $storage_vnet_exists"
echo -e "Storage 서브넷 존재 여부: $storage_subnet_exists"
echo -e "Storage NSG 존재 여부: $storage_nsg_exists"
echo -e "Storage 네트워크 리소스 확인 완료" 