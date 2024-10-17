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

--------Update 07/27/2023 by Andrew Huang, ahuang1@greendotcorp.com-------------
###This scripts need customerize folders and yourname/password to your own enivronment before running it######
1. change your own aws login account at 
Line 6: $UserName = "xx9@nextestate"
2. Update your folders. In this script, I copied the scripts and keyfile.txt to my folder "C:\PersonalScripts\Get-AWS-Resource-Powershell-script_20211123", so I changed the scripts
 line 7  as "$KeyFile = "C:\PersonalScripts\Get-AWS-Resource-Powershell-script_20211123\keyfile.txt". Your folder might be different, you need update this line 7 to your environment:
3. In Powershell, cd to the new folder, run 
"<password>" | ConvertTo-SecureString -AsPlainText -force | ConvertFrom-SecureString | out-file keyfile.txt, "<password>" is your own aws login password, and validate timestapm of the keyfile.txt, it should be the time you run this  cmdlet.
4. Right click "getawsresources-2023-07-27_AH.ps1"->"Run with PowerShell", you should be able to see prompts from scripts. If errors, go back to check above prerequiste settings.
5. Open AWS-Inventory.xlsx from EXCEL, "Enable Edit" at the top if displayed, "Enable Content" is the next in my test, then Data->Refresh All. You should be able to see data are refreshed to the date in #4.
   If errors, please go to Data->Data Source settings, and check the path are correctly set to the data generated at #4, also check the "Permissition", I set it up as "public" and it runs smoothly.



