# Windows PowerShell 5.1 + ThreadJobs
try {
    Import-Module ThreadJob -ErrorAction Stop
} catch {
    try {
        Install-Module ThreadJob -Force -ErrorAction Stop
        Import-Module ThreadJob -ErrorAction Stop
    } catch {
        Write-Host "Failed to install or import ThreadJob module." -ForegroundColor Red
        exit
    }
}

# Helper function to Write-Host with color
function Write-ColorOutput($ForegroundColor) {
    #save the current color
    $fc = $host.UI.RawUI.ForegroundColor
    #set the new color
    $host.UI.RawUI.ForegroundColor = $ForegroundColor

    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    #restore the original color
    $host.UI.RawUI.ForegroundColor = $fc
}

# Get local IP addresses, excluding loopback, APIPA, and virtual ethernet interfaces
$subnet = $NULL
$ips = $NULL
$LocalIP = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "169.*" } | Where-Object { $_.IPAddress -notlike "127.*" } | Where-Object { $_.InterfaceAlias -notlike "vEthernet*" } | Select-Object -property "IPAddress"
foreach ($ip in $LocalIP) {
    try {
        $address = [System.Net.IPAddress]$ip.IpAddress
        $mask = [System.Net.IPAddress]"255.255.255.0"
        $subnetAddress = $address.Address -band $mask.Address
        $subnet = [System.Net.IPAddress]$subnetAddress
        $subnet = $subnet.IPAddressToString
        $subnet = $subnet.substring(0, $subnet.length -1)
        $ips += 1..254 | ForEach-Object { "$subnet$_" }
    } catch {
        Write-Host "Failed to calculate subnet for $($ip.IpAddress)." -ForegroundColor Red
    }
}
$ThrottleLimit = 255
$jobs = @()

# Script block executed by each thread
$scriptBlock = {
    param($ip)

    $alive = $false
    try { $alive = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue } catch {}

    $hostname = $null
    if ($alive) {
        try {
            $hostname = (Resolve-DnsName -Name $ip -ErrorAction Stop | Select-Object -ExpandProperty NameHost -First 1)
        } catch {
            try {
                $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
            } catch {
                $hostname = $null
            }
        }
    } [PSCustomObject]@{
        IP       = $ip
        Alive    = $alive
        Hostname = $hostname
    }
}

# Start thread-jobs for to scan each $ip in $ips
foreach ($ip in $ips) {
    # Throttle: keep at/below the limit
    while ( ($jobs | Where-Object State -eq 'Running').Count -ge $ThrottleLimit ) {
        Start-Sleep -Milliseconds 50
    } try {
        $jobs += Start-ThreadJob -ArgumentList $ip -ScriptBlock $scriptBlock -ThrottleLimit $ThrottleLimit
    } catch {
        Write-Host "Failed to start job for $ip." -ForegroundColor Red
    }
}

# Thread-job progress reporting
Do {
	$runningJobs = (Get-Job -State Running).count
	$waitingJobs = (Get-Job -State NotStarted).count
	$completedJobs = (Get-Job -State Completed).count
	$failedJobs = (Get-Job -State Failed).count	
	
    Write-Host "--------------------------------------"
	Write-ColorOutput Yellow "$runningJobs IPs are being scanned."
	Write-ColorOutput Cyan "$waitingJobs IPs are queued to be scanned."
	Write-ColorOutput Green "$completedJobs IPs have been scanned."
	Write-ColorOutput Red "$failedJobs IPs failed to scan.`n"
    Write-Host "--------------------------------------"
	
	#if jobs are still running or queued to run, waits, then reports again
	if (($runningJobs -gt 0) -or ($waitingJobs -gt 0)) {
		Write-ColorOutput Magenta "Scanning jobs are in-progress. Please wait..."
		Sleep 5
	}
} While (($runningJobs -gt 0) -or ($waitingJobs -gt 0))

# Finish and collect results
Wait-Job -Job $jobs | Out-Null
try {
    $results = Receive-Job -Job $jobs
} catch {
    Write-Host "Failed to retrieve job results." -ForegroundColor Red
}
$jobs | Remove-Job -Force | Out-Null

# Report alive hosts, including DNS names if found
try {
    if ($results.count -ge 1) {
        $results | Where-Object Alive | Sort-Object -property IP | ForEach-Object {
	        if ($_.Hostname) { "$($_.IP) - ALIVE - $($_.Hostname)" } else { "$($_.IP) - ALIVE"}
        }
    } else {
        Write-Host "No alive hosts Found."
    }
} catch {
    Write-Host "Error processing results." -ForegroundColor Red
}
