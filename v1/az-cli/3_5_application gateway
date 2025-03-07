az login --tenant jupyteronlinegmail.onmicrosoft.com

# Hub VNet
HUB_VNET_NAME=Hub_VNET
FW_SUBNET_NAME=AzureFirewallSubnet
BASTION_SUBNET_NAME=AzureBastionSubnet
HUB_VNET_PREFIX=10.0.0.0/22 # IP address range of the Virtual network (VNet).
BASTION_SUBNET_PREFIX=10.0.0.128/26 # IP address range of the Bastion subnet 
FW_SUBNET_PREFIX=10.0.0.0/26 # IP address range of the Firewall subnet
JUMPBOX_SUBNET_PREFIX=10.0.0.64/26 # IP address range of the Jumpbox subnet

# Spoke VNet
SPOKE_VNET_NAME=Spoke_VNET
JUMPBOX_SUBNET_NAME=JumpboxSubnet
ENDPOINTS_SUBNET_NAME=endpoints-subnet
APPGW_SUBNET_NAME=app-gw-subnet
AKS_SUBNET_NAME=aks-subnet
LOADBALANCER_SUBNET_NAME=loadbalancer-subnet
SPOKE_VNET_PREFIX=10.1.0.0/22 # IP address range of the Virtual network (VNet).
AKS_SUBNET_PREFIX=10.1.0.0/24 # IP address range of the AKS subnet
LOADBALANCER_SUBNET_PREFIX=10.1.1.0/28 # IP address range of the Loadbalancer subnet
APPGW_SUBNET_PREFIX=10.1.2.0/24 # IP address range of the Application Gateway subnet
ENDPOINTS_SUBNET_PREFIX=10.1.1.16/28 # IP address range of the Endpoints subnet

# Infrastructure
HUB_RG=rg-hub
SPOKE_RG=rg-spoke
LOCATION=koreacentral 
BASTION_NSG_NAME=Bastion_NSG
JUMPBOX_NSG_NAME=Jumpbox_NSG
AKS_NSG_NAME=Aks_NSG
ENDPOINTS_NSG_NAME=Endpoints_NSG
LOADBALANCER_NSG_NAME=Loadbalancer_NSG
APPGW_NSG=Appgw_NSG
FW_NAME=azure-firewall
APPGW_NAME=AppGateway
ROUTE_TABLE_NAME=spoke-rt
AKS_IDENTITY_NAME=aks-msi
JUMPBOX_VM_NAME=Jumpbox-VM
AKS_CLUSTER_NAME=private-aks
ACR_NAME="aksacr$RANDOM"
STUDENT_NAME=ian # don't use spaces

# Public IP 생성
az network public-ip create \
  --resource-group $SPOKE_RG \
  --name $APPGW_NAME-PIP \
  --sku Standard

APPGW_PIP=$(az network public-ip show --resource-group $SPOKE_RG --name $APPGW_NAME-PIP --query ipAddress -o tsv)
echo $APPGW_PIP

# Application Gateway 생성
az network application-gateway create \
  --name $APPGW_NAME \
  --resource-group $SPOKE_RG \
  --vnet-name $SPOKE_VNET_NAME \
  --subnet $APPGW_SUBNET_NAME \
  --sku Standard_v2 \
  --capacity 2 \
  --public-ip-address $APPGW_PIP \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --routing-rule-type Basic \
  --priority 100

