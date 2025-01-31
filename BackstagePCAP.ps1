<#
Script: BackstagePCAP.ps1
Purpose: Starts a PCAP with tshark - a whileshark commandline tool

Instructions: 
1- transfer the wireshark portable installer to C:\_rootdir on the target device
2- in backstage (or UI with admin rights) run the installer
	- insure it is isntalled to C:\_rootdir\WiresharkPortable64
3 - in backstage (or UI with admin rights) run the script
	- either copy/paste the contents of this script in a powershell window
	- or transfer this file to the target device and run it in powershell with the Start-Process cmdlet
4- packet capture will run until this script gives you a way to stop it
	- alternatively, stopping the "tshark" process will also stop the packet capture
	- JUST CLOSING OUT OF THE POWERSHELL WINDOW WILL NOT STOP THE capture
	- running (Stop-Process -Name "tshark") will also stop the capture/Process
5- packet capture is output to a file like "COMPUTERNAME_DATE_TIME_packetdump.pcapng" in C:\_rootdir
	- this is readable with wireshark or other pcapng reading software

Written by Dennis Cliffman II 04/12/2024
Contact: DennisACliffman@gmail.com (personal), DCliffman@sja-solutions.com (professional)
/#>

#list windows adapters (human readable) and wiresharked listed adapters (not very readable, but includes numbers for input)
Clear-host
Write-host "Listing windows adapter information:" -Foregroundcolor Green
get-netadapter
write-host "`n`nListing wireshark available adapters:" -Foregroundcolor Green
$args1 = "-D"
Start-Process "C:\_rootdir\WiresharkPortable64\App\Wireshark\tshark" -ArgumentList $args1 -NoNewWindow
sleep 2

#user inputs number of adapter to capture
$interfaceNo  = Read-host "`nInput interface number"

#starts capture to a new file
Clear-Host
$date = get-date -Format "MMddyy_HHmm"
$filename = "C:\_rootdir\" + $env:computername + "_" + $date + "_packetdump.pcapng"
$args2 = "--interface " + $interfaceNo + " -w " + $filename
Start-Process "C:\_rootdir\WiresharkPortable64\App\Wireshark\tshark" -ArgumentList $args2 -NoNewWindow
#gives a way to stop the capture
Read-Host "`nCapture is running. Output data is located at $filename`nPress Enter to stop capture at any time"
Stop-Process -Name "tshark"