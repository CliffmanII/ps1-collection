$CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent()) 
if (($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) -eq $false) 
{ 
    $ArgumentList = "-noprofile -noexit -file `"{0}`" -Path `"$Path`" -MaxStage $MaxStage" 
    If ($ValidateOnly) { $ArgumentList = $ArgumentList + " -ValidateOnly" } 
    If ($SkipValidation) { $ArgumentList = $ArgumentList + " -SkipValidation $SkipValidation" } 
    If ($Mode) { $ArgumentList = $ArgumentList + " -Mode $Mode" } 
    Write-Host "elevating" 
    Start-Process powershell.exe -Verb RunAs -ArgumentList ($ArgumentList -f ($myinvocation.MyCommand.Definition)) -Wait 
    Exit 
}  
Function Import-PSWindowsUpdateModule {
	Try {Import-Module -Name PSWindowsUpdate}
	Catch {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
		Install-Module -Name PSWindowsUpdate -Force
		Import-PSWindowsUpdateModule
	}
}
Import-PSWindowsUpdateModule
$Updates = Get-WindowsUpdate
$UpdateKBs = $Updates | Select KB
Foreach ($KB in $UpdateKBs) {
	Get-WindowsUpdate -KBArticleID $KB -AcceptAll -Install -No-reboot
}
Read-Host "Updates have been installed. Press Enter to close this window."
Quit