#!/bin/bash
# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Windows Git Bash 환경에서 경로 변환 방지
export MSYS_NO_PATHCONV=1

echo -e "\n${YELLOW}테라폼 모듈 배포 작업을 시작합니다...${NC}"

# 먼저 리소스 그룹 배포 스크립트 실행
echo -e "\n${GREEN}리소스 그룹 배포 스크립트 실행 중...${NC}"
./v2/scripts/20_deploy_resource_groups.sh

# 리소스 그룹 배포 결과 확인
if [ $? -ne 0 ]; then
  echo -e "${RED}리소스 그룹 배포에 실패했습니다. 배포를 중단합니다.${NC}"
  exit 1
fi

echo -e "${GREEN}6단계: 모듈 배포 시작${NC}"

# 모듈 배포 함수 정의
deploy_module() {
  local module_name=$1
  local target_option=$2
  local max_retries=3
  local retry_count=0
  local success=false

  echo -e "${GREEN}${module_name} 모듈 배포${NC}"
  
  while [ $retry_count -lt $max_retries ] && [ "$success" != "true" ]; do
    terraform apply $target_option -auto-approve
    
    if [ $? -eq 0 ]; then
      success=true
      echo -e "${GREEN}${module_name} 모듈 배포 완료${NC}"
    else
      retry_count=$((retry_count + 1))
      
      if [ $retry_count -lt $max_retries ]; then
        echo -e "${YELLOW}${module_name} 모듈 배포 실패. 재시도 중... (${retry_count}/${max_retries})${NC}"
        
        # ACR 모듈인 경우 특별 처리
        if [[ "$module_name" == "ACR" ]]; then
          echo -e "${YELLOW}ACR 이름 충돌 가능성이 있습니다. 기존 ACR을 사용하도록 설정합니다...${NC}"
          sed -i 's/use_existing_acr = false/use_existing_acr = true/g' terraform.tfvars
          
          # ACR 리소스 확인 스크립트 다시 실행
          ../05_check_acr_resources.sh
        fi
        
        sleep 5
      else
        echo -e "${RED}${module_name} 모듈 배포 실패. 최대 재시도 횟수에 도달했습니다.${NC}"
        return 1
      fi
    fi
  done
  
  return 0
}

# Azure AD 모듈 배포
deploy_module "Azure AD" "-target=module.azure_ad"
if [ $? -ne 0 ]; then
  echo -e "${RED}Azure AD 모듈 배포 실패${NC}"
  exit 1
fi

# 네트워크 모듈 배포
deploy_module "네트워크" "-target=module.network"
if [ $? -ne 0 ]; then
  echo -e "${RED}네트워크 모듈 배포 실패${NC}"
  exit 1
fi

# 스토리지 모듈 배포
deploy_module "스토리지" "-target=module.storage"
if [ $? -ne 0 ]; then
  echo -e "${RED}스토리지 모듈 배포 실패${NC}"
  exit 1
fi

# ACR 모듈 배포
deploy_module "ACR" "-target=module.central_acr"
if [ $? -ne 0 ]; then
  echo -e "${RED}ACR 모듈 배포 실패${NC}"
  exit 1
fi

# KeyVault 모듈 배포
deploy_module "KeyVault" "-target=module.central_keyvault"
if [ $? -ne 0 ]; then
  echo -e "${RED}KeyVault 모듈 배포 실패${NC}"
  exit 1
fi

# Application Gateway 모듈 배포
deploy_module "Application Gateway" "-target=module.app_gateway"
if [ $? -ne 0 ]; then
  echo -e "${RED}Application Gateway 모듈 배포 실패${NC}"
  exit 1
fi

# 모니터링 모듈 배포
deploy_module "모니터링" "-target=module.monitoring"
if [ $? -ne 0 ]; then
  echo -e "${RED}모니터링 모듈 배포 실패${NC}"
  exit 1
fi

# Bastion 및 Jumpbox 모듈 배포
deploy_module "Bastion 및 Jumpbox" "-target=module.bastion -target=module.jumpbox"
if [ $? -ne 0 ]; then
  echo -e "${RED}Bastion 및 Jumpbox 모듈 배포 실패${NC}"
  exit 1
fi

# AKS 클러스터 모듈 배포
deploy_module "AKS 클러스터" "-target=module.aks_clusters"
if [ $? -ne 0 ]; then
  echo -e "${RED}AKS 클러스터 모듈 배포 실패${NC}"
  exit 1
fi

# 데이터베이스 모듈 배포
deploy_module "데이터베이스" "-target=module.database"
if [ $? -ne 0 ]; then
  echo -e "${RED}데이터베이스 모듈 배포 실패${NC}"
  exit 1
fi

# 애플리케이션 모듈 배포
deploy_module "애플리케이션" "-target=module.app"
if [ $? -ne 0 ]; then
  echo -e "${RED}애플리케이션 모듈 배포 실패${NC}"
  exit 1
fi

# 전체 인프라 검증
echo -e "${GREEN}전체 인프라 검증${NC}"
terraform apply -auto-approve
if [ $? -ne 0 ]; then
  echo -e "${RED}전체 인프라 검증 실패${NC}"
  exit 1
fi
echo -e "${GREEN}전체 인프라 검증 완료${NC}"

echo -e "${GREEN}모든 리소스가 성공적으로 배포되었습니다!${NC}"
