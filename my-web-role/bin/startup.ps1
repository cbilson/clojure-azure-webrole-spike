Write-Host "$(Get-Date -Format g): Starting application"

# $env:JAVA_CMD = 'C:\Program Files\Zulu\8.1.0.6\bin\java.exe'
# $env:APPLICATION = 'my-web-role-0.1.0-SNAPSHOT-standalone.jar'

# Stop-AzureEmulator; rm -r -for .\local_package.csx; Save-AzureServiceProjectPackage -Local; Start-AzureEmulator -Mode Express

$approotbin = Split-Path $PSCommandPath -Parent
Write-Host "approot/bin: $approotbin"

$java = $env:JAVA_CMD
Write-Host "Java Command: $cmd"

$app = $env:APPLICATION
Write-Host "Specified application: $app"

if (![io.Path]::IsPathRooted($app)) {
  $app = Join-Path $approotbin $app
  Write-Host "Application resolves to: $app"
}

function Enumerate-Parents($path) {
  $parent = Split-Path -Parent $path
  if (!$parent) { return }
  elseif (Test-Path $parent) {
    Get-ChildItem $parent | Out-Host
  } else {
    Write-Host "$parent does not exist."
  }

  Enumerate-Parents $parent
}

if (Test-Path $java) {
  Write-Host 'JAVA_CMD found.'
} else {
  Write-Host "$java not found."
  Enumerate-Parents $java
  exit 1
}

if (Test-Path $app) {
  Write-Host 'Application found.'
} else {
  Write-Host "$app not found."
  Enumerate-Parents $app
  exit 2
}

Write-Host "Starting: $java -jar $app"
Start-Process $java -ArgumentList '-jar', $app -Wait -NoNewWindow

Write-Host "$(Get-Date -Format g): Application exited."
exit 0