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
RESULT_FILE="$LOG_DIR/aks_cluster_check_${AKS_CLUSTER}_$TIMESTAMP.log"
echo "AKS 클러스터 점검 결과 ($(date))" > $RESULT_FILE
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

echo "🚀 AKS 클러스터 점검 시작" | tee -a $RESULT_FILE

# ===== 1. AKS 클러스터 기본 정보 점검 =====
echo -e "\n===== AKS 클러스터 기본 정보 점검 =====" | tee -a $RESULT_FILE

# 1.1 AKS 클러스터 기본 정보
run_check "AKS 클러스터 기본 정보" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query '{name:name, k8sVersion:kubernetesVersion, provisioningState:provisioningState, powerState:powerState, nodeResourceGroup:nodeResourceGroup, location:location}' -o json" \
    "critical"

# 1.2 AKS 노드풀 정보
run_check "AKS 노드풀 정보" \
    "az aks nodepool list --resource-group $RESOURCE_GROUP_SPOKE --cluster-name $AKS_CLUSTER -o json" \
    "high"

# 1.3 AKS 클러스터 업그레이드 가능 버전
run_check "AKS 클러스터 업그레이드 가능 버전" \
    "az aks get-upgrades --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --output table" \
    "normal"

# ===== 2. AKS 클러스터 네트워크 설정 점검 =====
echo -e "\n===== AKS 클러스터 네트워크 설정 점검 =====" | tee -a $RESULT_FILE

# 2.1 네트워크 프로필
run_check "네트워크 프로필" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query 'networkProfile' -o json" \
    "high"

# 2.2 네트워크 정책
run_check "네트워크 정책" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.networkPolicy\" --output json" \
    "high"

# 2.3 네트워크 플러그인
run_check "네트워크 플러그인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.networkPlugin\" --output json" \
    "high"

# 2.4 로드 밸런서 SKU
run_check "로드 밸런서 SKU" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.loadBalancerSku\" --output json" \
    "normal"

# 2.5 아웃바운드 타입
run_check "아웃바운드 타입" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.outboundType\" --output json" \
    "normal"

# 2.6 프라이빗 클러스터 확인
run_check "프라이빗 클러스터 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"apiServerAccessProfile.enablePrivateCluster\" --output json" \
    "high"

# ===== 3. AKS 클러스터 보안 설정 점검 =====
echo -e "\n===== AKS 클러스터 보안 설정 점검 =====" | tee -a $RESULT_FILE

# 3.1 RBAC 활성화 여부
run_check "RBAC 활성화 여부" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"enableRBAC\" --output json" \
    "critical"

# 3.2 Azure AD 연동 확인
run_check "Azure AD 연동 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"aadProfile\" -o json" \
    "high"

# 3.3 API 서버 인증 IP 범위
run_check "API 서버 인증 IP 범위" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"apiServerAccessProfile.authorizedIpRanges\" -o json" \
    "high"

# 3.4 디스크 암호화 설정
run_check "디스크 암호화 설정" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"diskEncryptionSetID\" -o json" \
    "normal"

# ===== 4. AKS 클러스터 애드온 점검 =====
echo -e "\n===== AKS 클러스터 애드온 점검 =====" | tee -a $RESULT_FILE

# 4.1 모니터링 애드온
run_check "모니터링 애드온" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.omsagent\" -o json" \
    "normal"

# 4.2 Application Gateway 애드온
run_check "Application Gateway 애드온" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.ingressApplicationGateway\" -o json" \
    "normal"

# 4.3 Azure Policy 애드온
run_check "Azure Policy 애드온" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.azurepolicy\" -o json" \
    "normal"

# 4.4 HTTP 애플리케이션 라우팅 애드온
run_check "HTTP 애플리케이션 라우팅 애드온" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.httpApplicationRouting\" -o json" \
    "low"

# 4.5 Azure Defender 애드온
run_check "Azure Defender 애드온" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.azureDefender\" -o json" \
    "normal"

# ===== 5. AKS 클러스터 모니터링 설정 점검 =====
echo -e "\n===== AKS 클러스터 모니터링 설정 점검 =====" | tee -a $RESULT_FILE

# 5.1 Azure Monitor 활성화 여부
run_check "Azure Monitor 활성화 여부" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.omsagent.enabled\" --output json" \
    "normal"

