$complist = @()
$complist = Get-ADComputer -Filter {Name -like "*" -and Enabled -eq $True}
$complist = $complist | sort-object -Property Name
$adobjects = @()

Foreach($CL in $CompList) {
	$Bitlocker_Object = Get-ADObject -Filter {objectclass -eq 'msFVE-RecoveryInformation'} -SearchBase $CL.DistinguishedName -Properties 'msFVE-RecoveryPassword'
	
	$Properties = @{'HostName'=$CL.DNSHostName; 'Enabled'=$CL.Enabled; 'BitLockerInfo'=$Bitlocker_Object}
	$ADObjects += New-Object -TypeName PSObject -Property $Properties
	
	if ($Bitlocker_Object.'msFVE-RecoveryPassword'.Count -gt 0) {
		Write-Host "Computer: "$CL.DNSHostName " -> AD Key Count:" $Bitlocker_Object.'msFVE-RecoveryPassword'.Count -Foregroundcolor Green
	} else {
		Write-Host "Computer: "$CL.DNSHostName " -> AD Key Count:" $Bitlocker_Object.'msFVE-RecoveryPassword'.Count -Foregroundcolor Red
	}
}