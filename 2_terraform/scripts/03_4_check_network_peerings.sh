#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# VNet 피어링 체크 시작
echo -e "\n${yellow}VNet 피어링 존재 여부 확인 중...${nc}"

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
spoke_rg=$(grep "resource_group_name_spoke" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
storage_rg=$(grep "storage_rg" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
hub_vnet=$(grep "hub_vnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
spoke_vnet=$(grep "spoke_vnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
storage_vnet=$(grep "storage_vnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')

# 리소스 그룹 존재 여부 확인
hub_rg_exists=$(az group exists --name $hub_rg)
spoke_rg_exists=$(az group exists --name $spoke_rg)
storage_rg_exists=$(az group exists --name $storage_rg)

# VNet 존재 여부 확인
hub_vnet_exists=false
spoke_vnet_exists=false
storage_vnet_exists=false

if [ "$hub_rg_exists" == "true" ]; then
  hub_vnet_check=$(az network vnet list --resource-group $hub_rg --query "[?name=='$hub_vnet'].name" -o tsv)
  if [ -n "$hub_vnet_check" ]; then
    hub_vnet_exists=true
  fi
fi

if [ "$spoke_rg_exists" == "true" ]; then
  spoke_vnet_check=$(az network vnet list --resource-group $spoke_rg --query "[?name=='$spoke_vnet'].name" -o tsv)
  if [ -n "$spoke_vnet_check" ]; then
    spoke_vnet_exists=true
  fi
fi

if [ "$storage_rg_exists" == "true" ]; then
  storage_vnet_check=$(az network vnet list --resource-group $storage_rg --query "[?name=='$storage_vnet'].name" -o tsv)
  if [ -n "$storage_vnet_check" ]; then
    storage_vnet_exists=true
  fi
fi

# VNet 피어링 존재 여부 확인
hub_to_spoke_peering_exists=false
spoke_to_hub_peering_exists=false
hub_to_storage_peering_exists=false
storage_to_hub_peering_exists=false
spoke_to_storage_peering_exists=false
storage_to_spoke_peering_exists=false

# Hub-Spoke 피어링 확인
if [ "$hub_vnet_exists" == "true" ] && [ "$spoke_vnet_exists" == "true" ]; then
  echo -e "\n${yellow}Hub-Spoke 피어링 확인 중...${nc}"
  
  hub_to_spoke_peering=$(az network vnet peering list --resource-group $hub_rg --vnet-name $hub_vnet --query "[?contains(remoteVirtualNetwork.id, '$spoke_vnet')].name" -o tsv)
  spoke_to_hub_peering=$(az network vnet peering list --resource-group $spoke_rg --vnet-name $spoke_vnet --query "[?contains(remoteVirtualNetwork.id, '$hub_vnet')].name" -o tsv)
  
  if [ -n "$hub_to_spoke_peering" ]; then
    hub_to_spoke_peering_exists=true
    echo -e "${green}Hub-to-Spoke 피어링 존재함: ${hub_to_spoke_peering}${nc}"
  else
    echo -e "${yellow}Hub-to-Spoke 피어링 존재하지 않음${nc}"
  fi
  
  if [ -n "$spoke_to_hub_peering" ]; then
    spoke_to_hub_peering_exists=true
    echo -e "${green}Spoke-to-Hub 피어링 존재함: ${spoke_to_hub_peering}${nc}"
  else
    echo -e "${yellow}Spoke-to-Hub 피어링 존재하지 않음${nc}"
  fi
else
  echo -e "${yellow}Hub VNet 또는 Spoke VNet이 존재하지 않아 Hub-Spoke 피어링을 확인할 수 없습니다.${nc}"
fi

# Hub-Storage 피어링 확인
if [ "$hub_vnet_exists" == "true" ] && [ "$storage_vnet_exists" == "true" ]; then
  echo -e "\n${yellow}Hub-Storage 피어링 확인 중...${nc}"
  
  hub_to_storage_peering=$(az network vnet peering list --resource-group $hub_rg --vnet-name $hub_vnet --query "[?contains(remoteVirtualNetwork.id, '$storage_vnet')].name" -o tsv)
  storage_to_hub_peering=$(az network vnet peering list --resource-group $storage_rg --vnet-name $storage_vnet --query "[?contains(remoteVirtualNetwork.id, '$hub_vnet')].name" -o tsv)
  
  if [ -n "$hub_to_storage_peering" ]; then
    hub_to_storage_peering_exists=true
    echo -e "${green}Hub-to-Storage 피어링 존재함: ${hub_to_storage_peering}${nc}"
  else
    echo -e "${yellow}Hub-to-Storage 피어링 존재하지 않음${nc}"
  fi
  
  if [ -n "$storage_to_hub_peering" ]; then
    storage_to_hub_peering_exists=true
    echo -e "${green}Storage-to-Hub 피어링 존재함: ${storage_to_hub_peering}${nc}"
  else
    echo -e "${yellow}Storage-to-Hub 피어링 존재하지 않음${nc}"
  fi
else
  echo -e "${yellow}Hub VNet 또는 Storage VNet이 존재하지 않아 Hub-Storage 피어링을 확인할 수 없습니다.${nc}"
fi

# Spoke-Storage 피어링 확인
if [ "$spoke_vnet_exists" == "true" ] && [ "$storage_vnet_exists" == "true" ]; then
  echo -e "\n${yellow}Spoke-Storage 피어링 확인 중...${nc}"
  
  spoke_to_storage_peering=$(az network vnet peering list --resource-group $spoke_rg --vnet-name $spoke_vnet --query "[?contains(remoteVirtualNetwork.id, '$storage_vnet')].name" -o tsv)
  storage_to_spoke_peering=$(az network vnet peering list --resource-group $storage_rg --vnet-name $storage_vnet --query "[?contains(remoteVirtualNetwork.id, '$spoke_vnet')].name" -o tsv)
  
  if [ -n "$spoke_to_storage_peering" ]; then
    spoke_to_storage_peering_exists=true
    echo -e "${green}Spoke-to-Storage 피어링 존재함: ${spoke_to_storage_peering}${nc}"
  else
    echo -e "${yellow}Spoke-to-Storage 피어링 존재하지 않음${nc}"
  fi
  
  if [ -n "$storage_to_spoke_peering" ]; then
    storage_to_spoke_peering_exists=true
    echo -e "${green}Storage-to-Spoke 피어링 존재함: ${storage_to_spoke_peering}${nc}"
  else
    echo -e "${yellow}Storage-to-Spoke 피어링 존재하지 않음${nc}"
  fi
else
  echo -e "${yellow}Spoke VNet 또는 Storage VNet이 존재하지 않아 Spoke-Storage 피어링을 확인할 수 없습니다.${nc}"
fi

# 전체 네트워크 설정 업데이트
echo -e "\n${yellow}전체 네트워크 설정을 업데이트합니다...${nc}"

# 모든 VNet이 존재하는지 확인
if [ "$hub_vnet_exists" == "true" ] && [ "$spoke_vnet_exists" == "true" ] && [ "$storage_vnet_exists" == "true" ]; then
  # 모든 피어링이 존재하는지 확인
  if [ "$hub_to_spoke_peering_exists" == "true" ] && [ "$spoke_to_hub_peering_exists" == "true" ] && \
     [ "$hub_to_storage_peering_exists" == "true" ] && [ "$storage_to_hub_peering_exists" == "true" ] && \
     [ "$spoke_to_storage_peering_exists" == "true" ] && [ "$storage_to_spoke_peering_exists" == "true" ]; then
    echo -e "${green}모든 VNet과 피어링이 존재합니다. use_existing_networks = true로 설정합니다.${nc}"
    sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
  else
    echo -e "${yellow}일부 피어링이 존재하지 않습니다. use_existing_networks = true로 설정하고 피어링을 생성합니다.${nc}"
    sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
  fi
else
  echo -e "${yellow}일부 VNet이 존재하지 않습니다. 개별 VNet 설정에 따라 리소스를 생성합니다.${nc}"
  # 개별 VNet 설정은 이미 각 스크립트에서 업데이트되었으므로 여기서는 추가 작업 없음
fi

# VNet 피어링 존재 여부 요약
echo -e "\n${yellow}VNet 피어링 존재 여부 요약:${nc}"
echo -e "Hub-to-Spoke 피어링 존재 여부: $hub_to_spoke_peering_exists"
echo -e "Spoke-to-Hub 피어링 존재 여부: $spoke_to_hub_peering_exists"
echo -e "Hub-to-Storage 피어링 존재 여부: $hub_to_storage_peering_exists"
echo -e "Storage-to-Hub 피어링 존재 여부: $storage_to_hub_peering_exists"
echo -e "Spoke-to-Storage 피어링 존재 여부: $spoke_to_storage_peering_exists"
echo -e "Storage-to-Spoke 피어링 존재 여부: $storage_to_spoke_peering_exists"
echo -e "VNet 피어링 확인 완료" 