#!/bin/bash

# 환경 파일 로드
if [ -f "check_aks_env.sh" ]; then
    source check_aks_env.sh
else
    echo "환경 파일(check_aks_env.sh)이 존재하지 않습니다."
    exit 1
fi

# 로그 디렉토리 존재 여부 확인 및 생성
if [ ! -d "$LOG_DIR" ]; then
    echo "📁 로그 디렉토리($LOG_DIR)가 존재하지 않습니다. 생성합니다..."
    mkdir -p "$LOG_DIR"
fi

# 결과 파일 설정
RESULT_FILE="$LOG_DIR/azure_infra_check_$TIMESTAMP.log"
echo "Azure 인프라 점검 결과 ($(date))" > $RESULT_FILE
echo "=====================================" >> $RESULT_FILE

# 민감 정보 필터링 함수 정의
filter_sensitive_info() {
    local input="$1"
    
    # IP 주소 마스킹
    input=$(echo "$input" | sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/xxx.xxx.xxx.xxx/g')
    
    # 암호 마스킹 (password=, pwd=, secret= 등의 패턴)
    input=$(echo "$input" | sed -E 's/(password|pwd|secret|key)=([^[:space:]&]+)/\1=********/gi')
    
    echo "$input"
}

# 함수: 명령어 실행 후 결과 저장
run_check() {
    local title="$1"
    local command="$2"
    local importance="${3:-normal}"  # 중요도: critical, high, normal, low
    
    # 중요도에 따른 아이콘 설정
    local icon="🔍"
    case "$importance" in
        critical) icon="⚠️" ;;
        high)     icon="🔴" ;;
        normal)   icon="🔵" ;;
        low)      icon="⚪" ;;
    esac
    
    echo -e "\n$icon $title" | tee -a $RESULT_FILE
    echo "--------------------------------------------------------" | tee -a $RESULT_FILE
    
    # 명령어 실행 및 결과 캡처
    local result
    result=$(eval "$command" 2>&1)
    local exit_code=$?
    
    # 결과 필터링 및 로깅
    local filtered_result=$(filter_sensitive_info "$result")
    echo "$filtered_result" | tee -a $RESULT_FILE
    
    # 에러 발생 시 처리
    if [ $exit_code -ne 0 ]; then
        echo "❌ 오류 발생 (종료 코드: $exit_code)" | tee -a $RESULT_FILE
        if [ "$importance" = "critical" ]; then
            echo "⚠️ 중요 점검 항목 실패! 조치가 필요합니다." | tee -a $RESULT_FILE
        fi
    else
        if [ -z "$result" ]; then
            echo "ℹ️ 결과 없음 (명령은 성공적으로 실행됨)" | tee -a $RESULT_FILE
        fi
    fi
    
    echo -e "\n" | tee -a $RESULT_FILE
    return $exit_code
}

echo "🚀 Azure 인프라 점검 시작" | tee -a $RESULT_FILE

# ===== 1. 리소스 그룹 점검 =====
echo -e "\n===== 리소스 그룹 점검 =====" | tee -a $RESULT_FILE

# 1.1 Hub 리소스 그룹 확인
run_check "Hub 리소스 그룹 확인" \
    "az group show --name $RESOURCE_GROUP_HUB --query '{name:name, location:location, provisioningState:properties.provisioningState}' -o json" \
    "critical"

# 1.2 Spoke 리소스 그룹 확인
run_check "Spoke 리소스 그룹 확인" \
    "az group show --name $RESOURCE_GROUP_SPOKE --query '{name:name, location:location, provisioningState:properties.provisioningState}' -o json" \
    "critical"

# 1.3 Storage 리소스 그룹 확인
run_check "Storage 리소스 그룹 확인" \
    "az group show --name $RESOURCE_GROUP_STORAGE --query '{name:name, location:location, provisioningState:properties.provisioningState}' -o json" \
    "critical"

# ===== 2. 네트워크 인프라 점검 =====
echo -e "\n===== 네트워크 인프라 점검 =====" | tee -a $RESULT_FILE

# 2.1 Hub VNet 확인
run_check "Hub VNet 확인" \
    "az network vnet show --resource-group $RESOURCE_GROUP_HUB --name $HUB_VNET_NAME --query '{name:name, addressSpace:addressSpace.addressPrefixes, subnets:length(subnets), provisioningState:provisioningState}' -o json" \
    "high"

# 2.2 Spoke VNet 확인
run_check "Spoke VNet 확인" \
    "az network vnet show --resource-group $RESOURCE_GROUP_SPOKE --name $SPOKE_VNET_NAME --query '{name:name, addressSpace:addressSpace.addressPrefixes, subnets:length(subnets), provisioningState:provisioningState}' -o json" \
    "high"

