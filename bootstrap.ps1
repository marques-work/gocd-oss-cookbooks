$GOLANG_BOOTSTRAPPER_VERSION='1.1'
$P4_VERSION='15.1'
$P4D_VERSION='16.2'
$NODEJS_VERSION='6.13.1'
$chocolateyUseWindowsCompression=false
$ErrorActionPreference = "Stop" 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Set-ExecutionPolicy Bypass
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

choco install -y nodejs.install --version="${NODEJS_VERSION}"
choco install -y hg svn yarn jdk8
Remove-Item C:\\Users\\ContainerAdministrator\\AppData\\Local\\Temp\\chocolatey -Force -Recurse
New-Item "${env:ProgramFiles(x86)}\\Perforce\\bin\\" -ItemType Directory
Invoke-WebRequest https://s3.amazonaws.com/mirrors-archive/local/perforce/r$P4_VERSION/bin.ntx64/p4.exe -Outfile "C:\\Program Files (x86)\\Perforce\\bin\\p4.exe"
Invoke-WebRequest https://s3.amazonaws.com/mirrors-archive/local/perforce/r$P4D_VERSION/bin.ntx64/p4d.exe -Outfile "C:\\Program Files (x86)\\Perforce\\bin\\p4d.exe"
Invoke-WebRequest https://github.com/ketan/gocd-golang-bootstrapper/releases/download/${GOLANG_BOOTSTRAPPER_VERSION}/go-bootstrapper-${GOLANG_BOOTSTRAPPER_VERSION}.windows.amd64.exe -Outfile C:\\go-agent.exe
Invoke-WebRequest https://github.com/git-for-windows/git/releases/download/v2.18.0.windows.1/MinGit-2.18.0-busybox-64-bit.zip -OutFile C:\\git.zip
Expand-Archive C:\\git.zip C:\\git
Remove-Item -Path C:\\git.zip
$newSystemPath = [System.Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
$newSystemPath = "${newSystemPath};${env:ProgramFiles(x86)}\\Perforce\\bin;C:\\Git\\Cmd"
[Environment]::SetEnvironmentVariable("Path", $newSystemPath, [EnvironmentVariableTarget]::Machine)
$env:Path = $newSystemPath + ";" + [System.Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
npm config set msvs_version 2015
git clone https://github.com/gocd/gocd --depth 1 C:\\gocd
cd C:\\gocd
gradlew.bat compileAll yarnInstall prepareJRuby --no-daemon --no-build-cache
tasklist
taskkill /F /IM java.exe
echo sleeping
timeout 5
echo done sleeping
tasklist
Remove-Item -Path C:\\gocd -Force -Recurse
mkdir c:\\go
