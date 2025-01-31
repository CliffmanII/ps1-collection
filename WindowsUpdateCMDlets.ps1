Install-Module PSWindowsUpdate
Get-WindowsUpdate
Install-WindowsUpdate

Install-WindowsUpdate -NotCategory "Drivers" -NotTitle OneDrive