<#
  run-all-windows.ps1
  Windows 11 automation script for PWA storefront demo.
  Place this file in the project root that contains 'api', 'web', and 'docker-compose.yml'.
  Run in PowerShell:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    .\run-all-windows.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Project root: $root" -ForegroundColor Cyan

function Copy-EnvIfMissing {
  $src = Join-Path $root "api\.env.example"
  $dst = Join-Path $root "api\.env"
  if (-Not (Test-Path $dst) -and (Test-Path $src)) {
    Copy-Item $src $dst
    Write-Host "Copied api\.env.example -> api\.env"
  } else {
    Write-Host "api\.env already exists or .env.example missing"
  }
}

function Run-DockerComposeIfPresent {
  if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Docker detected. Running: docker-compose up -d --build" -ForegroundColor Green
    pushd $root
    try {
      & docker-compose up -d --build
    } catch {
      Write-Warning "docker-compose up failed (continuing with local starts): $_"
    } finally { popd }
  } else {
    Write-Warning "Docker not found. Skipping docker-compose."
  }
}

function Wait-ForUrl {
  param($url, $timeoutSec = 60)
  $end = (Get-Date).AddSeconds($timeoutSec)
  while ((Get-Date) -lt $end) {
    try {
      $req = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
      if ($req.StatusCode -ge 200 -and $req.StatusCode -lt 400) {
        Write-Host "Ready: $url"
        return $true
      }
    } catch {}
    Start-Sleep -Seconds 1
  }
  Write-Warning "Timed out waiting for $url"
  return $false
}

function Install-And-Seed-API {
  $apiDir = Join-Path $root "api"
  if (-Not (Test-Path $apiDir)) { Write-Warning "api/ folder not found"; return }
  Push-Location $apiDir
  try {
    if (-Not (Test-Path "node_modules")) {
      Write-Host "Installing API dependencies..."
      & npm install
    } else { Write-Host "node_modules present for API, skipping npm install" }
    Write-Host "Running seed script (node seed.js)..."
    & node seed.js
  } catch {
    Write-Warning "API install/seed error: $_"
  } finally { Pop-Location }
}

function Install-Web {
  $webDir = Join-Path $root "web"
  if (-Not (Test-Path $webDir)) { Write-Warning "web/ folder not found"; return }
  Push-Location $webDir
  try {
    if (-Not (Test-Path "node_modules")) {
      Write-Host "Installing Web dependencies..."
      & npm install
    } else { Write-Host "node_modules present for Web, skipping npm install" }
  } catch {
    Write-Warning "Web install error: $_"
  } finally { Pop-Location }
}

function Generate-Mkcert-IfAvailable {
  if (Get-Command mkcert -ErrorAction SilentlyContinue) {
    Write-Host "mkcert found. Generating local certs..." -ForegroundColor Green
    pushd $root
    try {
      & mkcert -install
      & mkcert localhost 127.0.0.1 ::1
      $certDir = Join-Path $root "web\certs"
      New-Item -ItemType Directory -Force -Path $certDir | Out-Null
      # move matching pem files to web/certs
      Get-ChildItem -Path $root -Filter "localhost*.pem" -ErrorAction SilentlyContinue | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $certDir -Force
      }
      Write-Host "Certs moved to: $certDir"
    } catch {
      Write-Warning "mkcert generation failed: $_"
    } finally { popd }
  } else {
    Write-Host "mkcert not found. Skipping HTTPS cert generation (optional step)." -ForegroundColor Yellow
  }
}

function Start-In-New-PSWindow {
  param($workingDir, $command)
  $ps = "cd `"$workingDir`"; $command"
  Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit","-Command",$ps
}

# Begin execution
Copy-EnvIfMissing
Run-DockerComposeIfPresent

# Wait a short while and try to detect API health
$apiHealth = "http://localhost:4000/_health"
Write-Host "Waiting up to 30s for API health endpoint: $apiHealth"
$apiReady = Wait-ForUrl -url $apiHealth -timeoutSec 30

# Install & seed local copies
Install-And-Seed-API
Install-Web

# Try mkcert (optional)
Generate-Mkcert-IfAvailable

# If API is not yet ready, start local API in a new window
$apiDir = Join-Path $root "api"
if (-not $apiReady) {
  Write-Host "Starting API in a new PowerShell window..." -ForegroundColor Cyan
  Start-In-New-PSWindow -workingDir $apiDir -command "npm run dev"
} else {
  Write-Host "API is reachable at $apiHealth" -ForegroundColor Green
}

# Start frontend in a new window
$webDir = Join-Path $root "web"
Write-Host "Starting frontend (Vite) in a new PowerShell window..." -ForegroundColor Cyan
Start-In-New-PSWindow -workingDir $webDir -command "npm run dev"

# Open frontend URL in default browser
$frontendUrl = "http://localhost:5173"
Write-Host "Opening browser to $frontendUrl" -ForegroundColor Cyan
Start-Process $frontendUrl

Write-Host "`nScript completed. Check the new PowerShell windows for API and frontend logs." -ForegroundColor Green
