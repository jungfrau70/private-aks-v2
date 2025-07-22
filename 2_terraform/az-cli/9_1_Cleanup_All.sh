#!/bin/bash
set -e

# 변수 설정
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP_HUB="rg-hub"
RESOURCE_GROUP_SPOKE="rg-spoke"
AKS_CLUSTER_NAME="aks-cluster"
STORAGE_ACCOUNT_NAME="<your-storage-account-name>"
TERRAFORM_BACKEND_RG="rg-terraform-backend"

# Azure 로그인
echo "Azure에 로그인합니다..."
az login
az account set --subscription $SUBSCRIPTION_ID

# 1단계: AKS 클러스터 삭제 전 확인
echo "1단계: AKS 클러스터 삭제 전 확인..."
read -p "AKS 클러스터 $AKS_CLUSTER_NAME을 삭제하시겠습니까? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "AKS 클러스터 삭제 중..."
    az aks delete --resource-group $RESOURCE_GROUP_SPOKE --name $AKS_CLUSTER_NAME --yes
else
    echo "AKS 클러스터 삭제를 건너뜁니다."
fi

# 2단계: Spoke 리소스 그룹 삭제
echo "2단계: Spoke 리소스 그룹 삭제..."
read -p "Spoke 리소스 그룹 $RESOURCE_GROUP_SPOKE을 삭제하시겠습니까? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "Spoke 리소스 그룹 삭제 중..."
    az group delete --name $RESOURCE_GROUP_SPOKE --yes --no-wait
else
    echo "Spoke 리소스 그룹 삭제를 건너뜁니다."
fi

# 3단계: Hub 리소스 그룹 삭제
echo "3단계: Hub 리소스 그룹 삭제..."
read -p "Hub 리소스 그룹 $RESOURCE_GROUP_HUB을 삭제하시겠습니까? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "Hub 리소스 그룹 삭제 중..."
    az group delete --name $RESOURCE_GROUP_HUB --yes --no-wait
else
    echo "Hub 리소스 그룹 삭제를 건너뜁니다."
fi

# 4단계: Terraform 백엔드 삭제
echo "4단계: Terraform 백엔드 삭제..."
read -p "Terraform 백엔드 리소스 그룹 $TERRAFORM_BACKEND_RG을 삭제하시겠습니까? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "Terraform 백엔드 스토리지 계정 삭제 중..."
    az storage account delete --name $STORAGE_ACCOUNT_NAME --resource-group $TERRAFORM_BACKEND_RG --yes
    
    echo "Terraform 백엔드 리소스 그룹 삭제 중..."
    az group delete --name $TERRAFORM_BACKEND_RG --yes --no-wait
else
    echo "Terraform 백엔드 삭제를 건너뜁니다."
fi

# 5단계: 로컬 Terraform 상태 파일 정리
echo "5단계: 로컬 Terraform 상태 파일 정리..."
read -p "로컬 Terraform 상태 파일을 정리하시겠습니까? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "로컬 Terraform 상태 파일 정리 중..."
    find . -name ".terraform" -type d -exec rm -rf {} +
    find . -name "terraform.tfstate*" -type f -delete
else
    echo "로컬 Terraform 상태 파일 정리를 건너뜁니다."
fi

# 6단계: 로컬 Kubernetes 구성 정리
echo "6단계: 로컬 Kubernetes 구성 정리..."
read -p "로컬 Kubernetes 구성을 정리하시겠습니까? (y/n): " confirm
if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    echo "로컬 Kubernetes 구성 정리 중..."
    kubectl config delete-context $AKS_CLUSTER_NAME
    kubectl config delete-cluster $AKS_CLUSTER_NAME
else
    echo "로컬 Kubernetes 구성 정리를 건너뜁니다."
fi

echo "모든 정리가 완료되었습니다."
echo "참고: 리소스 그룹 삭제는 비동기적으로 진행되며 완료하는 데 시간이 걸릴 수 있습니다."
echo "Azure 포털에서 삭제 상태를 확인하세요." 