# 5.2 컨테이너 모니터링 설정
run_check "컨테이너 모니터링 설정" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.omsagent.config.logAnalyticsWorkspaceResourceID\" --output json" \
    "normal"

# 5.3 AKS 클러스터 진단 설정
run_check "AKS 클러스터 진단 설정" \
    "az monitor diagnostic-settings list --resource $(az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query id -o tsv) -o json" \
    "normal"

# 5.4 Cluster Autoscaler 설정
run_check "Cluster Autoscaler 설정" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"autoScalerProfile\" --output json" \
    "normal"

# ===== 6. AKS 클러스터 연결 및 통합 점검 =====
echo -e "\n===== AKS 클러스터 연결 및 통합 점검 =====" | tee -a $RESULT_FILE

# 6.1 ACR-AKS 연결 확인
run_check "ACR-AKS 연결 확인" \
    "az aks check-acr --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --acr $ACR_NAME -o json" \
    "high"

# 6.2 AKS 클러스터 자격 증명 가져오기
run_check "AKS 클러스터 자격 증명 가져오기" \
    "az aks get-credentials --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --admin --overwrite-existing" \
    "critical"

# ===== 7. Kubernetes 리소스 점검 =====
echo -e "\n===== Kubernetes 리소스 점검 =====" | tee -a $RESULT_FILE

# 7.1 노드 상태 확인
run_check "노드 상태 확인" \
    "kubectl get nodes -o wide" \
    "critical"

# 7.2 시스템 Pod 상태 확인
run_check "시스템 Pod 상태 확인" \
    "kubectl get pods -n kube-system" \
    "critical"

# 7.3 네임스페이스 확인
run_check "네임스페이스 확인" \
    "kubectl get namespaces" \
    "normal"

# 7.4 Kubernetes RBAC 설정 확인
run_check "Kubernetes RBAC 설정 확인" \
    "kubectl get roles,rolebindings,clusterroles,clusterrolebindings --all-namespaces" \
    "high"

# 7.5 Secret 및 ConfigMap 확인
run_check "Secret 및 ConfigMap 확인" \
    "kubectl get secret,configmap --all-namespaces" \
    "high"

# 7.6 컨테이너 보안 정책 확인
run_check "컨테이너 보안 정책 확인" \
    "kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].securityContext}'" \
    "normal"

# 7.7 Ingress 설정 확인
run_check "Ingress 설정 확인" \
    "kubectl get ingress --all-namespaces" \
    "normal"

# 7.8 CoreDNS 설정 확인
run_check "CoreDNS 설정 확인" \
    "kubectl get configmap -n kube-system coredns -o yaml" \
    "normal"

# 7.9 HPA 설정 확인
run_check "HPA 설정 확인" \
    "kubectl get hpa --all-namespaces" \
    "normal"

# 7.10 PVC 및 PV 상태 확인
run_check "PVC 및 PV 상태 확인" \
    "kubectl get pvc,pv --all-namespaces" \
    "normal"

# 7.11 스토리지 클래스 확인
run_check "스토리지 클래스 확인" \
    "kubectl get storageclass" \
    "normal"

# 7.12 Pod Affinity 및 Anti-Affinity 설정 확인
run_check "Pod Affinity 및 Anti-Affinity 설정 확인" \
    "kubectl get pods -o json | jq '.items[].spec.affinity'" \
    "low"

# 7.13 API 서버 로그 확인
run_check "API 서버 로그 확인" \
    "kubectl logs -n kube-system -l component=kube-apiserver --tail=50" \
    "normal"

echo "✅ AKS 클러스터 점검 완료" | tee -a $RESULT_FILE
echo "📊 결과 요약:" | tee -a $RESULT_FILE
echo "- 점검 시간: $(date)" | tee -a $RESULT_FILE
echo "- 점검 대상 클러스터: $AKS_CLUSTER" | tee -a $RESULT_FILE
echo "- 로그 파일 위치: $RESULT_FILE" | tee -a $RESULT_FILE

# 종료 메시지
echo ""
echo "=========================================================="
echo "✅ AKS 클러스터 점검이 완료되었습니다."
echo "📝 상세 결과는 로그 파일을 확인하세요: $RESULT_FILE"
echo "==========================================================" 