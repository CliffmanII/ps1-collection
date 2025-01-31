<#
Script: NewUserCreation.ps1
Purpose: Creates a new user in a company's tenant using their preferences.

Written by Dennis Cliffman II 04/15/2024 through 4/19/2024
Contact: DennisACliffman@gmail.com (personal)

scratch notes: 
to-do's:
	1- M365 licensing DONE
		Add a Business Standard license to every new user
		https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users/get-mguserlicensedetail?view=graph-powershell-1.0
	2- M365 group membership/copy DONE
	3- scan folder:
		On #Server Redacted#, create a scan folder for the new user
		- D:\Scans\username
		- Set folder security options
			Disable inheritance
			Remove Domain Users
			Add username
/#>

Clear-Host

#import required modules
Import-Module ActiveDirectory
Import-Module Microsoft.Graph.Users

#Function: Select-MenuOption
#Description: Script Menu
#Parameters: InvalidInput(boolean)
Function Select-MenuOption {
	param ([boolean]$invalidInput)
	
	Clear-Host
	Write-Host @"
New User Creation Tool

---------------------------------------------------

Select from the following options:


0- Create a new user and perform all checklist items.

1- Create AD new user.
2- Copy AD permissions from one user to another.
3- Look up account info.
4- Perform an AD Connect sync (delta).
	note: this will create an M365 account for any newly created users.
5- Copy M365 permissions from one user to another.
6- Add M365 Business Standard license to an account.
7- Create scan folder for user.

---------------------------------------------------
"@
	
	if ($invalidInput) {
		Write-Host "Invalid input entered." -Foregroundcolor Red
	} else {
		Write-Host ""
	}
	$input = Read-Host "Enter Selection Number"
	switch ($input) {
		0 { Create-ChecklistUser  }
		1 { Get-NewUserInfo }
		2 { Get-ParentAccount }
		3 { Write-ADUserInfo }
		4 { Perform-ADConnectDeltaSync }
		5 { Get-M365ParentAccount }
		6 { Add-M365License  }
		7 { Create-UserFolder }
		Default { Select-MenuOption -InvalidInput $true }		
	}
}


#Function: Create-ChecklistUser
#Description: Starts a user creation to complete all checklist items for the client
#Parameters: Checklist(boolean)
Function Create-ChecklistUser {
	
}


#Function: Get-NewUserInfo
#Description: Calls funcitons to get required user information to make an AD Account
#Parameters: Checklist(boolean)
Function Get-NewUserInfo {
	Clear-Host
	$firstName = Get-FirstName + ""
	Write-Host ""
	$lastName = Get-LastName + ""
	Write-Host ""
	$userPass = Get-UserPassword + ""
	Write-Host ""
	
	#Confirmation of information gathered
	Write-Host "Name entered: $firstName $lastName" -ForegroundColor Green
	Write-Host "Password entered: $userPass" -ForegroundColor Green
	
	#Calls Make-ADUserAccount to create the account
	Make-ADUserAccount -firstName $firstName -lastName $lastName -userPass $userPass
}

#Function: Get-FirstName
#Description: Gets the first name of the user
#Parameters: Checklist(boolean)
Function Get-FirstName {
	$firstName = Read-Host "Enter FIRST name for the user"
	$confirm = Read-Host "First name entered: $firstName.`nPlease confirm this is correct (y/n)"
	if ($confirm -ne 'y') { Get-FirstName }
	else { return $firstName }
}

#Function: Get-LastName
#Description: Gets the last name of the user
#Parameters: Checklist(boolean)
Function Get-LastName {
	$lastName = Read-Host "Enter LAST name for the user"
	$confirm = Read-Host "Last name entered: $lastName.`nPlease confirm this is correct (y/n)"
	if ($confirm -ne 'y') { Get-LastName }
	else { return $lastName }
}

#Function: Get-UserPassword
#Description: Gets a password for the user
#Parameters: Checklist(boolean)
Function Get-UserPassword {
	$userPass = "Support1"
	$global:userPass = $userpass
	Write-Host "Password is set to Support1"
	return $userPass
	<# This function is turned off due to the original company's New User Checklist requiring a specific password
	$userPass = Read-Host "Enter password for the user"
	$confirm = Read-Host "Password entered: $userPass.`nPlease confirm this is correct (y/n)"
	if ($confirm -ne 'y') { Get-UserPassword }
	else { 
	$global:userPass = $userPass
	return $userPass 
	}
	/#>
}

