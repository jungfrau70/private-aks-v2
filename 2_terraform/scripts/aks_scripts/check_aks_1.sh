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
LOG_FILE="$LOG_DIR/aks_check_${AKS_CLUSTER}_$TIMESTAMP.log"
echo "=== AKS 점검 결과 ($(date)) ===" > $LOG_FILE

# 함수: 명령어 실행 후 결과 저장
run_check() {
    echo -e "\n$1" | tee -a $LOG_FILE
    echo "--------------------------------------------------------" | tee -a $LOG_FILE
    eval "$2" 2>/dev/null | tee -a $LOG_FILE
    echo -e "\n" | tee -a $LOG_FILE
}

# 1. AKS RBAC 활성화 여부
run_check "[1] AKS RBAC 활성화 여부" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"enableRBAC\" --output json"

# 2. Kubernetes RBAC 설정 확인
run_check "[2] Kubernetes RBAC 설정" \
    "kubectl get roles,rolebindings,clusterroles,clusterrolebindings --all-namespaces"

# 3. 네트워크 정책 확인
run_check "[3] 네트워크 정책 설정 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.networkPolicy\" --output json"

# 4. 네트워크 플러그인 확인
run_check "[4] 네트워크 플러그인 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.networkPlugin\" --output json"

# 5. Secret 및 ConfigMap 확인
run_check "[5] Secret 및 ConfigMap 설정" \
    "kubectl get secret,configmap --all-namespaces"

# 6. 컨테이너 보안 정책 확인
run_check "[6] Root 권한 및 보안 설정 확인" \
    "kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].securityContext}'"

# 7. ACR 이미지 스캔 정책 확인
run_check "[7] ACR 이미지 보안 스캔 설정" \
    "az acr show --name $ACR_NAME --query \"policies\" --output json"

# 8. Key Vault 설정 확인
run_check "[8] Key Vault 설정 확인" \
    "az keyvault show --name $KEYVAULT_NAME --query \"properties.sku.name\" --output json"

# 9. 노드 상태 확인
run_check "[9] AKS 노드 상태 확인" \
    "kubectl get nodes -o wide"

# 10. Pod 상태 확인
run_check "[10] AKS Pod 상태 확인" \
    "kubectl get pods --all-namespaces -o wide"

# 11. Namespace 리스트 확인
run_check "[11] Kubernetes Namespace 리스트" \
    "kubectl get namespace"

# 12. Ingress 설정 확인
run_check "[12] Ingress 컨트롤러 상태 확인" \
    "kubectl get ingress --all-namespaces"

# 13. DNS 설정 확인
run_check "[13] CoreDNS 설정 확인" \
    "kubectl get configmap -n kube-system coredns -o yaml"

# 14. Auto Scaling (HPA) 설정 확인
run_check "[14] Horizontal Pod Autoscaler (HPA) 설정" \
    "kubectl get hpa --all-namespaces"

# 15. Cluster Autoscaler 설정 확인
run_check "[15] Cluster Autoscaler 설정" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"autoScalerProfile\" --output json"

# 16. PVC 및 PV 상태 확인
run_check "[16] PersistentVolumeClaim (PVC) 및 PersistentVolume (PV) 확인" \
    "kubectl get pvc,pv --all-namespaces"

# 17. Node 가용 영역 배치 확인
run_check "[17] 노드 가용 영역 배치 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"agentPoolProfiles[].availabilityZones\" --output json"

# 18. Pod 이중화(Affinity 및 Anti-Affinity) 설정 확인
run_check "[18] Pod Affinity 및 Anti-Affinity 설정 확인" \
    "kubectl get pods -o json | jq '.items[].spec.affinity'"

# 19. Azure Monitor 설정 확인
run_check "[19] Azure Monitor 활성화 여부" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.omsAgent.enabled\" --output json"

# 20. 컨테이너 모니터링 설정 확인
run_check "[20] 컨테이너 모니터링 설정 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.omsAgent.config.logAnalyticsWorkspaceResourceID\" --output json"

# 21. API 서버 로그 확인
run_check "[21] API 서버 로그 확인" \
    "kubectl logs -n kube-system -l component=kube-apiserver --tail=50"

# 22. 어플리케이션 Gateway 연동 확인
run_check "[22] Application Gateway 연동 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.ingressApplicationGateway.enabled\" --output json"

# 23. 프라이빗 클러스터 확인
run_check "[23] 프라이빗 클러스터 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"apiServerAccessProfile.enablePrivateCluster\" --output json"

# 24. 로드 밸런서 SKU 확인
run_check "[24] 로드 밸런서 SKU 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.loadBalancerSku\" --output json"

# 25. 아웃바운드 타입 확인
run_check "[25] 아웃바운드 타입 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.outboundType\" --output json"

echo "=== AKS 점검 완료. 결과 파일: $LOG_FILE ==="
