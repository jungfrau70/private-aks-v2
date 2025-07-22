#!/bin/bash

# 색상 정의
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
nc='\033[0m' # No Color

# 모니터링 리소스 체크 시작
echo -e "\n${yellow}모니터링 리소스 존재 여부 확인 중...${nc}"

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
hub_rg=$(grep "resource_group_name_hub" terraform.tfvars | cut -d'"' -f2)

# 리소스 그룹 존재 여부 확인
hub_rg_exists=$(az group exists --name "$hub_rg")

# Log Analytics 워크스페이스 이름 가져오기
log_analytics_workspace_name=$(grep "log_analytics_workspace_name" terraform.tfvars | cut -d'"' -f2)

# 모니터링 리소스 존재 여부 확인
log_analytics_exists=false
log_analytics_solution_exists=false
monitor_action_group_exists=false
monitor_alerts_exists=false

if [[ "$hub_rg_exists" == "true" ]]; then
  log_analytics_check=$(MSYS_NO_PATHCONV=1 az monitor log-analytics workspace show --resource-group "$hub_rg" --workspace-name "$log_analytics_workspace_name" --query "name" -o tsv 2>/dev/null)
  
  if [[ -n "$log_analytics_check" ]]; then
    echo -e "${green}Log Analytics 워크스페이스($log_analytics_workspace_name)가 존재합니다. use_existing_log_analytics = true로 설정합니다.${nc}"
    sed -i "s/use_existing_log_analytics = .*/use_existing_log_analytics = true/" terraform.tfvars
    log_analytics_exists=true
    
    # Log Analytics 솔루션 존재 여부 확인
    log_analytics_solution_check=$(MSYS_NO_PATHCONV=1 az monitor log-analytics solution list --resource-group "$hub_rg" --query "[?contains(name, 'ContainerInsights')].name" -o tsv 2>/dev/null)
    
    if [[ -n "$log_analytics_solution_check" ]]; then
      echo -e "${green}Log Analytics 솔루션이 존재합니다. use_existing_log_analytics_solution = true로 설정합니다.${nc}"
      sed -i "s/use_existing_log_analytics_solution = .*/use_existing_log_analytics_solution = true/" terraform.tfvars
      log_analytics_solution_exists=true
    else
      echo -e "${yellow}Log Analytics 솔루션이 존재하지 않습니다. use_existing_log_analytics_solution = false로 설정합니다.${nc}"
      sed -i "s/use_existing_log_analytics_solution = .*/use_existing_log_analytics_solution = false/" terraform.tfvars
    fi
    
    # 모니터 액션 그룹 이름 가져오기
    monitor_action_group_name=$(grep "monitor_action_group_name" terraform.tfvars | cut -d'"' -f2)
    
    # 모니터 액션 그룹 존재 여부 확인
    monitor_action_group_check=$(MSYS_NO_PATHCONV=1 az monitor action-group show --resource-group "$hub_rg" --name "$monitor_action_group_name" --query "name" -o tsv 2>/dev/null)
    
    if [[ -n "$monitor_action_group_check" ]]; then
      echo -e "${green}모니터 액션 그룹($monitor_action_group_name)이 존재합니다. use_existing_monitor_action_group = true로 설정합니다.${nc}"
      sed -i "s/use_existing_monitor_action_group = .*/use_existing_monitor_action_group = true/" terraform.tfvars
      monitor_action_group_exists=true
    else
      echo -e "${yellow}모니터 액션 그룹($monitor_action_group_name)이 존재하지 않습니다. use_existing_monitor_action_group = false로 설정합니다.${nc}"
      sed -i "s/use_existing_monitor_action_group = .*/use_existing_monitor_action_group = false/" terraform.tfvars
    fi
    
    # 모니터 알림 존재 여부 확인
    monitor_alerts_check=$(MSYS_NO_PATHCONV=1 az monitor metrics alert list --resource-group "$hub_rg" --query "length(@)" -o tsv 2>/dev/null)
    
    if [[ "$monitor_alerts_check" -gt 0 ]]; then
      echo -e "${green}모니터 알림이 존재합니다. use_existing_monitor_alerts = true로 설정합니다.${nc}"
      sed -i "s/use_existing_monitor_alerts = .*/use_existing_monitor_alerts = true/" terraform.tfvars
      monitor_alerts_exists=true
    else
      echo -e "${yellow}모니터 알림이 존재하지 않습니다. use_existing_monitor_alerts = false로 설정합니다.${nc}"
      sed -i "s/use_existing_monitor_alerts = .*/use_existing_monitor_alerts = false/" terraform.tfvars
    fi
  else
    echo -e "${yellow}Log Analytics 워크스페이스($log_analytics_workspace_name)가 존재하지 않습니다. use_existing_log_analytics = false로 설정합니다.${nc}"
    sed -i "s/use_existing_log_analytics = .*/use_existing_log_analytics = false/" terraform.tfvars
    sed -i "s/use_existing_log_analytics_solution = .*/use_existing_log_analytics_solution = false/" terraform.tfvars
    sed -i "s/use_existing_monitor_action_group = .*/use_existing_monitor_action_group = false/" terraform.tfvars
    sed -i "s/use_existing_monitor_alerts = .*/use_existing_monitor_alerts = false/" terraform.tfvars
  fi
else
  echo -e "${yellow}Hub 리소스 그룹이 존재하지 않아 모니터링 리소스를 확인할 수 없습니다.${nc}"
  sed -i "s/use_existing_log_analytics = .*/use_existing_log_analytics = false/" terraform.tfvars
  sed -i "s/use_existing_log_analytics_solution = .*/use_existing_log_analytics_solution = false/" terraform.tfvars
  sed -i "s/use_existing_monitor_action_group = .*/use_existing_monitor_action_group = false/" terraform.tfvars
  sed -i "s/use_existing_monitor_alerts = .*/use_existing_monitor_alerts = false/" terraform.tfvars
fi

# 모니터링 리소스 존재 여부 요약
echo -e "\n${yellow}모니터링 리소스 존재 여부 요약:${nc}"
echo -e "Log Analytics 워크스페이스 존재 여부: $log_analytics_exists"
echo -e "Log Analytics 솔루션 존재 여부: $log_analytics_solution_exists"
echo -e "모니터 액션 그룹 존재 여부: $monitor_action_group_exists"
echo -e "모니터 알림 존재 여부: $monitor_alerts_exists"
echo -e "모니터링 리소스 확인 완료" 