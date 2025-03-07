#!/bin/bash
export AZURE_SUBSCRIPTION_ID="b6f97aed-4542-491f-a94c-e0f05563485c"
export AZURE_TENANT_ID="b0a8bb4b-d934-4714-a4e1-213e1a3c31f5"
export AZURE_CLIENT_ID=""
export AZURE_CLIENT_SECRET=""

export RESOURCE_GROUP="rg-storage"
export AKS_CLUSTER="aks-dev"
export NAMESPACE="default"

# 특정 스토리지 계정의 키 확인
export STORAGE_ACCOUNT="sa1sharedstorage"
export RESOURCE_GROUP="rg-storage"
export STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query "[0].value" -o tsv)

export SHARE_NAME="quickscripts"
export MOUNT_POINT="~/clouddrive"

# 파일 공유 마운트
sudo mkdir -p $MOUNT_POINT
sudo mount -t cifs //"$STORAGE_ACCOUNT".file.core.windows.net/"$SHARE_NAME" "$MOUNT_POINT" -o vers=3.0,username="$STORAGE_ACCOUNT",password="$STORAGE_KEY",dir_mode=0777,file_mode=0777,serverino,mfsymlinks,cache=none