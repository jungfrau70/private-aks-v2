#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# 애플리케이션 게이트웨이 리소스 체크 시작
echo -e "\n${yellow}애플리케이션 게이트웨이 관련 리소스 존재 여부 확인 중...${nc}"

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
spoke_rg=$(grep "resource_group_name_spoke" terraform.tfvars | cut -d'"' -f2)

# 리소스 그룹 존재 여부 확인
spoke_rg_exists=$(az group exists --name "$spoke_rg")

# 애플리케이션 게이트웨이 이름 가져오기
appgw_name=$(grep "appgw_name" terraform.tfvars | cut -d'"' -f2)

# 애플리케이션 게이트웨이 존재 여부 확인
appgw_exists=false
appgw_public_ip_exists=false
appgw_waf_policy_exists=false

if [[ "$spoke_rg_exists" == "true" ]]; then
  appgw_check=$(MSYS_NO_PATHCONV=1 az network application-gateway show --resource-group "$spoke_rg" --name "$appgw_name" --query "name" -o tsv 2>/dev/null)
  
  if [[ -n "$appgw_check" ]]; then
    echo -e "${green}애플리케이션 게이트웨이($appgw_name)가 존재합니다. use_existing_app_gateway = true로 설정합니다.${nc}"
    sed -i "s/use_existing_app_gateway = .*/use_existing_app_gateway = true/" terraform.tfvars
    sed -i "s/use_existing_appgw = .*/use_existing_appgw = true/" terraform.tfvars
    appgw_exists=true
    
    # 애플리케이션 게이트웨이 공용 IP 존재 여부 확인
    appgw_public_ip_check=$(MSYS_NO_PATHCONV=1 az network application-gateway show --resource-group "$spoke_rg" --name "$appgw_name" --query "frontendIPConfigurations[?contains(name, 'Public')].publicIPAddress.id" -o tsv 2>/dev/null)
    
    if [[ -n "$appgw_public_ip_check" ]]; then
      echo -e "${green}애플리케이션 게이트웨이 공용 IP가 존재합니다. use_existing_app_gateway_public_ip = true로 설정합니다.${nc}"
      sed -i "s/use_existing_app_gateway_public_ip = .*/use_existing_app_gateway_public_ip = true/" terraform.tfvars
      appgw_public_ip_exists=true
    else
      echo -e "${yellow}애플리케이션 게이트웨이 공용 IP가 존재하지 않습니다. use_existing_app_gateway_public_ip = false로 설정합니다.${nc}"
      sed -i "s/use_existing_app_gateway_public_ip = .*/use_existing_app_gateway_public_ip = false/" terraform.tfvars
    fi
    
    # 애플리케이션 게이트웨이 WAF 정책 존재 여부 확인
    appgw_waf_policy_check=$(MSYS_NO_PATHCONV=1 az network application-gateway waf-policy list --resource-group "$spoke_rg" --query "[?contains(name, '$appgw_name')].name" -o tsv 2>/dev/null)
    
    if [[ -n "$appgw_waf_policy_check" ]]; then
      echo -e "${green}애플리케이션 게이트웨이 WAF 정책이 존재합니다. use_existing_app_gateway_waf_policy = true로 설정합니다.${nc}"
      sed -i "s/use_existing_app_gateway_waf_policy = .*/use_existing_app_gateway_waf_policy = true/" terraform.tfvars
      appgw_waf_policy_exists=true
    else
      echo -e "${yellow}애플리케이션 게이트웨이 WAF 정책이 존재하지 않습니다. use_existing_app_gateway_waf_policy = false로 설정합니다.${nc}"
      sed -i "s/use_existing_app_gateway_waf_policy = .*/use_existing_app_gateway_waf_policy = false/" terraform.tfvars
    fi
  else
    echo -e "${yellow}애플리케이션 게이트웨이($appgw_name)가 존재하지 않습니다. use_existing_app_gateway = false로 설정합니다.${nc}"
    sed -i "s/use_existing_app_gateway = .*/use_existing_app_gateway = false/" terraform.tfvars
    sed -i "s/use_existing_appgw = .*/use_existing_appgw = false/" terraform.tfvars
    sed -i "s/use_existing_app_gateway_public_ip = .*/use_existing_app_gateway_public_ip = false/" terraform.tfvars
    sed -i "s/use_existing_app_gateway_waf_policy = .*/use_existing_app_gateway_waf_policy = false/" terraform.tfvars
  fi
else
  echo -e "${yellow}Spoke 리소스 그룹이 존재하지 않아 애플리케이션 게이트웨이를 확인할 수 없습니다.${nc}"
  sed -i "s/use_existing_app_gateway = .*/use_existing_app_gateway = false/" terraform.tfvars
  sed -i "s/use_existing_appgw = .*/use_existing_appgw = false/" terraform.tfvars
  sed -i "s/use_existing_app_gateway_public_ip = .*/use_existing_app_gateway_public_ip = false/" terraform.tfvars
  sed -i "s/use_existing_app_gateway_waf_policy = .*/use_existing_app_gateway_waf_policy = false/" terraform.tfvars
fi

# 애플리케이션 게이트웨이 리소스 존재 여부 요약
echo -e "\n${yellow}애플리케이션 게이트웨이 리소스 존재 여부 요약:${nc}"
echo -e "애플리케이션 게이트웨이 존재 여부: $appgw_exists"
echo -e "애플리케이션 게이트웨이 공용 IP 존재 여부: $appgw_public_ip_exists"
echo -e "애플리케이션 게이트웨이 WAF 정책 존재 여부: $appgw_waf_policy_exists"
echo -e "애플리케이션 게이트웨이 리소스 확인 완료" 