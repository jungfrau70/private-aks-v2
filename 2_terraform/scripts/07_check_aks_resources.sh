#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# AKS 클러스터 리소스 체크 시작
echo -e "\n${yellow}AKS 클러스터 관련 리소스 존재 여부 확인 중...${nc}"

# Azure CLI 로그인 상태 확인
echo -e "${yellow}Azure CLI 로그인 상태 확인 중...${nc}"
az account show &>/dev/null
if [ $? -ne 0 ]; then
  echo -e "${red}Azure CLI에 로그인되어 있지 않습니다. 로그인을 진행합니다.${nc}"
  az login
  if [ $? -ne 0 ]; then
    echo -e "${red}Azure CLI 로그인에 실패했습니다. 스크립트를 종료합니다.${nc}"
    exit 1
  fi
fi

# 구독 ID 가져오기
subscription_id=$(grep "subscription_id" terraform.tfvars | cut -d'"' -f2)
echo -e "${yellow}구독 ID: $subscription_id${nc}"

# 구독 설정
az account set --subscription "$subscription_id"
if [ $? -ne 0 ]; then
  echo -e "${red}구독 설정에 실패했습니다. 스크립트를 종료합니다.${nc}"
  exit 1
fi

# 리소스 그룹 이름 가져오기
spoke_rg=$(grep "resource_group_name_spoke" terraform.tfvars | cut -d'"' -f2)

# 리소스 그룹 존재 여부 확인
spoke_rg_exists=$(az group exists --name "$spoke_rg")

# AKS 클러스터 이름 가져오기
aks_clusters=$(grep -A 10 "aks_clusters" terraform.tfvars | grep "name" | cut -d'"' -f2)

# AKS 클러스터 존재 여부 확인
aks_cluster_exists=false
aks_node_pool_exists=false
aks_identity_exists=false

if [[ "$spoke_rg_exists" == "true" ]]; then
  for aks_name in $aks_clusters; do
    aks_check=$(MSYS_NO_PATHCONV=1 az aks show --resource-group "$spoke_rg" --name "$aks_name" --query "name" -o tsv 2>/dev/null)
    
    if [[ -n "$aks_check" ]]; then
      echo -e "${green}AKS 클러스터($aks_name)가 존재합니다. use_existing_aks_cluster = true로 설정합니다.${nc}"
      sed -i "s/use_existing_aks_cluster = .*/use_existing_aks_cluster = true/" terraform.tfvars
      aks_cluster_exists=true
      
      # AKS 노드 풀 존재 여부 확인
      aks_node_pools=$(MSYS_NO_PATHCONV=1 az aks nodepool list --resource-group "$spoke_rg" --cluster-name "$aks_name" --query "[].name" -o tsv 2>/dev/null)
      
      if [[ -n "$aks_node_pools" ]]; then
        echo -e "${green}AKS 노드 풀이 존재합니다. use_existing_aks_node_pool = true로 설정합니다.${nc}"
        sed -i "s/use_existing_aks_node_pool = .*/use_existing_aks_node_pool = true/" terraform.tfvars
        aks_node_pool_exists=true
      else
        echo -e "${yellow}AKS 노드 풀이 존재하지 않습니다. use_existing_aks_node_pool = false로 설정합니다.${nc}"
        sed -i "s/use_existing_aks_node_pool = .*/use_existing_aks_node_pool = false/" terraform.tfvars
      fi
      
      # AKS 관리 ID 존재 여부 확인
      aks_identity=$(MSYS_NO_PATHCONV=1 az aks show --resource-group "$spoke_rg" --name "$aks_name" --query "identity.principalId" -o tsv 2>/dev/null)
      
      if [[ -n "$aks_identity" ]]; then
        echo -e "${green}AKS 관리 ID가 존재합니다. use_existing_aks_identity = true로 설정합니다.${nc}"
        sed -i "s/use_existing_aks_identity = .*/use_existing_aks_identity = true/" terraform.tfvars
        aks_identity_exists=true
      else
        echo -e "${yellow}AKS 관리 ID가 존재하지 않습니다. use_existing_aks_identity = false로 설정합니다.${nc}"
        sed -i "s/use_existing_aks_identity = .*/use_existing_aks_identity = false/" terraform.tfvars
      fi
    fi
  done
  
  if [[ "$aks_cluster_exists" == "false" ]]; then
    echo -e "${yellow}AKS 클러스터가 존재하지 않습니다. use_existing_aks_cluster = false로 설정합니다.${nc}"
    sed -i "s/use_existing_aks_cluster = .*/use_existing_aks_cluster = false/" terraform.tfvars
    sed -i "s/use_existing_aks_node_pool = .*/use_existing_aks_node_pool = false/" terraform.tfvars
    sed -i "s/use_existing_aks_identity = .*/use_existing_aks_identity = false/" terraform.tfvars
  fi
else
  echo -e "${yellow}Spoke 리소스 그룹이 존재하지 않아 AKS 클러스터를 확인할 수 없습니다.${nc}"
  sed -i "s/use_existing_aks_cluster = .*/use_existing_aks_cluster = false/" terraform.tfvars
  sed -i "s/use_existing_aks_node_pool = .*/use_existing_aks_node_pool = false/" terraform.tfvars
  sed -i "s/use_existing_aks_identity = .*/use_existing_aks_identity = false/" terraform.tfvars
fi

# AKS 클러스터 리소스 존재 여부 요약
echo -e "\n${yellow}AKS 클러스터 리소스 존재 여부 요약:${nc}"
echo -e "AKS 클러스터 존재 여부: $aks_cluster_exists"
echo -e "AKS 노드 풀 존재 여부: $aks_node_pool_exists"
echo -e "AKS 관리 ID 존재 여부: $aks_identity_exists"
echo -e "AKS 클러스터 리소스 확인 완료" 