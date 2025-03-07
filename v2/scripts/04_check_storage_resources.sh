#!/bin/bash
# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}4단계: Azure 스토리지 리소스 존재 여부 확인${NC}"

# 재시도 함수 정의
function retry {
  local max_attempts=$1
  local delay=$2
  local attempts=0
  shift 2

  until "$@"; do
    attempts=$((attempts + 1))
    if [[ $attempts -ge $max_attempts ]]; then
      echo -e "${RED}명령 실행 실패: $@${NC}"
      return 1
    fi
    echo -e "${YELLOW}명령 실행 실패, ${delay}초 후 재시도 중... (${attempts}/${max_attempts})${NC}"
    sleep $delay
  done
}

# terraform.tfvars 파일에서 변수 값 가져오기
STORAGE_RG=$(grep "storage_rg" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
STORAGE_ACCOUNT=$(grep "storage_account_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
FILE_SHARE_NAME=$(grep "file_share_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "aksshare")
STORAGE_VNET=$(grep "storage_vnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
STORAGE_SUBNET=$(grep "storage_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "' 2>/dev/null || echo "storage-subnet")

# 스토리지 계정 존재 여부 확인
echo -e "\n${YELLOW}스토리지 계정 확인 중...${NC}"
STORAGE_ACCOUNT_EXISTS=false
FILE_SHARE_EXISTS=false
STORAGE_SUBNET_EXISTS=false
PRIVATE_ENDPOINT_EXISTS=false

STORAGE_RG_EXISTS=$(az group exists --name $STORAGE_RG)
if [ "$STORAGE_RG_EXISTS" == "true" ]; then
  STORAGE_ACCOUNT_CHECK=$(retry 3 5 az storage account list --resource-group $STORAGE_RG --query "[?name=='$STORAGE_ACCOUNT'].name" -o tsv)
  if [ -n "$STORAGE_ACCOUNT_CHECK" ]; then
    STORAGE_ACCOUNT_EXISTS=true
    echo -e "스토리지 계정(${STORAGE_ACCOUNT}) 존재함: ${STORAGE_ACCOUNT_CHECK}"
    
    # 스토리지 계정 속성 확인
    echo -e "\n${YELLOW}스토리지 계정 속성 확인 중...${NC}"
    STORAGE_ACCOUNT_PROPS=$(retry 3 5 az storage account show --name $STORAGE_ACCOUNT --resource-group $STORAGE_RG --query "{sku:sku.name, kind:kind, accessTier:accessTier, httpsOnly:enableHttpsTrafficOnly, networkRuleSet:networkRuleSet.defaultAction}" -o json)
    echo -e "스토리지 계정 속성: ${STORAGE_ACCOUNT_PROPS}"
    
    # 파일 공유 확인
    echo -e "\n${YELLOW}파일 공유 확인 중...${NC}"
    # 스토리지 계정 키 가져오기
    STORAGE_KEY=$(retry 3 5 az storage account keys list --resource-group $STORAGE_RG --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)
    
    if [ -n "$STORAGE_KEY" ]; then
      FILE_SHARE_CHECK=$(retry 3 5 az storage share exists --name $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT --account-key "$STORAGE_KEY" --query "exists" -o tsv)
      
      if [ "$FILE_SHARE_CHECK" == "true" ]; then
        FILE_SHARE_EXISTS=true
        echo -e "파일 공유(${FILE_SHARE_NAME}) 존재함"
        
        # 파일 공유 속성 확인
        FILE_SHARE_PROPS=$(retry 3 5 az storage share show --name $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT --account-key "$STORAGE_KEY" --query "{quota:quota, metadata:metadata}" -o json)
        echo -e "파일 공유 속성: ${FILE_SHARE_PROPS}"
      else
        echo -e "파일 공유(${FILE_SHARE_NAME}) 존재하지 않음"
      fi
    else
      echo -e "${RED}스토리지 계정 키를 가져올 수 없습니다.${NC}"
    fi
    
    # 프라이빗 엔드포인트 확인
    echo -e "\n${YELLOW}프라이빗 엔드포인트 확인 중...${NC}"
    PRIVATE_ENDPOINT_CHECK=$(retry 3 5 az network private-endpoint list --resource-group $STORAGE_RG --query "[?contains(name, '${STORAGE_ACCOUNT}')].name" -o tsv)
    
    if [ -n "$PRIVATE_ENDPOINT_CHECK" ]; then
      PRIVATE_ENDPOINT_EXISTS=true
      echo -e "프라이빗 엔드포인트 존재함: ${PRIVATE_ENDPOINT_CHECK}"
      
      # 프라이빗 엔드포인트 속성 확인
      PRIVATE_ENDPOINT_PROPS=$(retry 3 5 az network private-endpoint show --name $PRIVATE_ENDPOINT_CHECK --resource-group $STORAGE_RG --query "{subnet:subnet.id, privateLinkServiceConnections:privateLinkServiceConnections[0].name}" -o json)
      echo -e "프라이빗 엔드포인트 속성: ${PRIVATE_ENDPOINT_PROPS}"
    else
      echo -e "프라이빗 엔드포인트 존재하지 않음"
    fi
  else
    echo -e "스토리지 계정(${STORAGE_ACCOUNT}) 존재하지 않음"
  fi
  
  # 스토리지 서브넷 확인
  if [ -n "$STORAGE_VNET" ]; then
    STORAGE_VNET_CHECK=$(retry 3 5 az network vnet list --resource-group $STORAGE_RG --query "[?name=='$STORAGE_VNET'].name" -o tsv)
    
    if [ -n "$STORAGE_VNET_CHECK" ]; then
      STORAGE_SUBNET_CHECK=$(retry 3 5 az network vnet subnet list --resource-group $STORAGE_RG --vnet-name $STORAGE_VNET --query "[?name=='$STORAGE_SUBNET'].name" -o tsv)
      
      if [ -n "$STORAGE_SUBNET_CHECK" ]; then
        STORAGE_SUBNET_EXISTS=true
        echo -e "스토리지 서브넷(${STORAGE_SUBNET}) 존재함: ${STORAGE_SUBNET_CHECK}"
      else
        echo -e "스토리지 서브넷(${STORAGE_SUBNET}) 존재하지 않음"
      fi
    fi
  fi
fi

# 스토리지 계정 설정 업데이트
if [ "$STORAGE_ACCOUNT_EXISTS" == "true" ] && [ "$FILE_SHARE_EXISTS" == "true" ]; then
  echo -e "${YELLOW}스토리지 계정과 파일 공유가 이미 존재합니다. 기존 스토리지 리소스를 사용하도록 설정합니다...${NC}"
  sed -i 's/use_existing_storage = false/use_existing_storage = true/g' terraform.tfvars
  sed -i 's/use_existing_file_share = false/use_existing_file_share = true/g' terraform.tfvars
  
  # Terraform 상태로 기존 리소스 가져오기
  echo -e "\n${YELLOW}기존 스토리지 리소스를 Terraform 상태로 가져옵니다...${NC}"
  
  # 상태 파일에 이미 있는지 확인
  TERRAFORM_STATE=$(terraform state list 2>/dev/null || echo "")
  
  # 스토리지 계정 가져오기 - 데이터 소스로 참조
  if [ "$STORAGE_ACCOUNT_EXISTS" == "true" ]; then
    echo -e "${YELLOW}스토리지 계정은 이미 존재합니다. 데이터 소스로 참조됩니다.${NC}"
    # 데이터 소스는 import 할 수 없으므로 import 시도하지 않음
  fi
  
  # 파일 공유 가져오기 - 데이터 소스로 참조
  if [ "$FILE_SHARE_EXISTS" == "true" ]; then
    echo -e "${YELLOW}파일 공유는 이미 존재합니다. 데이터 소스로 참조됩니다.${NC}"
    # 데이터 소스는 import 할 수 없으므로 import 시도하지 않음
  fi
  
  # 프라이빗 엔드포인트 가져오기 - 실제 리소스인 경우에만 import
  if [ "$PRIVATE_ENDPOINT_EXISTS" == "true" ] && [[ ! "$TERRAFORM_STATE" =~ "module.storage.azurerm_private_endpoint.storage_pe" ]]; then
    # 모듈에 실제 리소스가 있는지 확인
    if grep -q "resource \"azurerm_private_endpoint\" \"storage_pe\"" modules/storage/main.tf; then
      echo -e "${YELLOW}프라이빗 엔드포인트를 Terraform 상태로 가져옵니다...${NC}"
      terraform import -var-file=terraform.tfvars module.storage.azurerm_private_endpoint.storage_pe[0] /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$STORAGE_RG/providers/Microsoft.Network/privateEndpoints/$PRIVATE_ENDPOINT_CHECK || echo "프라이빗 엔드포인트 가져오기 실패"
    else
      echo -e "${YELLOW}프라이빗 엔드포인트는 데이터 소스로 참조되거나 모듈에 정의되지 않았습니다.${NC}"
    fi
  fi
  
  # 스토리지 서브넷 가져오기 - 실제 리소스인 경우에만 import
  if [ "$STORAGE_SUBNET_EXISTS" == "true" ] && [[ ! "$TERRAFORM_STATE" =~ "module.storage.azurerm_subnet.storage_subnet" ]]; then
    # 모듈에 실제 리소스가 있는지 확인
    if grep -q "resource \"azurerm_subnet\" \"storage_subnet\"" modules/storage/main.tf; then
      echo -e "${YELLOW}스토리지 서브넷을 Terraform 상태로 가져옵니다...${NC}"
      terraform import -var-file=terraform.tfvars module.storage.azurerm_subnet.storage_subnet[0] /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$STORAGE_RG/providers/Microsoft.Network/virtualNetworks/$STORAGE_VNET/subnets/$STORAGE_SUBNET || echo "스토리지 서브넷 가져오기 실패"
    else
      echo -e "${YELLOW}스토리지 서브넷은 데이터 소스로 참조되거나 모듈에 정의되지 않았습니다.${NC}"
    fi
  fi
elif [ "$STORAGE_ACCOUNT_EXISTS" == "true" ] && [ "$FILE_SHARE_EXISTS" == "false" ]; then
  echo -e "${YELLOW}스토리지 계정은 존재하지만 파일 공유가 없습니다. 기존 스토리지 계정을 사용하고 새 파일 공유를 생성하도록 설정합니다...${NC}"
  sed -i 's/use_existing_storage = false/use_existing_storage = true/g' terraform.tfvars
  sed -i 's/use_existing_file_share = true/use_existing_file_share = false/g' terraform.tfvars
else
  echo -e "${YELLOW}스토리지 계정이 존재하지 않습니다. 새 스토리지 계정을 생성하도록 설정합니다...${NC}"
  sed -i 's/use_existing_storage = true/use_existing_storage = false/g' terraform.tfvars
  sed -i 's/use_existing_file_share = true/use_existing_file_share = false/g' terraform.tfvars
fi

# 현재 설정 확인
USE_EXISTING_STORAGE=$(grep "use_existing_storage" terraform.tfvars | grep -o "true\|false")
USE_EXISTING_FILE_SHARE=$(grep "use_existing_file_share" terraform.tfvars | grep -o "true\|false" 2>/dev/null || echo "false")
echo -e "use_existing_storage 설정이 ${USE_EXISTING_STORAGE}로 설정되었습니다."
echo -e "use_existing_file_share 설정이 ${USE_EXISTING_FILE_SHARE}로 설정되었습니다."

# 리소스 존재 여부 요약
echo -e "\n${YELLOW}스토리지 리소스 존재 여부 요약:${NC}"
echo -e "스토리지 계정 존재 여부: ${STORAGE_ACCOUNT_EXISTS}"
echo -e "파일 공유 존재 여부: ${FILE_SHARE_EXISTS}"
echo -e "스토리지 서브넷 존재 여부: ${STORAGE_SUBNET_EXISTS}"
echo -e "프라이빗 엔드포인트 존재 여부: ${PRIVATE_ENDPOINT_EXISTS}"

echo -e "${GREEN}스토리지 리소스 확인 완료${NC}"
