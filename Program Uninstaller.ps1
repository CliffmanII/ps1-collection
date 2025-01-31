#Var clear
$AppName = $null

#List Installed Apps
Get-WmiObject -Class Win32_Product | Select-Object -Property Name

# Get name of app to uninstall, convert text to WMIObject
$AppName = Read-Host "Enter Full Name of Application to Uninstall"
$MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq $AppName}

#Uninstall the app
$MyApp.Uninstall()