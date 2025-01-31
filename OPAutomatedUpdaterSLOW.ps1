#Install-Module ActiveDirectory
$complist = @()
$complist = Get-ADComputer -Filter {Name -like "*" -and Enabled -eq $True}
$complist = $complist | sort-object -Property Name
$cred = Get-Credential

Foreach($CL in $CompList) {
	$name = $CL.name + ".fhp.local"
	Write-Host "Connecting to $name" -Foregroundcolor Blue
	if (Test-Connection $name -Quiet -Count 1) { 
        if ($Session = New-PSSession -ComputerName $Name -Credential $Cred -Authentication Negotiate) {
		    Write-Host "Copying update to \\$name\C$\OP" -Foregroundcolor Blue
		    Copy-Item -Path "C:\_rootdir\OPUpdateFiles\*" -Destination "C:\OP" -Recurse -ToSession $Session -Force
   		    Write-Host "Finished copying files to \\$name\C$\OP" -Foregroundcolor Green
        } else {
            Write-Host "Could not connect to $name" -ForegroundColor Magenta
        }
	} else {
		Write-Host "Could not connect to $name" -ForegroundColor Red
	}
}