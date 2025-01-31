##Company Redacted# Project Active Folder permissions script

$ProjectActive = "\\#Share Redacted#\Active Folders\Project Active\"
$Projects = @()
$Projects += Get-ChildItem -Path $ProjectActive -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName
$drivename = "TEMPSHARE"
Remove-PSDrive $drivename -ErrorAction SilentlyContinue 

Foreach($Proj in $Projects) {
    Remove-PSDrive $drivename -ErrorAction SilentlyContinue 
    $projpath = $proj.fullname
    New-PSDrive -Name $drivename -PSProvider FileSystem -Root $projpath
    $destinationpath = $drivename + ":\"
	$subs = @()
	$subs += Get-ChildItem -Path $projpath -Directory -Force -ErrorAction SilentlyContinue | Select-Object Name
		Foreach($sub in $subs) {
            $shortpath = $sub.name
            Write-host "Modifying permissoins for $projpath\$shortpath"
            $subpath = $destinationpath + $shortpath
			$ACL = get-ACL -Path $subpath
			$Rule = New-Object System.Security.AccessControl.FileSystemAccessRule("#Group Redacted#","FullControl","ContainerInherit,ObjectInherit", "None", "Allow")
			$ACL.SetAccessRule($Rule) 
			$ACL | Set-ACL -Path $subpath
		}
    Remove-PSDrive $drivename
}