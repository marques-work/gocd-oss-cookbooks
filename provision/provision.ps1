Get-ChildItem env:
&"$PSScriptroot\install-packages.ps1"
Get-ChildItem env:
refreshenv
Get-ChildItem env:
java -version
&"$PSScriptroot\init-gradle-cache.ps1"
