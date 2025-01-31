if((get-bitlockervolume|select-object -Property ProtectionStatus)-match"Off"){
	Enable-BitLocker -MountPoint "C:" -EncryptionMethod Aes256 -UsedSpaceOnly -RecoveryPasswordProtector -SkipHardwareTest
	$BLV = Get-BitLockerVolume -MountPoint "C:"
	Backup-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId
}