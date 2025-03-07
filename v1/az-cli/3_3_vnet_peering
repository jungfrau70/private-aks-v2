

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
az account set --subscription $SUBSCRIPTION_ID
LOCATION="koreacentral"

HUB_RG=rg-hub
SPOKE_RG=rg-spoke
LOCATION=koreacentral 
HUB_VNET_NAME=Hub_VNET
SPOKE_VNET_NAME=Spoke_VNET

echo "SPOKE_VNET_NAME: $SPOKE_VNET_NAME"
echo "HUB_VNET_NAME: $HUB_VNET_NAME"
echo "HUB_RG: $HUB_RG"
echo "SPOKE_RG: $SPOKE_RG"

# Peer from Hub to Spoke
HUB_PEER_NAME=hub-to-spoke
az network vnet peering create \
    --allow-vnet-access \
    --name $HUB_PEER_NAME \
    --vnet-name $HUB_VNET_NAME \
    --remote-vnet $SPOKE_VNET_NAME \
    --resource-group $HUB_RG

SPOKE_VNET_ID=$(az network vnet show --name $SPOKE_VNET_NAME --resource-group $SPOKE_RG \
    --query "id" --output tsv --subscription $SUBSCRIPTION_ID)
echo "SPOKE_VNET_ID: $SPOKE_VNET_ID"

HUB_VNET_ID=$(az network vnet show --name $HUB_VNET_NAME --resource-group $HUB_RG \
    --query "id"  --output tsv --subscription $SUBSCRIPTION_ID)
echo "HUB_VNET_ID: $HUB_VNET_ID"

# Peer from Spoke to Hub
SPOKE_PEER_NAME=spoke-to-hub
az network vnet peering create \
    --allow-vnet-access \
    --name $SPOKE_PEER_NAME \
    --vnet-name $SPOKE_VNET_NAME \
    --remote-vnet $HUB_VNET_ID \
    --resource-group $SPOKE_RG

# Peer from Hub to Spoke
HUB_PEER_NAME=hub-to-spoke
az network vnet peering create \
    --allow-vnet-access \
    --name $HUB_PEER_NAME \
    --vnet-name $HUB_VNET_NAME \
    --remote-vnet $SPOKE_VNET_ID \
    --resource-group $HUB_RG

