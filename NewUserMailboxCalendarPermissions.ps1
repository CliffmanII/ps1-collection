<#
Script: NewUserMailboxCalendarPermissions.ps1
Purpose: Adds permissions for all listed user to review the calendar of all mailboxes 

Written by Dennis Cliffman II 04/11/2024
Contact: DennisACliffman@gmail.com (personal), DCliffman@sja-solutions.com (professional)
/#>

#import needed modules and connect to Exchange Online
Clear-Host
Import-Module ExchangeOnlineManagement
Import-Module ThreadJob
Write-Host "Please input M365 admin credentials in the pop-up window:" -Foregroundcolor Cyan
Connect-ExchangeOnline -ShowBanner:$false -UserPrincipalName #UPN REDACTED#
Write-Host "Connected to ExchangeOnline" -Foregroundcolor Cyan
$startTime = Get-Date -Format "MM/dd/yy-HH:mm"

#clear out jobs and create empty job array
get-job | remove-job
$jobs = @()

#Get all mailboxes, and parse through text file to get user mailboxes
$AllMailBoxes = Get-Mailbox
$FileLocation = "C:\_rootdir\MailBoxCalendarPermissions\MailboxUsers.txt"
$UserMailboxes = @()
$UserMailboxes = Get-content $Filelocation
$count = 0

#parse through each mailbox and ensure permissions
Write-Host "Starting mailbox permission jobs..." -Foregroundcolor White
Foreach ($mbx in $AllMailBoxes) {
    ++$Count
    If ($Count -gt 30) {
        Do { 
			Clear-Host
			Write-Host "30 jobs limit has been reached. Pausing job creation until queued jobs complete...`n" -Foregroundcolor White
			$runningJobs = (Get-Job -State Running).count
			$waitingJobs = (Get-Job -State NotStarted).count
			$completedJobs = (Get-Job -State Completed).count
			$failedJobs = (Get-Job -State Failed).count	
			Write-Host "$runningJobs jobs are currently running." -Foregroundcolor Yellow
			Write-Host "$waitingJobs jobs are currently waiting." -Foregroundcolor Cyan
			Write-Host "$completedJobs jobs have completed successfully." -Foregroundcolor Green
			Write-Host "$failedJobs jobs have failed.`n" -Foregroundcolor Red
			Sleep 10
		} While ((Get-Job -State Running).count -gt 0)
		$Count = 0
		Write-Host "Resuming job creation." -Foregroundcolor White
    }
	$jobs += Start-ThreadJob -InitializationScript {import-module ExchangeOnlineManagement} -Name "$mbx calendar set reviewer permissions" -ThrottleLimit 25 -ScriptBlock {
		Connect-ExchangeOnline -ShowBanner:$false -UserPrincipalName #UPN REDACTED#.com
		$calendar=$mbx.alias+":\Calendar"
		foreach ($user in $using:UserMailBoxes) {
			Add-mailboxfolderpermission -identity $Calendar -user $user -AccessRights Reviewer
			#Write-host "Added $mbx calendar set $shortUser reviewer permissions" -Foregroundcolor Green
		}
	}
}
Do {
	Clear-Host
	$runningJobs = (Get-Job -State Running).count
	$waitingJobs = (Get-Job -State NotStarted).count
	$completedJobs = (Get-Job -State Completed).count
	$failedJobs = (Get-Job -State Failed).count	
	Write-Host "$runningJobs jobs are currently running." -Foregroundcolor Yellow
	Write-Host "$waitingJobs jobs are currently waiting." -Foregroundcolor Cyan
	Write-Host "$completedJobs jobs have completed successfully." -Foregroundcolor Green
	Write-Host "$failedJobs jobs have failed.`n" -Foregroundcolor Red
	
	#if jobs are still running or queued to run, waits, then reports again
	if (($runningJobs -gt 0) -or ($waitingJobs -gt 0)) {
		Write-Host "Mailbox permission jobs are in-progress. Refreshing in 5 seconds..." -Foregroundcolor White
		Sleep 5
	}
} While (($runningJobs -gt 0) -or ($waitingJobs -gt 0))

#Once all jobs are complete, provides confirmation on all jobs
Clear-Host
$currenttime = Get-Date -Format "MMddyy_HHmm" 
$currenttime += "_jobs"
$outpath = "C:\_rootdir\MailBoxCalendarPermissions\History\$currentTime.txt"
Get-Job | Select-Object Name, State | Out-File -FilePath $outpath
Write-Host "Job information is output to .\History\$currentTime.txt"
Write-Host "Mailbox permissions have been updated." -Foregroundcolor Green
Write-Host "Began adding permissions at $StartTime." -Foregroundcolor DarkGray
$EndTime = Get-Date -Format "MM/dd/yy-HH:mm"
Write-Host "Finished adding permissions at $EndTime." -Foregroundcolor DarkGray
Read-host "Press ENTER to close this window"
