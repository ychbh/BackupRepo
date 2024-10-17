Readme

------------Before your run this script, you need do something first so that it can run your environments well------

1 Setup powershell environment on your computer
#######set powershell Executionpolicy#######################
#####Open Powershell terminal or ISE as administriatior######
######run below in Powershell terminal or ISE###############
Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy UnRestricted

2 Install AWS tools module into the powershell
#####Open Powershell terminal or ISE as administriatior######
######run below in Powershell terminal or ISE###############
Install-Module -name AWSPowerShell.NetCore
Import-Module AWSPowerShell.NetCore


3 change the username as your in line 6 
$Credential = Get-Credential xxx9@nextestate

4 Run script on powershell terminal or ISE, ISE is perfered
you can see some of output when script running

5 Output will be save to root of your home folder, for example C:\Users\$username
you can find five csv file here

6 enjory, any question, please contect with paul.hu@greendotcorp.com, this script was made by rock.wang@greendotcorp.com,
he own copy right for this script, Thanks for him so much!!!!!!



