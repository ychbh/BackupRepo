$subscriptions = @{
    "Azure-Corp-WVD" = "30c97f90-f5d1-49e4-aa95-0436dc40734f"
}

foreach($subscription in $subscriptions) {
    Set-AzContext -Subscriptionid $subscription
    Get-AzPublicIpAddress | select name,ipaddress | export-csv Azure-Corp-Hub-EastIP.csv
}

Set-AzContext -Subscriptionid 15932589-859a-4901-84dc-dfb3db134d7d
Get-AzPublicIpAddress | select name,ipaddress | export-csv Azure-SD-DesktopAnalyticsIP.csv