# Copy over configs
New-Item "${env:USERPROFILE}\.gradle" -ItemType Directory | Out-Null
New-Item "${env:USERPROFILE}\.m2" -ItemType Directory | Out-Null
New-Item "${env:USERPROFILE}\.bundle" -ItemType Directory | Out-Null

Copy-Item "$PSScriptroot\bundle-config"       "${env:USERPROFILE}\.bundle\config"
Copy-Item "$PSScriptroot\gitconfig-windows"   "${env:USERPROFILE}\.gitconfig"
Copy-Item "$PSScriptroot\init.gradle"         "${env:USERPROFILE}\.gradle\init.gradle"
Copy-Item "$PSScriptroot\npmrc"               "${env:USERPROFILE}\.npmrc"
Copy-Item "$PSScriptroot\settings.xml"        "${env:USERPROFILE}\.m2\settings.xml"

# install chocolatey
$chocolateyUseWindowsCompression = 'true'
$env:chocolateyUseWindowsCompression = 'true'
$ErrorActionPreference = "Stop"
$progressPreference = 'silentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).path)\..\.."
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

RefreshEnv

# install packages
choco install --no-progress -y git --params "/GitAndUnixToolsOnPath /NoAutoCrlf"
choco install --no-progress -y nodejs yarn openjdk11 googlechrome

RefreshEnv

Add-LocalGroupMember -Group "Administrators" -Member "ContainerAdministrator"
