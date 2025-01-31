Set-ItemProperty -Path "Registry::HKEY_USERS\.Default\SOFTWARE\Policies\Citrix\ICA Client\Generic USB" -Name "EnableUSBForceRedirection" -Value 1
set-ItemProperty -Path "Registry::HKEY_USERS\.Default\SOFTWARE\Policies\Citrix\ICA Client\Generic USB" -Name "RedirectUnkownDevices" -Value 1
set-ItemProperty -Path "Registry::HKEY_USERS\.Default\SOFTWARE\Policies\Citrix\ICA Client\USB" -Name "NewDevices" -Value "Always"
set-ItemProperty -Path "Registry::HKEY_USERS\.Default\SOFTWARE\Policies\Citrix\ICA Client\USB" -Name "ExistingDevices" -Value "Always"
Get-ItemProperty -Path "Registry::HKEY_USERS\.Default\SOFTWARE\Policies\Citrix\ICA Client\Generic USB" -Name "EnableUSBForceRedirection"
Get-ItemProperty -Path "Registry::HKEY_USERS\.Default\SOFTWARE\Policies\Citrix\ICA Client\Generic USB" -Name "RedirectUnkownDevices"
Get-ItemProperty -Path "Registry::HKEY_USERS\.Default\SOFTWARE\Policies\Citrix\ICA Client\USB" -Name "NewDevices"
Get-ItemProperty -Path "Registry::HKEY_USERS\.Default\SOFTWARE\Policies\Citrix\ICA Client\USB" -Name "ExistingDevices"