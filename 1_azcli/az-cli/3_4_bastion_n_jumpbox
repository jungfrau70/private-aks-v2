SUBSCRIPTION_ID=$(az account show --query id --output tsv)
az account set --subscription $SUBSCRIPTION_ID
LOCATION="koreacentral"

HUB_RG=rg-hub
SPOKE_RG=rg-spoke
LOCATION=koreacentral 
HUB_VNET_NAME=Hub_VNET
SPOKE_VNET_NAME=Spoke_VNET
Jumpbox_SUBNET_NAME=JumpboxSubnet

JUMPBOX_USERNAME=azureuser
JUMPBOX_PASSWORD="bright2n@1234"

Bastion_HOST_NAME=bastionhost
Bastion_PIP_NAME=Bastion-PIP
JUMPBOX_VM_NAME=jumpbox-vm
JUMPBOX_SUBNET_NAME=JumpboxSubnet


# Bastion용 Public IP 생성
az network public-ip create \
    --resource-group $HUB_RG  \
    --name $Bastion_PIP_NAME \
    --sku Standard \
    --allocation-method Static

Bastion_PIP=$(az network public-ip show --name $Bastion_PIP_NAME --resource-group $HUB_RG --query ipAddress -o tsv
)

echo "SPOKE_VNET_NAME: $SPOKE_VNET_NAME"
echo "HUB_VNET_NAME: $HUB_VNET_NAME"
echo "HUB_RG: $HUB_RG"
echo "SPOKE_RG: $SPOKE_RG"
echo "Bastion_PIP: $Bastion_PIP"

echo "Bastion_HOST_NAME: $Bastion_HOST_NAME"
echo "Jumpbox_SUBNET_NAME: $Jumpbox_SUBNET_NAME"
echo "JUMPBOX_USERNAME: $JUMPBOX_USERNAME"
echo "JUMPBOX_PASSWORD: $JUMPBOX_PASSWORD"


# Jumpbox VM 생성 (Bastion을 통해 접속할 것이므로 필요없음)
az vm create \
    --resource-group $HUB_RG \
    --name $JUMPBOX_VM_NAME \
    --image Ubuntu2204 \
    --admin-username $JUMPBOX_USERNAME \
    --admin-password $JUMPBOX_PASSWORD \
    --vnet-name $HUB_VNET_NAME \
    --subnet $JUMPBOX_SUBNET_NAME \
    --size Standard_B2s \
    --storage-sku Standard_LRS \
    --os-disk-name $JUMPBOX_VM_NAME-VM-osdisk \
    --os-disk-size-gb 128 \
    --public-ip-address "" \
    --nsg "" 

# Create the Bastion Host
az network bastion create \
    --resource-group $HUB_RG \
    --name $Bastion_HOST_NAME \
    --public-ip-address $Bastion_PIP \
    --vnet-name $HUB_VNET_NAME \
    --location $LOCATION

az network bastion show \
    --resource-group $HUB_RG \
    --name $Bastion_HOST_NAME     

