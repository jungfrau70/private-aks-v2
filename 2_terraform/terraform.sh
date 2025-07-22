#!/bin/bash

# var.subscription_id
#   Azure 구독 ID
#   Enter a value: b6f97aed-4542-491f-a94c-e0f05563485c

# var.tenant_domain
#   Azure AD 테넌트 도메인
#   Enter a value: jupyteronlinegmail.onmicrosoft.com

# var.tenant_id
#   Azure 테넌트 ID
#   Enter a value: b0a8bb4b-d934-4714-a4e1-213e1a3c31f5

# 로그 디렉토리 생성
LOG_DIR="terraform_logs"
mkdir -p $LOG_DIR

# 타임스탬프 생성
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Plan 실행 및 로깅
echo "Terraform plan 실행 중..."
terraform plan -out=tfplan 2>&1 | tee "${LOG_DIR}/plan_${TIMESTAMP}.log"

# Plan 상세 내용 저장
echo "Plan 상세 내용 저장 중..."
terraform show -no-color tfplan > "${LOG_DIR}/plan_detail_${TIMESTAMP}.log"

# 사용자 확인
read -p "Terraform apply를 실행하시겠습니까? (y/n): " answer
if [[ $answer =~ ^[Yy]$ ]]
then
    # Apply 실행 및 로깅
    echo "Terraform apply 실행 중..."
    terraform apply -auto-approve tfplan 2>&1 | tee "${LOG_DIR}/apply_${TIMESTAMP}.log"
else
    echo "Apply가 취소되었습니다."
fi

# plan 파일 정리
rm -f tfplan 