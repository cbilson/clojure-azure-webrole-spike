
Write-Host "$(Get-Date -Format g): Starting runtime installation"

# $env:RUNTIME_VENDOR = 'Azul Systems, Inc.'
# $env:RUNTIME_PRODUCT_NAME = 'Zulu 8.1.0.6 (64-bit)'
# $env:RUNTIME_PRODUCT_VERSION = '8.1.0.6'
# $env:RUNTIME_INSTALLER = 'http://downloads.azulsystems.com/request.php?file=zulu1.8.0_05-8.1.0.6-win64.msi'
# $env:RUNTIME_INSTALLER_FILENAME = 'zulu1.8.0_05-8.1.0.6-win64.msi'
# $env:RUNTIME_INSTALLER_CHECKSUM = '730c347461955f055e1410d6c41f7b6d'
# $env:HTTP_REQUEST_HEADERS = 'Referer: http://www.azulsystems.com/products/zulu/downloads#Windows\\nAccept: *'

# Stop-AzureEmulator; rm -r -for .\local_package.csx; Save-AzureServiceProjectPackage -Local; Start-AzureEmulator

$approot = Split-Path $PSCommandPath -Parent
$productVendor = $env:RUNTIME_VENDOR
$productName = $env:RUNTIME_PRODUCT_NAME
$productVersion = $env:RUNTIME_PRODUCT_VERSION
$installerUri = [uri] $env:RUNTIME_INSTALLER
$installerChecksum = $env:RUNTIME_INSTALLER_CHECKSUM
if ($installerChecksum) { $installerChecksum = $installerChecksum.ToLower() }

$headerLines = $env:HTTP_REQUEST_HEADERS -split '\\\\n'
$httpHeaders = @{}
if ($headerLines) {
  foreach ($headerLine in $headerLines) {
    $name, $value = $headerLine -split ':', 2
    $httpHeaders[$name.Trim()] = $value.Trim()
  }
}

$installerFilename = $env:RUNTIME_INSTALLER_FILENAME
if (!$installerFilename) {
  $installerFilename = [io.Path]::GetFileName($installerUri.LocalPath)
}

$installerFilename = Join-Path $approot $installerFilename

function Not($f) { !(& $f) }

function Installed {
  $product = Get-CimInstance -Query @"
select *
from CIM_Product
where Vendor = '$productVendor'
and Name = '$productName'
and Version = '$productVersion'
"@

  $installed = $product -ne $null
  if ($installed) {
    Write-Host "$productVendor $productName $productVersion already installed."
    $product | fl
  } else {
    Write-Host "$productVendor $productName $productVersion not installed."
  }

  $installed
}

function Installer-Downloaded {
  $downloaded = Test-Path $installerFilename
  if ($downloaded) {
    Write-Host "Installer file $installerFilename already downloaded."
  } else {
    Write-Host "Installer file $installerFilename not downloaded."
  }

  $downloaded
}

function Checksum-Wrong {
  $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
  $file = [System.IO.File]::Open($installerFilename, 'Open', 'Read')
  try {
    $binaryHash = $md5.ComputeHash($file)
    $stringHash = [System.BitConverter]::ToString($binaryHash).Replace('-', '')
    $ok = if (!$installerChecksum) { $true } else { $stringHash -eq $installerChecksum }
    $displayHash = if ($stringHash) { $stringHash } else { '(none specified)' }
    $warning = if (!$ok) { ' *** CHECKSUM WRONG ***' }
    Write-Host "Expected file hash: $installerChecksum, actual: $displayHash$warning"
    !$ok
  } finally {
    if ($file) { $file.Dispose() }
  }
}

function Download-File($url, $headers, $localFilename) {
  $client = New-Object System.Net.WebClient

  if (Test-Path $localFilename) {
    Remove-Item -Force $localFilename
  }

  foreach ($name in $headers.Keys) {
    $value = $headers[$name]
    Write-Host "Adding HTTP Header, ${name}: $($value)"
    $client.Headers.Add([string] $name, $value)
  }

  Write-Host "Downloading $url to $localFilename"
  $client.DownloadFile($url, $localFilename)
}

function Download-Installer {
  Download-File $installerUri $httpHeaders $installerFilename
}

function Install-Runtime {
  $logFile = Join-Path $approot installer.txt
  $ext = [io.Path]::GetExtension($installerFilename)
  switch ($ext) {
    '.msi' {
      Write-Host "Installing $installerFilename, logging to $logFile"
      msiexec /i $installerFilename /quiet /log $logFile }
    default { throw "Runtime installer filename extension $ext not supported." }
  }
}

# if product not installed
if (Not Installed) {
  if ((Not Installer-Downloaded) -or (Checksum-Wrong)) {
    Download-Installer
    if (Checksum-Wrong) {
      throw "Downloaded file checksum didn't match."
    }
  }

  Install-Runtime

  $suffix = if (Installed) { 'installed.' } else { 'Not Installed!' }
  Write-Host "After installing, runtime is: $suffix"
}

# if lein not here, download it
# if (No-Leiningen) {
#   Download-Leiningen
#   Install-Leiningen
# }
# lein deps

Write-Host "$(Get-Date -Format g): Runtime installation complete"
