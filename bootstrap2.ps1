git clone https://github.com/gocd/gocd --depth 1 C:\\gocd
cd C:\\gocd
./gradlew.bat compileAll yarnInstall prepareJRuby --no-build-cache
tasklist
taskkill /F /IM java.exe
echo sleeping
timeout 5
echo done sleeping
tasklist
Remove-Item -Path C:\\gocd -Force -Recurse
mkdir c:\\go
