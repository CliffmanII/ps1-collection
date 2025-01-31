# Enable Storage Sense
# Ensure the StorageSense key exists
$key = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense"
If (!(Test-Path "$key")) {New-Item -Path "$key" | Out-Null}
If (!(Test-Path "$key\Parameters")) {New-Item -Path "$key\Parameters" | Out-Null}
If (!(Test-Path "$key\Parameters\StoragePolicy")) {New-Item -Path "$key\Parameters\StoragePolicy" | Out-Null}

# Set Storage Sense settings
## Enable Storage Sense
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "01" -Type DWord -Value 1

# Set 'Run Storage Sense' to Every Week
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "2048" -Type DWord -Value 7

# Enable 'Delete temporary files that my apps aren't using'
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "04" -Type DWord -Value 1

# Set 'Delete files in my recycle bin if they have been there for over' to 14 days
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "08" -Type DWord -Value 1
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "256" -Type DWord -Value 14

# Set 'Delete files in my Downloads folder if they have been there for over' to 30 days
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "32" -Type DWord -Value 1
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "512" -Type DWord -Value 30

# Set value that Storage Sense has already notified the user
Set-ItemProperty -Path "$key\Parameters\StoragePolicy" -Name "StoragePoliciesNotified" -Type DWord -Value 1

# Runs storage sense via the built-in scheduled task
Start-ScheduledTask -TaskName "Microsoft\Windows\DiskCleanup\SilentCleanup"
Start-ScheduledTask -TaskName "\Microsoft\Windows\DiskFootprint\StorageSense"