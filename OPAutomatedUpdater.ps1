<#
	.Name
	OPAutomatedUpdater.ps1
	
	.Author 
	Dennis Cliffman II 
	
	.Synopsis
	Automatically updates Office Practicum on all available devices within the domain. 

	.Description
	Automatically updates Office Practicum clients after updating the OP server.
	This script will look for any remote desktop servers and update those first, followed by workstations found in AD.
	
	.Notes
	If you are having trouble connecting to the X drive, make sure the X drive is mapped in the administrator space.
	Open an admin powershell or cmd window and use the "Net use X: \\(OP SERVER NAME HERE)\gdb_common /p:yes" command.
	"net use X: /delete" may need to be used first, if a connection already exists, but the script cannot find the update folder.
	And, per usual, verify the account you supply has permissions X:\updates and the $C share on domain-joined computers.

	Written by Dennis Cliffman II 04/10/2024 thru 04/19/2024
	Assistance by Bryce Skelton
	Contact: DennisACliffman@gmail.com (personal), DCliffman@sja-solutions.com (professional)

	#Requires -Version 6.0 -modules ActiveDirectory, ThreadJob
/#>

#check if running as administrator
if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
# Prompt the user to elevate the script
$arguments = "& '" + $myInvocation.MyCommand.Definition + "'"
Start-Process powershell -Verb runAs -ArgumentList $arguments
exit
}

function Write-ColorOutput($ForegroundColor) {
    #save the current color
    $fc = $host.UI.RawUI.ForegroundColor
    #set the new color
    $host.UI.RawUI.ForegroundColor = $ForegroundColor

    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    #restore the original color
    $host.UI.RawUI.ForegroundColor = $fc
}

#Gets time script starts
$StartTime = Get-Date -Format "MMddyy-HHmm"
$st = Get-Date
Clear-Host

#install required variables
write-output "Checking for and importing required modules. Please wait."
Register-PSRepository -Default -ErrorAction SilentlyContinue
Import-module ActiveDirectory -SkipEditionCheck -ErrorAction Stop
try {import-module ThreadJob}catch{ Install-Module ThreadJob -Force; Import-Module ThreadJob}

#Set error action and clear the $error variable
$ErrorActionPreference = "SilentlyContinue"
$Error.clear()

#generate a list of computers to update
$compList = @()
$serverList = @()
$nonServerList = @()
#grab servers and find RDS servers to update first
$serverList = Get-ADComputer -Filter {Name -like "*" -and Enabled -eq $True -and OperatingSystem -like "*server*"}
foreach ($svr in $serverList) {
	if ((Get-WindowsFeature -Computer $svr.name -Name RDS-RD-Server | select-object -ExpandProperty InstallState) -eq "Installed") { 
		$complist += $svr
	}
}
#grabs and adds AD computers
$nonServerList += Get-ADComputer -Filter {Name -like "*" -and Enabled -eq $True -and OperatingSystem -notlike "*Server*" -and OperatingSystem -notlike "*unknown*"}
$nonServerList = $nonServerList | sort-object -Property Name
$complist += $nonServerList

#get domain admin credentials
#write-output "Please input Domain Admin credentials:"
#$cred = Get-Credential -Message "Please input Domain Admin credentials:"

#grab update files, provided user provides latest update folder name/number
function Get-OPUpdateFiles {
	if (Get-PSDrive X -ErrorAction SilentlyContinue) {
		$xLocation = Get-PSDrive X | Select-Object -ExpandProperty DisplayRoot
		write-output "Confirmed X drive is active at $xLocation"
	} else {
		$server = Read-Host "Please enter the name of the OP server"
		New-PSDrive -Name "X" -PSProvider "Filesystem" -Root "\\$server\gdb_common\" -Persist | Out-Null
		$xLocation = Get-PSDrive X | Select-Object -ExpandProperty DisplayRoot
		write-output "Created X: drive at $xLocation"
	} 
	$latest = Get-ChildItem "X:\updates" | Where {$_.PSIsContainer } | Sort CreationTime -Descending | Select -First 1 | Select -expand Name
	write-output "Latest update folder is X:\updates\$latest"
	#$UpdateFolder = Read-Host "Please enter update folder number (X:\Updates\########\)"
	If (Test-Path -Path "X:\updates\$latest") {
		write-output "Copying update files. Please wait."
		Copy-Item -Path "X:\updates\$latest" -Destination "C:\_rootdir\OPUpdateFiles" -Recurse 
	} else {
		Write-ColorOutput Red "Could not find specified update folder."
		Get-OPUpdateFiles
	}
}
Get-OPUpdateFiles

#clear any jobs,host
Clear-Host
get-job | remove-job

