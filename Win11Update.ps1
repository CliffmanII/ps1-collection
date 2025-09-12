#Check OS for Windows 11, exit if already on Windows 11
$CurrentOS = Get-ComputerInfo | select-object OsName | Out-String -Stream | Select-String -Pattern "Microsoft Windows" | Out-String
if ($CurrentOS.contains("11")) {
	exit 
}
  
# Define the file paths and URLs
$logFile = "C:\Temp\Windows11UpgradeLog.txt"
$windows11LocalDownloadUrl = "\\kazoo-fs01\shared\readonly\Windows11\Windows11InstallationAssistant.exe"  # URL to download Windows 11 Installation Assistant
$windows11OnlineDownloadUrl = "https://go.microsoft.com/fwlink/?linkid=2171764"  # URL to download Windows 11 Installation Assistant

# Log function to write to log file
Function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    
    # Write message to log file and output to console
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

# Function to download Windows 11 Installation Assistant
Function Download-Windows11Installer {
    Write-Log "Downloading Windows 11 Installation Assistant..."

    $installerPath = "C:\TEMP\Windows11Setup.exe"
    try {
        Copy-Item -Path $windows11LocalDownloadUrl -Destination $installerPath
        Write-Log "Windows 11 Installation Assistant downloaded successfully from shared drive at $installerPath."
        return $installerPath
    } catch {
        Write-Log "Failed to download Windows 11 Installation Assistant from shared drive. Error: $_"
		try {
			$webClient = New-Object System.Net.WebClient
			$webClient.DownloadFile($windows11OnlineDownloadUrl,$installerPath)
			Write-Log "Windows 11 Installation Assistant downloaded successfully from online source at $installerPath."
			return $installerPath
		} catch {
			Write-Log "Failed to download Windows 11 Installation Assistant from online source. Error: $_"
			return $null
		}
    }
}

# Function to run the Windows 11 upgrade silently
Function Upgrade-Windows11 {
    param ([string]$installerPath)

    Write-Log "Initiating Windows 11 upgrade..."

    if ($installerPath -ne $null) {
        Write-Log "Starting the upgrade process..."
        Start-Process -FilePath $installerPath -ArgumentList "/auto upgrade /quietinstall /noreboot" -Wait
        Write-Log "Windows 11 upgrade process started."
    } else {
        Write-Log "Installer path is invalid, upgrade aborted."
    }
}

# Function to monitor upgrade status
Function Monitor-UpgradeStatus {
    Write-Log "Monitoring upgrade status..."
	Start-Sleep -Seconds 30
    # Checking for the setup process
    $process = Get-Process -Name "setup" -ErrorAction SilentlyContinue
    if ($process) {
        Write-Log "Upgrade process is running..."
        while ($process.HasExited -eq $false) {
            Write-Log "Upgrade still in progress..."
            Start-Sleep -Seconds 30
            $process = Get-Process -Name "setup" -ErrorAction SilentlyContinue
        }
        Write-Log "Upgrade process completed successfully."
    } else {
        Write-Log "No upgrade process found. Ensure the upgrade was initiated."
    }
}

# Main logic
Write-Log "Windows 11 upgrade script started."
#Download Windows 11 installer
$installerPath = Download-Windows11Installer
if ($installerPath -ne $null) {
	#Start the upgrade process silently
	Upgrade-Windows11 -installerPath $installerPath

	#Monitor the upgrade process
	Monitor-UpgradeStatus
} else {
	Write-Log "Failed to download Windows 11 installer. Upgrade aborted."
}

Write-Log "Windows 11 upgrade script finished."