<#
 # Sysmon Installation, Update and Upgrade Script
 #
 # Author: Nihlander
 #     https://twitter.com/nihlander
 #     https://github.com/nihlander
 #     https://github.com/jsypower
 #
 # Company: Defence Logic Limited 
 #     https://defencelogic.io
 #     https://twitter.com/DefenceLogic
 #
 #>

# Update this value to the version of Sysmon you expect to be installed.
$latestVersion = [double]10.0

# Update this value to the path of Sysmon Executable.
$sysmonExePath = '\\path\to\Sysmon.exe'

$sysmonConfPath = '\\path\to\sysmon-config.xml'

# Add additional flags if required.
$sysmonInstallFlags = '/accepteula -i C:\windows\sysmon-config.xml'

$running = $true
$installedVersion = [double](Get-Process -Name Sysmon -ErrorAction SilentlyContinue -ErrorVariable checkError | Select-Object -ExpandProperty ProductVersion)

function Install-Sysmon {
    Write-Host '[+] Installing Sysmon...'
    Copy-Item -Path $sysmonConfPath -Destination C:\Windows\sysmon-config.xml
    Start-Sleep -Seconds 3
    Start-Process -FilePath $sysmonExePath -ArgumentList $sysmonInstallFlags -NoNewWindow
}

function Upgrade-Sysmon {
    Write-Host '[+] Uninstalling Sysmon...'
    Start-Process -FilePath 'C:\Windows\Sysmon.exe' -ArgumentList '-u'
    Start-Sleep -Seconds 5
    Install-Sysmon
}

function Update-Config {
    Write-Host '[+] Updating Sysmon Configuration...'
    Copy-Item -Path $sysmonConfPath -Destination C:\Windows\sysmon-config.xml
    Start-Sleep -Seconds 3
    Start-Process -FilePath 'C:\Windows\Sysmon.exe' -ArgumentList '-c C:\Windows\sysmon-config.xml'
}

while ( $running ) {

    if ( $checkError ) {

        Write-Host '[!] Error : Sysmon not installed or is not running.'
        Write-Host '[+] Attempting to start Sysmon service...'
        Start-Service -Name Sysmon -ErrorAction SilentlyContinue -ErrorVariable serviceError

        if ( $serviceError ) {
            Write-Host '[!] Sysmon is not installed.'
            Install-Sysmon
            $running = $false
        }
        else {
            Write-Host '[+] Sysmon Started Successfully. Checking version...'
            $checkError = $null
            $installedVersion = [double](Get-Process -Name Sysmon -ErrorAction SilentlyContinue -ErrorVariable checkError | Select-Object -ExpandProperty ProductVersion)
        }
    } else {

        if ( $installedVersion -lt $latestVersion ) {
            Write-Host '[+] Sysmon Neeeds Updating!'
            Upgrade-Sysmon
            $running = $false
        }
        elseif ( $installedVersion -gt $latestVersion ) {
            Write-Host '[!] Error : Installed version is greater than latest version. Is this script up-to-date?'
        }
        else {
            Write-Host '[+] Sysmon is Up-to-Date!'
            Write-Host '[+] Applying configuration...'
            Update-Config
            $running = $false
        }
    }
}