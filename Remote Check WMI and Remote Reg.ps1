$server = Read-Host "Input Computer Name:"
$ErrorActionPreference = 'SilentlyContinue'
$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hive, $server)
$svc = Get-WmiObject -List -Class Win32_OperatingSystem -Computer $server
$ErrorActionPreference = 'Stop'

if ($reg) {
  "Access to registry on $server succeeded."
} else {
  "Cannot access registry on $server."
}

if ($svc) {
  "Access to WMI on $server succeeded."
} else {
  "Cannot access WMI on $server."
}