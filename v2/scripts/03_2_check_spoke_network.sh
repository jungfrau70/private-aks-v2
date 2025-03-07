#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# Spoke 네트워크 리소스 체크 시작
echo -e "\n${yellow}Spoke 네트워크 리소스 존재 여부 확인 중...${nc}"

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
spoke_rg=$(grep "resource_group_name_spoke" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
spoke_vnet=$(grep "spoke_vnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
endpoints_subnet=$(grep "endpoints_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
aks_subnet=$(grep "aks_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "aks-subnet")
appgw_subnet=$(grep "appgw_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "app-gw-subnet")
db_subnet=$(grep "db_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "db-subnet")

# 리소스 그룹 존재 여부 확인
echo -e "\n${yellow}Spoke 리소스 그룹 확인 중...${nc}"
spoke_rg_exists=$(az group exists --name $spoke_rg)
echo -e "Spoke 리소스 그룹(${spoke_rg}) 존재 여부: ${spoke_rg_exists}"

# Spoke 네트워크 리소스 존재 여부 확인
spoke_vnet_exists=false
endpoints_subnet_exists=false
aks_subnet_exists=false
appgw_subnet_exists=false
db_subnet_exists=false

# Spoke VNet 확인
if [ "$spoke_rg_exists" == "true" ]; then
  spoke_vnet_check=$(az network vnet list --resource-group $spoke_rg --query "[?name=='$spoke_vnet'].name" -o tsv)
  if [ -n "$spoke_vnet_check" ]; then
    spoke_vnet_exists=true
    echo -e "${green}Spoke VNet(${spoke_vnet}) 존재함: ${spoke_vnet_check}${nc}"
    
    # Endpoints 서브넷 확인
    endpoints_subnet_check=$(az network vnet subnet list --resource-group $spoke_rg --vnet-name $spoke_vnet --query "[?name=='$endpoints_subnet'].name" -o tsv)
    if [ -n "$endpoints_subnet_check" ]; then
      endpoints_subnet_exists=true
      echo -e "${green}Endpoints 서브넷(${endpoints_subnet}) 존재함: ${endpoints_subnet_check}${nc}"
    else
      echo -e "${yellow}Endpoints 서브넷(${endpoints_subnet}) 존재하지 않음${nc}"
    fi
    
    # AKS 서브넷 확인
    aks_subnet_check=$(az network vnet subnet list --resource-group $spoke_rg --vnet-name $spoke_vnet --query "[?name=='$aks_subnet'].name" -o tsv)
    if [ -n "$aks_subnet_check" ]; then
      aks_subnet_exists=true
      echo -e "${green}AKS 서브넷(${aks_subnet}) 존재함: ${aks_subnet_check}${nc}"
    else
      echo -e "${yellow}AKS 서브넷(${aks_subnet}) 존재하지 않음${nc}"
    fi
    
    # AppGW 서브넷 확인
    appgw_subnet_check=$(az network vnet subnet list --resource-group $spoke_rg --vnet-name $spoke_vnet --query "[?name=='$appgw_subnet'].name" -o tsv)
    if [ -n "$appgw_subnet_check" ]; then
      appgw_subnet_exists=true
      echo -e "${green}AppGW 서브넷(${appgw_subnet}) 존재함: ${appgw_subnet_check}${nc}"
    else
      echo -e "${yellow}AppGW 서브넷(${appgw_subnet}) 존재하지 않음${nc}"
    fi
    
    # DB 서브넷 확인
    db_subnet_check=$(az network vnet subnet list --resource-group $spoke_rg --vnet-name $spoke_vnet --query "[?name=='$db_subnet'].name" -o tsv)
    if [ -n "$db_subnet_check" ]; then
      db_subnet_exists=true
      echo -e "${green}DB 서브넷(${db_subnet}) 존재함: ${db_subnet_check}${nc}"
    else
      echo -e "${yellow}DB 서브넷(${db_subnet}) 존재하지 않음${nc}"
    fi
  else
    echo -e "${yellow}Spoke VNet(${spoke_vnet}) 존재하지 않음${nc}"
  fi
else
  echo -e "${yellow}Spoke 리소스 그룹이 존재하지 않아 Spoke 네트워크 리소스를 확인할 수 없습니다.${nc}"
fi

# Spoke 네트워크 리소스 설정 업데이트
echo -e "\n${yellow}Spoke 네트워크 리소스 설정을 업데이트합니다...${nc}"

# Spoke VNet 존재 여부에 따라 변수 설정
if [ "$spoke_vnet_exists" == "true" ]; then
  echo -e "${green}Spoke VNet이 존재합니다. use_existing_spoke_vnet = true로 설정합니다.${nc}"
  sed -i "s/use_existing_spoke_vnet = .*/use_existing_spoke_vnet = true/" terraform.tfvars
  
  # Spoke VNet이 존재하면 use_existing_networks도 true로 설정
  echo -e "${green}Spoke VNet이 존재하므로 use_existing_networks = true로 설정합니다.${nc}"
  sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
else
  echo -e "${yellow}Spoke VNet이 존재하지 않습니다. use_existing_spoke_vnet = false로 설정합니다.${nc}"
  sed -i "s/use_existing_spoke_vnet = .*/use_existing_spoke_vnet = false/" terraform.tfvars
fi

# Endpoints 서브넷 존재 여부에 따라 변수 설정
if [ "$endpoints_subnet_exists" == "true" ]; then
  echo -e "${green}Endpoints 서브넷이 존재합니다. use_existing_endpoints_subnet = true로 설정합니다.${nc}"
  sed -i "s/use_existing_endpoints_subnet = .*/use_existing_endpoints_subnet = true/" terraform.tfvars
else
  echo -e "${yellow}Endpoints 서브넷이 존재하지 않습니다. use_existing_endpoints_subnet = false로 설정합니다.${nc}"
  sed -i "s/use_existing_endpoints_subnet = .*/use_existing_endpoints_subnet = false/" terraform.tfvars
fi

# AKS 서브넷 존재 여부에 따라 변수 설정
if [ "$aks_subnet_exists" == "true" ]; then
  echo -e "${green}AKS 서브넷이 존재합니다. use_existing_aks_subnet = true로 설정합니다.${nc}"
  sed -i "s/use_existing_aks_subnet = .*/use_existing_aks_subnet = true/" terraform.tfvars
else
  echo -e "${yellow}AKS 서브넷이 존재하지 않습니다. use_existing_aks_subnet = false로 설정합니다.${nc}"
  sed -i "s/use_existing_aks_subnet = .*/use_existing_aks_subnet = false/" terraform.tfvars
fi

# 설정 일관성 확인
echo -e "\n${yellow}Spoke 네트워크 설정 일관성 확인 중...${nc}"

# terraform.tfvars 파일에서 현재 설정 값 가져오기
use_existing_networks=$(grep "use_existing_networks" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')
use_existing_spoke_vnet=$(grep "use_existing_spoke_vnet" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')

echo -e "현재 설정 값:"
echo -e "use_existing_networks = ${use_existing_networks}"
echo -e "use_existing_spoke_vnet = ${use_existing_spoke_vnet}"

# 설정 일관성 확인 및 수정
if [ "$use_existing_spoke_vnet" == "true" ] && [ "$use_existing_networks" != "true" ]; then
  echo -e "${red}설정 불일치 감지: use_existing_spoke_vnet이 true인데 use_existing_networks가 true가 아닙니다.${nc}"
  echo -e "${yellow}use_existing_networks를 true로 변경합니다...${nc}"
  sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
  echo -e "${green}설정이 업데이트되었습니다: use_existing_networks = true${nc}"
else
  echo -e "${green}Spoke 네트워크 설정이 일관적입니다.${nc}"
fi

# Spoke 네트워크 리소스 존재 여부 요약
echo -e "\n${yellow}Spoke 네트워크 리소스 존재 여부 요약:${nc}"
echo -e "Spoke VNet 존재 여부: $spoke_vnet_exists"
echo -e "Endpoints 서브넷 존재 여부: $endpoints_subnet_exists"
echo -e "AKS 서브넷 존재 여부: $aks_subnet_exists"
echo -e "AppGW 서브넷 존재 여부: $appgw_subnet_exists"
echo -e "DB 서브넷 존재 여부: $db_subnet_exists"
echo -e "Spoke 네트워크 리소스 확인 완료" 