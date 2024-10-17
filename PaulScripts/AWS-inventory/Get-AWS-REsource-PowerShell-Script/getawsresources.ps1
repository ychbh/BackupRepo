#This script will traverse all AWS accounts and get each AWS account's ec2 instance, network, interface and subnet, vpc information.
#Then export all of them into a csv file.

$adfsURI = "https://sts.wip.greendotcorp.com/adfs/ls/idpinitiatedsignon.aspx?loginToRp=urn:amazon:webservices"
$credsDuration = 3600
$UserName = "anh9@nextestate"
$KeyFile = "C:\scripts\keyfile.txt"
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (Get-Content $KeyFile | ConvertTo-SecureString)

#replace <password> with your own password and run this command to generate an encrypted standard string.
#"<password>" | ConvertTo-SecureString -AsPlainText -force | ConvertFrom-SecureString | out-file keyfile.txt

# set AWS credential, duration and adfsurl, use nextestate 9 account

$WebRequestParams=@{ #Initialize parameters object
    Uri = $adfsURI
    Method = 'POST'
    ContentType = 'application/x-www-form-urlencoded'
    SessionVariable = 'WebSession'
    UseBasicParsing = $true
}


#Function to retriveve AWS EC2 instance, network, subnet and VPC information.

function get-AWSResource
{
$accountid = Get-IAMAccountAlias
write-host "Account Name: $accountid"

$Time = (Get-date).ToUniversalTime()

#$ec2instance = (Get-EC2Instance).instances | select @{name='account';e={$accountid}},@{name='Region';e={$Global:AWSRegion}},instanceid,keyname,@{name='NetworkInterfaces';e={($_.NetworkInterfaces.PrivateDnsName) -join ":"}},PrivateIpAddress,publicipaddress,@{name='SecurityGroups';e={($_.SecurityGroups.GroupName) -join ":"}},SubnetId,@{name="instancestatus";e={$_.state.name}},@{name="interfaceid";e={$_.NetworkInterfaces.NetworkInterfaceId}},platform,vpcid,SecurityGroups,
$ec2instance = (Get-EC2Instance).instances | select instanceid,@{Name="InstanceName";Expression={$_.tags | where key -eq "Name" | Select Value -Expand Value}},@{name="instancestatus";e={$_.state.name}},platform,keyname,PrivateIpAddress,publicipaddress,@{name="interfaceid";e={$_.NetworkInterfaces.NetworkInterfaceId}},SubnetId,@{name="SecurityGroups";e={$_.SecurityGroups.GroupName}},vpcid,@{name='account';e={$accountid}},@{name='Region';e={$Global:AWSRegion}},@{name='UTC Time';e={$Time}}
if($ec2instance) {
write-host "ec2instance information"
$ec2instance | ft -AutoSize

$global:allec2instance += $ec2instance

}


$ec2network = Get-EC2NetworkInterface | select NetworkInterfaceId,SubnetId,Description,Status,PrivateIpAddress,PrivateIpAddresses,@{name="SecurityGroupID";e={$_.Groups.GroupId}},@{name="SecurityGroupName";e={$_.Groups.GroupName}}
if($ec2network)
{
write-host "ec2network information"
$ec2network | ft -AutoSize
$global:allec2network += $ec2network
#$ec2network | export-csv -notypeinformation -path ${accountid}_EC2network$(get-date -Format "yyyyMMdd_HHmmss").csv
}

$ec2subnet = Get-EC2Subnet | select SubnetId,CidrBlock,@{name="SubnetName";e={(($_).Tags | Where-Object {$_.Key -eq 'Name'}).Value}},AvailabilityZone,AvailabilityZoneId,SubnetArn,vpcid
if($ec2subnet){

write-host "ec2subnet information"
$ec2subnet | ft -AutoSize
$global:allec2subnet += $ec2subnet

}


$ec2vpc = Get-EC2Vpc | select IsDefault,CidrBlock,OwnerId,VpcId,@{name="vpcname";e={(($_).Tags | Where-Object {$_.Key -eq 'Name'}).Value}},@{name='account';e={$accountid}},@{name='Region';e={$Global:AWSRegion}}
if($ec2vpc){

write-host "ec2vpc information"
$ec2vpc | ft -AutoSize
$global:allec2vpc += $ec2vpc
}

#Get-EC2address | select InstanceId, AssociationId, AllocationId, PrivateIpAddress,PublicIp
$Ec2ElaticIP = Get-EC2Address | Select PublicIp,PrivateIpAddress,InstanceId, AssociationId, AllocationId,@{name='account';e={$accountid}},@{name='Region';e={$Global:AWSRegion}}
if($Ec2ElaticIP){

    write-host "ElasticIP information"
    $Ec2ElaticIP | ft -AutoSize
    $global:allec2EIP += $Ec2ElaticIP
}

}


