<#
Script: Local User Profile Cleanup Tool.ps1
Purpose: Allows technicians to browse and remove user profiles, providing information about the profiles 

Written by Dennis Cliffman II 04/01/2024
Contact: DennisACliffman@gmail.com (personal), DCliffman@sja-solutions.com (professional)
#>

#Gets all non-special user profiles
Get-CimInstance -Class Win32_UserProfile -Filter Special=FALSE |
	ForEach-Object -Begin {$ErrorActionPreference = 'Stop'} {
		try {			
			#Get the SID for the currently processing profile
			$sid = $_.SID
			
			#Convert the SID into a human-readable account name
			try { 
				$id = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $sid
				$id.Translate([System.Security.Principal.NTAccount]).Value
				$AccountName = $id.Translate([System.Security.Principal.NTAccount]).Value
			
				#Print the account name and SID for the user
				Write-Host "Account: $AccountName" 
				
			} catch {
				Write-Host "Account: Unknown or Orphaned Account"
				$AccountName = "$sid"
			}	
			
			#Print the SID
			Write-Host "SID: $sid"

			#Print the last use/update time for the profile
			$TBD = Get-CimInstance -Class Win32_UserProfile | Where-Object {$_.Special -eq $false -and $_.Loaded -eq $false -and $_.SID -eq $sid}
			$TBDTime = $TBD.LastUseTime
			Write-Host "Last Updated: $TBDTime"
			
			#Print the path to the profile (for troubleshooting)
			$TBDPath = $TBD.LocalPath
			Write-Host "Local Path: $TBDPath"

			#Get the profile path, get its size, convert it to GBs and round it, then print the result
			$TBDsize = (Get-ChildItem -Path $TBD.LocalPath -File -Recurse -Force | Measure-Object -Property Length -Sum).Sum
			#Write-Host "$TDBPath size: $TBDSize bytes"
			$TBDsizeInMB = $TBDsize / 1MB
			$TBDsizeInMB = [math]::Round($TBDsizeInMB,2)
			#Write-Host "$TBDPath size: $TBDsizeInMB MB"
			$TBDsizeInGB = $TBDsize / 1GB
			$TBDsizeInGB = [math]::Round($TBDsizeInGB,2)
			Write-Host "$TBDPath size: $TBDsizeInMB MB ($TBDsizeInGB GB)"
			
			#Roaming profile check and data printing, if applicable
			if ($TBD.RoamingConfigured -eq $true) {
				$TBDRPath = $TBD.RoamingPath
				Write-Host "Roaming Path: $TBDRpath"
				
				$TBDRsize = (Get-ChildItem -Path $TBDRPath -File -Recurse -Force | Measure-Object -Property Length -Sum).Sum
				$TBDRsizeInMB = $TBDRsize / 1MB
				$TBDRsizeInMB = [math]::Round($TBDRsizeInMB,2)
				$TBDRsizeInGB = $TBDRsize / 1GB
				$TBDRsizeInGB = [math]::Round($TBDRsizeInGB,2)
				Write-Host "$TBDRPath size: $TBDRsizeInMB MB ($TBDRsizeInGB GB)"
			} else {
				Write-Host "Not a roaming profile." -ForegroundColor DarkGray
			}
			
			#Process for deleting the profile. Requires a "y" response, else the profile will not be deleted.
			$delete = Read-Host "Would you like to delete $AccountName's profile? (Y/N)"
			if ($delete -eq 'y') {
				$confirm = Read-Host "Please type 'delete' to confirm you would like to delete this profile"
				if ($confirm -eq 'delete' ) {
					Write-Host "Removing profile $AccountName. Please wait..." -ForegroundColor Red
					Remove-CimInstance -inputobject $TBD
					Write-Host "$AccountName has been deleted. `n" -ForegroundColor Red
				} else {
					Write-Host "User confirmation failed." -ForegroundColor Cyan
					Write-Host "$AccountName will NOT be deleted. `n" -ForegroundColor Green
				}
			} elseif ($delete -eq 'n') {
				Write-Host "$AccountName will NOT be deleted. `n" -ForegroundColor Green
			} else {
				Write-Host "Invalid Input." -ForegroundColor Cyan
				Write-Host "$AccountName will NOT be deleted. `n" -ForegroundColor Green
			}
		} catch {
			#Catch if there is an error
			Write-Host "Failed to translate $sid! $_" -ForegroundColor DarkRed
		}
	}