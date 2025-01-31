$computers = get-adcomputer -filter 'OperatingSystem -notlike "*server*"' -properties Name | select-object Name
$cred = get-credential
$newXML = Read-Host "Enter the file path to the XML profile file"
$newWLANprofilename = "Enter the name of the new WiFi SSID"
$oldWLANprofilename = "Enter the name of the old WiFi SSID"
foreach ($computer in $computers) {
	$device = $computer.name
	invoke-command $device -ScriptBlock {
		netsh wlan add profile filename=$newXML user=all
		netsh wlan set profileorder name=$newWLANprofilename interface="Wi-Fi" priority=2
		netsh wlan set profileorder name=$oldWLANprofilename interface="Wi-Fi" priority=4
	} -Credential $cred
}