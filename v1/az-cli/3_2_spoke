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

# Create Resource Groups
az group create --name $HUB_RG --location $LOCATION
az group create --name $SPOKE_RG --location $LOCATION

# Create NSG
az network nsg create \
  --resource-group $SPOKE_RG \
  --name $AKS_NSG_NAME \
  --location $LOCATION

az network nsg create \
  --resource-group $SPOKE_RG \
  --name $ENDPOINTS_NSG_NAME \
  --location $LOCATION

az network nsg create \
  --resource-group $SPOKE_RG \
  --name $LOADBALANCER_NSG_NAME \
  --location $LOCATION

az network nsg create \
    --resource-group $SPOKE_RG \
    --name $APPGW_NSG \
    --location $LOCATION

# Create Spoke_RG NSG Rules for Inbound
# Allow Internet Client request on Port 443 and 80
az network nsg rule create \
  --resource-group $SPOKE_RG \
  --nsg-name $APPGW_NSG \
  --name Allow-Internet-Inbound-HTTP-HTTPS \
  --priority 100 \
  --source-address-prefixes Internet \
  --destination-port-ranges 80 443 \
  --access Allow \
  --protocol Tcp \
  --description "Allow inbound traffic to port 80 and 443 to Application Gateway from client requests originating from the Internet"

# Infrastructure ports
az network nsg rule create \
  --resource-group $SPOKE_RG \
  --nsg-name $APPGW_NSG \
  --name Allow-GatewayManager-Inbound \
  --priority 110 \
  --source-address-prefixes "GatewayManager" \
  --destination-port-ranges 65200-65535 \
  --access Allow \
  --protocol Tcp \
  --description "Allow inbound traffic to ports 65200-65535 from GatewayManager service tag"

# Create Spoke_RG VNet with AKS Subnet and NSG
az network vnet create \
  --resource-group $SPOKE_RG  \
  --name $SPOKE_VNET_NAME \
  --address-prefixes $SPOKE_VNET_PREFIX \
  --subnet-name $AKS_SUBNET_NAME \
  --subnet-prefixes $AKS_SUBNET_PREFIX \
  --network-security-group $AKS_NSG_NAME

# Create Spoke_RG VNet Subnet for Endpoints
az network vnet subnet create \
  --resource-group $SPOKE_RG  \
  --vnet-name $SPOKE_VNET_NAME  \
  --name $ENDPOINTS_SUBNET_NAME \
  --address-prefixes $ENDPOINTS_SUBNET_PREFIX \
	--network-security-group $ENDPOINTS_NSG_NAME

# Create Spoke_RG VNet Subnet for Loadbalancer
az network vnet subnet create \
  --resource-group $SPOKE_RG  \
  --vnet-name $SPOKE_VNET_NAME \
  --name $LOADBALANCER_SUBNET_NAME \
  --address-prefixes $LOADBALANCER_SUBNET_PREFIX \
	--network-security-group $LOADBALANCER_NSG_NAME

# Create Spoke_RG VNet Subnet for Application Gateway
az network vnet subnet create \
  --resource-group $SPOKE_RG  \
  --vnet-name $SPOKE_VNET_NAME \
  --name $APPGW_SUBNET_NAME \
  --address-prefixes $APPGW_SUBNET_PREFIX \
	--network-security-group $APPGW_NSG


###