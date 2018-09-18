Get-ChildItem env:
&"$PSScriptroot\install-packages.ps1"
Get-ChildItem env:
refreshenv
Get-ChildItem env:
&"$PSScriptroot\init-gradle-cache.ps1"
