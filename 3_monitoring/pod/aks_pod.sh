#!/bin/bash

# AKS 파드 점검 스크립트 (2차 기술지원용)
# 이 스크립트는 AKS 클러스터의 파드 수준 상세 점검을 수행합니다.

# 환경 변수 파일 로드
if [ ! -f "./aks_pod.env" ]; then
    echo "오류: aks_pod.env 파일을 찾을 수 없습니다."
    exit 1
fi
source ./aks_pod.env

# 환경 변수 검증
validate_env() {
    local missing_vars=()
    
    if [ -z "$RESOURCE_GROUP" ] || [ "$RESOURCE_GROUP" = "your-resource-group" ]; then
        missing_vars+=("RESOURCE_GROUP")
    fi
    if [ -z "$CLUSTER_NAME" ] || [ "$CLUSTER_NAME" = "your-cluster-name" ]; then
        missing_vars+=("CLUSTER_NAME")
    fi
    if [ -z "$SUBSCRIPTION_ID" ] || [ "$SUBSCRIPTION_ID" = "your-subscription-id" ]; then
        missing_vars+=("SUBSCRIPTION_ID")
    fi
    if [ -z "$LOCATION" ] || [ "$LOCATION" = "your-location" ]; then
        missing_vars+=("LOCATION")
    fi
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo "오류: 다음 환경 변수들이 올바르게 설정되지 않았습니다:"
        printf '%s\n' "${missing_vars[@]}"
        exit 1
    fi
}

# 기본 값 설정
LOG_DIR="./logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/aks_pod_${TIMESTAMP}.log"
HTML_LOG_FILE="${LOG_DIR}/aks_pod_${TIMESTAMP}.html"

# 로그 디렉토리가 없으면 생성
mkdir -p ${LOG_DIR}

