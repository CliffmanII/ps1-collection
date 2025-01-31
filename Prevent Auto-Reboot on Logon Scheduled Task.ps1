$trigger = New-ScheduledTaskTrigger -AtLogon
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument 'Start-sleep -seconds 30; shutdown -a'
$taskName = 'Prevent Auto-Restart on Logon' 
$taskDescription = 'Runs a shutdown -a command 30 seconds after logon to prevent automated restarts.' 
$user = 'SYSTEM' 

Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Trigger $trigger -Action $action -RunLevel Highest -User $user