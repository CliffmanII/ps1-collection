@echo on

start C:\Windows\System32
ipconfig.exe /release

TIMEOUT /t 5

start C:\Windows\System32
ipconfig.exe /renew

TIMEOUT/T 5

start C:\Windows\System32
ipconfig.exe /flushdns

End