# Build script to create a standalone .exe from the hex_map example
# This script creates a .love file and bundles it with love.exe

$lovePath = "C:\Program Files\LOVE"
$loveExe = Join-Path $lovePath "love.exe"
$projectDir = $PSScriptRoot
$outputDir = Join-Path $projectDir "dist"
$loveFile = Join-Path $outputDir "hex_map.love"
$exeFile = Join-Path $outputDir "hex_map.exe"

Write-Host "Building hex_map executable..." -ForegroundColor Green

# Check if love.exe exists
if (-not (Test-Path $loveExe)) {
    Write-Host "Error: love.exe not found at $loveExe" -ForegroundColor Red
    Write-Host "Please make sure Love2D is installed." -ForegroundColor Red
    exit 1
}

# Create output directory
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Create .love file (zip archive with all game files)
Write-Host "Creating .love file..." -ForegroundColor Yellow
$loveFiles = Get-ChildItem -Path $projectDir -File | Where-Object { 
    $_.Extension -in @('.lua', '.png', '.ttf', '.otf', '.jpg', '.jpeg', '.ogg', '.wav', '.mp3')
}

# Remove existing .love file if it exists
if (Test-Path $loveFile) {
    Remove-Item $loveFile -Force
}

# Create temporary directory for zip contents (ensures files are at root of zip)
$tempDir = Join-Path $env:TEMP "hex_map_build"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Copy files to temp directory
foreach ($file in $loveFiles) {
    Copy-Item -Path $file.FullName -Destination $tempDir -Force
    Write-Host "  Added: $($file.Name)" -ForegroundColor Gray
}

# Create zip file using Compress-Archive (PowerShell 5.0+)
$tempZip = Join-Path $env:TEMP "hex_map_temp.zip"
if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force
}

# Compress from temp directory (files will be at root of zip)
Compress-Archive -Path "$tempDir\*" -DestinationPath $tempZip -CompressionLevel Fastest

# Move zip to .love file
Move-Item -Path $tempZip -Destination $loveFile -Force

# Clean up temp directory
Remove-Item $tempDir -Recurse -Force

Write-Host "Created: $loveFile" -ForegroundColor Green

# Create fused executable by copying love.exe and appending .love file
Write-Host "Creating fused executable..." -ForegroundColor Yellow
Copy-Item -Path $loveExe -Destination $exeFile -Force

# Append .love file to the exe
$loveBytes = [System.IO.File]::ReadAllBytes($loveFile)
$exeBytes = [System.IO.File]::ReadAllBytes($exeFile)
$combinedBytes = $exeBytes + $loveBytes
[System.IO.File]::WriteAllBytes($exeFile, $combinedBytes)

Write-Host "Created executable: $exeFile" -ForegroundColor Green
Write-Host ""
Write-Host "Build complete! You can now run $exeFile" -ForegroundColor Green
Write-Host "The executable is standalone and doesn't require Love2D to be installed." -ForegroundColor Cyan

