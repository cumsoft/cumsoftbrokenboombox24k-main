$Log = "C:\Users\Public\Log.txt"
[bool]$restart = $false
filter timestamp {"$(Get-Date -Format G) | $_"}

Function Get-OfficeVersion {
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param (
        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [switch]$ShowAllInstalledProducts,
        [System.Management.Automation.PSCredential]$credentials
    )

    BEGIN {
        $HKLM = [UInt32] "0x80000002"
        $HKCR = [UInt32] "0x80000000"

        $excelKeyPath = "Excel\DefaultIcon"
        $wordKeyPath = "Word\DefaultIcon"

        $installKeys = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        $officeKeys = 'SOFTWARE\Microsoft\Office','SOFTWARE\Wow6432Node\Microsoft\Office'
        $defaultDisplaySet = 'DisplayName','Version','ComputerName'
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultDisplaySet)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

    }

    PROCESS {
        
        $results = New-Object PSObject[] 0;
        $MSexceptionList = "mui","visio","project","proofing","visual"

        ForEach ($computer in $ComputerName) {
            If ($credentials) {
                $os = Get-WmiObject Win32_OperatingSystem -ComputerName $computer -Credential $credentials
            }
            Else {
                $os = Get-WmiObject Win32_OperatingSystem -ComputerName $computer
            }

            $osArchitecture = $os.OSArchitecture

            If ($credentials) {
                $regProv = Get-WmiObject -list "StdRegProv" -NameSpace 'root\Default' -ComputerName $computer -Credential $credentials
            }
            Else {
                $regProv = Get-WmiObject -list "StdRegProv" -NameSpace 'root\Default' -ComputerName $computer
            }

            [System.Collections.ArrayList]$VersionList = New-Object -TypeName System.Collections.ArrayList
            [System.Collections.ArrayList]$PathList = New-Object -TypeName System.Collections.ArrayList
            [System.Collections.ArrayList]$PackageList = New-Object -TypeName System.Collections.ArrayList
            [System.Collections.ArrayList]$ClickToRunPathList = New-Object -TypeName System.Collections.ArrayList
            [System.Collections.ArrayList]$ConfigItemList = New-Object -TypeName System.Collections.ArrayList
            $ClickToRunList = New-Object PSObject[] 0;

            ForEach ($regKey in $officeKeys) {
                $officeVersion = $regProv.EnumKey($HKLM, $regKey)
                ForEach ($key in $officeVersion.sNames) {
                    If ($key -match "\d{2}\.\d") {
                        If (!$VersionList.Contains($key)) {
                            $AddItem = $VersionList.Add($key)
                        }

                        $path = Join-Path $regKey $key

                        $configPath = Join-Path $path "Common\Config"
                        $configItems = $regProv.EnumKey($HKLM, $configPath)
                        If ($configItems) {
                            ForEach ($configID in $configItems.sNames) {
                                If ($configID) {
                                    $Add = $ConfigItemList.Add($configID.ToUpper())
                                }
                            }
                        }

                        $cltr = New-Object -TypeName PSObject
                        $cltr | Add-Member -MemberType NoteProperty -Name InstallPath -Value ""
                        $cltr | Add-Member -MemberType NoteProperty -Name UpdatesEnabled -Value $false
                        $cltr | Add-Member -MemberType NoteProperty -Name UpdateUrl -Value ""
                        $cltr | Add-Member -MemberType NoteProperty -Name StreamingFinished -Value $false
                        $cltr | Add-Member -MemberType NoteProperty -Name Platform -Value ""
                        $cltr | Add-Member -MemberType NoteProperty -Name ClientCulture -Value ""

                        $packagePath = Join-Path $path "Common\Installed Packages"
                        $clickToRunPath = Join-Path $path "ClickToRun\Configuration"
                        $virtualInstallPath = $regProv.GetStringValue($HKLM, $clickToRunPath, "InstallationPath").sValue

                        [string]$officeLangResourcePath = Join-Path $path "Common\LanguageResources"
                        $mainLangId = $regProv.GetDWORDValue($HKLM, $officeLangResourcePath, "SKULanguage").uValue
                        If ($mainLangId) {
                            $mainLangCulture = [globalization.cultureinfo]::GetCultures("allCultures") | Where-Object {$_.LCID -eq $mainLangId}
                            If ($mainLangCulture) {
                                $cltr.ClientCulture = $mainLangCulture.Name
                            }
                        }

                        [string]$officeLangPath = Join-Path $path "Common\LanguageResources\InstalledUIs"
                        $langValues = $regProv.EnumValues($HKLM, $officeLangPath);
                        If ($langValues) {
                            ForEach ($langValue in $langValues) {
                                $langCulture = [globalization.cultureinfo]::GetCultures("allCultures") | Where-Object {$_.LCID -eq $langValue}
                            }
                        }
                        
                        If ($virtualInstallPath) {

                        }
                        Else {
                            $clickToRunPath = Join-Path $regKey "ClickToRun\Configuration"
                            $virtualInstallPath = $regProv.GetStringValue($HKLM, $clickToRunPath, "InstallationPath").sValue
                        }

                        If ($virtualInstallPath) {
                            If (!$ClickToRunPathList.Contains($virtualInstallPath.ToUpper())) {
                                $AddItem = $ClickToRunPathList.Add($virtualInstallPath.ToUpper())
                            }

                            $cltr.InstallPath = $virtualInstallPath
                            $cltr.StreamingFinished = $regProv.GetStringValue($HKLM, $clickToRunPath, "StreamingFinished").sValue
                            $cltr.UpdatesEnabled = $regProv.GetStringValue($HKLM, $clickToRunPath, "UpdatesEnabled").sValue
                            $cltr.UpdateUrl = $regProv.GetStringValue($HKLM, $clickToRunPath, "UpdateUrl").sValue
                            $cltr.Platform = $regProv.GetStringValue($HKLM, $clickToRunPath, "Platform").sValue
                            $cltr.ClientCulture = $regProv.GetStringValue($HKLM, $clickToRunPath, "ClientCulture").sValue
                            $ClickToRunList += $cltr
                        }

                        $packageItems = $regProv.EnumKey($HKLM, $packagePath)
                        $officeItems = $regProv.EnumKey($HKLM, $path)

                        ForEach ($itemKey in $officeItems.sNames) {
                            $itemPath = Join-Path $path $itemKey
                            $installRootPath = Join-Path $itemPath "InstallRoot"

                            $filePath = $regProv.GetStringValue($HKLM, $installRootPath, "Path").sValue
                            If (!$PathList.Contains($filePath)) {
                                $AddItem = $PathList.Add($filePath)
                            }
                        }

                        ForEach ($packageGuid in $packageItems.sNames) {
                            $packageItemPath = join-path $packagePath $packageGuid
                            $packageName = $regProv.GetStringValue($HKLM, $packageItemPath, "").sValue

                            If (!$PackageList.Contains($packageName)) {
                                If ($packageName) {
                                    $AddItem = $PackageList.Add($pacakgeName.Replace(' ','').ToLower())
                                }
                            }
                        }
                    }
                }
            }

            ForEach ($regKey in $installKeys) {
                $keyList = New-Object System.Collections.ArrayList
                $keys = $regProv.EnumKey($HKLM, $regKey)

                ForEach ($key in $keys.sNames) {
                    $path = Join-Path $regKey $key
                    $installPath = $regProv.GetStringValue($HKLM, $path, "InstallLocation").sValue
                    If (!($installPath)) {
                        continue
                    }
                    If ($installPath.Length -eq 0) {
                        continue
                    }
                    $buildType = "64-Bit"
                    If ($osArchitecture -eq "32-bit") {
                        $buildType = "32-bit"
                    }
                    If ($regKey.ToUpper().Contains("Wow6432Node".ToUpper())) {
                        $buildType = "32-Bit"
                    }
                    If ($key -match "{.{8}-.{4}-.{4}-1000-0000000FF1CE}") {
                        $buildType = "64-Bit"
                    }
                    If ($key -match "{.{8}-.{4}-.{4}-0000-0000000FF1CE}") {
                        $buildType = "32-Bit"
                    }
                    If ($modifyPath) {
                        If ($modifyPath.ToLower().Contains("platform=x86")) {
                            $buildType = "32-Bit"
                        }

                        If ($modifyPath.ToLower().Contains("platform=x64")) {
                            $buildType = "64-Bit"
                        }
                    }

                    $primaryOfficeProduct = $false
                    $officeProduct = $false
                    ForEach ($officeInstallPath in $PathList) {
                        If ($officeInstallPath) {
                            try {
                                $installReg = "^" + $installPath.Replace('\', '\\')
                                $installReg = $installReg.Replace('(', '\(')
                                $installReg = $installReg.Replace(')', '\)')
                                If ($officeInstallPath -match $installReg) {
                                    $officeProduct = $true
                                }
                            }
                            catch {
                                
                            }
                        }
                    }

                    If (!$officeProduct) {
                        continue
                    };

                    $name = $regProv.GetStringValue($HKLM, $path, "DisplayName").sValue

                    $primaryOfficeProduct = $true
                    If ($ConfigItemList.Contains($key.ToUpper()) -and $name.ToUpper().Contains("MICROSOFT OFFICE")) {
                        ForEach ($exception in $MSexceptionList) {
                            If ($name.ToLower() -match $exception.ToLower()) {
                                $primaryOfficeProduct = $false
                            }
                        }
                    }
                    Else {
                        $primaryOfficeProduct = $false
                    }

                    $clickToRunComponent = $regProv.GetDWORDValue($HKLM, $path, "ClickToRunComponent").uValue
                    $uninstallString = $regProv.GetStringValue($HKLM, $path, "UninstallString").sValue
                    If (!($clickToRunComponent)) {
                        If ($uninstallString) {
                            If ($uninstallString.Contains("OfficeClickToRun")) {
                                $clickToRunComponent = $true
                            }
                        }
                    }

                    $modifyPath = $regProv.GetStringValue($HKLM, $path, "ModifyPath").sValue
                    $version = $regProv.GetStringValue($HKLM, $path, "DisplayVersion").sValue

                    $cltrUpdatesEnabled = $null
                    $cltrUpdateUrl = $null
                    $clientCulture = $null;

                    [string]$clickToRun = $false

                    If ($clickToRunComponent) {
                        $clickToRun = $true
                        If ($name.ToUpper().Contains("MICROSOFT OFFICE")) {
                            $primaryOfficeProduct = $true
                        }

                        ForEach ($cltr in $ClickToRunList) {
                            If ($cltr.InstallPath) {
                                If ($cltr.InstallPath.ToUpper() -eq $installPath.ToUpper()) {
                                    $cltrUpdatesEnabled = $cltr.UpdatesEnabled
                                    $cltrUpdateUrl = $cltr.UpdateUrl
                                    If ($cltr.Platform -eq 'x64') {
                                        $buildType = "64-Bit"
                                    }
                                    If ($cltr.Platform -eq 'x86') {
                                        $buildType = "32-Bit"
                                    }
                                    $clientCulture = $cltr.ClientCulture
                                }
                            }
                        }
                    }

                    If (!$primaryOfficeProduct) {
                        If (!$ShowAllInstalledProducts) {
                            continue
                        }
                    }

                    $object = New-Object PSObject -Property @{
                        DisplayName = $name;
                        Version = $version;
                        InstallPath = $installPath;
                        ClickToRun = $clickToRun;
                        Bitness = $buildType;
                        ComputerName = $computer;
                        ClickToRunUpdatesEnabled = $cltrUpdatesEnabled;
                        ClickToRunUpdateUrl = $cltrUpdateUrl;
                        ClientCulture = $clientCulture
                    }
                    $object | Add-Member MemberSet PSStandardMembers $PSStandardMembers
                    $results += $object
                }
            }
        }

        $results = Get-Unique -InputObject $results
        
        return $results
    }
}

