<#
run-nimbus-validation.ps1
Automates starting backend/frontend, simple API checks, idempotency test,
and runs Lighthouse to produce an HTML PWA report.

Place this file at:
C:\Users\bhard\Desktop\pwa-storefront-fixed\run-nimbus-validation.ps1
#>

# ---------- Configuration ----------
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$apiDir = Join-Path $projectRoot 'api'
$webDir = Join-Path $projectRoot 'web'
$lighthouseReport = Join-Path $webDir 'lighthouse-full-report.html'

$backendHealth = 'http://localhost:4000/_health'
$productsApi = 'http://localhost:4000/api/products'
$frontendHttp = 'http://localhost:5173'
$frontendHttps = 'https://localhost:5173'

# timeout settings (seconds)
$waitForBackendSec = 60
$waitBetweenPollSec = 2

Write-Host "Nimbus validation script starting..." -ForegroundColor Cyan
Write-Host "Project root: $projectRoot`n"

# ---------- Helper functions ----------
function Start-NewPwshWindow {
    param($workDir, $command, $title)
    $escaped = $command -replace '"','\"'
    $args = "-NoExit -NoProfile -Command `"" + "cd `"$workDir`"; $command" + "`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $args -WindowStyle Normal -WorkingDirectory $workDir -Verb runAs
    Start-Sleep -Milliseconds 600
}

function Start-NewPwshWindowNoElev {
    param($workDir, $command)
    $args = "-NoExit -NoProfile -Command `"" + "cd `"$workDir`"; $command" + "`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $args -WorkingDirectory $workDir
    Start-Sleep -Milliseconds 600
}

function Wait-ForUrl {
    param($url, $timeoutSec)
    $start = Get-Date
    while ((Get-Date) -lt $start.AddSeconds($timeoutSec)) {
        try {
            $resp = Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 5 -ErrorAction Stop
            return $resp
        } catch {
            Start-Sleep -Seconds $waitBetweenPollSec
        }
    }
    throw "Timeout waiting for $url after $timeoutSec seconds"
}

# ---------- Start backend ----------
Write-Host "Starting backend (API) in a new PowerShell window..." -ForegroundColor Green
# Use npm run dev (assumes package.json has dev script)
$apiCmd = 'npm run dev'
# Try to open non-elevated window first (safer). If permission errors occur, user can open admin manually.
Start-NewPwshWindowNoElev -workDir $apiDir -command $apiCmd

# ---------- Start frontend ----------
Write-Host "Starting frontend (Web) in a new PowerShell window..." -ForegroundColor Green
$webCmd = 'npm run dev'
Start-NewPwshWindowNoElev -workDir $webDir -command $webCmd

# ---------- Wait for backend health ----------
Write-Host "`nWaiting for backend health at $backendHealth ..." -ForegroundColor Yellow
try {
    $h = Wait-ForUrl -url $backendHealth -timeoutSec $waitForBackendSec
    Write-Host "Backend healthy: $($h | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host "Backend did not become healthy in $waitForBackendSec seconds. Check backend logs." -ForegroundColor Red
    Write-Host "You can re-run this script after fixing the backend." -ForegroundColor Yellow
    exit 1
}

