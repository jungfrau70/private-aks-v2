#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# Hub 네트워크 리소스 체크 시작
echo -e "\n${yellow}Hub 네트워크 리소스 존재 여부 확인 중...${nc}"

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
hub_rg=$(grep "resource_group_name_hub" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
hub_vnet=$(grep "hub_vnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
bastion_subnet=$(grep "bastion_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "AzureBastionSubnet")
jumpbox_subnet=$(grep "jumpbox_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "jumpbox-subnet")
bastion_nsg=$(grep "bastion_nsg_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "Bastion_NSG")

# 리소스 그룹 존재 여부 확인
echo -e "\n${yellow}Hub 리소스 그룹 확인 중...${nc}"
hub_rg_exists=$(az group exists --name $hub_rg)
echo -e "Hub 리소스 그룹(${hub_rg}) 존재 여부: ${hub_rg_exists}"

# Hub 네트워크 리소스 존재 여부 확인
hub_vnet_exists=false
bastion_subnet_exists=false
jumpbox_subnet_exists=false
bastion_nsg_exists=false

# Hub VNet 확인
if [ "$hub_rg_exists" == "true" ]; then
  hub_vnet_check=$(az network vnet list --resource-group $hub_rg --query "[?name=='$hub_vnet'].name" -o tsv)
  if [ -n "$hub_vnet_check" ]; then
    hub_vnet_exists=true
    echo -e "${green}Hub VNet(${hub_vnet}) 존재함: ${hub_vnet_check}${nc}"
    
    # Bastion 서브넷 확인
    bastion_subnet_check=$(az network vnet subnet list --resource-group $hub_rg --vnet-name $hub_vnet --query "[?name=='$bastion_subnet'].name" -o tsv)
    if [ -n "$bastion_subnet_check" ]; then
      bastion_subnet_exists=true
      echo -e "${green}Bastion 서브넷(${bastion_subnet}) 존재함: ${bastion_subnet_check}${nc}"
    else
      echo -e "${yellow}Bastion 서브넷(${bastion_subnet}) 존재하지 않음${nc}"
    fi
    
    # Jumpbox 서브넷 확인
    jumpbox_subnet_check=$(az network vnet subnet list --resource-group $hub_rg --vnet-name $hub_vnet --query "[?name=='$jumpbox_subnet'].name" -o tsv)
    if [ -n "$jumpbox_subnet_check" ]; then
      jumpbox_subnet_exists=true
      echo -e "${green}Jumpbox 서브넷(${jumpbox_subnet}) 존재함: ${jumpbox_subnet_check}${nc}"
    else
      echo -e "${yellow}Jumpbox 서브넷(${jumpbox_subnet}) 존재하지 않음${nc}"
    fi
    
    # Bastion NSG 확인
    bastion_nsg_check=$(az network nsg list --resource-group $hub_rg --query "[?name=='$bastion_nsg'].name" -o tsv)
    if [ -n "$bastion_nsg_check" ]; then
      bastion_nsg_exists=true
      echo -e "${green}Bastion NSG(${bastion_nsg}) 존재함: ${bastion_nsg_check}${nc}"
      
      # NSG 규칙 확인
      echo -e "\n${yellow}Bastion NSG 규칙 확인 중...${nc}"
      nsg_rules=$(az network nsg rule list --resource-group $hub_rg --nsg-name $bastion_nsg --query "[].name" -o tsv)
      echo -e "Bastion NSG 규칙: ${nsg_rules}"
    else
      echo -e "${yellow}Bastion NSG(${bastion_nsg}) 존재하지 않음${nc}"
    fi
  else
    echo -e "${yellow}Hub VNet(${hub_vnet}) 존재하지 않음${nc}"
  fi
else
  echo -e "${yellow}Hub 리소스 그룹이 존재하지 않아 Hub 네트워크 리소스를 확인할 수 없습니다.${nc}"
fi

# Hub 네트워크 리소스 설정 업데이트
echo -e "\n${yellow}Hub 네트워크 리소스 설정을 업데이트합니다...${nc}"

# Hub VNet 존재 여부에 따라 변수 설정
if [ "$hub_vnet_exists" == "true" ]; then
  echo -e "${green}Hub VNet이 존재합니다. use_existing_hub_vnet = true로 설정합니다.${nc}"
  sed -i "s/use_existing_hub_vnet = .*/use_existing_hub_vnet = true/" terraform.tfvars
  
  # Hub VNet이 존재하면 use_existing_networks도 true로 설정
  echo -e "${green}Hub VNet이 존재하므로 use_existing_networks = true로 설정합니다.${nc}"
  sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
else
  echo -e "${yellow}Hub VNet이 존재하지 않습니다. use_existing_hub_vnet = false로 설정합니다.${nc}"
  sed -i "s/use_existing_hub_vnet = .*/use_existing_hub_vnet = false/" terraform.tfvars
fi

# 설정 일관성 확인
echo -e "\n${yellow}Hub 네트워크 설정 일관성 확인 중...${nc}"

# terraform.tfvars 파일에서 현재 설정 값 가져오기
use_existing_networks=$(grep "use_existing_networks" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')
use_existing_hub_vnet=$(grep "use_existing_hub_vnet" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')

echo -e "현재 설정 값:"
echo -e "use_existing_networks = ${use_existing_networks}"
echo -e "use_existing_hub_vnet = ${use_existing_hub_vnet}"

# 설정 일관성 확인 및 수정
if [ "$use_existing_hub_vnet" == "true" ] && [ "$use_existing_networks" != "true" ]; then
  echo -e "${red}설정 불일치 감지: use_existing_hub_vnet이 true인데 use_existing_networks가 true가 아닙니다.${nc}"
  echo -e "${yellow}use_existing_networks를 true로 변경합니다...${nc}"
  sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
  echo -e "${green}설정이 업데이트되었습니다: use_existing_networks = true${nc}"
else
  echo -e "${green}Hub 네트워크 설정이 일관적입니다.${nc}"
fi

# Hub 네트워크 리소스 존재 여부 요약
echo -e "\n${yellow}Hub 네트워크 리소스 존재 여부 요약:${nc}"
echo -e "Hub VNet 존재 여부: $hub_vnet_exists"
echo -e "Bastion 서브넷 존재 여부: $bastion_subnet_exists"
echo -e "Jumpbox 서브넷 존재 여부: $jumpbox_subnet_exists"
echo -e "Bastion NSG 존재 여부: $bastion_nsg_exists"
echo -e "Hub 네트워크 리소스 확인 완료" 