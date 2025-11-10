
# Windows PowerShell 5.1 + ThreadJobs
Import-Module ThreadJob

$ips = 1..254 | ForEach-Object { "10.69.10.$_" }
$ThrottleLimit = 127
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
            try { $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName } catch {}
        }
    } [PSCustomObject]@{
        IP       = $ip
        Alive    = $alive
        Hostname = $hostname
    }
}

foreach ($ip in $ips) {
    # Throttle: keep at/below the limit
    while ( ($jobs | Where-Object State -eq 'Running').Count -ge $ThrottleLimit ) {
        Start-Sleep -Milliseconds 50
    } $jobs += Start-ThreadJob -ArgumentList $ip -ScriptBlock $scriptBlock
}

# Finish and collect results
Wait-Job -Job $jobs | Out-Null
$results = Receive-Job -Job $jobs
$jobs | Remove-Job -Force | Out-Null

# Example: show alive hosts
$results | Where-Object Alive | Sort-Object { IP } | ForEach-Object {
	if ($_.Hostname) {
		"$($_.IP) - ALIVE - $($_.Hostname)"
	} else {
		"$($_.IP) - ALIVE - Could not resolve hostname"
	}
}
