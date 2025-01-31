$InputDrive = Read-Host "Enter assigned letter of drive to unlock (ex: C)"
$InputString = Read-Host -AsSecureString "Enter key to unlock drive $InputDrive"
Unlock-BitLocker -MountPoint "E:" -Password $InputString