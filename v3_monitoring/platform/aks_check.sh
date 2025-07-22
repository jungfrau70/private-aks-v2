#!/bin/bash

# AKS 플랫폼 점검 스크립트 (2차 기술지원용)
# 이 스크립트는 AKS 클러스터의 플랫폼 수준 상세 점검을 수행합니다.

# 환경 변수 파일 로드
source ./aks_check.env

# 기본 값 설정
LOG_DIR="./logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/aks_platform_${TIMESTAMP}.log"
HTML_LOG_FILE="${LOG_DIR}/aks_platform_${TIMESTAMP}.html"

# 로그 디렉토리가 없으면 생성
mkdir -p ${LOG_DIR}

# 색상 코드 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# 로그 파일 초기화
init_log_files() {
    # 텍스트 로그 파일 헤더
    cat > ${LOG_FILE} << EOF
============================================
     AKS 플랫폼 상태 점검 보고서
     실행 시각: $(date)
============================================

EOF

    # HTML 로그 파일 헤더
    cat > ${HTML_LOG_FILE} << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f8f9fa; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #dee2e6; border-radius: 5px; }
        .success { color: #28a745; }
        .warning { color: #ffc107; }
        .error { color: #dc3545; }
        .info { color: #17a2b8; }
        .timestamp { color: #6c757d; }
        .summary { background-color: #e9ecef; padding: 15px; margin-top: 20px; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 8px; text-align: left; border: 1px solid #dee2e6; }
        th { background-color: #f8f9fa; }
        .status-healthy { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-unhealthy { color: #dc3545; }
        .details { margin-left: 20px; }
        .metric-normal { color: #28a745; }
        .metric-warning { color: #ffc107; }
        .metric-critical { color: #dc3545; }
    </style>
</head>
<body>
    <div class="header">
        <h1>AKS 플랫폼 상태 점검 보고서</h1>
        <p class="timestamp">점검 시각: $(date)</p>
    </div>
EOF
}

# 로그 메시지 출력 함수
log_message() {
    local message="$1"
    local level="${2:-INFO}"
    
    # 개행 문자를 실제 개행으로 변환
    message=$(echo -e "$message")
    local masked_message=$(mask_sensitive_info "$message")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # HTML용 개행 변환
    local html_message=$(echo "$masked_message" | sed ':a;N;$!ba;s/\n/<br>/g')
    
    # 터미널 출력용 형식 (컬러)
    case $level in
        "ERROR")
            printf "${RED}[오류]${NC} %b\n" "$masked_message" >&2
            printf "[%s] [오류] %b\n" "$timestamp" "$masked_message" >> ${LOG_FILE}
            echo "<div class='section error'><strong>오류:</strong> $html_message</div>" >> ${HTML_LOG_FILE}
            ;;
        "WARNING")
            printf "${YELLOW}[경고]${NC} %b\n" "$masked_message"
            printf "[%s] [경고] %b\n" "$timestamp" "$masked_message" >> ${LOG_FILE}
            echo "<div class='section warning'><strong>경고:</strong> $html_message</div>" >> ${HTML_LOG_FILE}
            ;;
        "SUCCESS")
            printf "${GREEN}[성공]${NC} %b\n" "$masked_message"
            printf "[%s] [성공] %b\n" "$timestamp" "$masked_message" >> ${LOG_FILE}
            echo "<div class='section success'><strong>성공:</strong> $html_message</div>" >> ${HTML_LOG_FILE}
            ;;
        "SECTION")
            printf "\n${BLUE}${BOLD}=== %b ===${NC}\n" "$masked_message"
            printf "\n===========================================\n" >> ${LOG_FILE}
            printf "[%s] === %b ===\n" "$timestamp" "$masked_message" >> ${LOG_FILE}
            printf "===========================================\n" >> ${LOG_FILE}
            echo "<div class='section'><h2>$html_message</h2>" >> ${HTML_LOG_FILE}
            ;;
        "SECTION_END")
            echo "</div>" >> ${HTML_LOG_FILE}
            ;;
        *)
            printf "%b\n" "$masked_message"
            printf "[%s] %b\n" "$timestamp" "$masked_message" >> ${LOG_FILE}
            echo "<div class='details'>$html_message</div>" >> ${HTML_LOG_FILE}
            ;;
    esac
}

# 테이블 형식 출력 함수들
start_table() {
    local headers=("$@")
    echo "<table><tr>" >> ${HTML_LOG_FILE}
    for header in "${headers[@]}"; do
        echo "<th>$header</th>" >> ${HTML_LOG_FILE}
    done
    echo "</tr>" >> ${HTML_LOG_FILE}
}

add_table_row() {
    echo "<tr>" >> ${HTML_LOG_FILE}
    for cell in "$@"; do
        echo "<td>$cell</td>" >> ${HTML_LOG_FILE}
    done
    echo "</tr>" >> ${HTML_LOG_FILE}
}

end_table() {
    echo "</table>" >> ${HTML_LOG_FILE}
}

# 요약 정보 추가
add_summary() {
    local total_checks=$1
    local healthy_components=$2
    local warning_components=$3
    local unhealthy_components=$4
    
    echo "<div class='summary'>" >> ${HTML_LOG_FILE}
    echo "<h2>점검 요약</h2>" >> ${HTML_LOG_FILE}
    echo "<ul>" >> ${HTML_LOG_FILE}
    echo "<li>전체 점검 항목: $total_checks</li>" >> ${HTML_LOG_FILE}
    echo "<li>정상 상태: $healthy_components</li>" >> ${HTML_LOG_FILE}
    echo "<li>경고 상태: $warning_components</li>" >> ${HTML_LOG_FILE}
    echo "<li>비정상 상태: $unhealthy_components</li>" >> ${HTML_LOG_FILE}
    echo "</ul>" >> ${HTML_LOG_FILE}
    echo "</div>" >> ${HTML_LOG_FILE}
}

# HTML 파일 종료
finish_html() {
    echo "</body></html>" >> ${HTML_LOG_FILE}
    log_message "HTML 형식의 보고서가 생성되었습니다: ${HTML_LOG_FILE}" "SUCCESS"
}

# 민감 정보 마스킹 함수
mask_sensitive_info() {
    local content="$1"
    # 마스킹할 패턴 정의
    local patterns=(
        's/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/********-****-****-****-************/gi'  # UUID
        's/[A-Za-z0-9+/]{88,90}=[A-Za-z0-9+/]*={0,2}/************************************/g'  # Base64
        's/"clientId": "[^"]*"/"clientId": "****"/g'
        's/"clientSecret": "[^"]*"/"clientSecret": "****"/g'
        's/"subscriptionId": "[^"]*"/"subscriptionId": "****"/g'
        's/"tenantId": "[^"]*"/"tenantId": "****"/g'
        's/ssh-rsa [A-Za-z0-9+/]+[=]*/ssh-rsa ****/g'  # SSH 키
        's/password[=:][ ]*[^ ]*\b/password: ****/gi'   # 패스워드
        's/secret[=:][ ]*[^ ]*\b/secret: ****/gi'       # 시크릿
        's/token[=:][ ]*[^ ]*\b/token: ****/gi'         # 토큰
        's/key[=:][ ]*[^ ]*\b/key: ****/gi'             # 키
        's/managed-identity-id[=:][ ]*[^ ]*\b/managed-identity-id: ****/gi'  # Managed Identity
        's/principal-id[=:][ ]*[^ ]*\b/principal-id: ****/gi'  # Principal ID
    )
    
    local masked_content="$content"
    for pattern in "${patterns[@]}"; do
        masked_content=$(echo "$masked_content" | sed -E "$pattern")
    done
    echo "$masked_content"
}

# 명령어 실행 결과 로깅 함수
log_command() {
    local command="$1"
    local output
    output=$($command 2>&1)
    log_message "$(mask_sensitive_info "$output")"
}

# 클러스터 구성 확인
check_cluster_config() {
    log_message "\n=== 클러스터 구성 확인 ==="
    
    # 클러스터 정보 조회
    log_message "클러스터 기본 정보:"
    local k8s_version=$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query 'kubernetesVersion' -o tsv)
    log_message "- 쿠버네티스 버전: ${k8s_version}"
    
    # 네트워크 프로필 확인
    local network_plugin=$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query 'networkProfile.networkPlugin' -o tsv)
    local network_policy=$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query 'networkProfile.networkPolicy' -o tsv)
    log_message "\n네트워크 구성:"
    log_message "- 네트워크 플러그인: ${network_plugin:-'설정되지 않음'}"
    log_message "- 네트워크 정책: ${network_policy:-'설정되지 않음'}"
    
    # 애드온 상태 확인
    log_message "\n애드온 상태:"
    local addons=(
        "모니터링(Container Insights):omsagent"
        "HTTP 애플리케이션 라우팅:httpApplicationRouting"
        "Azure Policy:azurepolicy"
        "Azure Keyvault Secrets Provider:azureKeyvaultSecretsProvider"
        "Defender for Containers:defenderForContainers"
        "Open Service Mesh:openServiceMesh"
        "Ingress 애플리케이션 게이트웨이:ingressApplicationGateway"
        "Web Application Routing:webAppRouting"
        "Kubernetes 대시보드:kubeDashboard"
        "Azure Workload Identity:azureWorkloadIdentity"
        "Dapr:dapr"
        "GitOps:gitops"
    )
    
    for addon in "${addons[@]}"; do
        local addon_name="${addon%%:*}"
        local addon_key="${addon#*:}"
        local enabled=$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query "addonProfiles.${addon_key}.enabled" -o tsv 2>/dev/null)
        if [ "$enabled" = "true" ]; then
            log_message "- ${addon_name}: 활성화됨"
        else
            log_message "- ${addon_name}: 비활성화됨"
        fi
    done
}

# 노드풀 확인
check_node_pools() {
    log_message "\n=== 노드풀 상태 확인 ==="
    
    # 노드풀 정보 조회
    log_message "노드풀 기본 정보:"
    log_command "az aks nodepool list -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} -o table"
    
    # 자동 스케일링 설정 확인
    log_message "\n노드풀 상세 정보:"
    for pool in $(az aks nodepool list -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} --query '[].name' -o tsv); do
        log_message "\n노드풀: ${pool}"
        
        # 자동 스케일링 상태
        local auto_scaling=$(az aks nodepool show -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} -n ${pool} --query 'enableAutoScaling' -o tsv)
        log_message "- 자동 스케일링: ${auto_scaling:-false}"
        
        # 노드 수 설정
        local min_count=$(az aks nodepool show -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} -n ${pool} --query 'minCount' -o tsv)
        local max_count=$(az aks nodepool show -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} -n ${pool} --query 'maxCount' -o tsv)
        local current_count=$(az aks nodepool show -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} -n ${pool} --query 'count' -o tsv)
        
        log_message "- 현재 노드 수: ${current_count:-'정보 없음'}"
        if [ "$auto_scaling" = "true" ]; then
            log_message "- 최소 노드 수: ${min_count:-'정보 없음'}"
            log_message "- 최대 노드 수: ${max_count:-'정보 없음'}"
        fi
        
        # 노드 상태
        local power_state=$(az aks nodepool show -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} -n ${pool} --query 'powerState.code' -o tsv)
        log_message "- 전원 상태: ${power_state:-'정보 없음'}"
        
        # 프로비저닝 상태
        local provisioning_state=$(az aks nodepool show -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER_NAME} -n ${pool} --query 'provisioningState' -o tsv)
        log_message "- 프로비저닝 상태: ${provisioning_state:-'정보 없음'}"
    done
}

