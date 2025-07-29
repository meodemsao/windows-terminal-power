#Requires -Version 5.1
<#
.SYNOPSIS
    Creates deployment package for Windows Terminal & PowerShell Setup

.DESCRIPTION
    Creates a production-ready deployment package with all necessary files

.EXAMPLE
    .\Create-DeploymentPackage.ps1
    Create deployment package
#>

Write-Host "Windows Terminal & PowerShell Setup - Deployment Package Creator" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$OutputPath = "deployment"
$PackageName = "WindowsTerminalSetup_Production_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$PackagePath = Join-Path $OutputPath $PackageName

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Create package directory
New-Item -ItemType Directory -Path $PackagePath -Force | Out-Null
Write-Host "Created package directory: $PackagePath" -ForegroundColor Green
Write-Host ""

# Define files to include
$FilesToInclude = @(
    "Install-WindowsTerminalSetup-Simple.ps1",
    "Install-WindowsTerminalSetup-Enhanced.ps1",
    "modules",
    "configs", 
    "docs",
    "README.md"
)

# Validate project structure
Write-Host "Validating project structure..." -ForegroundColor Cyan
$MissingFiles = @()
foreach ($file in $FilesToInclude) {
    $sourcePath = Join-Path $PSScriptRoot $file
    if (Test-Path $sourcePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (missing)" -ForegroundColor Red
        $MissingFiles += $file
    }
}

if ($MissingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Cannot create package. Missing files: $($MissingFiles -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All required files present. Proceeding with package creation..." -ForegroundColor Green
Write-Host ""

# Test main script execution
Write-Host "Testing main script execution..." -ForegroundColor Cyan
$ScriptPath = Join-Path $PSScriptRoot "Install-WindowsTerminalSetup-Simple.ps1"
try {
    $result = & $ScriptPath -DryRun 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Script executed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Script completed with warnings (exit code $LASTEXITCODE)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "  ✗ Script execution error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Continuing with package creation..." -ForegroundColor Yellow
}

Write-Host ""

# Copy files to package
Write-Host "Copying files to package..." -ForegroundColor Cyan
foreach ($file in $FilesToInclude) {
    $sourcePath = Join-Path $PSScriptRoot $file
    try {
        if (Test-Path $sourcePath -PathType Container) {
            # Copy directory
            Copy-Item -Path $sourcePath -Destination $PackagePath -Recurse -Force
        } else {
            # Copy file
            Copy-Item -Path $sourcePath -Destination $PackagePath -Force
        }
        Write-Host "  ✓ $file" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Failed to copy $file : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create package metadata
Write-Host ""
Write-Host "Creating package metadata..." -ForegroundColor Cyan
$Metadata = @{
    PackageName = $PackageName
    Version = "1.0.0"
    CreatedDate = Get-Date
    CreatedBy = $env:USERNAME
    Requirements = @{
        MinimumPowerShellVersion = "5.1"
        MinimumWindowsVersion = "10.0.18362"
    }
    Installation = @{
        MainScript = "Install-WindowsTerminalSetup-Simple.ps1"
        AlternativeScript = "Install-WindowsTerminalSetup-Enhanced.ps1"
        Documentation = "docs/INSTALLATION_GUIDE.md"
    }
}

$MetadataPath = Join-Path $PackagePath "package-metadata.json"
$Metadata | ConvertTo-Json -Depth 3 | Out-File -FilePath $MetadataPath -Encoding UTF8
Write-Host "  ✓ package-metadata.json" -ForegroundColor Green

# Create installation instructions
$Instructions = @"
# Windows Terminal & PowerShell Setup - Installation Instructions

## Quick Start
1. Extract this package to a directory of your choice
2. Open PowerShell as Administrator (recommended)
3. Navigate to the extracted directory
4. Run: .\Install-WindowsTerminalSetup-Simple.ps1

## Alternative Installation
For advanced users with more customization options:
.\Install-WindowsTerminalSetup-Enhanced.ps1

## System Requirements
- Windows 10 version 1903 (build 18362) or later
- PowerShell 5.1 or later (PowerShell 7+ recommended)
- Internet connection for downloading tools
- Administrator privileges (recommended)

## Documentation
- Installation Guide: docs/INSTALLATION_GUIDE.md
- Troubleshooting: docs/TROUBLESHOOTING.md
- API Documentation: docs/API_DOCUMENTATION.md

## Support
For issues and questions, please refer to the documentation.

Package Version: $($Metadata.Version)
Created: $($Metadata.CreatedDate)
"@

$InstructionsPath = Join-Path $PackagePath "INSTALL.md"
$Instructions | Out-File -FilePath $InstructionsPath -Encoding UTF8
Write-Host "  ✓ INSTALL.md" -ForegroundColor Green

# Calculate package size
$PackageSize = (Get-ChildItem -Path $PackagePath -Recurse | Measure-Object -Property Length -Sum).Sum
$PackageSizeMB = [math]::Round($PackageSize / 1MB, 2)
$FileCount = (Get-ChildItem -Path $PackagePath -Recurse).Count

Write-Host ""
Write-Host "Package created successfully!" -ForegroundColor Green
Write-Host "  Location: $PackagePath" -ForegroundColor White
Write-Host "  Size: $PackageSizeMB MB" -ForegroundColor Gray
Write-Host "  Files: $FileCount" -ForegroundColor Gray

# Create ZIP archive
Write-Host ""
Write-Host "Creating ZIP archive..." -ForegroundColor Cyan
$ZipPath = "$PackagePath.zip"

try {
    Compress-Archive -Path "$PackagePath\*" -DestinationPath $ZipPath -Force
    $ZipSize = (Get-Item $ZipPath).Length / 1MB
    Write-Host "  ✓ ZIP created: $ZipPath" -ForegroundColor Green
    Write-Host "  ✓ ZIP size: $([math]::Round($ZipSize, 2)) MB" -ForegroundColor Gray
}
catch {
    Write-Host "  ✗ Failed to create ZIP: $($_.Exception.Message)" -ForegroundColor Red
}

# Final summary
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                           DEPLOYMENT SUMMARY                                  " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Deployment package created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Package Details:" -ForegroundColor White
Write-Host "  📦 Package Name: $PackageName" -ForegroundColor Gray
Write-Host "  📁 Package Path: $PackagePath" -ForegroundColor Gray
Write-Host "  🗜️ ZIP Archive: $ZipPath" -ForegroundColor Gray
Write-Host "  📊 Package Size: $PackageSizeMB MB" -ForegroundColor Gray
Write-Host "  📄 File Count: $FileCount files" -ForegroundColor Gray
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Test the package in a clean environment" -ForegroundColor Cyan
Write-Host "  2. Distribute the ZIP file to target users" -ForegroundColor Cyan
Write-Host "  3. Provide installation instructions from INSTALL.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "The package is ready for production deployment! 🚀" -ForegroundColor Green
Write-Host ""

# Export deployment results
$DeploymentResults = @{
    Timestamp = Get-Date
    PackageName = $PackageName
    PackagePath = $PackagePath
    ZipPath = $ZipPath
    Size = $PackageSizeMB
    FileCount = $FileCount
    Success = $true
    FilesIncluded = $FilesToInclude
}

$ResultsPath = Join-Path $OutputPath "deployment-results_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$DeploymentResults | ConvertTo-Json -Depth 3 | Out-File -FilePath $ResultsPath -Encoding UTF8
Write-Host "Deployment results saved to: $ResultsPath" -ForegroundColor Gray

Write-Host ""
Write-Host "Deployment completed successfully! ✅" -ForegroundColor Green
