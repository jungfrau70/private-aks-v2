# env.sh

# AKS 클러스터 정보
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
az account set --subscription $SUBSCRIPTION_ID


HUB_RG=rg-hub
SPOKE_RG=rg-spoke
LOCATION=koreacentral
AKS_CLUSTER_NAME=private-aks

# ACR 정보 가져오기
ACR_NAME=$(az acr list --resource-group $HUB_RG --query "[0].name" -o tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $HUB_RG --query "loginServer" -o tsv)

LOG_FILE="aks_check_result_$(date +%Y%m%d_%H%M%S).log"

echo "ACR_NAME: $ACR_NAME"
echo "ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"

echo "SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "LOCATION: $LOCATION"
echo "HUB_RG: $HUB_RG"
echo "SPOKE_RG: $SPOKE_RG"
echo "AKS_CLUSTER_NAME: $AKS_CLUSTER_NAME"