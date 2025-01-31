Get-CimInstance -Class Win32_UserProfile -Filter Special=FALSE |
    ForEach-Object -Begin {$ErrorActionPreference = 'Stop'} {
        try
        {
            $sid = $_.SID
            $id = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $sid
            $id.Translate([System.Security.Principal.NTAccount]).Value
        }
        catch
        {
            Write-Host "Failed to translate $sid! $_" -ForegroundColor Red
        }
    } |
    Select-Object -Property @{Label='PSChildName'; Expression={$_}}
