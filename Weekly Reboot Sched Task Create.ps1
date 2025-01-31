#remove old task
If (Get-ScheduledTask -TaskName "Post-Update Patch Window Reboot") {Unregister-ScheduledTask -TaskName "Post-Update Patch Window Reboot" -Confirm:$false -ErrorAction SilentlyContinue}
#Create Task Action Var
$taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument 'Restart-Computer -Force'
#Create Task Trigger Var
$taskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Tuesday -At 6am
#Create Task User Var
$taskUser = New-ScheduledTaskPrincipal -UserId "LOCALService" -LogonType ServiceAccount
#Register Scheduled Task using above parameters
Register-ScheduledTask -TaskName "Post-Update Patch Window Reboot" -Action $taskAction -Trigger $taskTrigger -Principal $taskUser -Description "Forcibly reboot the computer weekly at 6am"
#Enable newly created scheduled task
Enable-ScheduledTask -TaskName "Post-Update Patch Window Reboot"