# 색상 코드 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# HTML 스타일 정의
cat > ${HTML_LOG_FILE} << 'EOF'
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
        .pod-name { font-weight: bold; color: #0066cc; }
        .timestamp { color: #6c757d; }
        .summary { background-color: #e9ecef; padding: 15px; margin-top: 20px; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 8px; text-align: left; border: 1px solid #dee2e6; }
        th { background-color: #f8f9fa; }
        .status-running { color: #28a745; }
        .status-error { color: #dc3545; }
        .details { margin-left: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>AKS 파드 상태 점검 보고서</h1>
        <p class="timestamp">점검 시각: $(date)</p>
    </div>
EOF

# 로그 메시지 출력 함수 개선
log_message() {
    local message="$1"
    local level="${2:-INFO}" # 기본값은 INFO
    
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

# 테이블 형식 출력 시작
start_table() {
    local headers=("$@")
    echo "<table><tr>" >> ${HTML_LOG_FILE}
    for header in "${headers[@]}"; do
        echo "<th>$header</th>" >> ${HTML_LOG_FILE}
    done
    echo "</tr>" >> ${HTML_LOG_FILE}
}

# 테이블 행 추가
add_table_row() {
    echo "<tr>" >> ${HTML_LOG_FILE}
    for cell in "$@"; do
        echo "<td>$cell</td>" >> ${HTML_LOG_FILE}
    done
    echo "</tr>" >> ${HTML_LOG_FILE}
}

# 테이블 종료
end_table() {
    echo "</table>" >> ${HTML_LOG_FILE}
}

# 요약 정보 추가
add_summary() {
    local total_pods=$1
    local running_pods=$2
    local problem_pods=$3
    local namespaces=$4
    
    echo "<div class='summary'>" >> ${HTML_LOG_FILE}
    echo "<h2>점검 요약</h2>" >> ${HTML_LOG_FILE}
    echo "<ul>" >> ${HTML_LOG_FILE}
    echo "<li>검사한 네임스페이스: $namespaces</li>" >> ${HTML_LOG_FILE}
    echo "<li>전체 파드 수: $total_pods</li>" >> ${HTML_LOG_FILE}
    echo "<li>정상 실행 중인 파드: $running_pods</li>" >> ${HTML_LOG_FILE}
    echo "<li>문제가 있는 파드: $problem_pods</li>" >> ${HTML_LOG_FILE}
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
        's/connection[=:][ ]*[^ ]*\b/connection: ****/gi'  # Connection strings
        's/bearer [^ ]*\b/bearer ****/gi'  # Bearer tokens
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
    if ! output=$($command 2>&1); then
        log_message "경고: 명령어 실행 실패: $command"
        log_message "오류 메시지: $output"
        return 1
    fi
    log_message "$(mask_sensitive_info "$output")"
}

# 네임스페이스 목록 가져오기
get_namespaces() {
    if [ -n "$NAMESPACE" ]; then
        echo "$NAMESPACE"
    else
        kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null || echo "default"
    fi
}

# 특정 네임스페이스의 파드 상태 확인
check_pod_status() {
    local namespace=$1
    log_message "파드 상태 확인: ${namespace}" "SECTION"
    
    # 네임스페이스 존재 확인
    if ! kubectl get namespace "$namespace" &>/dev/null; then
        log_message "네임스페이스 ${namespace}가 존재하지 않습니다" "ERROR"
        return 1
    fi
    
    # 파드 상태 테이블 시작
    start_table "파드 이름" "상태" "준비상태" "재시작" "수명"
    
    # 네임스페이스의 모든 파드 조회
    local pods_output
    if ! pods_output=$(kubectl get pods -n "${namespace}" -o wide 2>&1); then
        log_message "파드 정보를 가져올 수 없습니다" "ERROR"
        log_message "오류 메시지: $pods_output" "ERROR"
        return 1
    fi
    
    echo "$pods_output" | while read -r pod_name status ready restarts age rest; do
        if [ "$pod_name" != "NAME" ]; then
            local status_class="status-running"
            if [ "$status" != "Running" ] && [ "$status" != "Completed" ]; then
                status_class="status-error"
            fi
            add_table_row "$pod_name" "<span class='$status_class'>$status</span>" "$ready" "$restarts" "$age"
        fi
    done
    
    end_table
    
    # 문제가 있는 파드 확인
    local problem_pods
    problem_pods=$(echo "$pods_output" | grep -v "Running\|Completed" | grep -v "NAME" || true)
    if [ -n "$problem_pods" ]; then
        log_message "문제가 있는 파드 발견:" "WARNING"
        echo "$problem_pods" | while read -r pod_line; do
            if [ -n "$pod_line" ]; then
                local pod_name=$(echo "$pod_line" | awk '{print $1}')
                log_message "파드 상세 정보: ${pod_name}" "WARNING"
                kubectl describe pod "${pod_name}" -n "${namespace}" 2>&1 | log_message
            fi
        done
    else
        log_message "모든 파드가 정상 실행 중입니다" "SUCCESS"
    fi
}

# 파드 리소스 사용량 확인
check_pod_resources() {
    local namespace=$1
    log_message "\n=== 파드 리소스 사용량 확인: ${namespace} ==="
    
    # 리소스 사용량 조회
    log_message "현재 리소스 사용량:"
    local top_output
    if ! top_output=$(kubectl top pods -n "${namespace}" 2>/dev/null); then
        log_message "경고: 메트릭 서버에서 리소스 사용량을 가져올 수 없습니다"
        log_message "메트릭 서버가 설치되어 있고 정상 작동하는지 확인하세요"
    else
        log_message "$top_output"
    fi
    
    # 리소스 제한 설정 확인
    log_message "\n파드 리소스 제한 설정:"
    local pods
    if ! pods=$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null); then
        log_message "경고: 파드 목록을 가져올 수 없습니다"
        return 1
    fi
    
    if [ -z "$pods" ]; then
        log_message "네임스페이스에 파드가 없습니다"
        return 0
    fi
    
    echo "$pods" | while read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        local pod_name=$(echo "$line" | awk '{print $1}')
        log_message "\n파드: ${pod_name}"
        
        # 컨테이너 목록 조회
        local containers
        if ! containers=$(kubectl get pod "${pod_name}" -n "${namespace}" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null); then
            log_message "경고: ${pod_name}의 컨테이너 정보를 가져올 수 없습니다"
            continue
        fi
        
        if [ -z "$containers" ]; then
            log_message "컨테이너가 없습니다"
            continue
        fi
        
        for container in $containers; do
            log_message "\n컨테이너: $container"
            
            # CPU 제한
            local cpu_limit
            cpu_limit=$(kubectl get pod "${pod_name}" -n "${namespace}" -o jsonpath="{.spec.containers[?(@.name=='$container')].resources.limits.cpu}" 2>/dev/null)
            log_message "CPU 제한: ${cpu_limit:-'설정되지 않음'}"
            
            # 메모리 제한
            local memory_limit
            memory_limit=$(kubectl get pod "${pod_name}" -n "${namespace}" -o jsonpath="{.spec.containers[?(@.name=='$container')].resources.limits.memory}" 2>/dev/null)
            log_message "메모리 제한: ${memory_limit:-'설정되지 않음'}"
            
            # CPU 요청
            local cpu_request
            cpu_request=$(kubectl get pod "${pod_name}" -n "${namespace}" -o jsonpath="{.spec.containers[?(@.name=='$container')].resources.requests.cpu}" 2>/dev/null)
            log_message "CPU 요청: ${cpu_request:-'설정되지 않음'}"
            
            # 메모리 요청
            local memory_request
            memory_request=$(kubectl get pod "${pod_name}" -n "${namespace}" -o jsonpath="{.spec.containers[?(@.name=='$container')].resources.requests.memory}" 2>/dev/null)
            log_message "메모리 요청: ${memory_request:-'설정되지 않음'}"
        done
    done
}

# 파드 네트워킹 확인
check_pod_networking() {
    local namespace=$1
    log_message "\n=== 파드 네트워킹 확인: ${namespace} ==="
    
    # 서비스 확인
    log_message "서비스 목록:"
    log_command "kubectl get services -n ${namespace}"
    
    # 엔드포인트 확인
    log_message "\n엔드포인트 목록:"
    log_command "kubectl get endpoints -n ${namespace}"
    
    # 네트워크 정책 확인
    log_message "\n네트워크 정책 목록:"
    if kubectl get networkpolicies -n ${namespace} &> /dev/null; then
        log_command "kubectl get networkpolicies -n ${namespace}"
    else
        log_message "네트워크 정책이 설정되어 있지 않습니다"
    fi
}

# 파드 볼륨 확인
check_pod_volumes() {
    local namespace=$1
    log_message "\n=== 파드 볼륨 확인: ${namespace} ==="
    
    # PVC 확인
    log_message "영구 볼륨 클레임(PVC) 목록:"
    if ! kubectl get pvc -n "${namespace}" 2>/dev/null; then
        log_message "PVC가 없거나 접근할 수 없습니다"
    fi
    
    # 파드별 볼륨 마운트 확인
    log_message "\n파드 볼륨 마운트 정보:"
    local pods
    if ! pods=$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null); then
        log_message "경고: 파드 목록을 가져올 수 없습니다"
        return 1
    fi
    
    if [ -z "$pods" ]; then
        log_message "네임스페이스에 파드가 없습니다"
        return 0
    fi
    
    echo "$pods" | while read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        local pod_name=$(echo "$line" | awk '{print $1}')
        log_message "\n파드: ${pod_name}"
        
        # 볼륨 정보 조회
        local pod_json
        if ! pod_json=$(kubectl get pod "${pod_name}" -n "${namespace}" -o json 2>/dev/null); then
            log_message "경고: 볼륨 정보를 가져올 수 없습니다"
            continue
        fi
        
        # 볼륨 목록 확인
        local volumes
        volumes=$(echo "$pod_json" | jq -r '.spec.volumes[]? | select(.name != null)' 2>/dev/null)
        if [ -z "$volumes" ]; then
            log_message "마운트된 볼륨이 없습니다"
            continue
        fi
        
        echo "$volumes" | while read -r volume; do
            if [ -z "$volume" ]; then
                continue
            fi
            
            local vol_name=$(echo "$volume" | jq -r '.name')
            log_message "\n볼륨 이름: $vol_name"
            
            # 볼륨 종류 확인
            if echo "$volume" | jq -e '.persistentVolumeClaim' >/dev/null 2>&1; then
                local pvc_name=$(echo "$volume" | jq -r '.persistentVolumeClaim.claimName')
                log_message "종류: PersistentVolumeClaim"
                log_message "PVC 이름: $pvc_name"
            elif echo "$volume" | jq -e '.configMap' >/dev/null 2>&1; then
                local cm_name=$(echo "$volume" | jq -r '.configMap.name')
                log_message "종류: ConfigMap"
                log_message "ConfigMap 이름: $cm_name"
            elif echo "$volume" | jq -e '.secret' >/dev/null 2>&1; then
                local secret_name=$(echo "$volume" | jq -r '.secret.secretName')
                log_message "종류: Secret"
                log_message "Secret 이름: $secret_name"
            elif echo "$volume" | jq -e '.emptyDir' >/dev/null 2>&1; then
                log_message "종류: EmptyDir"
                local medium=$(echo "$volume" | jq -r '.emptyDir.medium // "디스크"')
                log_message "저장 매체: $medium"
            elif echo "$volume" | jq -e '.hostPath' >/dev/null 2>&1; then
                log_message "종류: HostPath"
                log_message "경로: $(echo "$volume" | jq -r '.hostPath.path')"
            elif echo "$volume" | jq -e '.azureFile' >/dev/null 2>&1; then
                log_message "종류: AzureFile"
                log_message "공유 이름: $(echo "$volume" | jq -r '.azureFile.shareName')"
            elif echo "$volume" | jq -e '.azureDisk' >/dev/null 2>&1; then
                log_message "종류: AzureDisk"
                log_message "디스크 이름: $(echo "$volume" | jq -r '.azureDisk.diskName')"
            else
                log_message "종류: 기타"
                echo "$volume" | jq -r '.' | log_message
            fi
        done
        
        # 컨테이너별 마운트 정보
        log_message "\n컨테이너 마운트 정보:"
        echo "$pod_json" | jq -r '.spec.containers[]?' 2>/dev/null | while read -r container; do
            if [ -z "$container" ]; then
                continue
            fi
            
            local container_name=$(echo "$container" | jq -r '.name')
            log_message "\n컨테이너: $container_name"
            
            local mounts=$(echo "$container" | jq -r '.volumeMounts[]? | "  마운트 경로: \(.mountPath)\n  볼륨: \(.name)\n  읽기 전용: \(.readOnly // false)"' 2>/dev/null)
            if [ -n "$mounts" ]; then
                log_message "$mounts"
            else
                log_message "마운트된 볼륨 없음"
            fi
        done
    done
}

# 파드 로그 확인
check_pod_logs() {
    local namespace=$1
    log_message "\n=== 파드 로그 확인: ${namespace} ==="
    
    # 모든 파드의 로그 확인
    local pods
    if ! pods=$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null); then
        log_message "경고: 파드 목록을 가져올 수 없습니다"
        return 1
    fi
    
    if [ -z "$pods" ]; then
        log_message "네임스페이스에 파드가 없습니다"
        return 0
    fi
    
    echo "$pods" | while read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        local pod_name=$(echo "$line" | awk '{print $1}')
        log_message "\n파드 로그: ${pod_name}"
        
        # 컨테이너 목록 가져오기
        local containers
        containers=$(kubectl get pod "${pod_name}" -n "${namespace}" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null)
        if [ $? -ne 0 ]; then
            log_message "경고: 컨테이너 정보를 가져올 수 없습니다"
            continue
        fi
        
        for container in $containers; do
            log_message "\n컨테이너: ${container}"
            
            # 최근 300줄의 로그에서 에러 검사
            local error_logs
            local recent_logs
            if ! recent_logs=$(kubectl logs "${pod_name}" -c "${container}" -n "${namespace}" --tail=300 2>/dev/null); then
                log_message "경고: 로그를 가져올 수 없습니다"
                continue
            fi
            
            if ! error_logs=$(echo "$recent_logs" | grep -i "error\|exception\|failed\|실패\|오류\|예외" 2>/dev/null); then
                if [ $? -eq 1 ]; then
                    log_message "에러가 발견되지 않았습니다"
                    # 에러가 없는 경우 최근 로그 출력
                    log_message "\n최근 로그 (마지막 10줄):"
                    echo "$recent_logs" | tail -n 10 | log_message
                else
                    log_message "경고: 로그 검색 중 오류가 발생했습니다"
                fi
                continue
            fi
            
            # 에러가 발견된 경우
            if [ -n "$error_logs" ]; then
                log_message "최근 300줄에서 에러가 발견되었습니다. 각 에러의 최근 10줄 컨텍스트:"
                echo "$error_logs" | while read -r error_line; do
                    # 에러 라인 주변 10줄 가져오기 (에러 라인 포함)
                    local error_context
                    error_context=$(echo "$recent_logs" | grep -B 9 -F "$error_line" | tail -n 10)
                    if [ -n "$error_context" ]; then
                        log_message "\n--- 에러 컨텍스트 ---"
                        log_message "$error_context"
                        log_message "-------------------"
                    fi
                done
            fi
        done
    done
}

# 파드 이벤트 확인
check_pod_events() {
    local namespace=$1
    log_message "\n=== 파드 이벤트 확인: ${namespace} ==="
    
    # 시간순 정렬된 이벤트 조회
    local events=$(kubectl get events -n ${namespace} --sort-by='.metadata.creationTimestamp')
    if [ -z "$events" ]; then
        log_message "최근 이벤트가 없습니다"
    else
        log_message "$events"
    fi
}

# 파드 구성 확인
check_pod_config() {
    local namespace=$1
    log_message "\n=== 파드 구성 확인: ${namespace} ==="
    
    # 디플로이먼트 확인
    log_message "디플로이먼트 목록:"
    log_command "kubectl get deployments -n ${namespace}"
    
    # 레플리카셋 확인
    log_message "\n레플리카셋 목록:"
    log_command "kubectl get rs -n ${namespace}"
    
    # 컨피그맵 확인
    log_message "\n컨피그맵 목록:"
    log_command "kubectl get configmaps -n ${namespace}"
    
    # 시크릿 확인 (마스킹 처리)
    log_message "\n시크릿 목록:"
    local secrets_output=$(kubectl get secrets -n ${namespace} 2>&1)
    log_message "$(mask_sensitive_info "$secrets_output")"
}

# 로그 파일 초기화
init_log_files() {
    # 텍스트 로그 파일 헤더
    cat > ${LOG_FILE} << EOF
============================================
     AKS 파드 상태 점검 보고서
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
        .pod-name { font-weight: bold; color: #0066cc; }
        .timestamp { color: #6c757d; }
        .summary { background-color: #e9ecef; padding: 15px; margin-top: 20px; border-radius: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 8px; text-align: left; border: 1px solid #dee2e6; }
        th { background-color: #f8f9fa; }
        .status-running { color: #28a745; }
        .status-error { color: #dc3545; }
        .details { margin-left: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>AKS 파드 상태 점검 보고서</h1>
        <p class="timestamp">점검 시각: $(date)</p>
    </div>
EOF
}

# 메인 실행
main() {
    # 환경 변수 검증
    validate_env
    
    # 로그 파일 초기화
    init_log_files
    
    # Azure 로그인 상태 확인
    if ! az account show &>/dev/null; then
        log_message "오류: Azure에 로그인되어 있지 않습니다. 'az login' 명령어로 로그인하세요."
        exit 1
    fi
    
    # 클러스터 연결 상태 확인
    if ! kubectl cluster-info &>/dev/null; then
        log_message "오류: Kubernetes 클러스터에 연결할 수 없습니다."
        log_message "다음 명령어로 클러스터 자격 증명을 가져오세요:"
        log_message "az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${CLUSTER_NAME}"
        exit 1
    fi 
    
    # 네임스페이스 목록 가져오기
    local namespaces=($(get_namespaces))
    if [ ${#namespaces[@]} -eq 0 ]; then
        log_message "오류: 검사할 네임스페이스가 없습니다."
        exit 1
    fi
    
    # 통계 변수 초기화
    local total_pods=0
    local running_pods=0
    local problem_pods=0
    
    # 각 네임스페이스에 대해 점검 수행
    for namespace in "${namespaces[@]}"; do
        log_message "네임스페이스: ${namespace}" "SECTION"
        
        # 파드 수 계산
        local ns_pods=$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null | wc -l)
        local ns_running=$(kubectl get pods -n "${namespace}" --no-headers 2>/dev/null | grep "Running\|Completed" | wc -l)
        local ns_problems=$((ns_pods - ns_running))
        
        total_pods=$((total_pods + ns_pods))
        running_pods=$((running_pods + ns_running))
        problem_pods=$((problem_pods + ns_problems))
        
        check_pod_status "$namespace"
        check_pod_resources "$namespace"
        check_pod_networking "$namespace"
        check_pod_volumes "$namespace"
        check_pod_logs "$namespace"
        check_pod_events "$namespace"
        check_pod_config "$namespace"
        
        log_message "" "SECTION_END"
    done
    
    # 요약 정보 추가
    add_summary "$total_pods" "$running_pods" "$problem_pods" "${#namespaces[@]}"
    
    log_message "=== 파드 상태 점검 완료 ===" "SECTION"
    log_message "상세 결과는 다음 파일에서 확인할 수 있습니다:" "INFO"
    log_message "- 텍스트 로그: ${LOG_FILE}" "INFO"
    log_message "- HTML 보고서: ${HTML_LOG_FILE}" "INFO"
    
    finish_html
}

main
