# Simple deployment package creator for Windows Terminal & PowerShell Setup

Write-Host "Creating deployment package..." -ForegroundColor Cyan

# Configuration
$OutputPath = "deployment"
$PackageName = "WindowsTerminalSetup_Production_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$PackagePath = Join-Path $OutputPath $PackageName

# Create directories
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}
New-Item -ItemType Directory -Path $PackagePath -Force | Out-Null

Write-Host "Package directory: $PackagePath" -ForegroundColor Green

# Files to include
$FilesToInclude = @(
    "Install-WindowsTerminalSetup-Simple.ps1",
    "Install-WindowsTerminalSetup-Enhanced.ps1",
    "modules",
    "configs", 
    "docs",
    "README.md"
)

# Copy files
Write-Host "Copying files..." -ForegroundColor Gray
foreach ($file in $FilesToInclude) {
    $sourcePath = Join-Path $PSScriptRoot $file
    if (Test-Path $sourcePath) {
        if (Test-Path $sourcePath -PathType Container) {
            Copy-Item -Path $sourcePath -Destination $PackagePath -Recurse -Force
        } else {
            Copy-Item -Path $sourcePath -Destination $PackagePath -Force
        }
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (not found)" -ForegroundColor Red
    }
}

# Create metadata
$Metadata = @{
    PackageName = $PackageName
    Version = "1.0.0"
    CreatedDate = Get-Date
    CreatedBy = $env:USERNAME
}

$MetadataPath = Join-Path $PackagePath "package-metadata.json"
$Metadata | ConvertTo-Json | Out-File -FilePath $MetadataPath -Encoding UTF8
Write-Host "  ✓ package-metadata.json" -ForegroundColor Green

# Create installation instructions
$Instructions = "# Windows Terminal & PowerShell Setup`n`n"
$Instructions += "## Installation`n"
$Instructions += "1. Open PowerShell as Administrator`n"
$Instructions += "2. Run: .\Install-WindowsTerminalSetup-Simple.ps1`n`n"
$Instructions += "## Documentation`n"
$Instructions += "See docs/ folder for detailed instructions`n"

$InstructionsPath = Join-Path $PackagePath "INSTALL.md"
$Instructions | Out-File -FilePath $InstructionsPath -Encoding UTF8
Write-Host "  ✓ INSTALL.md" -ForegroundColor Green

# Calculate size
$PackageSize = (Get-ChildItem -Path $PackagePath -Recurse | Measure-Object -Property Length -Sum).Sum
$PackageSizeMB = [math]::Round($PackageSize / 1MB, 2)

Write-Host ""
Write-Host "Package created successfully!" -ForegroundColor Green
Write-Host "  Location: $PackagePath" -ForegroundColor White
Write-Host "  Size: $PackageSizeMB MB" -ForegroundColor Gray

# Create ZIP
Write-Host ""
Write-Host "Creating ZIP archive..." -ForegroundColor Gray
$ZipPath = "$PackagePath.zip"

try {
    Compress-Archive -Path "$PackagePath\*" -DestinationPath $ZipPath -Force
    $ZipSize = (Get-Item $ZipPath).Length / 1MB
    Write-Host "  ✓ ZIP created: $ZipPath ($([math]::Round($ZipSize, 2)) MB)" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Failed to create ZIP: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Deployment package ready! 🚀" -ForegroundColor Green
Write-Host "ZIP file: $ZipPath" -ForegroundColor White
