#this script is to remove office 2016 and 2013

#prompt for admin
if(!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "-File `"$($MyInvocation.MyCommand.Path)`"  `"$($MyInvocation.MyCommand.UnboundArguments)`""
 Exit
}
#kill office tasks
taskkill /f /im excel.exe
taskkill /f /im teams.exe
taskkill /f /im word.exe
taskkill /f /im powerpoint.exe
taskkill /f /im outlook.exe
write-output "Killed all Office tasks."
#change to _rootdir
cd C:\_rootdir
#unzip file
Expand-Archive -Force C:\_rootdir\saracmd.zip C:\_rootdir\
#change directory to SaRACmd directory
CD C:\_rootdir\saracmd\
#remove office 2016
write-output "Uninstalling Office 2016..."
.\SaRAcmd.exe -S OfficeScrubScenario -AcceptEula -Officeversion 2016
#remove office 2013
write-output "Uninstalling Office 2013..."
.\SaRAcmd.exe -S OfficeScrubScenario -AcceptEula -Officeversion 2013
#remove office 2010
write-output "Uninstalling Office 2010..."
.\SaRAcmd.exe -S OfficeScrubScenario -AcceptEula -Officeversion 2010
#install office m365
write-output "Installing Office 365..."
.\OfficeSetup.exe
#hold the window open
Read-Host -Prompt "Press enter to exit..."
exit