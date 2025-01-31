<#
This script is used to hardmatch an on-prem AD account with a M365 cloud account. 

Instructions are as follows:

1. Move AD account to non-syncing OU (create a new OU if needed, configuring AD connect to not sync it before proceeding)
2. Run Start-ADSyncSyncCycle -PolicyType Delta on the AD Connect server (requires elevation)
3. Wait for duplicate account to be deleted from AAD/Entra ID
4. Delete permanently from Entra ID Deleted Users; wait for users to disappear from 365 admin center deleted users container
5. Soft Match accounts with SMTP, SAM, and UPN by editing AD/365 attributes
6. Run Hardmatch.ps1 Script (sign in with 365 admin creds when prompted)
7. Move AD account back to a synced OU
8. Run Start-ADSyncSyncCycle -PolicyType Initial on the AD Connect server (requires elevation)
#>

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))   
{  
  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}
Install-Module MsOnline
Import-Module MsOnline
Connect-MsolService
 
do{
# Query the local AD and get all the users output to grid for selection
$ADGuidUser = Get-ADUser -Filter * | Select Name,ObjectGUID | Sort-Object Name | Out-GridView -Title "Select Local AD User To Get Immutable ID for" -PassThru
#Convert the GUID to the Immutable ID format
$UserimmutableID = [System.Convert]::ToBase64String($ADGuidUser.ObjectGUID.tobytearray())
# Query the existing users on Office 365 and output to grid for selection
$OnlineUser = Get-MsolUser -All | Select UserPrincipalName,DisplayName,ProxyAddresses,ImmutableID | Sort-Object DisplayName | Out-GridView -Title "Select The Office 365 Online User To HardLink The AD User To" -PassThru
# Money command that sets the office 365 user you picked with the OnPrem AD ImmutableID
Set-MSOLuser -UserPrincipalName $OnlineUser.UserPrincipalName -ImmutableID $UserimmutableID
#Verify ImmutableID has been updated
$Office365UserQuery = Get-MsolUser -UserPrincipalName $OnlineUser.UserPrincipalName | Select DisplayName,ImmutableId
Write-Host "Do the ID's Match? if not something is wrong"
Write-Host "AD Immutable ID Used" $UserimmutableID
Write-Host "Office365 UserLinked" $Office365UserQuery.ImmutableId
# Ask To Repeat The Script
$Repeat = read-host "Do you want to choose another user? Y or N"
}
while ($Repeat -eq "Y")
#List Users and ImmutableId
Get-MsolUser | Select DisplayName,ImmutableID | Sort-Object DisplayName | Out-GridView -Title "Office 365 User List With Immutableid Showing"
#Close your PS Office 365 Connection
Get-PSSession | Remove-PSSession
