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
RESULT_FILE="$LOG_DIR/all_checks_$TIMESTAMP.log"
echo "AKS 워크숍 전체 인프라 점검 결과 ($(date))" > $RESULT_FILE
echo "=====================================" >> $RESULT_FILE

# 시작 메시지
echo "🚀 AKS 워크숍 전체 인프라 점검 시작" | tee -a $RESULT_FILE
echo "=====================================" | tee -a $RESULT_FILE

# 1. Azure 인프라 점검
echo -e "\n📌 1. Azure 인프라 점검 시작" | tee -a $RESULT_FILE
if [ -f "check_azure_infra.sh" ]; then
    echo "실행 중: check_azure_infra.sh" | tee -a $RESULT_FILE
    bash check_azure_infra.sh
    if [ $? -eq 0 ]; then
        echo "✅ Azure 인프라 점검 완료" | tee -a $RESULT_FILE
    else
        echo "❌ Azure 인프라 점검 중 오류 발생" | tee -a $RESULT_FILE
    fi
else
    echo "❌ check_azure_infra.sh 파일이 존재하지 않습니다." | tee -a $RESULT_FILE
fi

# 2. AKS 클러스터 점검
echo -e "\n📌 2. AKS 클러스터 점검 시작" | tee -a $RESULT_FILE
if [ -f "check_aks_cluster.sh" ]; then
    echo "실행 중: check_aks_cluster.sh" | tee -a $RESULT_FILE
    bash check_aks_cluster.sh
    if [ $? -eq 0 ]; then
        echo "✅ AKS 클러스터 점검 완료" | tee -a $RESULT_FILE
    else
        echo "❌ AKS 클러스터 점검 중 오류 발생" | tee -a $RESULT_FILE
    fi
else
    echo "❌ check_aks_cluster.sh 파일이 존재하지 않습니다." | tee -a $RESULT_FILE
fi

# 3. 기존 AKS 아키텍처 점검 (선택적)
echo -e "\n📌 3. AKS 아키텍처 점검 시작" | tee -a $RESULT_FILE
if [ -f "check_aks_archi.sh" ]; then
    echo "실행 중: check_aks_archi.sh" | tee -a $RESULT_FILE
    bash check_aks_archi.sh
    if [ $? -eq 0 ]; then
        echo "✅ AKS 아키텍처 점검 완료" | tee -a $RESULT_FILE
    else
        echo "❌ AKS 아키텍처 점검 중 오류 발생" | tee -a $RESULT_FILE
    fi
else
    echo "❌ check_aks_archi.sh 파일이 존재하지 않습니다." | tee -a $RESULT_FILE
fi

# 결과 요약
echo -e "\n=====================================" | tee -a $RESULT_FILE
echo "📊 전체 점검 결과 요약:" | tee -a $RESULT_FILE
echo "- 점검 시간: $(date)" | tee -a $RESULT_FILE
echo "- 점검 대상 클러스터: $AKS_CLUSTER" | tee -a $RESULT_FILE
echo "- 로그 디렉토리: $LOG_DIR" | tee -a $RESULT_FILE

# 로그 파일 목록 출력
echo -e "\n📋 생성된 로그 파일 목록:" | tee -a $RESULT_FILE
ls -la $LOG_DIR/*_$TIMESTAMP.log | tee -a $RESULT_FILE

# 종료 메시지
echo ""
echo "=========================================================="
echo "✅ AKS 워크숍 전체 인프라 점검이 완료되었습니다."
echo "📝 상세 결과는 로그 파일을 확인하세요: $LOG_DIR"
echo "==========================================================" 