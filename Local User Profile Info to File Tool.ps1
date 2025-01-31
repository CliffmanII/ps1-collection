<#
#Script: Local User Profile Cleanup Tool.ps1
#Purpose: Allows technicians to browse and remove user profiles, providing information about the profiles 

#Written by Dennis Cliffman II 04/01/2024
#Contact: DennisACliffman@gmail.com (personal), DCliffman@sja-solutions.com (professional)
#>

$output = ""

#Gets all non-special user profiles
Get-CimInstance -Class Win32_UserProfile -Filter Special=FALSE |
	ForEach-Object -Begin {$ErrorActionPreference = 'Stop'} {
		$output += "`n------------------------------"
		try {			
			#Get the SID for the currently processing profile
			$sid = $_.SID
			
			#Convert the SID into a human-readable account name
			try { 
				$id = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $sid
				$id.Translate([System.Security.Principal.NTAccount]).Value
				$AccountName = $id.Translate([System.Security.Principal.NTAccount]).Value
			
				#Print the account name and SID for the user
				$output += "`nAccount: $AccountName" 
				
			} catch {
				$output += "`nAccount: Unknown or Orphaned Account"
				$AccountName = "$sid"
			}	
			
			#Print the SID
			$output += "`nSID: $sid"

			#Print the last use/update time for the profile
			$TBD = Get-CimInstance -Class Win32_UserProfile | Where-Object {$_.Special -eq $false -and $_.Loaded -eq $false -and $_.SID -eq $sid}
			$TBDTime = $TBD.LastUseTime
			$output += "`nLast Updated: $TBDTime"
			
			#Print the path to the profile (for troubleshooting)
			$TBDPath = $TBD.LocalPath
			$output += "`nLocal Path: $TBDPath"

			#Get the profile path, get its size, convert it to GBs and round it, then print the result
			$TBDsize = (Get-ChildItem -Path $TBD.LocalPath -File -Recurse -Force | Measure-Object -Property Length -Sum).Sum
			#$output += "$TDBPath size: $TBDSize bytes"
			$TBDsizeInMB = $TBDsize / 1MB
			$TBDsizeInMB = [math]::Round($TBDsizeInMB,2)
			#$output += "$TBDPath size: $TBDsizeInMB MB"
			$TBDsizeInGB = $TBDsize / 1GB
			$TBDsizeInGB = [math]::Round($TBDsizeInGB,2)
			$output += "`n$TBDPath size: $TBDsizeInMB MB ($TBDsizeInGB GB)"
			
			#Roaming profile check and data printing, if applicable
			if ($TBD.RoamingConfigured -eq $true) {
				$TBDRPath = $TBD.RoamingPath
				$output += "`nRoaming Path: $TBDRpath"
				
				$TBDRsize = (Get-ChildItem -Path $TBDRPath -File -Recurse -Force | Measure-Object -Property Length -Sum).Sum
				$TBDRsizeInMB = $TBDRsize / 1GB
				$TBDRsizeInMB = [math]::Round($TBDRsizeInMB,2)
				$TBDRsizeInGB = $TBDRsize / 1GB
				$TBDRsizeInGB = [math]::Round($TBDRsizeInGB,2)
				$output += "`n$TBDRPath size: $TBDRsizeInMB MB ($TBDRsizeInGB GB)"
			} else {
				$output += "`nNot a roaming profile."
			}
			
		} catch {
			#Catch if there is an error
			$output += "`nFailed to translate $sid! $_"
		}
	}
	
$output | Out-File -Filepath "C:\_rootdir\UserProfiles.txt"