# 2.3 Storage VNet 확인
run_check "Storage VNet 확인" \
    "az network vnet show --resource-group $RESOURCE_GROUP_STORAGE --name $STORAGE_VNET_NAME --query '{name:name, addressSpace:addressSpace.addressPrefixes, subnets:length(subnets), provisioningState:provisioningState}' -o json" \
    "high"

# 2.4 VNet Peering 확인 (Hub-Spoke)
run_check "VNet Peering 확인 (Hub-Spoke)" \
    "az network vnet peering list --resource-group $RESOURCE_GROUP_HUB --vnet-name $HUB_VNET_NAME --query \"[?contains(name, 'spoke')].{name:name, peeringState:peeringState, allowVnetAccess:allowVnetAccess, allowForwardedTraffic:allowForwardedTraffic}\" -o json" \
    "high"

# 2.5 VNet Peering 확인 (Hub-Storage)
run_check "VNet Peering 확인 (Hub-Storage)" \
    "az network vnet peering list --resource-group $RESOURCE_GROUP_HUB --vnet-name $HUB_VNET_NAME --query \"[?contains(name, 'storage')].{name:name, peeringState:peeringState, allowVnetAccess:allowVnetAccess, allowForwardedTraffic:allowForwardedTraffic}\" -o json" \
    "high"

# 2.6 Spoke-Storage Peering 확인
run_check "VNet Peering 확인 (Spoke-Storage)" \
    "az network vnet peering list --resource-group $RESOURCE_GROUP_SPOKE --vnet-name $SPOKE_VNET_NAME --query \"[?contains(name, 'storage')].{name:name, peeringState:peeringState, allowVnetAccess:allowVnetAccess, allowForwardedTraffic:allowForwardedTraffic}\" -o json" \
    "high"

# 2.7 Hub 서브넷 확인
run_check "Hub 서브넷 목록 확인" \
    "az network vnet subnet list --resource-group $RESOURCE_GROUP_HUB --vnet-name $HUB_VNET_NAME --query '[].{name:name, addressPrefix:addressPrefix, privateEndpointNetworkPolicies:privateEndpointNetworkPolicies}' -o json" \
    "normal"

# 2.8 Spoke 서브넷 확인
run_check "Spoke 서브넷 목록 확인" \
    "az network vnet subnet list --resource-group $RESOURCE_GROUP_SPOKE --vnet-name $SPOKE_VNET_NAME --query '[].{name:name, addressPrefix:addressPrefix, privateEndpointNetworkPolicies:privateEndpointNetworkPolicies}' -o json" \
    "normal"

# 2.9 Storage 서브넷 확인
run_check "Storage 서브넷 목록 확인" \
    "az network vnet subnet list --resource-group $RESOURCE_GROUP_STORAGE --vnet-name $STORAGE_VNET_NAME --query '[].{name:name, addressPrefix:addressPrefix, privateEndpointNetworkPolicies:privateEndpointNetworkPolicies}' -o json" \
    "normal"

# ===== 3. NSG 점검 =====
echo -e "\n===== NSG 점검 =====" | tee -a $RESULT_FILE

# 3.1 AKS NSG 확인
run_check "AKS NSG 확인" \
    "az network nsg show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_NSG_NAME --query '{name:name, resourceGroup:resourceGroup, securityRules:length(securityRules)}' -o json" \
    "high"

# 3.2 Endpoints NSG 확인
run_check "Endpoints NSG 확인" \
    "az network nsg show --resource-group $RESOURCE_GROUP_SPOKE --name $ENDPOINTS_NSG_NAME --query '{name:name, resourceGroup:resourceGroup, securityRules:length(securityRules)}' -o json" \
    "high"

# 3.3 AppGW NSG 확인
run_check "AppGW NSG 확인" \
    "az network nsg show --resource-group $RESOURCE_GROUP_HUB --name $APPGW_NSG_NAME --query '{name:name, resourceGroup:resourceGroup, securityRules:length(securityRules)}' -o json" \
    "normal"

# 3.4 Bastion NSG 확인
run_check "Bastion NSG 확인" \
    "az network nsg show --resource-group $RESOURCE_GROUP_HUB --name $BASTION_NSG_NAME --query '{name:name, resourceGroup:resourceGroup, securityRules:length(securityRules)}' -o json" \
    "normal"

# 3.5 Jumpbox NSG 확인
run_check "Jumpbox NSG 확인" \
    "az network nsg show --resource-group $RESOURCE_GROUP_HUB --name $JUMPBOX_NSG_NAME --query '{name:name, resourceGroup:resourceGroup, securityRules:length(securityRules)}' -o json" \
    "normal"

