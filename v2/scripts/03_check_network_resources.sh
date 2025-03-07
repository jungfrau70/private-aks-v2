#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# 네트워크 리소스 체크 시작
echo -e "\n${yellow}네트워크 리소스 체크를 시작합니다...${nc}"

# 스크립트 실행 권한 부여 (Windows 환경 고려)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  echo -e "${yellow}Windows 환경에서는 실행 권한 설정이 필요하지 않습니다.${nc}"
else
  chmod +x scripts/03_1_check_hub_network.sh
  chmod +x scripts/03_2_check_spoke_network.sh
  chmod +x scripts/03_3_check_storage_network.sh
  chmod +x scripts/03_4_check_network_peerings.sh
fi

# Hub 네트워크 리소스 체크
echo -e "\n${yellow}Hub 네트워크 리소스 체크 중...${nc}"
source ./scripts/03_1_check_hub_network.sh

# Spoke 네트워크 리소스 체크
echo -e "\n${yellow}Spoke 네트워크 리소스 체크 중...${nc}"
source ./scripts/03_2_check_spoke_network.sh

# Storage 네트워크 리소스 체크
echo -e "\n${yellow}Storage 네트워크 리소스 체크 중...${nc}"
source ./scripts/03_3_check_storage_network.sh

# VNet 피어링 체크
echo -e "\n${yellow}VNet 피어링 체크 중...${nc}"
source ./scripts/03_4_check_network_peerings.sh

# 네트워크 설정 일관성 확인 및 수정
echo -e "\n${yellow}네트워크 설정 일관성 확인 및 수정 중...${nc}"

# terraform.tfvars 파일에서 현재 설정 값 가져오기
use_existing_networks=$(grep "use_existing_networks" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')
use_existing_hub_vnet=$(grep "use_existing_hub_vnet" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')
use_existing_spoke_vnet=$(grep "use_existing_spoke_vnet" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')
use_existing_storage_vnet=$(grep "use_existing_storage_vnet" terraform.tfvars | cut -d "=" -f2 | tr -d ' ')

echo -e "현재 설정 값:"
echo -e "use_existing_networks = ${use_existing_networks}"
echo -e "use_existing_hub_vnet = ${use_existing_hub_vnet}"
echo -e "use_existing_spoke_vnet = ${use_existing_spoke_vnet}"
echo -e "use_existing_storage_vnet = ${use_existing_storage_vnet}"

# 설정 일관성 확인
if [ "$use_existing_hub_vnet" == "true" ] || [ "$use_existing_spoke_vnet" == "true" ] || [ "$use_existing_storage_vnet" == "true" ]; then
  if [ "$use_existing_networks" != "true" ]; then
    echo -e "${red}설정 불일치 감지: VNet 중 하나라도 기존 것을 사용하는 경우 use_existing_networks도 true여야 합니다.${nc}"
    echo -e "${yellow}use_existing_networks를 true로 변경합니다...${nc}"
    sed -i "s/use_existing_networks = .*/use_existing_networks = true/" terraform.tfvars
    echo -e "${green}설정이 업데이트되었습니다: use_existing_networks = true${nc}"
  else
    echo -e "${green}네트워크 설정이 일관적입니다.${nc}"
  fi
else
  if [ "$use_existing_networks" == "true" ]; then
    echo -e "${yellow}경고: 모든 VNet을 새로 생성하는데 use_existing_networks가 true로 설정되어 있습니다.${nc}"
    echo -e "${yellow}이 설정은 문제를 일으키지 않지만, 명확성을 위해 false로 변경하는 것이 좋습니다.${nc}"
    read -p "use_existing_networks를 false로 변경하시겠습니까? (y/n): " change_setting
    if [ "$change_setting" == "y" ]; then
      sed -i "s/use_existing_networks = .*/use_existing_networks = false/" terraform.tfvars
      echo -e "${green}설정이 업데이트되었습니다: use_existing_networks = false${nc}"
    else
      echo -e "${yellow}설정을 유지합니다: use_existing_networks = true${nc}"
    fi
  else
    echo -e "${green}네트워크 설정이 일관적입니다.${nc}"
  fi
fi

echo -e "\n${green}모든 네트워크 리소스 체크가 완료되었습니다.${nc}"
