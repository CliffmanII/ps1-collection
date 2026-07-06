#Transform MAC into appropriate Byte Array
$Mac = "XX:XX:XX:XX:XX:XX"
$MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
[Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray * 16)
#Enable Broadcast
$UdpClient.EnableBroadcast = $true
#Broadcast WOL packet on port 7
$UdpClient = New-Object System.Net.Sockets.UdpClient
$UdpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
$UdpClient.Send($MagicPacket,$MagicPacket.Length)
#Wait then close connection
Start-Sleep 10
$UdpClient.Close()
#Broadcast WOL packet on port 9
$UdpClient = New-Object System.Net.Sockets.UdpClient
$UdpClient.Connect(([System.Net.IPAddress]::Broadcast),9)
$UdpClient.Send($MagicPacket,$MagicPacket.Length)
$UdpClient.Close()