#Function: Make-ADUserAccount
#Description: Creates an AD user account per the company's New User Checklist requirements
#Parameters: FirstName(mandatory, string), LastName(mandatory, string), UserPass(Mandatory, string)
Function Make-ADUserAccount {
	param ([Parameter(mandatory)][string]$firstName, [Parameter(mandatory)][string]$lastName, [Parameter(mandatory)][string]$userPass)
	
	$securePass = ConvertTo-SecureString -String $userPass -AsPlainText -Force
	
	$adName = $firstName + " " + $lastName
	$SAMAccountName = $firstName.substring(0,1) + $lastName
	$userMailAddr = $firstName + "." + $lastName + #Domain Redacted#
	
	New-ADUser -Name $adName -GivenName $firstName -SurName $lastName -SAMAccountName $SAMAccountName -Enabled $true -Path "OU=Main Office,OU=Users,DC=#Domain Redacted#,DC=local" -ChangePasswordAtLogon $true -AccountPassword $securePass -confirm -OtherAttributes @{
		'UserPrincipalName' = $userMailAddr
		'displayName' = ($firstName + " " + $lastName)
		'mail' = $userMailAddr
		'Company' = #Company Redacted#
	}
	Write-Host "Created the following account"
	Get-ADUser -Filter 'Name -eq $adname'| Format-List Name, @{Label = 'Password'; Expression = {$userPass} }, SamAccountName, UserPrincipalName, DistinguishedName 
	Read-Host "Press Enter to continue"
	Get-ParentAccount $adName
}

#Function: Get-ParentAccount
#Description: "parent" account picker to copy security groups from, to a "child" Account
#Parameters: childName(string)
Function Get-ParentAccount {
	param ([string]$childName)
	
	Clear-Host
	if ($childName -eq $null -or $childName -eq "") {
		$childName = Read-Host "Please enter full name (like John Doe) of the user to copy groups TO"
		$potentialChild = Get-ADUser -Filter 'Name -like $childName' | Select-object -ExpandProperty Name
	}
	$parentName = Read-Host "Please enter full name (like John Doe) of the user to copy groups FROM`nIf none, leave this empty and press Enter"
	if ($parentName -eq $null -or $parentName -eq "") {
		Write-Host "No account entered. Adding default/universal group memberships."
		$hasParent = $false
		Copy-ParentAccount -hasParent $hasParent -parentName $parentName -childName $childName
	} else {
		$potentialParents = Get-ADUser -Filter 'Name -like $parentName' | Select-object -ExpandProperty Name
		$potentialParentCount = $potentialParents.count
		
		if ($potentialParentCount -eq 0) {
			Write-Host "No accounts found."
			Get-ParentAccount $childName
		} elseif ($potentialParentCount -eq 1) {
			$confirm = Read-Host "Please confirm. Would you like to copy groups from $parentName to $childName`? (y/n)"
			
			if ($confirm -ne 'y') {
				Get-ParentAccount $childName 
			} else { 
				$parentName = $potentialParents
				$hasParent = $true
				Copy-ParentAccount -hasParent $hasParent -parentName $parentName -childName $childName
			}
		} elseif ($potentialParentCount -gt 1) {
			Write-Host "Found the following accounts as potential matches:"
			foreach ($account in $potentialParents) {
				Get-ADUser -filter 'name -eq $account' | Select Name,UserPrincipalName,Enabled
			}
			
			$selectedParent = Read-Host "Please enter the full name of the user you would like to choose (like John Doe).`nTo find or choose different accounts, leave this empty and press Enter"
			$finalParent = Get-ADUser -Filter 'Name -eq $selectedParent' | Select-object -ExpandProperty Name
			$finalParentCount = $finalParent.count
			
			if ($finalParentCount -eq 1) {
				$confirm = Read-Host "Please confirm. Would you like to copy groups from $finalParent to $childName`? (y/n)"
				if ($confirm -ne 'y') { 
				Get-ParentAccount $childName
				} else {
					$parentName = $selectedParent
					$hasParent = $true
					Copy-ParentAccount -hasParent $hasParent -parentName $parentName -childName $childName
				}
			} else {
				Write-Host "No account selected."
				Get-ParentAccount $childName
			}
		}
	}
}

