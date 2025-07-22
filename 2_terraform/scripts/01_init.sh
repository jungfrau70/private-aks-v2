#!/bin/bash
# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}1단계: Terraform 초기화${NC}"
terraform init
if [ $? -ne 0 ]; then
  echo -e "${RED}Terraform 초기화 실패${NC}"
  exit 1
fi
echo -e "${GREEN}Terraform 초기화 완료${NC}"