# 네트워크 연결성 확인
check_network() {
    log_message "\n=== 네트워크 연결성 확인 ==="
    
    # DNS 해석 테스트
    log_message "DNS 해석 테스트 중..."
    
    # 먼저 권한 확인
    if ! kubectl auth can-i create pod --namespace default &> /dev/null; then
        log_message "경고: DNS 테스트를 위한 파드 생성 권한이 없습니다"
        log_message "필요한 권한: default 네임스페이스에서 파드 생성 권한"
    else
        # DNS 테스트 파드 생성 및 테스트 실행
        kubectl run dns-test --image=mcr.microsoft.com/aks/fundamental/base-ubuntu:v0.0.11 --restart=Never --rm -i --timeout=10s -- nslookup kubernetes.default 2>&1 | while read -r line; do
            log_message "$line"
        done
    fi
    
    # 네트워크 정책 확인
    log_message "\n네트워크 정책 상태:"
    if kubectl get networkpolicies --all-namespaces &> /dev/null; then
        log_message "네트워크 정책 목록:"
        log_command "kubectl get networkpolicies --all-namespaces"
    else
        log_message "네트워크 정책이 설정되어 있지 않습니다"
    fi
}

# 스토리지 구성 확인
check_storage() {
    log_message "\n=== 스토리지 구성 확인 ==="
    
    # 스토리지 클래스 확인
    log_message "스토리지 클래스 상태:"
    local sc_list=$(kubectl get storageclass -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner,DEFAULT:.metadata.annotations."storageclass\.kubernetes\.io/is-default-class")
    log_message "$sc_list"
    
    # PVC 확인
    log_message "\n영구 볼륨 클레임(PVC) 상태:"
    local pvc_list=$(kubectl get pvc --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,VOLUME:.spec.volumeName,CAPACITY:.spec.resources.requests.storage,STORAGECLASS:.spec.storageClassName)
    log_message "$pvc_list"
}

