#!/bin/bash

# 환경 파일 로드
if [ -f "check_aks_env.sh" ]; then
    source check_aks_env.sh
else
    echo "환경 파일(check_aks_env.sh)이 존재하지 않습니다."
    exit 1
fi

# 로그 디렉토리 변수 확인
if [ -z "$LOG_DIR" ]; then
    echo "⚠️ 로그 디렉토리 변수가 비어 있습니다. 기본값으로 './logs'를 사용합니다."
    export LOG_DIR="./logs"
fi

# 로그 디렉토리 존재 여부 확인 및 생성
if [ ! -d "$LOG_DIR" ]; then
    echo "📁 로그 디렉토리($LOG_DIR)가 존재하지 않습니다. 생성합니다..."
    mkdir -p "$LOG_DIR"
    if [ $? -eq 0 ]; then
        echo "✅ 로그 디렉토리 생성 완료: $LOG_DIR"
    else
        echo "❌ 로그 디렉토리 생성 실패! 권한을 확인하세요."
        # 대체 로그 디렉토리 시도
        export LOG_DIR="/tmp/aks_check_logs"
        echo "🔄 대체 로그 디렉토리를 시도합니다: $LOG_DIR"
        mkdir -p "$LOG_DIR"
        if [ $? -eq 0 ]; then
            echo "✅ 대체 로그 디렉토리 생성 완료: $LOG_DIR"
        else
            echo "❌ 대체 로그 디렉토리 생성도 실패했습니다. 로그 파일 없이 진행합니다."
            export LOG_DIR=""
        fi
    fi
else
    echo "✅ 로그 디렉토리가 이미 존재합니다: $LOG_DIR"
fi

# 타임스탬프 생성
export TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 로그 파일 경로 설정 (AKS 클러스터 이름 포함)
if [ -n "$LOG_DIR" ]; then
    export LOG_FILE="$LOG_DIR/aks_check_detailed_${AKS_CLUSTER}_$TIMESTAMP.log"
    echo "📝 로그 파일 경로: $LOG_FILE"
else
    export LOG_FILE=""
    echo "⚠️ 로그 파일을 생성할 수 없습니다. 화면에만 출력합니다."
fi

