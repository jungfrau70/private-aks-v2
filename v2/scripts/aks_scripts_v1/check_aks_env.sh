#!/bin/bash

# AKS 클러스터 정보
RESOURCE_GROUP_HUB="rg-hub"
RESOURCE_GROUP_SPOKE="rg-spoke"
RESOURCE_GROUP_STORAGE="rg-storage"
AKS_CLUSTER="aks-dev"
ACR_NAME="centralacrc92dai"
KEYVAULT_NAME="central-keyvault-unique"
APPGW_NAME="central-appgw"
BASTION_NAME="central-bastion"
JUMPBOX_NAME="central-jumpbox"
LOG_ANALYTICS_WORKSPACE="law-aks-workshop"
HUB_VNET_NAME="hub_vnet"
SPOKE_VNET_NAME="spoke_vnet"
STORAGE_VNET_NAME="storage_vnet"
LOG_FILE="check_aks_result_$(date +%Y%m%d_%H%M%S).log"
NAMESPACES='default,kube-system'

# 환경 변수 설정
export RESOURCE_GROUP_HUB=$RESOURCE_GROUP_HUB
export RESOURCE_GROUP_SPOKE=$RESOURCE_GROUP_SPOKE
export RESOURCE_GROUP_STORAGE=$RESOURCE_GROUP_STORAGE
export AKS_CLUSTER=$AKS_CLUSTER
export ACR_NAME=$ACR_NAME
export KEYVAULT_NAME=$KEYVAULT_NAME
export APPGW_NAME=$APPGW_NAME
export BASTION_NAME=$BASTION_NAME
export JUMPBOX_NAME=$JUMPBOX_NAME
export LOG_ANALYTICS_WORKSPACE=$LOG_ANALYTICS_WORKSPACE
export HUB_VNET_NAME=$HUB_VNET_NAME
export SPOKE_VNET_NAME=$SPOKE_VNET_NAME
export STORAGE_VNET_NAME=$STORAGE_VNET_NAME
export LOG_FILE=$LOG_FILE
export NAMESPACES=$NAMESPACES

# 스크립트 실행 경로 확인
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# 로그 파일 설정
export LOG_DIR="${SCRIPT_DIR}/logs"
mkdir -p "$LOG_DIR" 2>/dev/null

# 타임스탬프 생성
export TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