$office = Get-OfficeVersion
If ($office.DisplayName.Length -gt 0) {
    $outlook = New-Object -ComObject Outlook.Application
    $outlook.Session.Stores | Where-Object {$_.FilePath -like "*.pst"} | Select-Object DisplayName,FilePath | Export-Csv "C:\Users\Public\OutlookPSTs.csv" -NoTypeInformation
    
    Function Read-InputBoxDialog([string]$message, [string]$title, [string]$defaultText) {
            Add-Type -AssemblyName Microsoft.VisualBasic
            return [Microsoft.VisualBasic.Interaction]::InputBox($message, $title, $defaultText)
    }
    $text = Read-InputBoxDialog -Message "Enter Name and Path of Old Profile's PSTs`n- In CSV Format" -title "Old PST File #1" -defaultText "(ex: Steve,C:\Users\Public\steve@mail.com.pst)"
    
    If ($text.Length -gt 0) {
        $text | Out-File "C:\Users\Public\OutlookPSTs.csv" -Append -Encoding unicode
        
        $text2 = Read-InputBoxDialog -Message "Old Outlook Profile have more than 1 PST file?  Into the box it goes" -title "Old PST File #2" -defaultText "(ex: jdoe@contoso.com,C:\Users\jdoe\Documents\Outlook Files\jdoe@contoso.com - Default.pst)"
        
        If ($text2.length -gt 0) {
            $text2 | Out-File "C:\Users\Public\OutlookPSTs.csv" -Append -Encoding unicode
            
            $text3 = Read-InputBoxDialog -Message "More than 2?  You know what to do" -title "Old PST File #3" -defaultText "Remember, CSV stands for Comma-Separated-Values"
            
            If ($text3.Length -gt 0) {
                $text3 | Out-File "C:\Users\Public\OutlookPSTs.csv" -Append -Encoding unicode
            }
        }
    }
    
    $VBScripts = @("OffScrub03.vbs","OffScrub07.vbs","OffScrub10.vbs","OffScrub_O15msi.vbs","OffScrub_O16msi.vbs","OffScrubc2r.vbs","Remove-PreviousOfficeInstalls.ps1")
    ForEach ($vbs in $VBScripts) {
        $sauce = "https://lt.msinetworks.com/labtech/Transfer/Scripts/VBS/$vbs"
        $dest = "C:\Users\Public\$vbs"
        (New-Object System.Net.WebClient).DownloadFile($sauce,$dest)
    }
    & C:\Users\Public\Remove-PreviousOfficeInstalls.ps1 -RemoveClickToRun $true -KeepUserSettings $true -Remove2016Installs $true -NoReboot $true
    
    If (Test-Path C:\Users\Public\step08.ps1) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\CurrentVersion\Run" -Name "ScriptStep" -Value "C:\Windows\System32\WindowsPowershell\v1.0\powershell.exe -File C:\Users\Public\step08.ps1"
    }
    Restart-Computer -Force -Confirm:$false
}
Else {
    If (Test-Path C:\Users\Public\step08.ps1) {
        & "C:\Users\Public\step08.ps1"
    }
}
