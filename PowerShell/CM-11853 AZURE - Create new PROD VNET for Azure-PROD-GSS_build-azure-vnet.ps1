## Written by Tim Muse / May 2022 ##

## THIS WILL NOT WORK FOR AGW SUBNETS
## Variable information:
## $subscription - This must be the exact name of the subscription to use 
## $gdot_environment - This must be CORP or PROD. No other options are accepted
## $location - This must be an Azure region in the format WESTUS or WESTUS3. If you're unsure of available options, look down the script for the lookup table
## $app_name - A simple name for the app. IE, NP-APIM, AKS, ACTIVEDIR, etc
## $vnet_prefix - The prefix for the entire VNET in CIDR notation
## $subnets - All of subnets to be created in the VNET.
##     This should be a comma-separated list of arrays. IE:
##     @("NAME","IPSUBNET","If AGW or APIM subnet, type AGW or APIM, else type false")
##     @("DEFAULT","192.168.0.0/29","false"),
##     @("DEFAULT2","192.168.0.8/29","false")
##     If you only have one subnet, put a comma in front of the array. IE:
##     ,@("DEFAULT","192.168.0.0/29","false")
## NAMING CONVENTIONS are built into the script. No need to add -RG or -VNET to your variables. Let the script do it's job.

## This will open a separate window for authentication. It will likely pop up behind your current active window.
Connect-AzAccount

## Adjust these as necessary
$subscription = "AZURE-ITS-Sandbox"
$gdot_environment = "CORP"
$location = "WESTUS3"
$app_name = "TIMTEST"
$seq_number = "001"
$vnet_prefix = "192.168.0.0/24"
$subnets = @(
    @("DEFAULT","192.168.0.0/29","false"),
    @("DEFAULT2","192.168.0.8/29","AGW"),
    @("DEFAULT3","192.168.0.16/29","APIM")
)

