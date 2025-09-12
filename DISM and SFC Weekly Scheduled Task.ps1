If (Get-ScheduledTask -TaskName "Weekly SFC and DISM") {Unregister-ScheduledTask -TaskName "Weekly SFC and DISM" -Confirm:$false -ErrorAction SilentlyContinue}
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "DISM /online /cleanup-image /restorehealth; SFC /scannow"
$taskName = 'Weekly SFC and DISM' 
$taskDescription = 'Runs DISM in Restore Health mode, followed by SFC to verify system file integrity.' 
$user = 'NT AUTHORITY\SYSTEM' 
Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Trigger $trigger -Action $action -RunLevel Highest -User $user