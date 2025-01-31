<#
Script: Block MS Teams Number Tool.ps1
Purpose: Allows technicians to easily block phone numbers in MSTeams 

Written by Dennis Cliffman II 04/10/2024
Contact: DennisACliffman@gmail.com (personal), DCliffman@sja-solutions.com (professional)
/#>

Clear-Host
Write-Host "Checking for and installing required modules..."
#installs required modules
Try {
	Install-Module -Name PowerShellGet
} catch {
	write-host "Admin permissions required. Please run in an elevated powershell instance" -Foregroundcolor Red
	break
}
Try {
	Install-Module -Name MicrosoftTeams
} catch {
	write-host "Admin permissions required. Please run in an elevated powershell instance" -Foregroundcolor Red
	break
}

#sign in and connect to MSTeams PS
write-host "Please sign in with M365 Administrator credentials..."
Try {
	Connect-MicrosoftTeams | Out-Null
	Clear-Host
} catch {
	write-host "Unable to sign in to Microsoft Teams online" -Foregroundcolor Red
	break
}

#function to block a number
function Block-MSTeamsNumber {
	try {
		#Get phone number and put in the proper format
		write-host "Block MS Teams Number Tool`n" -Foregroundcolor White
		write-host "There are 3 required entries to block numbers:`n1- The phone number to be blocked`n2- A name for the rule`n3- A description of the rule (generally ticket number/reason for blocking number)`n" -Foregroundcolor Blue
		write-host "Please enter the number you wish to block in the following format: ###########"
		$Number = Read-Host "For example, to block the number 1(555)123-4567, input 15551234567" 
		#$Pattern = "^\+?" + $Number + "$"
		
		#Have the user input a name and description
		$Name = Read-Host "Enter a name for the block rule"
		$Description = Read-Host "Enter a description for the rule (usually include CWM service ticket number here)"
		
		#Block the number, list all blocked numbers
		New-CsInboundBlockedNumberPattern -Name $Name -Enabled $True -Description $Description -Pattern "^\+?$Number$" | Out-Null
		write-host "`n$Number has been blocked with rule name $name" -Foregroundcolor Green
		write-host "Listing all blocked numbers:"
		Get-CsInboundBlockedNumberPattern | Select-Object -Property Name, Description, Pattern | Format-Table
	} catch {
		write-host "Error blocking number. Please check parameters and try again."
	}
	#prompt if use wants to try again/block more numbers
	Prompt-User
}

#function to repeat if needed
function Prompt-User {
	$again = Read-Host "Would you like to block another number? (Y/N)"
	if ($again -eq 'y') {
		Block-MSTeamsNumber
	} elseif ($again -eq 'n') {
		break
	} else {
		write-host "Invalid input" -Foregroundcolor Red
		Prompt-User
	}
}
#calls the function
Block-MSTeamsNumber