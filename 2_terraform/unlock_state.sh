#!/bin/bash

# Storage Account 정보
STORAGE_ACCOUNT_NAME="tfstate00e55e92"
CONTAINER_NAME="tfstate"
BLOB_NAME="terraform.tfstate"

# Lock 해제
az storage blob lease break \
  --account-name $STORAGE_ACCOUNT_NAME \
  --container-name $CONTAINER_NAME \
  --blob-name $BLOB_NAME 