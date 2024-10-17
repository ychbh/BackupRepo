run ISE as admin mode 
execute "Set-ExecutionPolicy -ExecutionPolicy bypass -scope LocalMachine"
then load dis.ps1 in ISE
run it
you will be kicked off from RDP session,
ask SE help to restart your jump box, if RDP service can't be restart
then you can enjoy copy and paste on your jumpbox