## YOU SHOULD NOT NEED TO EDIT ANYTHING BELOW THIS LINE TO RUN THE SCRIPT ##
## Static variables for some common entries
$generic_name = "$gdot_environment-$app_name-$location"
$rt_routes = @(
    @("10.0.0.0-8","10.0.0.0/8"),
    @("172.16.0.0-12","172.16.0.0/12"),
    @("192.168.0.0-16","192.168.0.0/16"),
    @("100.64.0.0-10","100.64.0.0/10")
)
$lookup = @{
    "PROD" = @{
        "WESTUS2" = @{"reg_short" = "WUS2";"dns" = @("10.211.254.132","10.211.254.133");"nexthop" = "10.211.254.196";"nexthop_id" = "/subscriptions/b3e08ce2-607b-441f-b2f8-920b9f62fd51/resourceGroups/PROD-RG/providers/Microsoft.Network/virtualNetworks/PROD";"hub_rt" = "PROD-VPN-GATEWAY-ROUTE"}
        "WESTUS3" = @{"reg_short" = "WUS3";"dns" = @("10.211.254.132","10.211.254.133");"nexthop" = "10.211.254.196";"nexthop_id" = "/subscriptions/b3e08ce2-607b-441f-b2f8-920b9f62fd51/resourceGroups/PROD-RG/providers/Microsoft.Network/virtualNetworks/PROD";"hub_rt" = "PROD-VPN-GATEWAY-ROUTE"}
        "EASTUS2" = @{"reg_short" = "EUS2";"dns" = @("10.210.0.100","10.210.0.101");"nexthop" = "10.210.0.116";"nexthop_id" = "/subscriptions/63840cf4-7d8d-4c5f-a926-f9c3298a0cff/resourceGroups/PROD-HUB-EAST-VNET-RG/providers/Microsoft.Network/virtualNetworks/PROD-HUB-EAST-VNET";"hub_rt" = "PROD-HUB-EAST-RT"}
        "EASTUS" = @{"reg_short" = "EUS";"dns" = @("10.210.0.100","10.210.0.101");"nexthop" = "10.210.0.116";"nexthop_id" = "/subscriptions/63840cf4-7d8d-4c5f-a926-f9c3298a0cff/resourceGroups/PROD-HUB-EAST-VNET-RG/providers/Microsoft.Network/virtualNetworks/PROD-HUB-EAST-VNET";"hub_rt" = "PROD-HUB-EAST-RT"}
    }
    "CORP" = @{
        "WESTUS2" = @{"reg_short" = "WUS2";"dns" = @("10.212.254.100","10.212.254.101");"nexthop" = "10.212.254.116";"nexthop_id" = "/subscriptions/1b027a38-9142-4579-bb5b-c6994e6aa02f/resourceGroups/CORP-HUB-RG/providers/Microsoft.Network/virtualNetworks/CORP-HUB";"hub_rt" = "CORP-VNG-GATEWAY-RTB"}
        "WESTUS3" = @{"reg_short" = "WUS3";"dns" = @("10.212.254.100","10.212.254.101");"nexthop" = "10.212.254.116";"nexthop_id" = "/subscriptions/1b027a38-9142-4579-bb5b-c6994e6aa02f/resourceGroups/CORP-HUB-RG/providers/Microsoft.Network/virtualNetworks/CORP-HUB";"hub_rt" = "CORP-VNG-GATEWAY-RTB"}
        "EASTUS2" = @{"reg_short" = "EUS2";"dns" = @("10.213.0.100","10.213.0.101");"nexthop" = "10.213.0.116";"nexthop_id" = "/subscriptions/e6f11509-30bc-4342-81df-67c9eb047866/resourceGroups/CORP-HUB-EAST-VNET-RG/providers/Microsoft.Network/virtualNetworks/CORP-HUB-EAST-VNET";"hub_rt" = "CORP-HUB-EAST-RT"}
        "EASTUS" = @{"reg_short" = "EUS";"dns" = @("10.213.0.100","10.213.0.101");"nexthop" = "10.213.0.116";"nexthop_id" = "/subscriptions/e6f11509-30bc-4342-81df-67c9eb047866/resourceGroups/CORP-HUB-EAST-VNET-RG/providers/Microsoft.Network/virtualNetworks/CORP-HUB-EAST-VNET";"hub_rt" = "CORP-HUB-EAST-RT"}
    }
}

## Select the right subscription
Set-AzContext -Subscription $subscription

## Build new RG
$rg_name = "$gdot_environment-$app_name-$($lookup.$gdot_environment.$location.reg_short)-VNET-RG"
$rg_test = ''
$rg_test = (Get-AzResourceGroup -Name $rg_name -Location $location).ResourceGroupName
if ($rg_test -ne $rg_name) {
    New-AzResourceGroup -Name $rg_name -Location $location
}

## Create Route Tables & Add the routes
$rt_object_check = 0
$rt_object_apim_check = 0
$rt_object_agw_check = 0
foreach($snet in $subnets) {
    if ($snet[2] -eq "false") {
        if ($rt_object_check -eq 0) {
            $rt_name = "$generic_name-RT"
            $rt_obj = New-AzRouteTable -Name $rt_name -ResourceGroupName $rg_name -Location $location -DisableBgpRoutePropagation
            $rt_obj | Add-AzRouteConfig -Name "0.0.0.0-0" -AddressPrefix "0.0.0.0/0" -NextHopType "VirtualAppliance" -NextHopIpAddress $lookup.$gdot_environment.$location.nexthop
            $rt_obj | Set-AzRouteTable
            $rt_object_check = 1
        }
    } elseif ($snet[2] -eq "APIM") {
        if ($rt_object_apim_check -eq 0) {
            $rt_name_apim = "$generic_name-APIM-RT"
            $rt_obj_apim = New-AzRouteTable -Name $rt_name_apim -ResourceGroupName $rg_name -Location $location -DisableBgpRoutePropagation
            foreach ($route in $rt_routes) {
                $rt_obj_apim | Add-AzRouteConfig -Name $route[0] -AddressPrefix $route[1] -NextHopType "VirtualAppliance" -NextHopIpAddress $lookup.$gdot_environment.$location.nexthop
            }
            $rt_obj_apim | Set-AzRouteTable
            $rt_object_apim_check = 1
        }
    } elseif ($snet[2] -eq "AGW") {
        if ($rt_object_agw_check -eq 0) {
            $rt_name_agw = "$generic_name-AGW-RT"
            $rt_obj_agw = New-AzRouteTable -Name $rt_name_agw -ResourceGroupName $rg_name -Location $location -DisableBgpRoutePropagation
            foreach ($route in $rt_routes) {
                $rt_obj_agw | Add-AzRouteConfig -Name $route[0] -AddressPrefix $route[1] -NextHopType "VirtualAppliance" -NextHopIpAddress $lookup.$gdot_environment.$location.nexthop
            }
            $rt_obj_agw | Set-AzRouteTable
            $rt_object_agw_check = 1
        }
    }
}

