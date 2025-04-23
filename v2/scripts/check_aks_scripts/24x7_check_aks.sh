#!/bin/bash

# 환경 파일 로드
if [ -f "check_aks.env" ]; then
    source check_aks.env
else
    echo "환경 파일(check_aks_env.sh)이 존재하지 않습니다."
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 로그 디렉토리 존재 여부 확인 및 생성
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
LOG_DIR=${SCRIPT_DIR}/check_aks_logs

if [ ! -d "$LOG_DIR" ]; then
    echo "로그 디렉토리($LOG_DIR)가 존재하지 않습니다. 생성합니다..."
    mkdir -p "$LOG_DIR"
fi

# 결과 파일 설정
LOG_FILE="$LOG_DIR/${BASH_SOURCE[0]%???}_${AKS_CLUSTER}_$TIMESTAMP.log"
echo "=== AKS 점검 결과 ($(date)) ===" > $LOG_FILE

# 함수: 명령어 실행 후 결과 저장
run_check() {
    echo -e "\n$1" | tee -a $LOG_FILE
    echo "-----------------------------------------------------------------------------------------------------------------" | tee -a $LOG_FILE
    eval "$2" 2>/dev/null | tee -a $LOG_FILE
    echo -e "\n" | tee -a $LOG_FILE
}

###########################################################################################################################
# 체크리스트 영역
###########################################################################################################################

check_list() {
    # 1. Azure Kubernetes 버전 확인	
    run_check "[CHK-1] Azure Kubernetes 버전 확인" \
        "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query \"kubernetesVersion\" --output json"

    # 2. 네트워크 정책(NetworkPolicy) 확인
    run_check "[CHK-2] 네트워크 정책(NetworkPolicy) 확인" \
        "kubectl get networkpolicy -A"

    # 3. 비밀 관리 확인
    run_check "[CHK-3] Keyvault 통합 비밀 관리 확인" \
        "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query \"addonProfiles.azureKeyvaultSecretsProvider.enabled\" --output json"

    # 4. Namespace 상태 확인
    run_check "[CHK-4] Namespace 상태 확인" \
        "kubectl get namespace"

    # 5. Pod 상태 확인
    run_check "[CHK-5] Pod 상태 확인" \
        "kubectl get pods --all-namespaces -o wide"

    # 6. Pod 사용량 확인
    run_check "[CHK-6] Pod 사용량 확인" \
        "kubectl top pod -A"

    # 7. Pod 사용 제한 설정 확인
    run_check "[CHK-7] Pod 사용 제한 설정 확인" \
        "kubectl describe ns"

    # 8. 서비스 확인
    run_check "[CHK-8] 서비스 확인" \
        "kubectl get svc -A"

    # 9. 엔드포인트 확인
    run_check "[CHK-9] 엔드포인트 확인" \
        "kubectl get endpoints -A"

    # 10. Pod auto scaling(HPA) 확인
    run_check "[CHK-10] auto scaling(HPA) 확인" \
        "kubectl get hpa -A"

    # 11. Persistent Volume Claim (PVC) 상태 확인
    run_check "[CHK-11] Persistent Volume Claim (PVC) 상태 확인" \
        "kubectl get pvc -A"

    # 12. Persistent Volume Claim (PVC) 상세 정보 확인
    run_check "[CHK-12] Persistent Volume Claim (PVC) 상세 정보 확인" \
        "kubectl describe pvc -A"

    # 13. Storage Account 연결 상태 확인
    run_check "[CHK-13] Storage Account 연결 상태 확인" \
        "az storage account list --resource-group $RESOURCE_GROUP --query \"[].{Name:name, Status:provisioningState}\" -o table"

    # 14. Pod 이중화(Affinity 및 Anti-Affinity) 설정 확인
    run_check "[CHK-14] Pod Affinity 및 Anti-Affinity 설정 확인" \
        "kubectl get pods -o json | jq '.items[].spec.affinity'"

    # 15. Azure Monitor 활성화 확인
    run_check "[CHK-15] Azure Monitor 활성화 확인" \
        "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query \"azureMonitorProfile.metrics.enabled\" --output json"

    echo "#############################################################################################################################################"
}

main() {
    check_list

    echo "=== AKS 점검 완료. 결과 파일: $LOG_FILE ==="
}

main
