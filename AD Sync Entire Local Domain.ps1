Import-Module ActiveDirectory
$DCs = (Get-ADForest).Domains | %{ Get-ADDomainController -Filter * -Server $_ } | select HostName
foreach ($DC in $DCs) {repadmin /syncall $DC.HostName}