# ===== 4. 중앙 서비스 점검 =====
echo -e "\n===== 중앙 서비스 점검 =====" | tee -a $RESULT_FILE

# 4.1 ACR 확인
run_check "ACR 확인" \
    "az acr show --name $ACR_NAME --query '{name:name, loginServer:loginServer, adminUserEnabled:adminUserEnabled, sku:sku.name, privateEndpointConnections:length(privateEndpointConnections)}' -o json" \
    "high"

# 4.2 KeyVault 확인
run_check "KeyVault 확인" \
    "az keyvault show --name $KEYVAULT_NAME --query '{name:name, sku:properties.sku.name, enabledForDeployment:properties.enabledForDeployment, enabledForTemplateDeployment:properties.enabledForTemplateDeployment, enableRbacAuthorization:properties.enableRbacAuthorization, privateEndpointConnections:length(properties.privateEndpointConnections)}' -o json" \
    "high"

# 4.3 Application Gateway 확인
run_check "Application Gateway 확인" \
    "az network application-gateway show --resource-group $RESOURCE_GROUP_HUB --name $APPGW_NAME --query '{name:name, operationalState:operationalState, sku:sku.name, tier:sku.tier, capacity:sku.capacity}' -o json" \
    "normal"

# 4.4 Bastion 확인
run_check "Bastion 확인" \
    "az network bastion show --resource-group $RESOURCE_GROUP_HUB --name $BASTION_NAME --query '{name:name, sku:sku.name, scaleUnits:scaleUnits, enableTunneling:enableTunneling, enableFileCopy:enableFileCopy}' -o json" \
    "normal"

# 4.5 Jumpbox VM 확인
run_check "Jumpbox VM 확인" \
    "az vm show --resource-group $RESOURCE_GROUP_HUB --name $JUMPBOX_NAME --query '{name:name, vmSize:hardwareProfile.vmSize, osType:storageProfile.osDisk.osType, provisioningState:provisioningState}' -o json" \
    "normal"

# 4.6 Log Analytics Workspace 확인
run_check "Log Analytics Workspace 확인" \
    "az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP_HUB --workspace-name $LOG_ANALYTICS_WORKSPACE --query '{name:name, sku:sku.name, retentionInDays:retentionInDays, provisioningState:provisioningState}' -o json" \
    "normal"

# ===== 5. 프라이빗 엔드포인트 점검 =====
echo -e "\n===== 프라이빗 엔드포인트 점검 =====" | tee -a $RESULT_FILE

# 5.1 프라이빗 엔드포인트 확인
run_check "프라이빗 엔드포인트 확인" \
    "az network private-endpoint list --query '[].{name:name, resourceGroup:resourceGroup, privateLinkServiceConnections:privateLinkServiceConnections[0].name, provisioningState:provisioningState}' -o json" \
    "high"

# 5.2 프라이빗 DNS 영역 확인
run_check "프라이빗 DNS 영역 확인" \
    "az network private-dns zone list --query '[].{name:name, resourceGroup:resourceGroup, numberOfRecordSets:numberOfRecordSets, numberOfVirtualNetworkLinks:numberOfVirtualNetworkLinks}' -o json" \
    "normal"

# 5.3 ACR 프라이빗 엔드포인트 확인
run_check "ACR 프라이빗 엔드포인트 확인" \
    "az network private-endpoint list --query \"[?contains(name, '$ACR_NAME')].{name:name, resourceGroup:resourceGroup, privateLinkServiceConnections:privateLinkServiceConnections[0].name, provisioningState:provisioningState}\" -o json" \
    "normal"

# 5.4 KeyVault 프라이빗 엔드포인트 확인
run_check "KeyVault 프라이빗 엔드포인트 확인" \
    "az network private-endpoint list --query \"[?contains(name, '$KEYVAULT_NAME')].{name:name, resourceGroup:resourceGroup, privateLinkServiceConnections:privateLinkServiceConnections[0].name, provisioningState:provisioningState}\" -o json" \
    "normal"

echo "✅ Azure 인프라 점검 완료" | tee -a $RESULT_FILE
echo "📊 결과 요약:" | tee -a $RESULT_FILE
echo "- 점검 시간: $(date)" | tee -a $RESULT_FILE
echo "- 로그 파일 위치: $RESULT_FILE" | tee -a $RESULT_FILE

# 종료 메시지
echo ""
echo "=========================================================="
echo "✅ Azure 인프라 점검이 완료되었습니다."
echo "📝 상세 결과는 로그 파일을 확인하세요: $RESULT_FILE"
echo "==========================================================" 