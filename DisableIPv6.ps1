Write-Host "Listing Network Adapters"
Get-NetAdapter
$adapter = Read-Host "Enter Name of Adapter to disable IPv6 on"
Disable-NetAdapterBinding -Name $adapter -ComponentID ms_tcpip6
