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
    --resource-group $HUB_RG \
    --name $BASTION_NSG_NAME \
    --location $LOCATION

# Create Hub_RG NSG Rules for Inbound
az network nsg rule create --name AllowHttpsInbound \
  --nsg-name $BASTION_NSG_NAME --priority 120 --resource-group $HUB_RG\
  --access Allow --protocol TCP --direction Inbound \
  --source-address-prefixes "Internet" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "443"

az network nsg rule create --name AllowGatewayManagerInbound \
  --nsg-name $BASTION_NSG_NAME --priority 130 --resource-group $HUB_RG\
  --access Allow --protocol TCP --direction Inbound \
  --source-address-prefixes "GatewayManager" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "443"

az network nsg rule create --name AllowAzureLoadBalancerInbound \
  --nsg-name $BASTION_NSG_NAME --priority 140 --resource-group $HUB_RG\
  --access Allow --protocol TCP --direction Inbound \
  --source-address-prefixes "AzureLoadBalancer" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges "443"

az network nsg rule create --name AllowBastionHostCommunication \
  --nsg-name $BASTION_NSG_NAME --priority 150 --resource-group $HUB_RG\
  --access Allow --protocol TCP --direction Inbound \
  --source-address-prefixes "VirtualNetwork" \
  --source-port-ranges "*" \
  --destination-address-prefixes "VirtualNetwork" \
  --destination-port-ranges 8080 5701  

# Create Hub_RG NSG Rules for Outbound
az network nsg rule create --name AllowSshRdpOutbound \
  --nsg-name $BASTION_NSG_NAME --priority 100 --resource-group $HUB_RG\
  --access Allow --protocol "*" --direction outbound \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "VirtualNetwork" \
  --destination-port-ranges 22 3389

az network nsg rule create --name AllowAzureCloudOutbound \
  --nsg-name $BASTION_NSG_NAME --priority 110 --resource-group $HUB_RG\
  --access Allow --protocol Tcp --direction outbound \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "AzureCloud" \
  --destination-port-ranges 443

az network nsg rule create --name AllowBastionCommunication \
  --nsg-name $BASTION_NSG_NAME --priority 120 --resource-group $HUB_RG\
  --access Allow --protocol "*" --direction outbound \
  --source-address-prefixes "VirtualNetwork" \
  --source-port-ranges "*" \
  --destination-address-prefixes "VirtualNetwork" \
  --destination-port-ranges 8080 5701

az network nsg rule create --name AllowHttpOutbound \
  --nsg-name $BASTION_NSG_NAME --priority 130 --resource-group $HUB_RG\
  --access Allow --protocol "*" --direction outbound \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "Internet" \
  --destination-port-ranges 80

# Create Jumpbox_RG NSG
az network nsg create \
  --resource-group $HUB_RG \
  --name $JUMPBOX_NSG_NAME \
  --location $LOCATION

# Create Hub_RG VNet with Bastion Subnet and NSG
az network vnet create \
  --resource-group $HUB_RG  \
  --name $HUB_VNET_NAME \
  --address-prefixes $HUB_VNET_PREFIX \
  --subnet-name $BASTION_SUBNET_NAME \
  --subnet-prefixes $BASTION_SUBNET_PREFIX \
  --network-security-group $BASTION_NSG_NAME

# Create Hub_RG VNet Subnet for Firewall
az network vnet subnet create \
  --resource-group $HUB_RG  \
  --vnet-name $HUB_VNET_NAME \
  --name $FW_SUBNET_NAME \
  --address-prefixes $FW_SUBNET_PREFIX

# Create Hub_RG VNet Subnet for Jumpbox
az network vnet subnet create \
  --resource-group $HUB_RG  \
  --vnet-name $HUB_VNET_NAME \
  --name $JUMPBOX_SUBNET_NAME \
  --address-prefixes $JUMPBOX_SUBNET_PREFIX \
  --network-security-group $JUMPBOX_NSG_NAME

###