# 민감 정보 필터링 함수 정의
filter_sensitive_info() {
    local input="$1"
    
    # 클라이언트 시크릿 마스킹
    if [ -n "$AZURE_CLIENT_SECRET" ]; then
        input=$(echo "$input" | sed "s/$AZURE_CLIENT_SECRET/********/g")
    fi
    
    # 구독 ID 부분 마스킹 (앞 8자리만 표시)
    if [ -n "$AZURE_SUBSCRIPTION_ID" ]; then
        local sub_prefix="${AZURE_SUBSCRIPTION_ID:0:8}"
        input=$(echo "$input" | sed "s/$AZURE_SUBSCRIPTION_ID/$sub_prefix********/g")
    fi
    
    # 테넌트 ID 부분 마스킹 (앞 8자리만 표시)
    if [ -n "$AZURE_TENANT_ID" ]; then
        local tenant_prefix="${AZURE_TENANT_ID:0:8}"
        input=$(echo "$input" | sed "s/$AZURE_TENANT_ID/$tenant_prefix********/g")
    fi
    
    # 클라이언트 ID 부분 마스킹 (앞 8자리만 표시)
    if [ -n "$AZURE_CLIENT_ID" ]; then
        local client_prefix="${AZURE_CLIENT_ID:0:8}"
        input=$(echo "$input" | sed "s/$AZURE_CLIENT_ID/$client_prefix********/g")
    fi
    
    # IP 주소 마스킹
    input=$(echo "$input" | sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/xxx.xxx.xxx.xxx/g')
    
    # 암호 마스킹 (password=, pwd=, secret= 등의 패턴)
    input=$(echo "$input" | sed -E 's/(password|pwd|secret|key)=([^[:space:]&]+)/\1=********/gi')
    
    echo "$input"
}

# 로그 함수 정의 (민감 정보 필터링 추가)
log() {
    local filtered_message=$(filter_sensitive_info "$1")
    echo "$filtered_message"
    if [ -n "$LOG_FILE" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - $filtered_message" >> "$LOG_FILE"
    fi
}

log "🚀 AKS 클러스터 점검 시작"
if [ -n "$LOG_FILE" ]; then
    log "(로그 파일: $LOG_FILE)"
fi

# 함수: 명령어 실행 후 결과 저장 (에러 처리 포함)
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
    
    log "\n$icon $title"
    log "--------------------------------------------------------"
    
    # 명령어 실행 및 결과 캡처
    local result
    result=$(eval "$command" 2>&1)
    local exit_code=$?
    
    # 결과 필터링 및 로깅
    local filtered_result=$(filter_sensitive_info "$result")
    log "$filtered_result"
    
    # 에러 발생 시 처리
    if [ $exit_code -ne 0 ]; then
        log "❌ 오류 발생 (종료 코드: $exit_code)"
        if [ "$importance" = "critical" ]; then
            log "⚠️ 중요 점검 항목 실패! 조치가 필요합니다."
        fi
    else
        if [ -z "$result" ]; then
            log "ℹ️ 결과 없음 (명령은 성공적으로 실행됨)"
        fi
    fi
    
    log ""
    return $exit_code
}

# 1. Azure 로그인 상태 확인
run_check "Azure 로그인 상태 확인" \
    "az account show --query '{name:name, subscriptionId:id, tenantId:tenantId, user:user.name}' -o json" \
    "critical"

# 2. AKS 클러스터 기본 정보 확인
run_check "AKS 클러스터 기본 정보" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query '{name:name, k8sVersion:kubernetesVersion, provisioningState:provisioningState, powerState:powerState, nodeResourceGroup:nodeResourceGroup, location:location}' -o json" \
    "critical"

# 3. AKS 노드풀 정보 확인
run_check "AKS 노드풀 정보" \
    "az aks nodepool list --resource-group $RESOURCE_GROUP_SPOKE --cluster-name $AKS_CLUSTER -o json" \
    "high"

# 4. AKS 클러스터 네트워크 정보
run_check "AKS 클러스터 네트워크 정보" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query 'networkProfile' -o json" \
    "high"

# 5. AKS 클러스터 보안 정보
run_check "AKS 클러스터 보안 정보" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query '{aadProfile:aadProfile, apiServerAccessProfile:apiServerAccessProfile, enableRBAC:enableRBAC, diskEncryptionSetID:diskEncryptionSetID}' -o json" \
    "high"

# 6. AKS 클러스터 애드온 정보
run_check "AKS 클러스터 애드온 정보" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query 'addonProfiles' -o json" \
    "normal"

# 7. AKS 클러스터 업그레이드 가능 버전 확인
run_check "AKS 클러스터 업그레이드 가능 버전" \
    "az aks get-upgrades --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --output table" \
    "normal"

# 8. AKS 클러스터 진단 설정 확인
run_check "AKS 클러스터 진단 설정" \
    "az monitor diagnostic-settings list --resource $(az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query id -o tsv) -o json" \
    "normal"

# 9. AKS 클러스터 로그 분석 연결 확인
run_check "AKS 클러스터 로그 분석 연결" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query 'addonProfiles.omsagent' -o json" \
    "normal"

# 10. ACR 정보 확인
run_check "ACR 정보" \
    "az acr show --name $ACR_NAME --query '{name:name, loginServer:loginServer, adminUserEnabled:adminUserEnabled, sku:sku.name, privateEndpointConnections:privateEndpointConnections}' -o json" \
    "high"

# 11. ACR-AKS 연결 확인
run_check "ACR-AKS 연결 확인" \
    "az aks check-acr --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --acr $ACR_NAME -o json" \
    "high"

# 12. KeyVault 정보 확인
run_check "KeyVault 정보" \
    "az keyvault show --name $KEYVAULT_NAME --query '{name:name, sku:properties.sku.name, enabledForDeployment:properties.enabledForDeployment, enabledForTemplateDeployment:properties.enabledForTemplateDeployment, enableRbacAuthorization:properties.enableRbacAuthorization, privateEndpointConnections:properties.privateEndpointConnections}' -o json" \
    "high"

# 13. Application Gateway 정보 확인
run_check "Application Gateway 정보" \
    "az network application-gateway show --resource-group $RESOURCE_GROUP_HUB --name $APPGW_NAME --query '{name:name, operationalState:operationalState, sku:sku.name, tier:sku.tier, capacity:sku.capacity}' -o json" \
    "normal"

# 14. Bastion 정보 확인
run_check "Bastion 정보" \
    "az network bastion show --resource-group $RESOURCE_GROUP_HUB --name $BASTION_NAME --query '{name:name, sku:sku.name, scaleUnits:scaleUnits, enableTunneling:enableTunneling, enableFileCopy:enableFileCopy}' -o json" \
    "normal"

# 15. Jumpbox VM 정보 확인
run_check "Jumpbox VM 정보" \
    "az vm show --resource-group $RESOURCE_GROUP_HUB --name $JUMPBOX_NAME --query '{name:name, vmSize:hardwareProfile.vmSize, osType:storageProfile.osDisk.osType, provisioningState:provisioningState}' -o json" \
    "normal"

# 16. Log Analytics Workspace 정보 확인
run_check "Log Analytics Workspace 정보" \
    "az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP_HUB --workspace-name $LOG_ANALYTICS_WORKSPACE --query '{name:name, sku:sku.name, retentionInDays:retentionInDays, provisioningState:provisioningState}' -o json" \
    "normal"

# 17. VNet 피어링 확인 (Hub-Spoke)
run_check "VNet 피어링 확인 (Hub-Spoke)" \
    "az network vnet peering list --resource-group $RESOURCE_GROUP_HUB --vnet-name $HUB_VNET_NAME --query \"[?contains(name, 'spoke')].{name:name, peeringState:peeringState, allowVnetAccess:allowVnetAccess, allowForwardedTraffic:allowForwardedTraffic}\" -o json" \
    "high"

# 18. VNet 피어링 확인 (Hub-Storage)
run_check "VNet 피어링 확인 (Hub-Storage)" \
    "az network vnet peering list --resource-group $RESOURCE_GROUP_HUB --vnet-name $HUB_VNET_NAME --query \"[?contains(name, 'storage')].{name:name, peeringState:peeringState, allowVnetAccess:allowVnetAccess, allowForwardedTraffic:allowForwardedTraffic}\" -o json" \
    "high"

# 19. 프라이빗 엔드포인트 확인
run_check "프라이빗 엔드포인트 확인" \
    "az network private-endpoint list --query '[].{name:name, resourceGroup:resourceGroup, privateLinkServiceConnections:privateLinkServiceConnections[0].name, provisioningState:provisioningState}' -o json" \
    "high"

# 20. 프라이빗 DNS 영역 확인
run_check "프라이빗 DNS 영역 확인" \
    "az network private-dns zone list --query '[].{name:name, resourceGroup:resourceGroup, numberOfRecordSets:numberOfRecordSets, numberOfVirtualNetworkLinks:numberOfVirtualNetworkLinks}' -o json" \
    "normal"

# 21. NSG 규칙 확인 (AKS 서브넷)
run_check "NSG 규칙 확인 (AKS 서브넷)" \
    "az network nsg show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_NSG_NAME --query 'securityRules' -o json" \
    "high"

# 22. NSG 규칙 확인 (Endpoints 서브넷)
run_check "NSG 규칙 확인 (Endpoints 서브넷)" \
    "az network nsg show --resource-group $RESOURCE_GROUP_SPOKE --name $ENDPOINTS_NSG_NAME --query 'securityRules' -o json" \
    "high"

# 23. NSG 규칙 확인 (AppGW 서브넷)
run_check "NSG 규칙 확인 (AppGW 서브넷)" \
    "az network nsg show --resource-group $RESOURCE_GROUP_HUB --name $APPGW_NSG_NAME --query 'securityRules' -o json" \
    "normal"

# 24. NSG 규칙 확인 (Bastion 서브넷)
run_check "NSG 규칙 확인 (Bastion 서브넷)" \
    "az network nsg show --resource-group $RESOURCE_GROUP_HUB --name $BASTION_NSG_NAME --query 'securityRules' -o json" \
    "normal"

# 25. NSG 규칙 확인 (Jumpbox 서브넷)
run_check "NSG 규칙 확인 (Jumpbox 서브넷)" \
    "az network nsg show --resource-group $RESOURCE_GROUP_HUB --name $JUMPBOX_NSG_NAME --query 'securityRules' -o json" \
    "normal"

# 26. AKS 클러스터 노드 상태 확인
run_check "AKS 클러스터 노드 상태 확인" \
    "kubectl get nodes -o wide" \
    "critical"

# 27. AKS 클러스터 시스템 Pod 상태 확인
run_check "AKS 클러스터 시스템 Pod 상태 확인" \
    "kubectl get pods -n kube-system" \
    "critical"

# 28. AKS 클러스터 네임스페이스 확인
run_check "AKS 클러스터 네임스페이스 확인" \
    "kubectl get namespaces" \
    "normal"

# 29. AKS 클러스터 스토리지 클래스 확인
run_check "AKS 클러스터 스토리지 클래스 확인" \
    "kubectl get storageclass" \
    "normal"

# 30. AKS 클러스터 PVC 확인
run_check "AKS 클러스터 PVC 확인" \
    "kubectl get pvc --all-namespaces" \
    "normal"

log "✅ AKS 클러스터 점검 완료"
log "📊 결과 요약:"
log "- 점검 시간: $(date)"
log "- 점검 대상 클러스터: $AKS_CLUSTER"
log "- 로그 파일 위치: $LOG_FILE"

# 종료 메시지
echo ""
echo "=========================================================="
echo "✅ AKS 클러스터 점검이 완료되었습니다."
echo "📝 상세 결과는 로그 파일을 확인하세요: $LOG_FILE"
echo "=========================================================="
