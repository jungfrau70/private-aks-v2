#!/bin/bash

# 환경 파일 로드
if [ -f "aks_archi_env.conf" ]; then
    source aks_archi_env.conf
else
    echo "환경 파일(aks_env.conf)이 존재하지 않습니다."
    exit 1
fi

# 결과 파일 설정
RESULT_FILE="aks_check_results.txt"
echo "AKS 아키텍처 및 버전 점검 결과" > $RESULT_FILE
echo "=====================================" >> $RESULT_FILE

# Private AKS 확인
echo "[1] Private AKS 확인" | tee -a $RESULT_FILE
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "privateFQDN" -o tsv | tee -a $RESULT_FILE

# VNet 통합 확인
echo "[2] VNet 통합 확인" | tee -a $RESULT_FILE
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "networkProfile.networkPlugin" -o tsv | tee -a $RESULT_FILE

# Application Gateway 활성화 확인
echo "[3] Application Gateway 활성화 확인" | tee -a $RESULT_FILE
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "ingressProfile.webAppRouting.enabled" -o tsv | tee -a $RESULT_FILE

# Azure AD 연동 확인
echo "[4] Azure AD 연동 확인" | tee -a $RESULT_FILE
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "aadProfile" -o json | tee -a $RESULT_FILE

# Bastion 존재 확인
echo "[5] Bastion 확인" | tee -a $RESULT_FILE
az network bastion show --resource-group $RESOURCE_GROUP --name $BASTION_NAME -o json | tee -a $RESULT_FILE

# Hub & Spoke VNet 확인
echo "[6] Hub & Spoke VNet 확인" | tee -a $RESULT_FILE
az network vnet list -o table | tee -a $RESULT_FILE
echo "VNet Peering 확인" | tee -a $RESULT_FILE
az network vnet peering list --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME -o json | tee -a $RESULT_FILE

# Private ACR 사용 확인
echo "[7] Private ACR 사용 확인" | tee -a $RESULT_FILE
az acr show --name $ACR_NAME --query "sku.name" -o tsv | tee -a $RESULT_FILE
echo "ACR 네트워크 제한 확인" | tee -a $RESULT_FILE
ez acr show --name $ACR_NAME --query "networkRuleSet" -o json | tee -a $RESULT_FILE

# Key Vault 연동 확인
echo "[8] Azure Key Vault 확인" | tee -a $RESULT_FILE
ez keyvault list --resource-group $RESOURCE_GROUP -o table | tee -a $RESULT_FILE
echo "Key Vault 네트워크 제한 확인" | tee -a $RESULT_FILE
ez keyvault show --name $KEYVAULT_NAME --query "properties.networkAcls.defaultAction" -o tsv | tee -a $RESULT_FILE

# AKS 버전 확인
echo "[9] AKS 버전 확인" | tee -a $RESULT_FILE
ez aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query "kubernetesVersion" -o tsv | tee -a $RESULT_FILE

# 업그레이드 가능한 버전 확인
echo "[10] 업그레이드 가능 버전 확인" | tee -a $RESULT_FILE
ez aks get-upgrades --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME -o table | tee -a $RESULT_FILE

echo "점검 완료. 결과는 $RESULT_FILE 파일을 확인하세요."
