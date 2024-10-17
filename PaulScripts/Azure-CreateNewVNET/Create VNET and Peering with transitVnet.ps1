############################################################################
#####Create Azure Virtual network and Subnets in exist resource group#######
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

$TransitvNetOFSubscriptionName = Get-AzSubscription | where-object {$_.Name -eq "Azure-Corp-Hub"}
Set-AzContext -SubscriptionName $TransitvNetOFSubscriptionName
$TransitVNet = Get-AzVirtualNetwork -ResourceGroupName CORP-HUB-RG -Name CORP-HUB
$ExistSubscriptionName = Get-AzSubscription | where-object {$_.Name -eq "Azure-Corp-WVD"}
$ExistRG = "CORP-WVD-VENDOR-RG"
$Location = "westus2"
$NewVNETName = "CORP-WVD-SYSTECHUSA-VNET"
$NewVNETAddressSpace = "10.212.207.32/27"
$NetVNETDNSServer = "10.212.254.100", "10.212.254.101"
$Subnet1Name = "CORP-WVD-SYSTECHUSA-SNET"
$Subnet1AddPrefix = "10.212.207.32/27"
$NewRTBName = "CORP-WVD-SYSTECHUSA-RT"


Set-AzContext -SubscriptionName $ExistSubscriptionName

##Create new subnet ####
$Subnet1 = New-AzVirtualNetworkSubnetConfig -Name $Subnet1Name -AddressPrefix $Subnet1AddPrefix  

##Create new Virtual network on exist resource group ##### 
$NewvirtualNetwork = New-AzVirtualNetwork `
   -Name $NewVNETName `
   -ResourceGroupName $ExistRG `
   -AddressPrefix $NewVNETAddressSpace `
   -Location $Location `
   -DnsServer $NetVNETDNSServer `
   -Subnet $Subnet1
  
$NewvirtualNetwork | Set-AzVirtualNetwork

Start-Sleep 10

### Define param for new RouteTable#####
$RouteTable = New-AzRouteTable `
 -Name $NewRTBName `
 -ResourceGroupName $ExistRG `
 -location $Location `
 -DisableBgpRoutePropagation

##### Inset default route and create new RouteTable#####
Get-AzRouteTable `
  -ResourceGroupName $ExistRG `
  -Name $NewRTBName `
  | Add-AzRouteConfig `
  -Name "Default2CORP-HUB-WEST-LBI" `
  -AddressPrefix 0.0.0.0/0 `
  -NextHopType "VirtualAppliance" `
  -NextHopIpAddress 10.212.254.116 `
  | Set-AzRouteTable

$NEWRT = Get-AzRouteTable `
  -ResourceGroupName $ExistRG `
  -Name $NewRTBName
  
##### Associate RouterTable with Subnet#########
Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $NewvirtualNetwork `
  -Name $Subnet1Name `
  -AddressPrefix $Subnet1AddPrefix `
  -RouteTable $NEWRT | `
Set-AzVirtualNetwork



#Add remote Vnet peering from CORP-HUB to CORP-WVD-SYSTECHUSA-VNET
$newRemotepeeringName = $TransitVNet.Name+"-TO-"+$NewvirtualNetwork.name
Set-AzContext -SubscriptionName $TransitvNetOFSubscriptionName
Add-AzVirtualNetworkPeering `
  -Name $newRemotepeeringName `
  -VirtualNetwork $TransitVNet `
  -RemoteVirtualNetworkId $NewvirtualNetwork.Id `
  -AllowForwardedTraffic `
  -AllowGatewayTransit

#Add loca Vnet peering with `CORP-WVD-SYSTECHUSA-VNET and CORP-HUB

$newLocalpeeringName = $NewvirtualNetwork.name+"-TO-"+$TransitVNet.Name
Set-AzContext -SubscriptionName $ExistSubscriptionName
Add-AzVirtualNetworkPeering `
  -Name $newLocalpeeringName `
  -VirtualNetwork $NewvirtualNetwork `
  -RemoteVirtualNetworkId $TransitVNet.Id `
  -AllowForwardedTraffic `
  -AllowGatewayTransit  `
  -UseRemoteGateways

start-sleep 15 

#add return route for 10.212.207.32/27 set next hop as 10.212.254.116#######
Set-AzContext -SubscriptionName $TransitvNetOFSubscriptionName

start-sleep 5
$RoterName = $NewvirtualNetwork.name+"-ROUTE"
Get-AzRouteTable -ResourceGroupName CORP-HUB-RG -Name CORP-VNG-GATEWAY-RTB `
| Add-AzRouteConfig `
  -Name $RoterName `
  -AddressPrefix $NewVNETAddressSpace `
  -NextHopType "VirtualAppliance" `
  -NextHopIpAddress 10.212.254.116 `
  | Set-AzRouteTable


###Validate return route for new vNet#####
Get-AzRouteTable -ResourceGroupName CORP-HUB-RG -Name CORP-VNG-GATEWAY-RTB | Get-AzRouteConfig | where-object {$_.Name -like "*$NewVNETName*"} | ft

###Validate NewVNet, check prefix,Ip prefix,DNS, peering status#####
Set-AzContext -SubscriptionName $ExistSubscriptionName
Get-AzVirtualNetwork -ResourceGroupName $NewvirtualNetwork.ResourceGroupName -Name $NewvirtualNetwork.Name

