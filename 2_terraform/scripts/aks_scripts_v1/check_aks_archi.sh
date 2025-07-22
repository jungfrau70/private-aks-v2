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
RESULT_FILE="$LOG_DIR/aks_archi_check_${AKS_CLUSTER}_$TIMESTAMP.log"
echo "AKS 아키텍처 및 버전 점검 결과 ($(date))" > $RESULT_FILE
echo "=====================================" >> $RESULT_FILE

# 함수: 명령어 실행 후 결과 저장
run_check() {
    echo -e "\n$1" | tee -a $RESULT_FILE
    echo "--------------------------------------------------------" | tee -a $RESULT_FILE
    eval "$2" 2>/dev/null | tee -a $RESULT_FILE
    echo -e "\n" | tee -a $RESULT_FILE
}

# Private AKS 확인
run_check "[1] Private AKS 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"apiServerAccessProfile.enablePrivateCluster\" -o tsv"

# VNet 통합 확인
run_check "[2] VNet 통합 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"networkProfile.networkPlugin\" -o tsv"

# Application Gateway 활성화 확인
run_check "[3] Application Gateway 확인" \
    "az network application-gateway show --resource-group $RESOURCE_GROUP_HUB --name $APPGW_NAME --query \"sku.name\" -o tsv"

# Azure AD 연동 확인
run_check "[4] Azure AD 연동 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"aadProfile\" -o json"

# Bastion 존재 확인
run_check "[5] Bastion 확인" \
    "az network bastion show --resource-group $RESOURCE_GROUP_HUB --name $BASTION_NAME --query \"sku.name\" -o tsv"

# Jumpbox 확인
run_check "[6] Jumpbox 확인" \
    "az vm show --resource-group $RESOURCE_GROUP_HUB --name $JUMPBOX_NAME --query \"hardwareProfile.vmSize\" -o tsv"

# Hub & Spoke VNet 확인
run_check "[7] Hub VNet 확인" \
    "az network vnet show --resource-group $RESOURCE_GROUP_HUB --name $HUB_VNET_NAME --query \"addressSpace.addressPrefixes\" -o json"

run_check "[8] Spoke VNet 확인" \
    "az network vnet show --resource-group $RESOURCE_GROUP_SPOKE --name $SPOKE_VNET_NAME --query \"addressSpace.addressPrefixes\" -o json"

run_check "[9] Storage VNet 확인" \
    "az network vnet show --resource-group $RESOURCE_GROUP_STORAGE --name $STORAGE_VNET_NAME --query \"addressSpace.addressPrefixes\" -o json"

run_check "[10] VNet Peering 확인 (Hub-Spoke)" \
    "az network vnet peering list --resource-group $RESOURCE_GROUP_HUB --vnet-name $HUB_VNET_NAME -o table"

run_check "[11] VNet Peering 확인 (Hub-Storage)" \
    "az network vnet peering list --resource-group $RESOURCE_GROUP_HUB --vnet-name $HUB_VNET_NAME --query \"[?contains(name, 'storage')].peeringState\" -o tsv"

# Private ACR 사용 확인
run_check "[12] ACR 확인" \
    "az acr show --name $ACR_NAME --query \"sku.name\" -o tsv"

run_check "[13] ACR 네트워크 제한 확인" \
    "az acr show --name $ACR_NAME --query \"networkRuleSet\" -o json"

# Key Vault 연동 확인
run_check "[14] Azure Key Vault 확인" \
    "az keyvault show --name $KEYVAULT_NAME --query \"properties.sku.name\" -o tsv"

run_check "[15] Key Vault 네트워크 제한 확인" \
    "az keyvault show --name $KEYVAULT_NAME --query \"properties.networkAcls.defaultAction\" -o tsv"

# AKS 버전 확인
run_check "[16] AKS 버전 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"kubernetesVersion\" -o tsv"

# 업그레이드 가능한 버전 확인
run_check "[17] 업그레이드 가능 버전 확인" \
    "az aks get-upgrades --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER -o table"

# Log Analytics 확인
run_check "[18] Log Analytics 확인" \
    "az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP_HUB --workspace-name $LOG_ANALYTICS_WORKSPACE --query \"sku.name\" -o tsv"

# AKS 모니터링 확인
run_check "[19] AKS 모니터링 확인" \
    "az aks show --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER --query \"addonProfiles.omsagent.enabled\" -o tsv"

# 프라이빗 엔드포인트 확인
run_check "[20] 프라이빗 엔드포인트 확인" \
    "az network private-endpoint list --resource-group $RESOURCE_GROUP_SPOKE -o table"

echo "점검 완료. 결과는 $RESULT_FILE 파일을 확인하세요."
