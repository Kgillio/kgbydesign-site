$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $root 'index.html'
$backupPath = Join-Path $root 'index-before-asset-migration.html'

if (-not (Test-Path $indexPath)) {
    Write-Host ''
    Write-Host 'ERROR: index.html was not found in this folder.' -ForegroundColor Red
    Write-Host 'Place migrate-assets.ps1 and run-migration.bat in the same kgbydesign-site folder as index.html.'
    Read-Host 'Press Enter to close'
    exit 1
}

$html = Get-Content -Path $indexPath -Raw -Encoding UTF8
$pattern = 'https://kgbydesign\.com/wp-content/uploads/[A-Za-z0-9._~%/\-]+'
$urls = [regex]::Matches($html, $pattern) | ForEach-Object { $_.Value } | Sort-Object -Unique

if ($urls.Count -eq 0) {
    Write-Host ''
    Write-Host 'No WordPress media URLs were found. The migration may already be complete.' -ForegroundColor Yellow
    Read-Host 'Press Enter to close'
    exit 0
}

if (-not (Test-Path $backupPath)) {
    Copy-Item $indexPath $backupPath
}

Write-Host ''
Write-Host "Found $($urls.Count) unique images/videos to preserve." -ForegroundColor Cyan
Write-Host 'Downloading them into the assets folder...' -ForegroundColor Cyan
Write-Host ''

$failed = @()
$count = 0
foreach ($url in $urls) {
    $count++
    $relative = $url -replace '^https://kgbydesign\.com/wp-content/uploads/', 'assets/'
    $relative = [Uri]::UnescapeDataString($relative)
    $target = Join-Path $root ($relative -replace '/', '\')
    $targetFolder = Split-Path -Parent $target

    if (-not (Test-Path $targetFolder)) {
        New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
    }

    $fileName = Split-Path $target -Leaf
    Write-Host "[$count/$($urls.Count)] $fileName"

    try {
        if (-not (Test-Path $target)) {
            Invoke-WebRequest -Uri $url -OutFile $target -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
        }
        $html = $html.Replace($url, ($relative -replace '\', '/'))
    }
    catch {
        $failed += $url
        Write-Host "  FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Set-Content -Path $indexPath -Value $html -Encoding UTF8

Write-Host ''
if ($failed.Count -eq 0) {
    Write-Host 'SUCCESS: All media files were downloaded and index.html now uses the local assets folder.' -ForegroundColor Green
    Write-Host 'A backup was saved as index-before-asset-migration.html.'
}
else {
    Write-Host "Completed, but $($failed.Count) file(s) could not be downloaded." -ForegroundColor Yellow
    Write-Host 'Do not switch the domain yet. Copy the failed URLs shown above and send them to ChatGPT.'
}
Write-Host ''
Read-Host 'Press Enter to close'
