$Localfolderpath = "C:\Personal Documents\SecureCRT operation logs"
$Remotefolderpath = "\\gdcfs01\GeneralSoftware\_PaulHu\operation logs"

$Localfolderfiles = Get-ChildItem -Path $Localfolderpath
$Remotefolderfiles = Get-ChildItem -Path $Remotefolderpath

$FileDiffs = Compare-object -ReferenceObject $Localfolderfiles -DifferenceObject $Remotefolderfiles
$FileDiffs | foreach {
    $copyParams =@{
	    'path' = $_.InputObject.FullName
		}
		if ($_.SideIndicator -eq '<=')
		{
			$copyParams.Destination = $Remotefolderpath
		}
		else
		{
			$copyParams.Destination = $Localfolderpath
		}
		Copy-Item @copyParams
		}
