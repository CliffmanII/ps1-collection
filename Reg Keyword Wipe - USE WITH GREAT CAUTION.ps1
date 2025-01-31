$keyword = Read-Host "Enter keyword to remove from registry"
Get-ChildItem -path HKLM:\ -Recurse | where { $_.Name -match $keyword} | Remove-Item -Force -Verbose
Get-ChildItem -path HKCU:\ -Recurse | where { $_.Name -match $keyword} | Remove-Item -Force -Verbose
Get-ChildItem -path HKCC:\ -Recurse | where { $_.Name -match $keyword} | Remove-Item -Force -Verbose