$Mac = Read-Host -Prompt "Input the target MAC address. Format XXXXXXXXXXXX"
$MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
[Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray * 16)
$UdpClient = New-Object System.Net.Sockets.UdpClient
$UdpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
$UdpClient.Send($using:MagicPacket,$using:MagicPacket.Length)
$UdpClient.Close()