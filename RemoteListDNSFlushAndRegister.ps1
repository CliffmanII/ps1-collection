$listofservers = Get-Content .\servers.txt
foreach ($servers in $listofservers) {
Invoke-WmiMethod -class Win32_process -name Create -ArgumentList ("cmd.exe /c ipconfig /flushdns") -ComputerName $servers
Invoke-WmiMethod -class Win32_process -name Create -ArgumentList ("cmd.exe /c ipconfig /registerdns") -ComputerName $servers
}