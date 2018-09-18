&"$PSScriptroot\install-packages.ps1"
refreshenv
Get-ChildItem env:
&"$PSScriptroot\init-gradle-cache.ps1"
