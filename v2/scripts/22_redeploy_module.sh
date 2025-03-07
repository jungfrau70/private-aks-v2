#!/bin/bash
# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 사용법 확인
if [ $# -lt 1 ]; then
  echo -e "${YELLOW}사용법: $0 <모듈_이름>${NC}"
  echo -e "사용 가능한 모듈 이름:"
  echo -e "  azure_ad, network, storage, central_acr, central_keyvault,"
  echo -e "  app_gateway, monitoring, bastion, jumpbox, aks_clusters,"
  echo -e "  database, app"
  exit 1
fi

MODULE_NAME=$1

echo -e "${GREEN}${MODULE_NAME} 모듈 재배포 시작${NC}"

# 모듈 이름에 따라 적절한 타겟 옵션 설정
case $MODULE_NAME in
  azure_ad)
    TARGET_OPTION="-target=module.azure_ad"
    ;;
  network)
    TARGET_OPTION="-target=module.network"
    ;;
  storage)
    TARGET_OPTION="-target=module.storage"
    ;;
  central_acr)
    TARGET_OPTION="-target=module.central_acr"
    # ACR 모듈 재배포 전에 ACR 리소스 확인 스크립트 실행
    echo -e "${YELLOW}ACR 리소스 확인 중...${NC}"
    ./05_check_acr_resources.sh
    ;;
  central_keyvault)
    TARGET_OPTION="-target=module.central_keyvault"
    ;;
  app_gateway)
    TARGET_OPTION="-target=module.app_gateway"
    ;;
  monitoring)
    TARGET_OPTION="-target=module.monitoring"
    ;;
  bastion)
    TARGET_OPTION="-target=module.bastion"
    ;;
  jumpbox)
    TARGET_OPTION="-target=module.jumpbox"
    ;;
  aks_clusters)
    TARGET_OPTION="-target=module.aks_clusters"
    ;;
  database)
    TARGET_OPTION="-target=module.database"
    ;;
  app)
    TARGET_OPTION="-target=module.app"
    ;;
  *)
    echo -e "${RED}오류: 알 수 없는 모듈 이름 '${MODULE_NAME}'${NC}"
    exit 1
    ;;
esac

# 모듈 재배포
echo -e "${YELLOW}${MODULE_NAME} 모듈을 재배포합니다...${NC}"
terraform apply $TARGET_OPTION -auto-approve

if [ $? -eq 0 ]; then
  echo -e "${GREEN}${MODULE_NAME} 모듈 재배포 완료${NC}"
else
  echo -e "${RED}${MODULE_NAME} 모듈 재배포 실패${NC}"
  exit 1
fi

echo -e "${GREEN}재배포가 완료되었습니다. 전체 인프라 상태를 확인하려면 다음 명령을 실행하세요:${NC}"
echo -e "${YELLOW}terraform plan${NC}"
