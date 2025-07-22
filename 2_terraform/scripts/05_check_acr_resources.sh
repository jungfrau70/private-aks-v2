#!/bin/bash
# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}5단계: Azure Container Registry 리소스 존재 여부 확인${NC}"

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
ACR_RG=$(grep "acr_resource_group_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
ACR_NAME=$(grep "acr_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
SPOKE_RG=$(grep "resource_group_name_spoke" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
ENDPOINTS_SUBNET=$(grep "endpoints_subnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')
SPOKE_VNET=$(grep "spoke_vnet_name" terraform.tfvars | cut -d "=" -f2 | tr -d ' "')

# ACR 존재 여부 확인
echo -e "\n${YELLOW}ACR 리소스 확인 중...${NC}"
ACR_EXISTS=false
ACR_PE_EXISTS=false
ACR_DNS_ZONE_EXISTS=false
ACR_DNS_LINK_EXISTS=false

# ACR 이름 전역 유일성 확인
echo -e "\n${YELLOW}ACR 이름 전역 유일성 확인 중...${NC}"
ACR_NAME_CHECK=$(retry 3 5 az acr check-name --name $ACR_NAME --query "nameAvailable" -o tsv)

if [ "$ACR_NAME_CHECK" == "false" ]; then
  echo -e "${RED}ACR 이름 '${ACR_NAME}'은 이미 사용 중입니다. 다른 이름을 선택해야 합니다.${NC}"
  
  # 이미 사용 중인 ACR 이름의 소유자 확인
  ACR_EXISTS_GLOBALLY=true
  
  # 현재 구독에서 해당 이름의 ACR 찾기
  EXISTING_ACR_ID=$(retry 3 5 az acr list --query "[?name=='$ACR_NAME'].id" -o tsv)
  
  if [ -n "$EXISTING_ACR_ID" ]; then
    EXISTING_ACR_RG=$(echo $EXISTING_ACR_ID | cut -d'/' -f5)
    echo -e "${YELLOW}ACR '${ACR_NAME}'은 현재 구독의 리소스 그룹 '${EXISTING_ACR_RG}'에 존재합니다.${NC}"
    
    # 현재 지정된 리소스 그룹과 일치하는지 확인
    if [ "$EXISTING_ACR_RG" == "$ACR_RG" ]; then
      ACR_EXISTS=true
      echo -e "${GREEN}ACR은 지정된 리소스 그룹에 존재합니다. 기존 ACR을 사용합니다.${NC}"
    else
      echo -e "${RED}ACR은 다른 리소스 그룹에 존재합니다. terraform.tfvars의 acr_resource_group_name을 '${EXISTING_ACR_RG}'로 업데이트하는 것이 좋습니다.${NC}"
      # 리소스 그룹 업데이트
      sed -i "s/acr_resource_group_name = \"$ACR_RG\"/acr_resource_group_name = \"$EXISTING_ACR_RG\"/g" terraform.tfvars
      ACR_RG=$EXISTING_ACR_RG
      ACR_EXISTS=true
    fi
  else
    echo -e "${RED}ACR '${ACR_NAME}'은 다른 Azure 구독에서 사용 중입니다. 다른 이름을 선택해야 합니다.${NC}"
    # 새 ACR 이름 생성 (원래 이름 + 랜덤 문자열)
    NEW_ACR_NAME="${ACR_NAME}$(date +%s | sha256sum | base64 | head -c 5)"
    echo -e "${YELLOW}새 ACR 이름 '${NEW_ACR_NAME}'을 제안합니다.${NC}"
    
    # 새 이름이 사용 가능한지 확인
    NEW_ACR_NAME_CHECK=$(retry 3 5 az acr check-name --name $NEW_ACR_NAME --query "nameAvailable" -o tsv)
    if [ "$NEW_ACR_NAME_CHECK" == "true" ]; then
      echo -e "${GREEN}새 ACR 이름 '${NEW_ACR_NAME}'은 사용 가능합니다.${NC}"
      # terraform.tfvars 파일 업데이트
      sed -i "s/acr_name = \"$ACR_NAME\"/acr_name = \"$NEW_ACR_NAME\"/g" terraform.tfvars
      ACR_NAME=$NEW_ACR_NAME
    else
      echo -e "${RED}새 ACR 이름 '${NEW_ACR_NAME}'도 사용할 수 없습니다. 수동으로 고유한 이름을 지정해야 합니다.${NC}"
    fi
  fi
else
  echo -e "${GREEN}ACR 이름 '${ACR_NAME}'은 사용 가능합니다.${NC}"
fi

# 리소스 그룹 존재 여부 확인
ACR_RG_EXISTS=$(az group exists --name $ACR_RG)

if [ "$ACR_RG_EXISTS" == "true" ]; then
  # ACR 존재 여부 확인
  if [ "$ACR_EXISTS" != "true" ]; then
    ACR_CHECK=$(retry 3 5 az acr list --resource-group $ACR_RG --query "[?name=='$ACR_NAME'].name" -o tsv)
    if [ -n "$ACR_CHECK" ]; then
      ACR_EXISTS=true
      echo -e "ACR(${ACR_NAME}) 존재함: ${ACR_CHECK}"
      
      # ACR 속성 확인
      echo -e "\n${YELLOW}ACR 속성 확인 중...${NC}"
      ACR_PROPS=$(retry 3 5 az acr show --name $ACR_NAME --resource-group $ACR_RG --query "{sku:sku.name, adminEnabled:adminUserEnabled, networkRuleSet:networkRuleSet.defaultAction}" -o json)
      echo -e "ACR 속성: ${ACR_PROPS}"
    else
      echo -e "ACR(${ACR_NAME}) 존재하지 않음"
    fi
  fi
  
  # ACR 프라이빗 엔드포인트 확인
  echo -e "\n${YELLOW}ACR 프라이빗 엔드포인트 확인 중...${NC}"
  ACR_PE_CHECK=$(retry 3 5 az network private-endpoint list --resource-group $SPOKE_RG --query "[?contains(name, '${ACR_NAME}')].name" -o tsv)
  
  if [ -n "$ACR_PE_CHECK" ]; then
    ACR_PE_EXISTS=true
    echo -e "ACR 프라이빗 엔드포인트 존재함: ${ACR_PE_CHECK}"
    
    # 프라이빗 엔드포인트 속성 확인
    ACR_PE_PROPS=$(retry 3 5 az network private-endpoint show --name $ACR_PE_CHECK --resource-group $SPOKE_RG --query "{subnet:subnet.id, privateLinkServiceConnections:privateLinkServiceConnections[0].name}" -o json)
    echo -e "ACR 프라이빗 엔드포인트 속성: ${ACR_PE_PROPS}"
  else
    echo -e "ACR 프라이빗 엔드포인트 존재하지 않음"
  fi
  
  # ACR DNS 영역 확인
  echo -e "\n${YELLOW}ACR DNS 영역 확인 중...${NC}"
  ACR_DNS_ZONE_CHECK=$(retry 3 5 az network private-dns zone list --resource-group $SPOKE_RG --query "[?name=='privatelink.azurecr.io'].name" -o tsv)
  
  if [ -n "$ACR_DNS_ZONE_CHECK" ]; then
    ACR_DNS_ZONE_EXISTS=true
    echo -e "ACR DNS 영역 존재함: ${ACR_DNS_ZONE_CHECK}"
    
    # DNS 영역 링크 확인
    ACR_DNS_LINK_CHECK=$(retry 3 5 az network private-dns link vnet list --resource-group $SPOKE_RG --zone-name privatelink.azurecr.io --query "[?contains(virtualNetwork.id, '${SPOKE_VNET}')].name" -o tsv)
    
    if [ -n "$ACR_DNS_LINK_CHECK" ]; then
      ACR_DNS_LINK_EXISTS=true
      echo -e "ACR DNS 영역 링크 존재함: ${ACR_DNS_LINK_CHECK}"
    else
      echo -e "ACR DNS 영역 링크 존재하지 않음"
    fi
  else
    echo -e "ACR DNS 영역 존재하지 않음"
  fi
fi

# ACR 설정 업데이트
echo -e "\n${YELLOW}ACR 리소스 설정을 업데이트합니다...${NC}"

if [ "$ACR_EXISTS" == "true" ]; then
  echo -e "${YELLOW}ACR이 이미 존재합니다. 기존 ACR을 사용하도록 설정합니다...${NC}"
  sed -i 's/use_existing_acr = false/use_existing_acr = true/g' terraform.tfvars
  
  # Terraform 상태로 기존 리소스 가져오기
  echo -e "\n${YELLOW}기존 ACR 리소스를 Terraform 상태로 가져옵니다...${NC}"
  
  # 상태 파일에 이미 있는지 확인
  TERRAFORM_STATE=$(terraform state list 2>/dev/null || echo "")
  
  # ACR 가져오기 - 실제 리소스인 경우에만 import
  if [ "$ACR_EXISTS" == "true" ] && [[ ! "$TERRAFORM_STATE" =~ "module.acr.azurerm_container_registry.acr" ]]; then
    # 모듈에 실제 리소스가 있는지 확인
    if grep -q "resource \"azurerm_container_registry\" \"acr\"" modules/acr/main.tf; then
      echo -e "${YELLOW}ACR을 Terraform 상태로 가져옵니다...${NC}"
      terraform import -var-file=terraform.tfvars module.acr.azurerm_container_registry.acr[0] /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ACR_RG/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME || echo "ACR 가져오기 실패"
    else
      echo -e "${YELLOW}ACR은 데이터 소스로 참조되거나 모듈에 정의되지 않았습니다.${NC}"
    fi
  fi
  
  # ACR 프라이빗 엔드포인트 가져오기 - 실제 리소스인 경우에만 import
  if [ "$ACR_PE_EXISTS" == "true" ] && [[ ! "$TERRAFORM_STATE" =~ "module.acr.azurerm_private_endpoint.acr_pe" ]]; then
    # 모듈에 실제 리소스가 있는지 확인
    if grep -q "resource \"azurerm_private_endpoint\" \"acr_pe\"" modules/acr/main.tf; then
      echo -e "${YELLOW}ACR 프라이빗 엔드포인트를 Terraform 상태로 가져옵니다...${NC}"
      terraform import -var-file=terraform.tfvars module.acr.azurerm_private_endpoint.acr_pe[0] /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$SPOKE_RG/providers/Microsoft.Network/privateEndpoints/$ACR_PE_CHECK || echo "ACR 프라이빗 엔드포인트 가져오기 실패"
    else
      echo -e "${YELLOW}ACR 프라이빗 엔드포인트는 데이터 소스로 참조되거나 모듈에 정의되지 않았습니다.${NC}"
    fi
  fi
  
  # ACR DNS 영역 가져오기 - 실제 리소스인 경우에만 import
  if [ "$ACR_DNS_ZONE_EXISTS" == "true" ] && [[ ! "$TERRAFORM_STATE" =~ "module.acr.azurerm_private_dns_zone.acr_dns" ]]; then
    # 모듈에 실제 리소스가 있는지 확인
    if grep -q "resource \"azurerm_private_dns_zone\" \"acr_dns\"" modules/acr/main.tf; then
      echo -e "${YELLOW}ACR DNS 영역을 Terraform 상태로 가져옵니다...${NC}"
      terraform import -var-file=terraform.tfvars module.acr.azurerm_private_dns_zone.acr_dns[0] /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$SPOKE_RG/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io || echo "ACR DNS 영역 가져오기 실패"
    else
      echo -e "${YELLOW}ACR DNS 영역은 데이터 소스로 참조되거나 모듈에 정의되지 않았습니다.${NC}"
    fi
  fi
  
  # ACR DNS 영역 링크 가져오기 - 실제 리소스인 경우에만 import
  if [ "$ACR_DNS_LINK_EXISTS" == "true" ] && [[ ! "$TERRAFORM_STATE" =~ "module.acr.azurerm_private_dns_zone_virtual_network_link.acr_dns_link" ]]; then
    # 모듈에 실제 리소스가 있는지 확인
    if grep -q "resource \"azurerm_private_dns_zone_virtual_network_link\" \"acr_dns_link\"" modules/acr/main.tf; then
      echo -e "${YELLOW}ACR DNS 영역 링크를 Terraform 상태로 가져옵니다...${NC}"
      terraform import -var-file=terraform.tfvars module.acr.azurerm_private_dns_zone_virtual_network_link.acr_dns_link[0] /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$SPOKE_RG/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io/virtualNetworkLinks/$ACR_DNS_LINK_CHECK || echo "ACR DNS 영역 링크 가져오기 실패"
    else
      echo -e "${YELLOW}ACR DNS 영역 링크는 데이터 소스로 참조되거나 모듈에 정의되지 않았습니다.${NC}"
    fi
  fi
else
  echo -e "${YELLOW}ACR이 존재하지 않습니다. 새 ACR을 생성하도록 설정합니다...${NC}"
  sed -i 's/use_existing_acr = true/use_existing_acr = false/g' terraform.tfvars
fi

# 현재 설정 확인
USE_EXISTING_ACR=$(grep "use_existing_acr" terraform.tfvars | grep -o "true\|false")
echo -e "use_existing_acr 설정이 ${USE_EXISTING_ACR}로 설정되었습니다."

# 리소스 존재 여부 요약
echo -e "\n${YELLOW}ACR 리소스 존재 여부 요약:${NC}"
echo -e "ACR 존재 여부: ${ACR_EXISTS}"
echo -e "ACR 프라이빗 엔드포인트 존재 여부: ${ACR_PE_EXISTS}"
echo -e "ACR DNS 영역 존재 여부: ${ACR_DNS_ZONE_EXISTS}"
echo -e "ACR DNS 영역 링크 존재 여부: ${ACR_DNS_LINK_EXISTS}"

echo -e "${GREEN}ACR 리소스 확인 완료${NC}"
