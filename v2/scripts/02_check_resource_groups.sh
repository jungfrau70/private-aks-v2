#!/bin/bash
# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}2단계: Azure 리소스 그룹 존재 여부 확인${NC}"

# terraform.tfvars 파일에서 변수 값 가져오기
LOCATION=$(grep "location" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
HUB_RG=$(grep "resource_group_name_hub" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
SPOKE_RG=$(grep "resource_group_name_spoke" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
STORAGE_RG=$(grep "resource_group_name_storage" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')

echo -e "${YELLOW}Azure에서 리소스 그룹 존재 여부를 직접 확인합니다...${NC}"

# 리소스 그룹 존재 여부 확인
echo -e "\n${YELLOW}리소스 그룹 확인 중...${NC}"
HUB_RG_EXISTS=$(az group exists --name $HUB_RG)
SPOKE_RG_EXISTS=$(az group exists --name $SPOKE_RG)
STORAGE_RG_EXISTS=$(az group exists --name $STORAGE_RG)

echo -e "Hub 리소스 그룹(${HUB_RG}) 존재 여부: ${HUB_RG_EXISTS}"
echo -e "Spoke 리소스 그룹(${SPOKE_RG}) 존재 여부: ${SPOKE_RG_EXISTS}"
echo -e "Storage 리소스 그룹(${STORAGE_RG}) 존재 여부: ${STORAGE_RG_EXISTS}"

# 리소스 그룹 생성 또는 사용 설정
if [ "$HUB_RG_EXISTS" == "true" ] && [ "$SPOKE_RG_EXISTS" == "true" ] && [ "$STORAGE_RG_EXISTS" == "true" ]; then
  echo -e "${YELLOW}모든 리소스 그룹이 이미 존재합니다. 기존 리소스 그룹을 사용하도록 설정합니다...${NC}"
  sed -i 's/use_existing_resource_group_hub = false/use_existing_resource_group_hub = true/g' terraform.tfvars
  sed -i 's/use_existing_resource_group_spoke = false/use_existing_resource_group_spoke = true/g' terraform.tfvars
  sed -i 's/use_existing_resource_group_storage = false/use_existing_resource_group_storage = true/g' terraform.tfvars
else
  # 존재하지 않는 리소스 그룹 생성
  echo -e "${YELLOW}일부 또는 모든 리소스 그룹이 존재하지 않습니다. 필요한 리소스 그룹을 생성합니다...${NC}"
  
  if [ "$HUB_RG_EXISTS" == "false" ]; then
    echo -e "${YELLOW}Hub 리소스 그룹(${HUB_RG})을 생성합니다...${NC}"
    az group create --name $HUB_RG --location $LOCATION
    HUB_RG_EXISTS="true"
    sed -i 's/use_existing_resource_group_hub = false/use_existing_resource_group_hub = true/g' terraform.tfvars
  else
    sed -i 's/use_existing_resource_group_hub = false/use_existing_resource_group_hub = true/g' terraform.tfvars
  fi
  
  if [ "$SPOKE_RG_EXISTS" == "false" ]; then
    echo -e "${YELLOW}Spoke 리소스 그룹(${SPOKE_RG})을 생성합니다...${NC}"
    az group create --name $SPOKE_RG --location $LOCATION
    SPOKE_RG_EXISTS="true"
    sed -i 's/use_existing_resource_group_spoke = false/use_existing_resource_group_spoke = true/g' terraform.tfvars
  else
    sed -i 's/use_existing_resource_group_spoke = false/use_existing_resource_group_spoke = true/g' terraform.tfvars
  fi
  
  if [ "$STORAGE_RG_EXISTS" == "false" ]; then
    echo -e "${YELLOW}Storage 리소스 그룹(${STORAGE_RG})을 생성합니다...${NC}"
    az group create --name $STORAGE_RG --location $LOCATION
    STORAGE_RG_EXISTS="true"
    sed -i 's/use_existing_resource_group_storage = false/use_existing_resource_group_storage = true/g' terraform.tfvars
  else
    sed -i 's/use_existing_resource_group_storage = false/use_existing_resource_group_storage = true/g' terraform.tfvars
  fi
fi

# 현재 설정 확인
HUB_RG_SETTING=$(grep "use_existing_resource_group_hub" terraform.tfvars | grep -o "true\|false")
SPOKE_RG_SETTING=$(grep "use_existing_resource_group_spoke" terraform.tfvars | grep -o "true\|false")
STORAGE_RG_SETTING=$(grep "use_existing_resource_group_storage" terraform.tfvars | grep -o "true\|false")

echo -e "use_existing_resource_group_hub 설정이 ${HUB_RG_SETTING}로 설정되었습니다."
echo -e "use_existing_resource_group_spoke 설정이 ${SPOKE_RG_SETTING}로 설정되었습니다."
echo -e "use_existing_resource_group_storage 설정이 ${STORAGE_RG_SETTING}로 설정되었습니다."
echo -e "${GREEN}리소스 그룹 확인 완료${NC}"
