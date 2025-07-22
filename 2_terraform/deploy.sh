#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# 스크립트 실행 권한 부여 (Windows 환경 고려)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  echo -e "${yellow}Windows 환경에서는 실행 권한 설정이 필요하지 않습니다.${nc}"
else
  chmod +x scripts/*.sh
fi

# 초기화 스크립트 실행
echo -e "${yellow}초기화 스크립트 실행 중...${nc}"
source ./scripts/01_init.sh

# 리소스 그룹 체크 스크립트 실행
echo -e "${yellow}리소스 그룹 체크 스크립트 실행 중...${nc}"
source ./scripts/02_check_resource_groups.sh

# 네트워크 리소스 체크 스크립트 실행
echo -e "${yellow}네트워크 리소스 체크 스크립트 실행 중...${nc}"
source ./scripts/03_check_network_resources.sh

# 스토리지 리소스 체크 스크립트 실행
echo -e "${yellow}스토리지 리소스 체크 스크립트 실행 중...${nc}"
source ./scripts/04_check_storage_resources.sh

# ACR 리소스 체크 스크립트 실행
echo -e "${yellow}ACR 리소스 체크 스크립트 실행 중...${nc}"
source ./scripts/05_check_acr_resources.sh

# KeyVault 리소스 체크 스크립트 실행
echo -e "${yellow}KeyVault 리소스 체크 스크립트 실행 중...${nc}"
source ./scripts/06_check_keyvault_resources.sh

# AKS 클러스터 리소스 체크 스크립트 실행
echo -e "${yellow}AKS 클러스터 리소스 체크 스크립트 실행 중...${nc}"
source ./scripts/07_check_aks_resources.sh

# 애플리케이션 게이트웨이 리소스 체크 스크립트 실행
echo -e "${yellow}애플리케이션 게이트웨이 리소스 체크 스크립트 실행 중...${nc}"
source ./scripts/08_check_appgw_resources.sh

# 모니터링 리소스 체크 스크립트 실행
echo -e "${yellow}모니터링 리소스 체크 스크립트 실행 중...${nc}"
source ./scripts/09_check_monitoring_resources.sh

# 데이터베이스 리소스 체크 스크립트 실행
echo -e "${yellow}데이터베이스 리소스 체크 스크립트 실행 중...${nc}"
source ./scripts/10_check_database_resources.sh

# 기존 리소스 가져오기 스크립트 실행
echo -e "${yellow}기존 리소스 가져오기 스크립트 실행 중...${nc}"
source ./scripts/11_import_existing_resources.sh

# 모듈 배포 스크립트 실행
echo -e "${yellow}모듈 배포 스크립트 실행 중...${nc}"
source ./scripts/21_deploy_modules.sh

# 실패한 모듈 재배포 스크립트 실행
echo -e "${yellow}실패한 모듈 재배포 스크립트 실행 중...${nc}"
source ./scripts/22_redeploy_module.sh

# 배포 완료 메시지 출력
echo -e "\n${green}배포가 완료되었습니다.${nc}" 