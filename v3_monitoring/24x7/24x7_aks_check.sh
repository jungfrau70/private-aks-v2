#!/bin/bash

# AKS 24x7 점검 스크립트 (1차 기술지원용)
# 이 스크립트는 AKS 클러스터의 기본적인 상태를 점검합니다.

# 환경 변수 파일 로드
source ./24x7_aks_check.env

# 기본 값 설정
LOG_DIR="./logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/24x7_aks_${TIMESTAMP}.log"
HTML_LOG_FILE="${LOG_DIR}/24x7_aks_${TIMESTAMP}.html"
TIMEOUT=30  # 명령어 실행 타임아웃 (초)

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
     AKS 24x7 모니터링 보고서
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
        .status-ok { color: #28a745; }
        .status-warning { color: #ffc107; }
        .status-error { color: #dc3545; }
        .details { margin-left: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>AKS 24x7 모니터링 보고서</h1>
        <p class="timestamp">점검 시각: $(date)</p>
    </div>
EOF
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
    )
    
    local masked_content="$content"
    for pattern in "${patterns[@]}"; do
        masked_content=$(echo "$masked_content" | sed -E "$pattern")
    done
    echo "$masked_content"
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

# 오류 처리 함수
handle_error() {
    local error_message="$1"
    log_message "오류 발생: ${error_message}"
    return 1
}

# 명령어 실행 결과 로깅 함수 (타임아웃 포함)
log_command() {
    local command="$1"
    local output
    
    # timeout 명령어로 실행
    output=$(timeout ${TIMEOUT} bash -c "$command" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 124 ]; then
        handle_error "명령어 실행 시간 초과: $command"
        return 1
    elif [ $exit_code -ne 0 ]; then
        handle_error "명령어 실행 실패: $command"
        log_message "$(mask_sensitive_info "$output")"
        return 1
    fi
    
    log_message "$(mask_sensitive_info "$output")"
    return 0
}

# 필수 도구 설치 여부 확인
check_prerequisites() {
    log_message "\n=== 필수 도구 설치 여부 확인 ==="
    for tool in az kubectl; do
        if ! command -v $tool &> /dev/null; then
            log_message "오류: $tool이 설치되어 있지 않습니다"
            exit 1
        fi
    done
    log_message "모든 필수 도구가 설치되어 있습니다"
}

# Azure 로그인 상태 확인
check_azure_login() {
    log_message "\n=== Azure 로그인 상태 확인 ==="
    if ! az account show &> /dev/null; then
        log_message "오류: Azure에 로그인되어 있지 않습니다. 'az login' 명령어를 실행해주세요"
        exit 1
    fi
    log_message "Azure에 정상적으로 로그인되어 있습니다"
    
    # 현재 구독 설정
    az account set --subscription "${SUBSCRIPTION_ID}"
    
    # AKS 자격 증명 가져오기
    log_message "AKS 클러스터 자격 증명을 가져오는 중..."
    if ! az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" --overwrite-existing; then
        log_message "오류: AKS 클러스터 자격 증명을 가져오는데 실패했습니다"
        exit 1
    fi
    log_message "AKS 클러스터 자격 증명을 성공적으로 가져왔습니다"
}

# AKS 클러스터 상태 확인
check_aks_status() {
    log_message "\n=== AKS 클러스터 상태 확인 ==="
    local cluster_status=$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} -o json)
    
    # 클러스터 존재 여부 확인
    if [ $? -ne 0 ]; then
        log_message "오류: 클러스터 상태 확인 실패"
        return 1
    fi

    # 클러스터 상태 마스킹 및 로깅
    local masked_status=$(mask_sensitive_info "$cluster_status")
    
    # 프로비저닝 상태 확인
    local provisioning_state=$(echo ${masked_status} | grep -oP '"provisioningState": "\K[^"]+' | sed 's/"//g')
    log_message "클러스터 프로비저닝 상태: ${provisioning_state}"

    # 전원 상태 확인
    local power_state=$(echo ${masked_status} | grep -oP '"code": "\K[^"]+' | sed 's/"//g')
    log_message "클러스터 전원 상태: ${power_state}"
}

# 노드 상태 확인
check_node_status() {
    log_message "\n=== 노드 상태 확인 ==="
    log_command "kubectl get nodes -o wide"
    
    # NotReady 노드 확인
    local not_ready_nodes=$(kubectl get nodes | grep -c "NotReady")
    if [ ${not_ready_nodes} -gt 0 ]; then
        log_message "경고: ${not_ready_nodes}개의 노드가 NotReady 상태입니다"
    else
        log_message "모든 노드가 정상 상태입니다"
    fi
}

# 파드 상태 확인
check_pod_status() {
    log_message "\n=== 파드 상태 확인 ==="
    local pod_output
    local problem_pods=0 # Initialize to 0

    # Run kubectl with -A flag instead of --all-namespaces
    pod_output=$(kubectl get pods -A 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_message "오류: 파드 상태를 가져오는 데 실패했습니다."
        log_message "$pod_output" # Log the error output from kubectl
        return 1 # Indicate failure
    fi

    # Log the full output (masked)
    log_message "$(mask_sensitive_info "$pod_output")"

    # Filter for non-running/completed pods and count (excluding header)
    problem_pods=$(echo "$pod_output" | grep -E -v 'Running|Completed' | grep -v 'NAMESPACE' | wc -l)

    if [ ${problem_pods} -gt 0 ]; then
        log_message "경고: ${problem_pods}개의 파드가 비정상 상태입니다"
        # Log the specific problematic pods
        log_message "비정상 상태 파드 목록:"
        echo "$pod_output" | grep -E -v 'Running|Completed' | grep -v 'NAMESPACE' | while read line; do
            log_message "$line"
        done
    else
        log_message "모든 파드가 정상 실행 중입니다"
    fi
}

# 시스템 서비스 확인
check_system_services() {
    log_message "\n=== 시스템 서비스 상태 확인 ==="
    log_command "kubectl get pods -n kube-system"
}

# 메인 실행
main() {
    check_prerequisites
    check_azure_login
    check_aks_status
    check_node_status
    check_pod_status
    check_system_services
    
    log_message "\n=== 상태 점검 완료 ==="
    log_message "상세 결과는 다음 파일에서 확인할 수 있습니다: ${LOG_FILE}"
}

main
