#Created by DC on 04/30/24 for Service Ticket #1092187
$acl = Get-Acl HKCU:\SOFTWARE\Accubid
$rule = New-Object System.Security.AccessControl.RegistryAccessRule ("Everyone","FullControl",@("ObjectInherit","ContainerInherit"),"None","Allow")  
$acl.SetAccessRule($rule)  
$acl | Set-Acl -Path HKCU:\SOFTWARE\Accubid