# ---------- Check products API ----------
Write-Host "`nChecking products API ($productsApi) ..." -ForegroundColor Yellow
try {
    $prod = Invoke-RestMethod -Uri $productsApi -Method GET -TimeoutSec 10
    if ($prod.data -and $prod.data.Count -gt 0) {
        $first = $prod.data[0]
        Write-Host "Products OK — first product: $($first.name) (sku: $($first.sku))" -ForegroundColor Green
    } else {
        Write-Host "Products endpoint responded but no products found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to fetch products API: $_" -ForegroundColor Red
    exit 1
}

# ---------- Idempotency quick test for /api/orders ----------
Write-Host "`nRunning idempotency test on POST /api/orders ..." -ForegroundColor Yellow
$orderTest = @{
    clientOrderId = "test-client-" + (Get-Date -Format "yyyyMMddHHmmss")
    items = @(@{ sku = $prod.data[0].sku; quantity = 1; price = $prod.data[0].price })
    totalAmount = $prod.data[0].price
}
$bodyJson = $orderTest | ConvertTo-Json -Compress

# First POST
try {
    $r1 = Invoke-RestMethod -Uri 'http://localhost:4000/api/orders' -Method Post -Body $bodyJson -ContentType 'application/json' -ErrorAction Stop
    Write-Host "First POST response: $($r1 | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host "First POST failed: $_" -ForegroundColor Red
}

# Second POST with same clientOrderId (should be idempotent)
try {
    $r2 = Invoke-RestMethod -Uri 'http://localhost:4000/api/orders' -Method Post -Body $bodyJson -ContentType 'application/json' -ErrorAction Stop
    Write-Host "Second POST response: $($r2 | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host "Second POST failed: $_" -ForegroundColor Red
}

# ---------- Check for HTTPS certs ----------
$certPem = Join-Path $webDir 'localhost.pem'
$certKey = Join-Path $webDir 'localhost-key.pem'
$haveCerts = (Test-Path $certPem) -and (Test-Path $certKey)

if ($haveCerts) {
    Write-Host "`nFound HTTPS certs in web folder. Frontend should run on HTTPS." -ForegroundColor Green
    $lighthouseTarget = $frontendHttps
    $chromeFlag = '--ignore-certificate-errors'  # still safe to pass
} else {
    Write-Host "`nNo local HTTPS certs found in web folder." -ForegroundColor Yellow
    Write-Host "If you want full installability checks, run mkcert in the web folder and rerun." -ForegroundColor Yellow
    Write-Host "Continuing Lighthouse with --ignore-certificate-errors (works for local testing)..." -ForegroundColor Yellow
    $lighthouseTarget = $frontendHttps
    $chromeFlag = '--ignore-certificate-errors'
}

# ---------- Wait a moment for frontend to be available ----------
Write-Host "`nWaiting a few seconds for frontend to boot..." -ForegroundColor Yellow
Start-Sleep -Seconds 6

# Try to open the frontend URL in default browser (https)
try {
    Start-Process $frontendHttps
    Write-Host "Opened $frontendHttps in browser (if it is trusted)." -ForegroundColor Green
} catch {
    Write-Host "Unable to open browser automatically. Please open $frontendHttps manually." -ForegroundColor Yellow
}

# ---------- Run Lighthouse (full) ----------
Write-Host "`nRunning Lighthouse (full audit). This may take 30-90 seconds..." -ForegroundColor Cyan
Set-Location $webDir

# Compose lighthouse command
$lighthouseCmd = "npx lighthouse `"$lighthouseTarget`" --output html --output-path `"$lighthouseReport`" --chrome-flags=""$chromeFlag"""

Write-Host "Command: $lighthouseCmd" -ForegroundColor Gray

try {
    iex $lighthouseCmd
    Write-Host "Lighthouse finished. Opening report at: $lighthouseReport" -ForegroundColor Green
    Start-Process $lighthouseReport
} catch {
    Write-Host "Lighthouse failed: $_" -ForegroundColor Red
    Write-Host "If Lighthouse cannot launch Chrome automatically, ensure Chrome is installed and accessible." -ForegroundColor Yellow
}

# ---------- Final checks: service worker manifest detection (best-effort) ----------
Write-Host "`nBest-effort check: whether manifest link exists in frontend index.html ..." -ForegroundColor Cyan
$indexHtml = Join-Path $webDir 'index.html'
if (Test-Path $indexHtml) {
    $indexContent = Get-Content $indexHtml -Raw
    if ($indexContent -match 'rel=["'']manifest["'']') {
        Write-Host "Manifest link appears in index.html." -ForegroundColor Green
    } else {
        Write-Host "Manifest link not found in index.html. Ensure <link rel=""manifest"" href=""/manifest.json""> is present." -ForegroundColor Yellow
    }
} else {
    Write-Host "index.html not found at $indexHtml" -ForegroundColor Yellow
}

# ---------- Summary ----------
Write-Host "`n==== Nimbus Validation Summary ====" -ForegroundColor Cyan
Write-Host "Backend health: $backendHealth" -ForegroundColor Gray
Write-Host "Products API: $productsApi" -ForegroundColor Gray
Write-Host "Frontend target (Lighthouse): $lighthouseTarget" -ForegroundColor Gray
Write-Host "Local certs found: $haveCerts" -ForegroundColor Gray
Write-Host "Lighthouse report: $lighthouseReport" -ForegroundColor Gray
Write-Host "`nOpen the Lighthouse report and inspect the Progressive Web App section for installability and offline checks." -ForegroundColor Yellow
Write-Host "If PWA checks fail (manifest/service worker/HTTPS), follow the mkcert instructions (install mkcert and create certs in the web folder), then re-run this script." -ForegroundColor Yellow

Write-Host "`nCompleted Nimbus validation script." -ForegroundColor Cyan
