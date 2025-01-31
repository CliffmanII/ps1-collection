Start-ADSyncSyncCycle -PolicyType Delta
#Start-ADSyncSyncCycle -PolicyType Initial 


<# to run on a remote server, run these commands in order or together:
$comp = Read-Host "Enter AD Connect Sync Server FQDN"
$cred = Get-Credential
Invoke-Command -Computer $comp -Credential $cred -scriptblock {Start-ADSyncSyncCycle -PolicyType Delta}
#>