# 클러스터 메트릭 확인
check_metrics() {
    log_message "\n=== 클러스터 메트릭 확인 ==="
    
    # 노드 리소스 사용량
    log_message "노드 리소스 사용량:"
    local node_metrics=$(kubectl top nodes 2>/dev/null)
    if [ $? -eq 0 ]; then
        log_message "$node_metrics"
        
        # 노드 리소스 사용량 분석
        log_message "\n노드 리소스 사용량 분석:"
        echo "$node_metrics" | tail -n +2 | while read -r line; do
            local node_name=$(echo "$line" | awk '{print $1}')
            local cpu_usage=$(echo "$line" | awk '{print $3}' | sed 's/%//')
            local memory_usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
            
            log_message "노드: $node_name"
            log_message "- CPU 사용률: $cpu_usage%"
            if [ ${cpu_usage%.*} -gt 80 ]; then
                log_message "  경고: CPU 사용률이 80%를 초과합니다"
            fi
            
            log_message "- 메모리 사용률: $memory_usage%"
            if [ ${memory_usage%.*} -gt 80 ]; then
                log_message "  경고: 메모리 사용률이 80%를 초과합니다"
            fi
        done
    else
        log_message "경고: 메트릭 서버에서 노드 메트릭을 가져올 수 없습니다"
    fi
    
    # 파드 리소스 사용량 (상위 10개)
    log_message "\n파드 리소스 사용량 (메모리 기준 상위 10개):"
    local pod_metrics=$(kubectl top pods --all-namespaces 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$pod_metrics" | head -n 1
        echo "$pod_metrics" | tail -n +2 | sort -k 4 -h -r | head -n 10
    else
        log_message "경고: 메트릭 서버에서 파드 메트릭을 가져올 수 없습니다"
    fi
}

# 보안 설정 확인
check_security() {
    log_message "\n=== 보안 설정 확인 ==="
    
    # RBAC 설정 요약
    log_message "RBAC 설정 요약:"
    log_message "1. ClusterRoles:"
    kubectl get clusterroles --no-headers 2>/dev/null | wc -l | xargs -I {} echo "총 ClusterRole 수: {}개" || log_message "ClusterRoles 정보를 가져올 수 없습니다"
    
    log_message "\n2. ClusterRoleBindings:"
    kubectl get clusterrolebindings --no-headers 2>/dev/null | wc -l | xargs -I {} echo "총 ClusterRoleBinding 수: {}개" || log_message "ClusterRoleBindings 정보를 가져올 수 없습니다"
    
    # 주요 RBAC 역할 확인
    log_message "\n주요 관리자 역할:"
    kubectl get clusterrolebindings -o custom-columns=NAME:.metadata.name,ROLE:.roleRef.name 2>/dev/null | grep -E 'admin|cluster-admin' || log_message "관리자 역할을 찾을 수 없습니다"
    
    # Pod Security Policy 확인
    log_message "\nPod Security Policy 상태:"
    if kubectl get psp &> /dev/null; then
        log_message "- Pod Security Policy가 활성화되어 있습니다"
        log_command "kubectl get psp -o custom-columns=NAME:.metadata.name,PRIV:.spec.privileged,VOLUMES:.spec.volumes"
    else
        log_message "- Pod Security Policy가 비활성화되어 있습니다"
        log_message "- 권장: Pod Security Standards 또는 Pod Security Admission을 고려하세요"
    fi
}

# 로깅 및 모니터링 확인
check_monitoring() {
    log_message "\n=== 로깅 및 모니터링 확인 ==="
    
    # 진단 설정 확인
    log_message "진단 설정 상태:"
    if az monitor diagnostic-settings list --resource ${CLUSTER_NAME} --resource-group ${RESOURCE_GROUP} --resource-type Microsoft.ContainerService/managedClusters -o tsv &> /dev/null; then
        log_message "- 진단 설정이 구성되어 있습니다"
        
        # 로그 카테고리 상태 확인
        local diag_settings=$(az monitor diagnostic-settings list --resource ${CLUSTER_NAME} --resource-group ${RESOURCE_GROUP} --resource-type Microsoft.ContainerService/managedClusters --query '[0].logs[].{Category:category,Enabled:enabled}' -o tsv)
        log_message "\n로그 카테고리 상태:"
        echo "$diag_settings" | while read -r category enabled; do
            if [ "$enabled" = "true" ]; then
                log_message "- ${category}: 활성화됨"
            else
                log_message "- ${category}: 비활성화됨"
            fi
        done
        
        # 메트릭 상태 확인
        local metrics_enabled=$(az monitor diagnostic-settings list --resource ${CLUSTER_NAME} --resource-group ${RESOURCE_GROUP} --resource-type Microsoft.ContainerService/managedClusters --query '[0].metrics[0].enabled' -o tsv)
        log_message "\n메트릭 수집 상태:"
        if [ "$metrics_enabled" = "true" ]; then
            log_message "- 메트릭 수집이 활성화되어 있습니다"
        else
            log_message "- 메트릭 수집이 비활성화되어 있습니다"
        fi
    else
        log_message "- 경고: 진단 설정이 구성되어 있지 않습니다"
        log_message "- 권장: Azure Monitor를 통한 로깅 및 모니터링 설정을 검토하세요"
    fi
    
    # Prometheus 메트릭 확인
    log_message "\nPrometheus 모니터링 상태:"
    if kubectl get servicemonitors --all-namespaces &> /dev/null; then
        log_message "- ServiceMonitor가 구성되어 있습니다"
        log_message "ServiceMonitor 목록:"
        log_command "kubectl get servicemonitors --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,SELECTOR:.spec.selector.matchLabels"
    else
        log_message "- ServiceMonitor가 구성되어 있지 않습니다"
        log_message "- 권장: Prometheus 모니터링 설정을 검토하세요"
    fi
}

# 메인 실행
main() {
    check_cluster_config
    check_node_pools
    check_network
    check_storage
    check_metrics
    check_security
    check_monitoring
    
    log_message "\n=== 플랫폼 상태 점검 완료 ==="
    log_message "상세 결과는 다음 파일에서 확인할 수 있습니다: ${LOG_FILE}"
}

main