## Build new VNET
$vnet_name = "$generic_name-$seq_number-VNET"
$vnet_obj = New-AzVirtualNetwork -Name $vnet_name -ResourceGroupName $rg_name -Location $location -AddressPrefix $vnet_prefix -DnsServer $lookup.$gdot_environment.$location.dns
## Add the Subnets
foreach ($snet in $subnets) {
    if ($snet[2] -eq "false"){
        $snet_name = $generic_name + "-" + $snet[0] + "-SNET"
        Add-AzVirtualNetworkSubnetConfig -Name $snet_name -VirtualNetwork $vnet_obj -AddressPrefix $snet[1] -RouteTable $rt_obj
    } elseif ($snet[2] -eq "APIM"){
        $snet_name = $generic_name + "-" + $snet[0] + "-APIM-SNET"
        Add-AzVirtualNetworkSubnetConfig -Name $snet_name -VirtualNetwork $vnet_obj -AddressPrefix $snet[1] -RouteTable $rt_obj_apim
    } elseif ($snet[2] -eq "AGW"){
        $snet_name = $generic_name + "-" + $snet[0] + "-AGW-SNET"
        Add-AzVirtualNetworkSubnetConfig -Name $snet_name -VirtualNetwork $vnet_obj -AddressPrefix $snet[1] -RouteTable $rt_obj_agw
    }
}
$vnet_obj | Set-AzVirtualNetwork

## Create the peer on the spoke
$hub_vnet_name = ($lookup.$gdot_environment.$location.nexthop_id -Split "/")[-1]
Add-AzVirtualNetworkPeering -Name "PEERLINK-$vnet_name-TO-$hub_vnet_name" -VirtualNetwork $vnet_obj -RemoteVirtualNetworkId $lookup.$gdot_environment.$location.nexthop_id -UseRemoteGateways -AllowForwardedTraffic
## Switch subscriptions to Hub
Set-AzContext -Subscription ($lookup.$gdot_environment.$location.nexthop_id -Split "/")[2]
## Create the peer on the Hub side
Add-AzVirtualNetworkPeering -Name "PEERLINK-$hub_vnet_name-TO-$vnet_name" -VirtualNetwork (Get-AzVirtualNetwork -Name $hub_vnet_name) -RemoteVirtualNetworkId $vnet_obj.Id -AllowGatewayTransit -AllowForwardedTraffic
## Update Hub routing table
$hub_rt_obj = Get-AzRouteTable -Name $lookup.$gdot_environment.$location.hub_rt
$hub_rt_obj | Add-AzRouteConfig -Name "$generic_name-RT" -AddressPrefix $vnet_prefix -NextHopType "VirtualAppliance" -NextHopIpAddress $lookup.$gdot_environment.$location.nexthop
$hub_rt_obj | Set-AzRouteTable

# verification steps (to remain manual)
