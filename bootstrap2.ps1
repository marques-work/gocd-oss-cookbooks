$ErrorActionPreference = "Stop" 

git clone https://github.com/gocd/gocd --depth 1 C:\\gocd --quiet
cd C:\\gocd
tasklist
./gradlew.bat compileAll yarnInstall prepareJRuby --no-build-cache --quiet
tasklist
taskkill /F /IM java.exe
echo sleeping
timeout 5
echo done sleeping
tasklist
Remove-Item -Path C:\\gocd -Force -Recurse
New-Item C:\\go -ItemType Directory
