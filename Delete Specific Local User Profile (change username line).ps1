$userprofile = Get-CimInstance Win32_UserProfile -filter "localpath='C:\\Users\\(INSERT FOLDER HERE)'"
$userprofile | Remove-CimInstance -whatif