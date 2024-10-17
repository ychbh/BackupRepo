
param (
[alias("i")]
$infile,
[alias("e")]
$enapwd
)

function helpsyntax {
write-host "`n============================================================="
write-host "RTRBK - Backup Utility for Network Devices"
write-host "Mandatory Parameters:"
write-host "    -i          <input file name>"
write-host "Optional Parameters:"
write-host "    -e          <enable pwd>"
write-host "                if not specified, interactively supplied password is used"
write-host "=============================================================`n"
}

if ($infile.length -eq 0) {  helpsyntax ; exit }

# CHECK FOR DEPENDENCIES / INSTALL POSH-SSH if needed
if ($(Get-Module -ListAvailable | ? Name -like "Posh-SSH") -eq $null) {
iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
}

$devcreds = get-credential
if ($enapwd.length -eq 0) { $enapwd = $devcreds.GetNetworkCredential().password }

$devs = Import-Csv -path $infile


foreach ($dev in $devs) {
  write-host "backing up" $dev.name
  if ($dev.devtype -eq 1) { $nopage = "term len 0`n" }
 # DEVTYPE 1 - CISCO IOS Router
 $Session = New-SSHSession -ComputerName $dev.ip -Credential $devcreds -acceptkey:$true 
 $stream = $Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 10000)
 Start-Sleep 2
 $prmpt = $stream.Read().Trim()
 # check - need to get to enable mode?
 if ($prmpt -like "*>*")
   {
   $stream.Write("en`n")
   Start-Sleep 1
   $stream.Write("$enapwd`n")
   Start-Sleep 1
   }

 $stream.Write($nopage)
 Start-Sleep 1

 $clearbuff = $stream.Read()
 $stream.Write("show ip interface brief`n")
 Start-Sleep 2
 $IPinterfaces = $stream.Read()
 Start-Sleep 1
 out-file -force -filepath "C:\DailyCollections\IPInterfaces\$($dev.name)_ShowIPinterface.txt" -inputobject $IPinterfaces
 
 $clearbuff = $stream.Read()
 $stream.Write("show ip arp`n")
 Start-Sleep 2
 $ARP = $stream.Read()
 Start-Sleep 1
 out-file -force -filepath "C:\DailyCollections\ARPTables\$($dev.name)_ShowIPARP.txt" -inputobject $ARP
 
 $clearbuff = $stream.Read()
 $stream.Write("show ip route`n")
 Start-Sleep 5
 $route = $stream.Read()
 # $stream.Write("exit`n")
 Start-Sleep 2
 out-file -force -filepath "C:\DailyCollections\RouteTables\$($dev.name)_ShowIPRoute.txt" -inputobject $route

 $clearbuff = $stream.Read()
 $stream.Write("show running`n")
 Start-Sleep 20
 $cfg = $stream.Read()
 Start-Sleep 1
 out-file -force -filepath "C:\DailyCollections\Configurations\$($dev.name)_showrun.txt" -inputobject $cfg

 Remove-SSHSession -SSHsession $session | out-null

  if ($dev.devtype -eq 2) { $nopage = "term page 0`n" }
    # DEVTYPE 2 - CISCO ASA
    $Session = New-SSHSession -ComputerName $dev.ip -Credential $devcreds -acceptkey:$true 
    $stream = $Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 10000)
    Start-Sleep 2
    $prmpt = $stream.Read().Trim()
    # check - need to get to enable mode?
    if ($prmpt -like "*>*")
      {
      $stream.Write("en`n")
      Start-Sleep 1
      $stream.Write("$enapwd`n")
      Start-Sleep 1
      }
   
    $stream.Write($nopage)
    Start-Sleep 1
    $clearbuff = $stream.Read()
    $stream.Write("show ip address`n")
    Start-Sleep 2
    $IPinterfaces = $stream.Read()
    Start-Sleep 1
    out-file -force -filepath "C:\DailyCollections\IPInterfaces\$($dev.name)_ShowIPinterface.txt" -inputobject $IPinterfaces
    
    $clearbuff = $stream.Read()
    $stream.Write("show arp`n")
    Start-Sleep 2
    $ARP = $stream.Read()
    Start-Sleep 1
    out-file -force -filepath "C:\DailyCollections\ARPTables\$($dev.name)_ShowIPARP.txt" -inputobject $ARP

    $clearbuff = $stream.Read()
    $stream.Write("show route`n")
    Start-Sleep 5
    $route = $stream.Read()
    # $stream.Write("exit`n")
    Start-Sleep 2
    out-file -force -filepath "C:\DailyCollections\RouteTables\$($dev.name)_ShowIPRoute.txt" -inputobject $route

    $clearbuff = $stream.Read()
    $stream.Write("show running`n")
    Start-Sleep 180
    $cfg = $stream.Read()
    Start-Sleep 1
    out-file -force -filepath "C:\DailyCollections\Configurations\$($dev.name)_showrun.txt" -inputobject $cfg
    Remove-SSHSession -SSHsession $session | out-null
    }
  if ($dev.devtype -eq 4) {
    # DEVTYPE 4 - PROCURVE SWITCH
    $Session = New-SSHSession -ComputerName $dev.ip -Credential $devcreds -acceptkey:$true
    $stream = $Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    Start-Sleep 10
    $stream.Write("`n")
    $stream.Write("no page`n")
    $clearbuff = $stream.Read()
    Start-Sleep 2
    $stream.Write("show config`n")
    Start-Sleep 5
    $cfg = $stream.Read() 
    $cfg = $cfg  -split "`n" | ?{$_ -notmatch "\x1B"}   # strip out ANSI Escape Chars
    Start-Sleep 1
    out-file -force -filepath ($dev.name+".cfg") -inputobject $cfg
    Remove-SSHSession -SSHsession $session | out-null
  }

  if ($dev.devtype -eq 5) {
    # DEVTYPE 5 - COMWARE SWITCH
    $Session = New-SSHSession -ComputerName $dev.ip -Credential $devcreds -acceptkey:$true
    $stream = $Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    Start-Sleep 2
    $stream.Write("`n")
    $stream.Write("screen-length disable`n")
    $clearbuff = $stream.Read()
    Start-Sleep 2
    $stream.Write("dis cur`n")
    Start-Sleep 5
    $cfg = $stream.Read()
    $stream.Write("exit`n")
    Start-Sleep 1
    out-file -force -filepath ($dev.name+".cfg") -inputobject $cfg
    Remove-SSHSession -SSHsession $session | out-null
  }
  if (($dev.devtype -eq 6) -or ($dev.devtype -eq 7)) {
    # DEVTYPE 6 or 7 - PALO ALTO SWITCH
    if ($dev.devtype -eq 5) { $outcmd = "set cli config-output-format set`n" ; $outtype = "set"}
    if ($dev.devtype -eq 6) { $outcmd = "set cli config-output-format xml`n" ; $outtype = "xml" }
    $Session = New-SSHSession -ComputerName $dev.ip -Credential $devcreds -acceptkey:$true
    $stream = $Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)
    Start-Sleep 2
    $stream.Write("set cli pager off`n")
    $stream.Write($outtype)
    Start-Sleep 1
    $clearbuff = $stream.Read()
    Start-Sleep 2
    $stream.Write("configure`nshow'n")
    Start-Sleep 5
    $cfg = $stream.Read()
    $stream.Write("exit`n")
    Start-Sleep 1
    out-file -force -filepath ($dev.name+$outtype+".cfg") -inputobject $cfg
    Remove-SSHSession -SSHsession $session | out-null
  }
