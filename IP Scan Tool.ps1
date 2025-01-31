$IPbase = "10.1.150."
$startIP = 0
$endIP = 255
Write-Host "Scanning the $ipbase$startip/24 network"
Write-Host "Alive hosts listed below:"
while ($startIP -le $endIP) {
	$testIP = $IPbase+$startIP
	Write-Host -NoNewLine "`rTesting $TestIP..." -ForegroundColor DarkGray
	$output = $null
	If (Test-Connection $testIP -Count 1 -ErrorAction SilentlyContinue) { 
		$output = "`r" + $testIP + " - ALIVE"
		$hostname = Resolve-DNSName $testIP -ErrorAction SilentlyContinue | Select-Object NameHost
		if ($hostname) {$output += " - " + $hostname} else {$output += " - Could not resolve hostname"}
		Write-Host -NoNewLine "$output`n"
	} $startIP++
}