#Function: Copy-ParentAccount
#Description: copies AD security group memberships from a "parent" account to a "child" account
#Parameters: ParentName(string), ChildName(string), HasParent(boolean)
Function Copy-ParentAccount {
	param ([string]$parentName, [string]$childName, [boolean]$hasParent)
	
	if ($hasParent -ne $false) {
		$userC = Get-ADUser -Filter 'Name -eq $childName' | Select-Object -ExpandProperty SAMAccountName
		$userP = Get-ADUser -Filter 'Name -eq $parentName' | Select-Object -ExpandProperty SAMAccountName
		$groups = Get-ADPrincipalGroupMembership -Identity $userP | Select-Object -ExpandProperty Name
		foreach ($grp in $groups) {
			Add-ADGroupMember $grp -Members $userC -ErrorAction SilentlyContinue
		}
	}
	$user = Get-ADUser -Filter 'Name -eq $childName' | Select-Object -ExpandProperty SAMAccountName
	Add-ADGroupMember -Identity BSN-Employees -Members $user
	Write-Host "All available groups have been added."
	$SecurityGroups = Get-ADPrincipalGroupMembership -Identity $userC | Select-Object -ExpandProperty Name
	$SecurityGroups
	Read-Host "Press Enter to continue"
	Write-ADUserInfo -AccountName $childName
}
 
#Function: Write-ADUserInfo
#Description: Grabs AD info for a user and outputs it in an easy to ready way
#Parameters: AccountName(string), UserPass(string)
Function Write-ADUserInfo {
	param ([string]$AccountName, [string]$UserPass)
	
	Clear-Host
	if ($AccountName -eq $null -or $AccountName -eq "") {
		$AccountName = Read-Host "Enter Account Name (like John Doe)"
	} 
	$potentialAccounts = @()
	$potentialAccounts = Get-ADUser -Filter 'Name -like $AccountName' | Select-object -ExpandProperty Name
	$potentialAccountsCount = $potentialAccounts.count
	
	if ($potentialAccountsCount -eq 0) {
		Write-Host "No accounts found."
		Write-ADUserInfo
	} elseif ($potentialAccountsCount -gt 1) {
		Write-Host "Multiple accounts found:"
		foreach ($acct in $potentialAccounts) {
			$user = Get-ADuser -Filter 'Name -eq $acct' | Select-Object -ExpandProperty SAMAccountName
			$SecurityGroups = Get-ADPrincipalGroupMembership -Identity $user | Select-Object -ExpandProperty Name
			$output = Get-ADUser -Filter 'Name -eq $AccountName' | Format-List Name, SamAccountName, UserPrincipalName, DistinguishedName, @{Label = 'SecurityGroups'; Expression = {$SecurityGroups} }
			$output
		}
	} elseif ($potentialAccountsCount -eq 1) {
		Write-Host "Account information:"
		$user = Get-ADUser -Filter 'Name -eq $AccountName' | Select-Object -ExpandProperty SAMAccountName
		$SecurityGroups = Get-ADPrincipalGroupMembership -Identity $user | Select-Object -ExpandProperty Name
		$output = Get-ADUser -Filter 'Name -eq $AccountName' | Format-List Name, @{Label = 'Password'; Expression = {$global:userPass} }, SamAccountName, UserPrincipalName, DistinguishedName, @{Label = 'SecurityGroups'; Expression = {$SecurityGroups} }
		$output
	}
	$userPass = $null
	Read-Host "Press Enter to return to menu"
	Select-MenuOption
}

#Function: Perform-ADConnectDeltaSync
#Description: Performs an Start-ADSyncSyncCycle on the AD Connect server
#Parameters: Checklist(boolean)
function Perform-ADConnectDeltaSync {
	$Server = #Server Redacted#

	Clear-Host
	Write-Output "Performing an AD Connect Sync type Delta via $Server..."
	if (Test-Connection $Server -Quiet -Count 1) {
		$sync = Invoke-Command -ComputerName $Server -ScriptBlock {Start-ADSyncSyncCycle Delta}
		sleep 5
		$sync | Select-Object -ExpandProperty Result
	} else {
		Write-host "Could not reach $Server"
	}
	Read-Host "Press Enter to return to menu"
	Select-MenuOption
}

