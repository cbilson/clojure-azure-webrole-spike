@echo off

if "%EMULATED%"=="true" goto :RunSetup

echo Configuring powershell permissions > ..\setup.txt
powershell -Command { Set-Executionpolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned }

:RunSetup
powershell .\setup.ps1 >> ..\setup.txt 2>&1
exit /b %ERRORLEVEL%
