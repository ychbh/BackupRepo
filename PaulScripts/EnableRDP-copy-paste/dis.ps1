function BlockSysSetRegValue {
param ([string]$Path)
$acl = get-acl -Path $Path
$aclaccessrules = $acl.GetAccessRules($true,$true, [System.Security.Principal.NTAccount])
[System.Collections.ArrayList]$permission=@()
$permission.add("NT AUTHORITY\SYSTEM") | out-null
$permission.add("SetValue") | out-null
$permission.add("Deny") | out-null
$accessrule = new-object System.Security.AccessControl.RegistryAccessRule $permission
$acl.AddAccessRule($accessrule)
set-acl $Path $acl
}
$usrpath = "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
BlockSysSetRegValue -Path $usrpath
Set-ItemProperty -Path $usrpath -Name ScreenSaveActive -Value "0"
Set-ItemProperty -Path $usrpath -Name ScreenSaverIsSecure -Value "0"
Set-ItemProperty -Path $usrpath -Name ScreenSaveTimeOut -Value "0"
$tspath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
BlockSysSetRegValue -Path $tspath
Set-ItemProperty -Path $tspath -Name fDisableCdm -Value "0"
Set-ItemProperty -Path $tspath -Name fDisableClip -Value "0"
Restart-Service -Name TermService -Force