#Function: Get-M365ParentAccount
#Description: "parent" account picker to copy M365 groups from, to a "child" Account
#Parameters: ChildName(string)
function Get-M365ParentAccount {
	param ([string]$ChildName)
	
	$has365Parent = $false
	
	Clear-Host
	Write-Host "Attempting to connect to Microsoft's online services.`nPlease sign in using M365 admin credentials."
	Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All" -NoWelcome
	
	if (!($childName)) {
		$childName = Read-Host "Please enter full name (like John Doe) of the user to copy M365 groups TO"
	}
	if (Get-MgUser -Search "DisplayName:$childName" -ConsistencyLevel eventual) {
		$potentialChild = Get-MgUser -Search "DisplayName:$childName" -ConsistencyLevel eventual | Select-object -ExpandProperty DisplayName
		$potentialChild
	} else {
		Write-Host "Could not find an account that matches the name $childName."
		Get-M365ParentAccount
	}
	
	if (!($parentName)) {
		$parentName = Read-Host "Please enter full name (like John Doe) of the user to copy M365 groups FROM"
		if (Get-MgUser -Search "DisplayName:$parentName" -ConsistencyLevel eventual) {\
			$has365Parent = $true
			$potentialParent = Get-MgUser -Search "DisplayName:$parentName" -ConsistencyLevel eventual | Select-object -ExpandProperty DisplayName
			$potentialParent
		} else {
			Write-Host "Could not find account with that name."
			Get-M365ParentAccount $childName
		}
	}
	$potentialParent = Get-MgUser -Search "DisplayName:$parentName" -ConsistencyLevel eventual | Select-object -ExpandProperty DisplayName
	$potentialParent
	Disconnect-MgGraph | Out-Null
	Copy-M365ParentAccount $parentName $childName $has365Parent
}

#Function: Copy-M365ParentAccount
#Description: Copies M365 group memberships from a "parent" account to a "child" account
#Parameters: ParentName(string), ChildName(string), has365Parent(boolean)
function Copy-M365ParentAccount {
	param ([string]$parentName, [string]$childName, [boolean]$has365Parent)
	
	Write-Host "Attempting to connect to Microsoft's online services.`nPlease sign in using M365 admin credentials."
	Connect-MgGraph -Scopes "User.Read.All", "Group.ReadWrite.All" -NoWelcome
	$childID = Get-MgUser -Search "DisplayName:$childName" -ConsistencyLevel eventual | Select-object -ExpandProperty ID
	if ($has365Parent -ne $false) {
		$parentID = Get-MgUser -Search "DisplayName:$parentName" -ConsistencyLevel eventual | Select-object -ExpandProperty ID
		$parentGroups = Get-MgUserMemberOfAsGroup -UserID $parentID -ConsistencyLevel eventual | Select-Object DisplayName, Description
		foreach ($grp in $parentGroups) {
			New-MgGroupMember -GroupId $grp -DirectoryObjectId $childID -ErrorAction SilentlyContinue
		}
	}
	Write-Host "All available groups have been added."
	$childGroups = Get-MgUserMemberOfAsGroup -UserID $childID -ConsistencyLevel eventual | Select-Object DisplayName, Description
	$childGroups
	Read-Host "Press Enter to continue"
	Disconnect-MgGraph | Out-Null
	Select-MenuOption
}

