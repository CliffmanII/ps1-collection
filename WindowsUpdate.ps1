#Install PSWindowsUpdate module
try {
	install-module PSWindowsUpdate
} catch {
	Write-Error "Unable to install PSWindowsUpdate module."
}

#import the module
try  {
	import-module PSWindowsUpdate
} catch {
	Write-Error "Failed in import PSWindowsUpdate module."
}

#install non-driver, OneDrive updates. Auto Accept, doesn't auto reboot
Install-WindowsUpdate -NotCategory "Drivers" -NotTitle "OneDrive" -AcceptAll -IgnoreReboot
