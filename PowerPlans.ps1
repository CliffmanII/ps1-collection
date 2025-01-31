#configure reg keys that prevent power plan changes to allow changes.
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "CsEnabled" -Value 0
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "CsEnabled"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride" -Value 0
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PlatformAoAcOverride"
#disable hibernate
powercfg /h off
#add power plans
#[High Performance]
powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
#[Power Saver]
powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a
#[Ultimate Performance]
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
#list available power plans. Should include balanced, power saver, high performance, and ulitmate performance
powercfg /l