#Function: Add-M365License
#Description: Get license information for an account
#Parameters: AccountName(string)
function Add-M365License {
	param ([string]$accountName)
	
	Write-Host "Attempting to connect to Microsoft's online services.`nPlease sign in using M365 admin credentials."
	Connect-MgGraph -Scopes "User.ReadWrite.All", "Organization.Read.All" -NoWelcome
	
	if (!($accountName)) {
		$accountName = Read-Host "Please enter full name (like John Doe) of the user to copy M365 groups TO"
	}
	if (Get-MgUser -Search "DisplayName:$accountName" -ConsistencyLevel eventual) {
		$accountName = Get-MgUser -Search "DisplayName:$accountName" -ConsistencyLevel eventual | Select-object -ExpandProperty DisplayName
		$accountName
	} else {
		Write-Host "Could not find an account that matches the name $accontName."
		Get-M365LisenceInfo
	}
	
	$acctID = Get-MgUser -Search "DisplayName:$accountName" -ConsistencyLevel eventual | Select-object -ExpandProperty ID
	$sku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq "O365_BUSINESS_ESSENTIALS"
	Set-MgUserLicense -UserId $acctID -AddLicenses @{SkuId = $sku.SkuId} -RemoveLicenses @() | Out-Null
	Write-Host "The account $accountName has the following licenses applied to it:"
	Get-MgUserLicenseDetail -UserId $acctID | Select-Object -ExpandProperty SkuPartNumber
	sleep 5
	Read-Host "Press Enter to continue"
	Disconnect-MgGraph | Out-Null
	Select-MenuOption
}

#Function: Create-UserFolder
#Description: Get license information for an account
#Parameters: AccountName(string)
function Create-UserFolder {
	param ([string]$accountName)
	
	<#old function:
	$serverName = #Server Redacted#
	$SAM = Get-ADUser -Filter 'Name -like $AccountName' | Select-object -ExpandProperty SAMAccountName
	$path = "D:\Users\"
	$directory = "D:\Users\$SAM"
	
	#Create a PSSessiosn to FS1
	$session = New-PSSession -ComputerName $serverName -Authentication Negotiate -credential $cred
	#Create user folder
	Invoke-Command -Session $session -ScriptBlock {New-Item -Path $path -Name $using:SAM -ItemType "directory"}
	Write-Host "Created folder $directory on $serverName"
	#Get folder's ACL
	Invoke-Command -Session $session -ScriptBlock {$acl = get-ACL -Path $directory}
	#Rule: Remove Domain Users
	$RuleOne = New-Object System.Security.AccessControl.FileSystemAccessRule("Domain Users","Read","Allow")
	Invoke-Command -Session $session -ScriptBlock {$ACL.RemoveAccessRule($using:RuleOne)}
	#Rule: Add user RWX or Full Control
	$RuleTwo = New-Object System.Security.AccessControl.FileSystemAccessRule("$using:SAM","Full Control","Allow") #Check if SAM or AccountName is needed here
	Invoke-Command -Session $session -ScriptBlock {$ACL.RemoveAccessRule($using:RuleTwo)}
	#Rule: Disable inheritance
	$ACL.SetAccessRuleProtection($true,$false)
	/#>

	#creates a temporary shared drive to the computer
	$SAM = Get-ADUser -Filter 'Name -like $AccountName' | Select-object -ExpandProperty SAMAccountName
	$drivename = "TEMPSHARE"
	$serverName = #Server Redacted#
	New-PSDrive -Name $drivename -PSProvider FileSystem -Root "\\$serverName\Scans" | Out-Null
	$destinationpath = $drivename + ":\"
	
	#Create user folder
	New-Item -Path $destinationpath -Name $SAM -ItemType "directory"
	$userFolder = $destinationpath + "\" + $SAM
	Write-Host "Created folder $userFolder"
	
	#Get folder's ACL
	$ACL = get-ACL -Path $userFolder
	#Rule: Remove Domain Users
	$RuleOne = New-Object System.Security.AccessControl.FileSystemAccessRule("Domain Users","Read","Allow")
	$ACL.RemoveAccessRule($using:RuleOne)
	#Rule: Add user RWX or Full Control
	$RuleTwo = New-Object System.Security.AccessControl.FileSystemAccessRule("$SAM","Full Control","Allow") #Check if SAM or AccountName is needed here
	$ACL.RemoveAccessRule($using:RuleTwo)
	#Rule: Disable inheritance
	$ACL.SetAccessRuleProtection($true,$false)
	#Sets the above permissions
	$ACL | Set-ACL -Path $userFolder
	(Get-ACL -Path $userFolder).Access | Format-Table IdentityReference,FileSystemRights,AccessControlType,IsInherited,InheritanceFlags -AutoSize
	
	#kill the temporary shared drive
	Remove-PSDrive $drivename
	
	Read-Host "Press Enter to continue"
	Select-MenuOption
}

#Call the starter function
Select-MenuOption