if ($Credential) {
    $WebRequestParams.Add('Body',@{UserName=$Credential.UserName;Password=$Credential.GetNetworkCredential().Password})
}

$InitialResponse=Invoke-WebRequest @WebRequestParams
$SAMLResponseEncoded=$InitialResponse.InputFields.FindByName('SAMLResponse').value

if (!$SAMLResponseEncoded) {
    Throw "No valid ADFS assertion received. Please check credentials."
}

#Evaluate SAML Response
$SAMLResponseDecoded=[xml]([System.Text.Encoding]::utf8.GetString([System.Convert]::FromBase64String($SAMLResponseEncoded))) | Select -ExpandProperty response

$AvailableRoles = $SAMLResponseDecoded.Assertion.AttributeStatement.Attribute |?{$_.name -eq 'https://aws.amazon.com/SAML/Attributes/Role'}  | %{
    $_.AttributeValue |%{
        [PSCustomObject]@{"SAMLProvider" = ($_ -split ",")[0];"Role" = ($_ -split ",")[1]}
    }
}
$AvailableRoles = @($AvailableRoles)
$allroles = $AvailableRoles | where-object {$_.Role -like "*ADFS*"}

#define global variable to store all ec2instance, netowrk, subnet, vpc information retrieve from each foreach loop.

$global:allec2instance = @()
$global:allec2network = @()
$global:allec2subnet = @()
$global:allec2vpc = @()
$global:allec2EIP = @()

foreach($availablerole in $AvailableRoles)
{
    write-host
    write-host "Checking Role: $($availablerole.role)"
    $AssumedRole= Use-STSRoleWithSAML -SAMLAssertion $SAMLResponseEncoded -PrincipalArn $AvailableRole.SAMLProvider -RoleArn $AvailableRole.Role -DurationInSeconds $credsDuration -ErrorAction Stop
    $credsInfo = @()

    $credProfileName = "prod"
    Set-AWSCredential -AccessKey $AssumedRole.Credentials.AccessKeyId -SecretKey $AssumedRole.Credentials.SecretAccessKey -SessionToken $AssumedRole.Credentials.SessionToken -StoreAs $credProfileName

    $credsInfo += [PSCustomObject]@{"AssumedSAMLRole" = $_.FriendlyName;"AWSProfileName" = $credProfileName;"CredentialsExpirationDate" = $AssumedRole.Credentials.Expiration}

    Set-AWSCredential -ProfileName $credProfileName   
    
    $USRegions = Get-AWSRegion |where-object region -like "us-west-*"

    Foreach ($region in $USRegions) {
    $Global:AWSRegion = $Region.Region
    Set-DefaultAWSRegion -Region $Global:AWSRegion
    write-host
    write-host "Checking Region: $Global:AWSRegion"
    get-AWSResource
    }
   #
    
}
$global:allec2instance | export-csv -notypeinformation -Force -path C:\Reports\ec2info.csv
$global:allec2network | export-csv -notypeinformation -Force -path C:\Reports\ec2networkinterface.csv
$global:allec2subnet | export-csv -notypeinformation -Force -path C:\Reports\ec2subnet.csv
$global:allec2vpc | export-csv -notypeinformation -Force -path C:\Reports\vpc.csv
$global:allec2EIP | export-csv -notypeinformation -Force -path C:\Reports\EC2EIP.csv
write-host

#move-item -Force -path C:\Reports\*.csv -Destination "\\gdcfs01\GeneralSoftware\_PaulHu\AWSInventoryReports\"
