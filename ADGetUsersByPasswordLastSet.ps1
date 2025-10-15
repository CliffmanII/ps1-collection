Get-ADUser -Filter * -Properties SamAccountName, DisplayName, UserPrincipalName, Enabled, PasswordLastSet, userAccountControl -ResultSetSize $null | sort PasswordLastSet |
   Select-Object `
       Name,
       SamAccountName,
       UserPrincipalName,
       Enabled,
       @{Name='PasswordLastChanged'; Expression = { $_.PasswordLastSet }},
       @{Name='PasswordNeverExpires'; Expression = { (($_.useraccountcontrol -band 0x10000) -ne 0) }} | out-file -filepath C:\temp\pwdreport.txt