# Old Location ID on left, New Location ID on right
$locTABLE = @{
    1  = '1'
    2  = '2'
    25 = '3'
    ...
}

# Bring in the LT Powershell Module
(New-Object Net.WebClient).DownloadString('http://bit.ly/ltposh') | Invoke-Expression

# Declare variables
$oldSVR = (Get-LTServiceInfo).Server
$oldLOC = (Get-LTServiceInfo).LocationID
$newLOC = $locTABLE[[int]$oldLOC]

If ($oldSVR -like "*old.servername.com") {
    Install-LTService -Server https://new.servername.com -LocationID $newLOC -Force -Confirm:$false
}
