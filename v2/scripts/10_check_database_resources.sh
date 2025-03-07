#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# 데이터베이스 리소스 체크 시작
echo -e "\n${yellow}데이터베이스 관련 리소스 존재 여부 확인 중...${nc}"

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

# PostgreSQL 서버 이름 가져오기
db_server_name=$(grep "db_server_name" terraform.tfvars | cut -d'"' -f2)

# 데이터베이스 리소스 존재 여부 확인
postgresql_exists=false
postgresql_private_endpoint_exists=false
postgresql_private_dns_zone_exists=false

if [[ "$spoke_rg_exists" == "true" ]]; then
  postgresql_check=$(MSYS_NO_PATHCONV=1 az postgres server show --resource-group "$spoke_rg" --name "$db_server_name" --query "name" -o tsv 2>/dev/null)
  
  if [[ -n "$postgresql_check" ]]; then
    echo -e "${green}PostgreSQL 서버($db_server_name)가 존재합니다. use_existing_postgresql = true로 설정합니다.${nc}"
    sed -i "s/use_existing_postgresql = .*/use_existing_postgresql = true/" terraform.tfvars
    postgresql_exists=true
    
    # PostgreSQL 프라이빗 엔드포인트 존재 여부 확인
    postgresql_private_endpoint_check=$(MSYS_NO_PATHCONV=1 az network private-endpoint list --resource-group "$spoke_rg" --query "[?contains(name, '$db_server_name')].name" -o tsv 2>/dev/null)
    
    if [[ -n "$postgresql_private_endpoint_check" ]]; then
      echo -e "${green}PostgreSQL 프라이빗 엔드포인트가 존재합니다. use_existing_postgresql_private_endpoint = true로 설정합니다.${nc}"
      sed -i "s/use_existing_postgresql_private_endpoint = .*/use_existing_postgresql_private_endpoint = true/" terraform.tfvars
      postgresql_private_endpoint_exists=true
    else
      echo -e "${yellow}PostgreSQL 프라이빗 엔드포인트가 존재하지 않습니다. use_existing_postgresql_private_endpoint = false로 설정합니다.${nc}"
      sed -i "s/use_existing_postgresql_private_endpoint = .*/use_existing_postgresql_private_endpoint = false/" terraform.tfvars
    fi
    
    # PostgreSQL 프라이빗 DNS 영역 이름 가져오기
    private_dns_zone_name_postgres=$(grep "private_dns_zone_name_postgres" terraform.tfvars | cut -d'"' -f2)
    
    # PostgreSQL 프라이빗 DNS 영역 존재 여부 확인
    postgresql_private_dns_zone_check=$(MSYS_NO_PATHCONV=1 az network private-dns zone show --resource-group "$spoke_rg" --name "$private_dns_zone_name_postgres" --query "name" -o tsv 2>/dev/null)
    
    if [[ -n "$postgresql_private_dns_zone_check" ]]; then
      echo -e "${green}PostgreSQL 프라이빗 DNS 영역($private_dns_zone_name_postgres)이 존재합니다. use_existing_postgresql_private_dns_zone = true로 설정합니다.${nc}"
      sed -i "s/use_existing_postgresql_private_dns_zone = .*/use_existing_postgresql_private_dns_zone = true/" terraform.tfvars
      postgresql_private_dns_zone_exists=true
    else
      echo -e "${yellow}PostgreSQL 프라이빗 DNS 영역($private_dns_zone_name_postgres)이 존재하지 않습니다. use_existing_postgresql_private_dns_zone = false로 설정합니다.${nc}"
      sed -i "s/use_existing_postgresql_private_dns_zone = .*/use_existing_postgresql_private_dns_zone = false/" terraform.tfvars
    fi
  else
    echo -e "${yellow}PostgreSQL 서버($db_server_name)가 존재하지 않습니다. use_existing_postgresql = false로 설정합니다.${nc}"
    sed -i "s/use_existing_postgresql = .*/use_existing_postgresql = false/" terraform.tfvars
    sed -i "s/use_existing_postgresql_private_endpoint = .*/use_existing_postgresql_private_endpoint = false/" terraform.tfvars
    sed -i "s/use_existing_postgresql_private_dns_zone = .*/use_existing_postgresql_private_dns_zone = false/" terraform.tfvars
  fi
else
  echo -e "${yellow}Spoke 리소스 그룹이 존재하지 않아 PostgreSQL 서버를 확인할 수 없습니다.${nc}"
  sed -i "s/use_existing_postgresql = .*/use_existing_postgresql = false/" terraform.tfvars
  sed -i "s/use_existing_postgresql_private_endpoint = .*/use_existing_postgresql_private_endpoint = false/" terraform.tfvars
  sed -i "s/use_existing_postgresql_private_dns_zone = .*/use_existing_postgresql_private_dns_zone = false/" terraform.tfvars
fi

# 데이터베이스 리소스 존재 여부 요약
echo -e "\n${yellow}데이터베이스 리소스 존재 여부 요약:${nc}"
echo -e "PostgreSQL 서버 존재 여부: $postgresql_exists"
echo -e "PostgreSQL 프라이빗 엔드포인트 존재 여부: $postgresql_private_endpoint_exists"
echo -e "PostgreSQL 프라이빗 DNS 영역 존재 여부: $postgresql_private_dns_zone_exists"
echo -e "데이터베이스 리소스 확인 완료" 