$GOLANG_BOOTSTRAPPER_VERSION='2.2'
$P4_VERSION='15.1'
$P4D_VERSION='16.2'
$NODEJS_VERSION='6.13.1'
$RUBY_VERSION='1.9.3.55100'
$NANT_VERSION='0.92.2'

# Copy over configs
New-Item "C:/Users/ContainerAdministrator/.gradle" -ItemType Directory
New-Item "C:/Users/ContainerAdministrator/.m2" -ItemType Directory
New-Item "C:/Users/ContainerAdministrator/.bundle" -ItemType Directory

Copy-Item C:/Users/ContainerAdministrator/user-config/gitconfig C:/Users/ContainerAdministrator/.gitconfig
Copy-Item C:/Users/ContainerAdministrator/user-config/npmrc C:/Users/ContainerAdministrator/.npmrc
Copy-Item C:/Users/ContainerAdministrator/user-config/init.gradle C:/Users/ContainerAdministrator/.gradle/init.gradle
Copy-Item C:/Users/ContainerAdministrator/user-config/settings.xml C:/Users/ContainerAdministrator/.m2/settings.xml
Copy-Item C:/Users/ContainerAdministrator/user-config/bundle-config C:/Users/ContainerAdministrator/.bundle/config

Remove-Item C:/Users/ContainerAdministrator/user-config -Recurse -Force

# install chocolatey
$chocolateyUseWindowsCompression='false'
$ErrorActionPreference = "Stop" 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# install packages
choco install -y nodejs.install --version="${NODEJS_VERSION}"
choco install -y ruby --version=${RUBY_VERSION}
choco install -y nant --version=${NANT_VERSION}
choco install -y hg yarn jdk8 svn ant git

# Remove chocolatey from temp location
Remove-Item C:\\Users\\ContainerAdministrator\\AppData\\Local\\Temp\\chocolatey -Force -Recurse

# install p4
New-Item "${env:ProgramFiles(x86)}\\Perforce\\bin\\" -ItemType Directory
Invoke-WebRequest https://s3.amazonaws.com/mirrors-archive/local/perforce/r$P4_VERSION/bin.ntx64/p4.exe -Outfile "C:\\Program Files (x86)\\Perforce\\bin\\p4.exe"
Invoke-WebRequest https://s3.amazonaws.com/mirrors-archive/local/perforce/r$P4D_VERSION/bin.ntx64/p4d.exe -Outfile "C:\\Program Files (x86)\\Perforce\\bin\\p4d.exe"

# install gocd bootstrapper
Invoke-WebRequest https://github.com/ketan/gocd-golang-bootstrapper/releases/download/${GOLANG_BOOTSTRAPPER_VERSION}/go-bootstrapper-${GOLANG_BOOTSTRAPPER_VERSION}.windows.amd64.exe -Outfile C:\\go-agent.exe

$newSystemPath = [System.Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
$newSystemPath = "${newSystemPath};${env:ProgramFiles(x86)}\\Perforce\\bin;C:\\Git\\Cmd;C:\tools\ruby193\bin\;${env:ProgramFiles(x86)}\nant-0.92\bin;${env:ProgramFiles}\Git\bin;"
$env:Path = $newSystemPath + ";" + [System.Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
[Environment]::SetEnvironmentVariable("Path", $newSystemPath, [EnvironmentVariableTarget]::Machine)

Add-LocalGroupMember -Group "Administrators" -Member "ContainerAdministrator"
npm config set msvs_version 2015