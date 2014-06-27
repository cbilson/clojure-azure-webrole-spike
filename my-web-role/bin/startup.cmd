@echo off
powershell .\startup.ps1 > ..\startup.txt 2>&1
exit /b %ERRORLEVEL%
