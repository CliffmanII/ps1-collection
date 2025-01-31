[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon

$objNotifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$objNotifyIcon.BalloonTipIcon = "Info" 
$objNotifyIcon.BalloonTipText = "The quick brown fox jumped over the lazy dog." 
$objNotifyIcon.BalloonTipTitle = "Test Notification Title"
$objNotifyIcon.Visible = $True

$objNotifyIcon.ShowBalloonTip(10000)