#parse through each computer, targeting one device at a time
Foreach($CL in $compList) {
	$name = $CL.name
	$sourcepath = "C:\_rootdir\OPUpdateFiles"
	
	#Test connection to target device with a single ping, for speed
	Write-ColorOutput DarkGray "Connecting to $name"
	if (Test-Connection $name -Quiet -Count 1) {
		<#$session = $null
		#Creates a PS Session to target device, using previously input credentials to authenticate
        if ($session = New-PSSession -ComputerName $Name -Authentication negotiate -credential $cred) {
		    Write-ColorOutput DarkGray "PSSession created with $name"
			#New-PSSession -ComputerName $Name -Authentication negotiate -credential $cred
			#if successful, create a ThreadJob to copy the update files to the C:/OP folder on target device
		    $jobs += Start-ThreadJob -Name "$name's job" -ThrottleLimit 10 -ScriptBlock {Copy-Item -Path "$using:sourcepath\*" -Destination "$using:destinationpath" -Recurse -ToSession $Session -Force}
   		    Write-ColorOutput DarkGray "Created job for $name`n"
        } else {
            Write-ColorOutput Magenta "Could not connect to $name`n"
        }/#>
		#creates a temporary shared drive to the computer
		$drivename = $name + "_share"
		New-PSDrive -Name $drivename -PSProvider FileSystem -Root "\\$name\c$\OP\" | Out-Null
		$destinationpath = $drivename + ":\" 
		#makes a job to copy the files to the share
		Start-ThreadJob -Name "$name job" -ThrottleLimit 10 -ScriptBlock {Copy-Item -Path "$sourcepath\*" -Destination $destinationpath -Recurse -Force} | out-null
		Write-ColorOutput DarkGray "Created job for $name`n"
		#kill the share
		Remove-PSDrive $drivename
	} else {
		Write-ColorOutput Red "Could not connect to $name`n"
    }
	#report on jobs
	$runningJobs = (Get-Job -State Running).count
	$waitingJobs = (Get-Job -State NotStarted).count
	$completedJobs = (Get-Job -State Completed).count
	$failedJobs = (Get-Job -State Failed).count
	If ($runningJobs -gt 0) {
		write-output "Currently running jobs:"
		Get-Job -State Running | Format-Table Name, State
	}
	Write-ColorOutput Yellow "$runningJobs jobs are currently running."
	Write-ColorOutput Cyan "$waitingJobs jobs are currently waiting."
	Write-ColorOutput Green "$completedJobs jobs have completed successfully."
	Write-ColorOutput Red "$failedJobs jobs have failed.`n"
	
	#and repeats for each computer pulled from AD
}

#Once done checking computer availability and created jobs, provides information on said jobs
Do {
	Clear-Host
	$runningJobs = (Get-Job -State Running).count
	$waitingJobs = (Get-Job -State NotStarted).count
	$completedJobs = (Get-Job -State Completed).count
	$failedJobs = (Get-Job -State Failed).count	
	If ($runningJobs -gt 0) {
		write-output "Currently running jobs:"
		Get-Job -State Running | Format-Table Name, State
	}
	If ($waitingJobs -gt 0) {
		write-output "Currently waiting jobs:"
		Get-Job -State NotStarted | Format-Table Name, State
	}
	Write-ColorOutput Yellow "$runningJobs jobs are currently running."
	Write-ColorOutput Cyan "$waitingJobs jobs are currently waiting."
	Write-ColorOutput Green "$completedJobs jobs have completed successfully."
	Write-ColorOutput Red "$failedJobs jobs have failed.`n"
	
	#if jobs are still running or queued to run, waits one minute, then reports again
	if (($runningJobs -gt 0) -or ($waitingJobs -gt 0)) {
		Write-ColorOutput Magenta "Copy jobs are in-progress. Please wait."
		Sleep 5
	}
} While (($runningJobs -gt 0) -or ($waitingJobs -gt 0))

#Once all jobs are complete, provides confirmation on all jobs
write-output "Listing all jobs from this update:"
Get-Job | Select-Object Name, State
Sleep 10
Write-ColorOutput Green "`nCopy jobs have completed for each online client."

#Creates error log, if errors were created.
$EndTime = Get-Date -Format "MMddyy-HHmm"
$et = Get-Date
If ($Error -ne $null) {
	$ErrorLogFilePath = ("C:\_rootdir\OPAUErrorLog_" + $StartTime + "_to_" + $EndTime)
	Out-File -InputObject $Error -FilePath "$ErrorLogFilePath.txt"
}

#get runtime
$runMinutes = ($et - $st) | Select-Object -Expandproperty Minutes
$runSeconds = ($et - $st) | Select-Object -Expandproperty Seconds
Write-ColorOutput DarkGray "Run time was $runMinutes minutes, $runSeconds seconds."

Remove-Item -Path "C:\_rootdir\OPUpdateFiles" -Recurse -Force
Read-Host "Press Enter to exit"