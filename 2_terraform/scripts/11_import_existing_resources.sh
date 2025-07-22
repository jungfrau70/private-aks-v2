#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# Windows Git Bash 환경에서 경로 변환 방지
export MSYS_NO_PATHCONV=1

echo -e "\n${yellow}기존 리소스를 테라폼 상태로 가져오는 작업을 시작합니다...${nc}"

# Azure CLI 로그인 상태 확인
echo -e "Azure CLI 로그인 상태 확인 중..."
subscription_id=$(az account show --query id -o tsv 2>/dev/null)
if [ -z "$subscription_id" ]; then
  echo -e "${red}Azure CLI에 로그인되어 있지 않습니다. 로그인을 진행합니다...${nc}"
  az login
  subscription_id=$(az account show --query id -o tsv)
fi
echo -e "구독 ID: ${subscription_id}"

# 리소스 그룹 이름 가져오기
hub_rg=$(grep "resource_group_name_hub" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')
spoke_rg=$(grep "resource_group_name_spoke" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')
storage_rg=$(grep "storage_rg" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')

# VNet 이름 가져오기
hub_vnet_name=$(grep "hub_vnet_name" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')
spoke_vnet_name=$(grep "spoke_vnet_name" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')
storage_vnet_name=$(grep "storage_vnet_name" terraform.tfvars | head -1 | cut -d "=" -f2 | tr -d ' "')

# 현재 테라폼 상태 확인
echo -e "\n${yellow}현재 테라폼 상태 확인 중...${nc}"
terraform_state_list=$(terraform state list)

# 테라폼 상태에서 리소스 제거 함수
remove_from_state() {
  resource_address=$1
  if echo "$terraform_state_list" | grep -q "$resource_address"; then
    echo -e "${yellow}테라폼 상태에서 ${resource_address} 제거 중...${nc}"
    terraform state rm "$resource_address" || echo -e "${red}제거 실패: ${resource_address}${nc}"
  else
    echo -e "${blue}테라폼 상태에 ${resource_address}가 없습니다.${nc}"
  fi
}

# 스크립트 시작 부분에 변수 추가
successful_imports=0
failed_imports=0

# 테라폼 상태로 리소스 가져오기 함수 (개선됨)
import_resource() {
  resource_address=$1
  resource_id=$2
  
  if echo "$terraform_state_list" | grep -q "$resource_address"; then
    echo -e "${blue}리소스가 이미 테라폼 상태에 있습니다: ${resource_address}${nc}"
    return 0
  else
    echo -e "${yellow}리소스 가져오기 중: ${resource_address}${nc}"
    
    # Windows Git Bash 환경에서 경로 문제 해결
    resource_id_fixed=$(echo "$resource_id" | sed 's/\\/\//g')
    
    # 데이터 소스 대신 리소스로 가져오기 시도
    if [[ $resource_address == *"data."* ]]; then
      # 데이터 소스 주소를 리소스 주소로 변환
      resource_address_fixed=$(echo "$resource_address" | sed 's/data\.//g')
      echo -e "${cyan}데이터 소스 대신 리소스로 가져오기 시도: ${resource_address_fixed}${nc}"
      
      # 리소스로 가져오기 시도
      MSYS_NO_PATHCONV=1 terraform import "$resource_address_fixed" "$resource_id_fixed" &>/dev/null
      if [ $? -eq 0 ]; then
        echo -e "${green}리소스로 가져오기 성공: ${resource_address_fixed}${nc}"
        ((successful_imports++))
        return 0
      else
        echo -e "${red}리소스로 가져오기 실패: ${resource_address_fixed}${nc}"
        echo -e "${yellow}PowerShell에서 직접 실행하는 명령어:${nc}"
        echo "terraform import \"$resource_address_fixed\" \"$resource_id_fixed\""
        ((failed_imports++))
        return 1
      fi
    else
      # 일반 리소스 가져오기
      MSYS_NO_PATHCONV=1 terraform import "$resource_address" "$resource_id_fixed" &>/dev/null
      if [ $? -eq 0 ]; then
        echo -e "${green}리소스 가져오기 성공: ${resource_address}${nc}"
        ((successful_imports++))
        return 0
      else
        echo -e "${red}가져오기 실패: ${resource_address}${nc}"
        echo -e "${yellow}PowerShell에서 직접 실행하는 명령어:${nc}"
        echo "terraform import \"$resource_address\" \"$resource_id_fixed\""
        ((failed_imports++))
        return 1
      fi
    fi
  fi
}

# 리소스 존재 여부 확인 함수 (수정됨)
check_resource_exists() {
  resource_type=$1
  resource_group=$2
  resource_name=$3
  
  # 리소스 ID로 확인 (더 정확한 방법)
  local resource_id=""
  
  if [ "$resource_type" == "group" ]; then
    resource_id=$(az $resource_type show --name "$resource_name" --query "id" -o tsv 2>/dev/null)
  else
    resource_id=$(az $resource_type show --resource-group "$resource_group" --name "$resource_name" --query "id" -o tsv 2>/dev/null)
  fi
  
  if [ -n "$resource_id" ] && [ "$resource_id" != "null" ]; then
    echo -e "${green}리소스($resource_name) 존재함: $resource_id${nc}" >&2
    echo "$resource_id"
    return 0
  else
    echo -e "${red}리소스($resource_name) 존재하지 않음${nc}" >&2
    return 1
  fi
}

# 서브넷 존재 여부 확인 함수 (수정됨)
check_subnet_exists() {
  resource_group=$1
  vnet_name=$2
  subnet_name=$3
  
  # 리소스 ID로 확인 (더 정확한 방법)
  local subnet_id=$(az network vnet subnet show --resource-group "$resource_group" --vnet-name "$vnet_name" --name "$subnet_name" --query "id" -o tsv 2>/dev/null)
  
  if [ -n "$subnet_id" ] && [ "$subnet_id" != "null" ]; then
    echo -e "${green}서브넷($subnet_name) 존재함: $subnet_id${nc}" >&2
    echo "$subnet_id"
    return 0
  else
    echo -e "${red}서브넷($subnet_name) 존재하지 않음${nc}" >&2
    return 1
  fi
}

# terraform.tfvars 파일 업데이트 함수
update_tfvars() {
  local var_name=$1
  local var_value=$2
  
  # 기존 변수가 있는지 확인
  if grep -q "^$var_name\s*=" terraform.tfvars; then
    # 변수 값 업데이트
    sed -i "s/^$var_name\s*=.*/$var_name = $var_value/" terraform.tfvars
    echo -e "${green}terraform.tfvars 파일에서 $var_name = $var_value 로 업데이트했습니다.${nc}"
  else
    # 변수 추가
    echo "$var_name = $var_value" >> terraform.tfvars
    echo -e "${green}terraform.tfvars 파일에 $var_name = $var_value 를 추가했습니다.${nc}"
  fi
}

# 상태 파일 백업
echo -e "\n${yellow}테라폼 상태 파일 백업 중...${nc}"
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d%H%M%S)
echo -e "${green}백업 완료${nc}"

# 리소스 존재 여부 직접 확인 및 변수 설정
echo -e "\n${yellow}리소스 존재 여부 직접 확인 중...${nc}"

# 리소스 그룹 존재 여부 확인
hub_rg_exists=$(check_resource_exists "group" "" "$hub_rg" > /dev/null && echo "true" || echo "false")
spoke_rg_exists=$(check_resource_exists "group" "" "$spoke_rg" > /dev/null && echo "true" || echo "false")
storage_rg_exists=$(check_resource_exists "group" "" "$storage_rg" > /dev/null && echo "true" || echo "false")

# VNet 존재 여부 확인
hub_vnet_exists=$(check_resource_exists "network vnet" "$hub_rg" "$hub_vnet_name" > /dev/null && echo "true" || echo "false")
spoke_vnet_exists=$(check_resource_exists "network vnet" "$spoke_rg" "$spoke_vnet_name" > /dev/null && echo "true" || echo "false")
storage_vnet_exists=$(check_resource_exists "network vnet" "$storage_rg" "$storage_vnet_name" > /dev/null && echo "true" || echo "false")

# 서브넷 존재 여부 확인
endpoints_subnet_exists=$(check_subnet_exists "$spoke_rg" "$spoke_vnet_name" "endpoints-subnet" > /dev/null && echo "true" || echo "false")

# 변수 일관성 유지
echo -e "\n${yellow}변수 일관성 확인 및 업데이트 중...${nc}"

# 리소스 그룹 변수 설정
use_existing_resource_group_hub="$hub_rg_exists"
use_existing_resource_group_spoke="$spoke_rg_exists"
use_existing_resource_group_storage="$storage_rg_exists"

# 네트워크 변수 설정
use_existing_hub_vnet="$hub_vnet_exists"
use_existing_spoke_vnet="$spoke_vnet_exists"
use_existing_storage_vnet="$storage_vnet_exists"
use_existing_endpoints_subnet="$endpoints_subnet_exists"

# 전체 네트워크 변수 설정
use_existing_networks="false"
if [ "$hub_vnet_exists" == "true" ] || [ "$spoke_vnet_exists" == "true" ] || [ "$storage_vnet_exists" == "true" ]; then
  use_existing_networks="true"
fi

# terraform.tfvars 파일 업데이트
echo -e "\n${yellow}terraform.tfvars 파일 업데이트 중...${nc}"
update_tfvars "use_existing_resource_group_hub" "$use_existing_resource_group_hub"
update_tfvars "use_existing_resource_group_spoke" "$use_existing_resource_group_spoke"
update_tfvars "use_existing_resource_group_storage" "$use_existing_resource_group_storage"
update_tfvars "use_existing_networks" "$use_existing_networks"
update_tfvars "use_existing_hub_vnet" "$use_existing_hub_vnet"
update_tfvars "use_existing_spoke_vnet" "$use_existing_spoke_vnet"
update_tfvars "use_existing_storage_vnet" "$use_existing_storage_vnet"
update_tfvars "use_existing_endpoints_subnet" "$use_existing_endpoints_subnet"

# 리소스 존재 여부 요약
echo -e "\n${yellow}리소스 존재 여부 요약:${nc}"
echo -e "Hub 리소스 그룹 존재 여부: ${hub_rg_exists}"
echo -e "Spoke 리소스 그룹 존재 여부: ${spoke_rg_exists}"
echo -e "Storage 리소스 그룹 존재 여부: ${storage_rg_exists}"
echo -e "Hub VNet 존재 여부: ${hub_vnet_exists}"
echo -e "Spoke VNet 존재 여부: ${spoke_vnet_exists}"
echo -e "Storage VNet 존재 여부: ${storage_vnet_exists}"
echo -e "Endpoints 서브넷 존재 여부: ${endpoints_subnet_exists}"

# 충돌 해결을 위한 리소스 상태 관리
echo -e "\n${yellow}충돌 해결을 위한 리소스 상태 관리 중...${nc}"

# 1. 리소스 그룹 처리
echo -e "\n${yellow}리소스 그룹 처리 중...${nc}"
if [ "$hub_rg_exists" == "true" ]; then
  hub_rg_id=$(check_resource_exists "group" "" "$hub_rg")
  # 리소스 ID가 유효한지 확인
  if [ -n "$hub_rg_id" ]; then
    import_resource "azurerm_resource_group.hub_rg[0]" "$hub_rg_id"
  fi
fi

if [ "$spoke_rg_exists" == "true" ]; then
  spoke_rg_id=$(check_resource_exists "group" "" "$spoke_rg")
  # 리소스 ID가 유효한지 확인
  if [ -n "$spoke_rg_id" ]; then
    import_resource "azurerm_resource_group.spoke_rg[0]" "$spoke_rg_id"
  fi
fi

if [ "$storage_rg_exists" == "true" ]; then
  storage_rg_id=$(check_resource_exists "group" "" "$storage_rg")
  # 리소스 ID가 유효한지 확인
  if [ -n "$storage_rg_id" ]; then
    import_resource "azurerm_resource_group.storage_rg[0]" "$storage_rg_id"
  fi
fi

# 2. Endpoints 서브넷 처리
if [ "$endpoints_subnet_exists" == "true" ] && [ "$spoke_vnet_exists" == "true" ]; then
  echo -e "\n${yellow}Endpoints 서브넷 처리 중...${nc}"
  
  # 테라폼 상태에서 리소스 제거
  remove_from_state "module.network.azurerm_subnet.endpoints_subnet[0]"
  
  # 리소스 존재 여부 확인
  subnet_id=$(check_subnet_exists "$spoke_rg" "$spoke_vnet_name" "endpoints-subnet")
  if [ $? -eq 0 ]; then
    # 리소스로 직접 가져오기 시도
    import_resource "module.network.azurerm_subnet.endpoints_subnet[0]" "$subnet_id"
  fi
fi

# 3. Spoke VNet 처리
if [ "$spoke_vnet_exists" == "true" ]; then
  echo -e "\n${yellow}Spoke VNet 처리 중...${nc}"
  
  # 테라폼 상태에서 리소스 제거
  remove_from_state "module.network.azurerm_virtual_network.spoke_vnet[0]"
  
  # 리소스 존재 여부 확인
  vnet_id=$(check_resource_exists "network vnet" "$spoke_rg" "$spoke_vnet_name")
  if [ $? -eq 0 ]; then
    # 리소스로 직접 가져오기 시도
    import_resource "module.network.azurerm_virtual_network.spoke_vnet[0]" "$vnet_id"
  fi
fi

# 4. Hub VNet 처리
if [ "$hub_vnet_exists" == "true" ]; then
  echo -e "\n${yellow}Hub VNet 처리 중...${nc}"
  
  # 테라폼 상태에서 리소스 제거
  remove_from_state "module.network.azurerm_virtual_network.hub_vnet[0]"
  
  # 리소스 존재 여부 확인
  vnet_id=$(check_resource_exists "network vnet" "$hub_rg" "$hub_vnet_name")
  if [ $? -eq 0 ]; then
    # 리소스로 직접 가져오기 시도
    import_resource "module.network.azurerm_virtual_network.hub_vnet[0]" "$vnet_id"
  fi
fi

# 5. Storage VNet 처리
if [ "$storage_vnet_exists" == "true" ]; then
  echo -e "\n${yellow}Storage VNet 처리 중...${nc}"
  
  # 테라폼 상태에서 리소스 제거
  remove_from_state "module.network.azurerm_virtual_network.storage_vnet[0]"
  
  # 리소스 존재 여부 확인
  vnet_id=$(check_resource_exists "network vnet" "$storage_rg" "$storage_vnet_name")
  if [ $? -eq 0 ]; then
    # 리소스로 직접 가져오기 시도
    import_resource "module.network.azurerm_virtual_network.storage_vnet[0]" "$vnet_id"
  fi
fi

# 6. 프라이빗 엔드포인트 관련 리소스 확인
echo -e "\n${yellow}프라이빗 엔드포인트 관련 리소스 확인 중...${nc}"

# 프라이빗 엔드포인트 목록 가져오기 (개선된 방법)
# 1. 모든 프라이빗 엔드포인트 검색
echo -e "${cyan}모든 프라이빗 엔드포인트 검색 중...${nc}"
all_private_endpoints=$(az network private-endpoint list --query "[].{id:id, name:name, resourceGroup:resourceGroup}" -o json 2>/dev/null)

# 2. 검색 결과 출력
echo -e "${cyan}발견된 프라이빗 엔드포인트:${nc}"
echo "$all_private_endpoints" | jq -r '.[] | "이름: \(.name), 리소스 그룹: \(.resourceGroup)"' 2>/dev/null || echo "$all_private_endpoints"

# 3. 프라이빗 엔드포인트 ID 추출
private_endpoints=$(echo "$all_private_endpoints" | jq -r '.[].id' 2>/dev/null)

if [ -n "$private_endpoints" ]; then
  echo -e "${yellow}프라이빗 엔드포인트가 발견되었습니다. 테라폼 상태로 가져옵니다...${nc}"
  
  # 프라이빗 엔드포인트 가져오기
  for pe_id in $private_endpoints; do
    pe_name=$(echo $pe_id | awk -F'/' '{print $NF}')
    pe_rg=$(echo $pe_id | awk -F'/' '{for(i=1;i<=NF;i++) if($i=="resourceGroups") print $(i+1)}')
    echo -e "${yellow}프라이빗 엔드포인트 처리 중: ${pe_name} (리소스 그룹: ${pe_rg})${nc}"
    
    # 테라폼 상태에서 관련 리소스 제거
    remove_from_state "module.storage.azurerm_private_endpoint.blob_pe[0]"
    
    # 리소스로 직접 가져오기 시도
    import_resource "module.storage.azurerm_private_endpoint.blob_pe[0]" "$pe_id"
    
    # 가져오기 실패 시 대체 리소스 주소로 시도
    if [ $? -ne 0 ]; then
      echo -e "${yellow}대체 리소스 주소로 가져오기 시도...${nc}"
      import_resource "azurerm_private_endpoint.${pe_name}" "$pe_id"
    fi
  done
else
  echo -e "${blue}프라이빗 엔드포인트가 발견되지 않았습니다.${nc}"
  
  # 특정 리소스 그룹에서 다시 검색 시도
  echo -e "${yellow}특정 리소스 그룹에서 다시 검색 시도...${nc}"
  for rg in "$hub_rg" "$spoke_rg" "$storage_rg"; do
    echo -e "${cyan}리소스 그룹 ${rg}에서 프라이빗 엔드포인트 검색 중...${nc}"
    rg_private_endpoints=$(az network private-endpoint list --resource-group "$rg" --query "[].id" -o tsv 2>/dev/null)
    
    if [ -n "$rg_private_endpoints" ]; then
      echo -e "${green}리소스 그룹 ${rg}에서 프라이빗 엔드포인트 발견!${nc}"
      
      for pe_id in $rg_private_endpoints; do
        pe_name=$(echo $pe_id | awk -F'/' '{print $NF}')
        echo -e "${yellow}프라이빗 엔드포인트 처리 중: ${pe_name}${nc}"
        
        # 테라폼 상태에서 관련 리소스 제거
        remove_from_state "module.storage.azurerm_private_endpoint.blob_pe[0]"
        
        # 리소스로 직접 가져오기 시도
        import_resource "module.storage.azurerm_private_endpoint.blob_pe[0]" "$pe_id"
        
        # 가져오기 실패 시 대체 리소스 주소로 시도
        if [ $? -ne 0 ]; then
          echo -e "${yellow}대체 리소스 주소로 가져오기 시도...${nc}"
          import_resource "azurerm_private_endpoint.${pe_name}" "$pe_id"
        fi
      done
    else
      echo -e "${blue}리소스 그룹 ${rg}에서 프라이빗 엔드포인트를 찾을 수 없습니다.${nc}"
    fi
  done
fi

# 7. 수동 가져오기 명령어 생성
echo -e "\n${yellow}자동 가져오기가 실패한 경우 아래 명령어를 PowerShell에서 직접 실행하세요:${nc}"

# 리소스 그룹 ID 가져오기
hub_rg_id_clean=$(az group show --name "$hub_rg" --query "id" -o tsv 2>/dev/null)
spoke_rg_id_clean=$(az group show --name "$spoke_rg" --query "id" -o tsv 2>/dev/null)
storage_rg_id_clean=$(az group show --name "$storage_rg" --query "id" -o tsv 2>/dev/null)

# VNet ID 가져오기
hub_vnet_id_clean=$(az network vnet show --resource-group "$hub_rg" --name "$hub_vnet_name" --query "id" -o tsv 2>/dev/null)
spoke_vnet_id_clean=$(az network vnet show --resource-group "$spoke_rg" --name "$spoke_vnet_name" --query "id" -o tsv 2>/dev/null)
storage_vnet_id_clean=$(az network vnet show --resource-group "$storage_rg" --name "$storage_vnet_name" --query "id" -o tsv 2>/dev/null)

# 서브넷 ID 가져오기
endpoints_subnet_id_clean=$(az network vnet subnet show --resource-group "$spoke_rg" --vnet-name "$spoke_vnet_name" --name "endpoints-subnet" --query "id" -o tsv 2>/dev/null)

echo -e "${cyan}# 리소스 그룹 가져오기${nc}"
[ -n "$hub_rg_id_clean" ] && echo "terraform import \"azurerm_resource_group.hub_rg[0]\" \"$hub_rg_id_clean\""
[ -n "$spoke_rg_id_clean" ] && echo "terraform import \"azurerm_resource_group.spoke_rg[0]\" \"$spoke_rg_id_clean\""
[ -n "$storage_rg_id_clean" ] && echo "terraform import \"azurerm_resource_group.storage_rg[0]\" \"$storage_rg_id_clean\""

echo -e "${cyan}# VNet 가져오기${nc}"
[ -n "$hub_vnet_id_clean" ] && echo "terraform import \"module.network.azurerm_virtual_network.hub_vnet[0]\" \"$hub_vnet_id_clean\""
[ -n "$spoke_vnet_id_clean" ] && echo "terraform import \"module.network.azurerm_virtual_network.spoke_vnet[0]\" \"$spoke_vnet_id_clean\""
[ -n "$storage_vnet_id_clean" ] && echo "terraform import \"module.network.azurerm_virtual_network.storage_vnet[0]\" \"$storage_vnet_id_clean\""

echo -e "${cyan}# 서브넷 가져오기${nc}"
[ -n "$endpoints_subnet_id_clean" ] && echo "terraform import \"module.network.azurerm_subnet.endpoints_subnet[0]\" \"$endpoints_subnet_id_clean\""

echo -e "\n${green}기존 리소스 가져오기 작업이 완료되었습니다.${nc}"

# 가져온 리소스 최종 요약 함수 추가
summarize_imported_resources() {
  echo -e "\n${magenta}=== 리소스 가져오기 최종 요약 ===${nc}"
  
  # 가져오기 시도 결과 기록
  echo -e "${yellow}가져오기 시도 결과:${nc}"
  echo -e "${red}모든 자동 가져오기가 실패했습니다. 수동 가져오기가 필요합니다.${nc}"
  
  echo -e "\n${yellow}테라폼 상태에 있는 리소스 목록:${nc}"
  
  # 최신 테라폼 상태 목록 가져오기
  local current_state_list=$(terraform state list)
  
  # 리소스 그룹 요약
  echo -e "\n${cyan}리소스 그룹:${nc}"
  echo "$current_state_list" | grep "azurerm_resource_group" || echo -e "${red}가져온 리소스 그룹 없음${nc}"
  
  # VNet 요약
  echo -e "\n${cyan}가상 네트워크:${nc}"
  echo "$current_state_list" | grep "azurerm_virtual_network" || echo -e "${red}가져온 가상 네트워크 없음${nc}"
  
  # 서브넷 요약
  echo -e "\n${cyan}서브넷:${nc}"
  echo "$current_state_list" | grep "azurerm_subnet" || echo -e "${red}가져온 서브넷 없음${nc}"
  
  # 프라이빗 엔드포인트 요약
  echo -e "\n${cyan}프라이빗 엔드포인트:${nc}"
  echo "$current_state_list" | grep "azurerm_private_endpoint" || echo -e "${red}가져온 프라이빗 엔드포인트 없음${nc}"
  
  # 가져오기 실패한 리소스 요약 - 수정된 부분
  echo -e "\n${yellow}가져오기 실패한 리소스:${nc}"
  
  echo -e "${red}다음 리소스들은 PowerShell에서 수동으로 가져와야 합니다:${nc}"
  echo -e "1. ${red}Hub 리소스 그룹 (${hub_rg})${nc}"
  echo -e "2. ${red}Spoke 리소스 그룹 (${spoke_rg})${nc}"
  echo -e "3. ${red}Storage 리소스 그룹 (${storage_rg})${nc}"
  echo -e "4. ${red}Hub VNet (${hub_vnet_name})${nc}"
  echo -e "5. ${red}Spoke VNet (${spoke_vnet_name})${nc}"
  echo -e "6. ${red}Storage VNet (${storage_vnet_name})${nc}"
  echo -e "7. ${red}Endpoints 서브넷 (endpoints-subnet)${nc}"
  
  echo -e "\n${magenta}=== 다음 단계 ===${nc}"
  echo -e "1. ${yellow}위에 제공된 PowerShell 명령어로 수동 가져오기를 시도하세요.${nc}"
  echo -e "2. ${yellow}terraform plan을 실행하여 변경 사항을 확인하세요.${nc}"
  echo -e "3. ${yellow}terraform apply를 실행하여 변경 사항을 적용하세요.${nc}"
}

# 최종 요약 추가
summarize_imported_resources

echo -e "${yellow}이제 테라폼 배포를 다시 시도할 수 있습니다.${nc}"

# 요약 부분 수정
echo -e "\n${yellow}가져오기 통계:${nc}"
echo -e "성공한 가져오기: ${successful_imports}"
echo -e "실패한 가져오기: ${failed_imports}" 