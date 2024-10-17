
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
     sleep 2
     $prmpt = $stream.Read().Trim()
     # check - need to get to enable mode?
     if ($prmpt -like "*>*")
       {
       $stream.Write("en`n")
       sleep 1
       $stream.Write("$enapwd`n")
       sleep 1
       }
    
     $stream.Write($nopage)
     sleep 1
     $clearbuff = $stream.Read()
     $stream.Write("show running`n")
     sleep 20
     $cfg = $stream.Read()
     # $stream.Write("exit`n")
     sleep 5
     out-file -force -filepath "C:\DailyCollections\Configurations\$($dev.name)_showrun.txt" -inputobject $cfg
     $clearbuff = $stream.Read()
     $stream.Write("show ip route`n")
     sleep 5
     $route = $stream.Read()
     # $stream.Write("exit`n")
     sleep 2
     out-file -force -filepath "C:\DailyCollections\RouteTables\$($dev.name)_ShowIPRoute.txt" -inputobject $route
     $clearbuff = $stream.Read()
     $stream.Write("show ip interface brief`n")
     sleep 5
     $IPinterfaces = $stream.Read()
     # $stream.Write("exit`n")
     sleep 2
     out-file -force -filepath "C:\DailyCollections\IPInterfaces\$($dev.name)_ShowIPinterface.txt" -inputobject $IPinterfaces
     $clearbuff = $stream.Read()
     $stream.Write("show ip arp`n")
     sleep 5
     $ARP = $stream.Read()
     # $stream.Write("exit`n")
     sleep 2
     out-file -force -filepath "C:\DailyCollections\ARPTables\$($dev.name)_ShowIPARP.txt" -inputobject $ARP
    
     Remove-SSHSession -SSHsession $session | out-null
    
      if ($dev.devtype -eq 2) { $nopage = "term page 0`n" }
        # DEVTYPE 2 - CISCO ASA
        $Session = New-SSHSession -ComputerName $dev.ip -Credential $devcreds -acceptkey:$true 
        $stream = $Session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 10000)
        sleep 2
        $prmpt = $stream.Read().Trim()
        # check - need to get to enable mode?
        if ($prmpt -like "*>*")
          {
          $stream.Write("en`n")
          sleep 1
          $stream.Write("$enapwd`n")
          sleep 1
          }
       
        $stream.Write($nopage)
        sleep 1
        $clearbuff = $stream.Read()
        $stream.Write("show running`n")
        sleep 180
        $cfg = $stream.Read()
        # $stream.Write("exit`n")
        sleep 20
        out-file -force -filepath "C:\DailyCollections\Configurations\$($dev.name)_showrun.txt" -inputobject $cfg
        sleep 20
        $clearbuff = $stream.Read()
        $stream.Write("show route`n")
        sleep 5
        $route = $stream.Read()
        # $stream.Write("exit`n")
        sleep 2
        out-file -force -filepath "C:\DailyCollections\RouteTables\$($dev.name)_ShowIPRoute.txt" -inputobject $route
        $clearbuff = $stream.Read()
        $stream.Write("show ip address`n")
        sleep 5
        $IPinterfaces = $stream.Read()
        # $stream.Write("exit`n")
        sleep 2
        out-file -force -filepath "C:\DailyCollections\IPInterfaces\$($dev.name)_ShowIPinterface.txt" -inputobject $IPinterfaces
        $clearbuff = $stream.Read()
        $stream.Write("show arp`n")
        sleep 5
        $ARP = $stream.Read()
        # $stream.Write("exit`n")
        sleep 2
        out-file -force -filepath "C:\DailyCollections\ARPTables\$($dev.name)_ShowIPARP.txt" -inputobject $ARP
       
        Remove-SSHSession -SSHsession $session | out-null
        }