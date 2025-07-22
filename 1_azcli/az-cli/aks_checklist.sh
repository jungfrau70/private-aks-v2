#!/bin/bash

# 환경 변수 불러오기
source env.sh

# 결과 파일 설정
echo "=== AKS 점검 결과 ($(date)) ===" > $LOG_FILE

# 함수: 명령어 실행 후 결과 저장
run_check() {
    echo -e "\n$1" | tee -a $LOG_FILE
    echo "--------------------------------------------------------" | tee -a $LOG_FILE
    eval "$2" | tee -a $LOG_FILE
    echo -e "\n" | tee -a $LOG_FILE
}

# 1. AKS RBAC 활성화 여부
run_check "[1] AKS RBAC 활성화 여부" \
    "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query \"enableRBAC\" --output json"

# 2. Kubernetes RBAC 설정 확인
run_check "[2] Kubernetes RBAC 설정" \
    "kubectl get roles,rolebindings,clusterroles,clusterrolebindings --all-namespaces"

# 3. 네트워크 정책 확인
run_check "[3] 네트워크 정책 설정 확인" \
    "kubectl get networkpolicy --all-namespaces"

# 4. Secret 및 ConfigMap 확인
run_check "[4] Secret 및 ConfigMap 설정" \
    "kubectl get secret,configmap --all-namespaces"

# 5. 컨테이너 보안 정책 확인
run_check "[5] Root 권한 및 보안 설정 확인" \
    "kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].securityContext}'"

# 6. ACR 이미지 스캔 정책 확인
run_check "[6] ACR 이미지 보안 스캔 설정" \
    "az acr show --name $ACR_NAME --query \"policies\" --output json"

# 7. Key Vault SSL 인증서 확인
run_check "[7] Key Vault 설정 확인" \
    "az keyvault list --resource-group $RESOURCE_GROUP --output table"

# 8. 노드 상태 확인
run_check "[8] AKS 노드 상태 확인" \
    "kubectl get nodes -o wide"

# 9. Pod 상태 확인
run_check "[9] AKS Pod 상태 확인" \
    "kubectl get pods --all-namespaces -o wide"

# 10. Namespace 리스트 확인
run_check "[10] Kubernetes Namespace 리스트" \
    "kubectl get namespace"

# 11. Ingress 설정 확인
run_check "[11] Ingress 컨트롤러 상태 확인" \
    "kubectl get ingress --all-namespaces"

# 12. DNS 설정 확인
run_check "[12] CoreDNS 설정 확인" \
    "kubectl get configmap -n kube-system coredns -o yaml"

# 13. Auto Scaling (HPA) 설정 확인
run_check "[13] Horizontal Pod Autoscaler (HPA) 설정" \
    "kubectl get hpa --all-namespaces"

# 14. Cluster Autoscaler 설정 확인
run_check "[14] Cluster Autoscaler 설정" \
    "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query \"autoScalerProfile\" --output json"

# 15. PVC 및 PV 상태 확인
run_check "[15] PersistentVolumeClaim (PVC) 및 PersistentVolume (PV) 확인" \
    "kubectl get pvc,pv --all-namespaces"

# 16. Node 가용 영역 배치 확인
run_check "[16] 노드 가용 영역 배치 확인" \
    "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query \"agentPoolProfiles[].availabilityZones\" --output json"

# 17. Pod 이중화(Affinity 및 Anti-Affinity) 설정 확인
run_check "[17] Pod Affinity 및 Anti-Affinity 설정 확인" \
    "kubectl get pods -o json | jq '.items[].spec.affinity'"

# 18. Azure Monitor 설정 확인
run_check "[18] Azure Monitor 활성화 여부" \
    "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query \"addonProfiles.omsAgent.enabled\" --output json"

# 19. 컨테이너 모니터링 설정 확인
run_check "[19] 컨테이너 모니터링 설정 확인" \
    "az aks show --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --query \"addonProfiles.omsAgent.config.logAnalyticsWorkspaceResourceID\" --output json"

# 20. API 서버 로그 확인
run_check "[20] API 서버 로그 확인" \
    "kubectl logs -n kube-system kube-apiserver-$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"

# 21. 어플리케이션 Pod 로그 확인
run_check "[21] 어플리케이션 Pod 로그 확인" \
    "kubectl logs --all-containers=true --all-namespaces"

echo "=== AKS 점검 완료. 결과 파일: $LOG_FILE ==="
