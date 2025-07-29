#Requires -Version 5.1
<#
.SYNOPSIS
    Simple deployment script for Windows Terminal & PowerShell Setup

.DESCRIPTION
    Creates a deployment package with all necessary files for distribution

.PARAMETER CreatePackage
    Create deployment package

.PARAMETER OutputPath
    Path for deployment artifacts

.EXAMPLE
    .\Deploy-Simple.ps1 -CreatePackage
    Create deployment package
#>

[CmdletBinding()]
param(
    [switch]$CreatePackage,
    [string]$OutputPath = "deployment"
)

function New-DeploymentPackage {
    <#
    .SYNOPSIS
        Creates deployment package
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Creating deployment package..." -ForegroundColor Cyan
    
    $packageName = "WindowsTerminalSetup_Production_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $packagePath = Join-Path $OutputPath $packageName
    
    # Create package directory
    New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
    Write-Host "Package directory: $packagePath" -ForegroundColor Green
    
    # Define files to include
    $filesToInclude = @(
        "Install-WindowsTerminalSetup-Simple.ps1",
        "Install-WindowsTerminalSetup-Enhanced.ps1",
        "modules",
        "configs", 
        "docs",
        "README.md"
    )
    
    # Copy files
    Write-Host "Copying files..." -ForegroundColor Gray
    foreach ($file in $filesToInclude) {
        $sourcePath = Join-Path $PSScriptRoot $file
        if (Test-Path $sourcePath) {
            try {
                if (Test-Path $sourcePath -PathType Container) {
                    Copy-Item -Path $sourcePath -Destination $packagePath -Recurse -Force
                } else {
                    Copy-Item -Path $sourcePath -Destination $packagePath -Force
                }
                Write-Host "  ✓ $file" -ForegroundColor Green
            }
            catch {
                Write-Host "  ✗ Failed to copy $file : $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  ⚠ $file not found" -ForegroundColor Yellow
        }
    }
    
    # Create package metadata
    $metadata = @{
        PackageName = $packageName
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
    
    $metadataPath = Join-Path $packagePath "package-metadata.json"
    $metadata | ConvertTo-Json -Depth 3 | Out-File -FilePath $metadataPath -Encoding UTF8
    Write-Host "  ✓ package-metadata.json" -ForegroundColor Green
    
    # Create installation instructions
    $instructions = "# Windows Terminal & PowerShell Setup - Installation Instructions`n`n"
    $instructions += "## Quick Start`n"
    $instructions += "1. Extract this package to a directory of your choice`n"
    $instructions += "2. Open PowerShell as Administrator (recommended)`n"
    $instructions += "3. Navigate to the extracted directory`n"
    $instructions += "4. Run: .\Install-WindowsTerminalSetup-Simple.ps1`n`n"
    $instructions += "## Alternative Installation`n"
    $instructions += "For advanced users: .\Install-WindowsTerminalSetup-Enhanced.ps1`n`n"
    $instructions += "## System Requirements`n"
    $instructions += "- Windows 10 version 1903 (build 18362) or later`n"
    $instructions += "- PowerShell 5.1 or later (PowerShell 7+ recommended)`n"
    $instructions += "- Internet connection for downloading tools`n"
    $instructions += "- Administrator privileges (recommended)`n`n"
    $instructions += "## Documentation`n"
    $instructions += "- Installation Guide: docs/INSTALLATION_GUIDE.md`n"
    $instructions += "- Troubleshooting: docs/TROUBLESHOOTING.md`n"
    $instructions += "- API Documentation: docs/API_DOCUMENTATION.md`n`n"
    $instructions += "Package Version: $($metadata.Version)`n"
    $instructions += "Created: $($metadata.CreatedDate)`n"
    
    $instructionsPath = Join-Path $packagePath "INSTALL.md"
    $instructions | Out-File -FilePath $instructionsPath -Encoding UTF8
    Write-Host "  ✓ INSTALL.md" -ForegroundColor Green
    
    # Calculate package size
    $packageSize = (Get-ChildItem -Path $packagePath -Recurse | Measure-Object -Property Length -Sum).Sum
    $packageSizeMB = [math]::Round($packageSize / 1MB, 2)
    
    Write-Host ""
    Write-Host "Package created successfully!" -ForegroundColor Green
    Write-Host "  Location: $packagePath" -ForegroundColor Gray
    Write-Host "  Size: $packageSizeMB MB" -ForegroundColor Gray
    Write-Host "  Files: $((Get-ChildItem -Path $packagePath -Recurse).Count)" -ForegroundColor Gray
    
    # Create ZIP archive
    Write-Host ""
    Write-Host "Creating ZIP archive..." -ForegroundColor Gray
    $zipPath = "$packagePath.zip"
    
    try {
        Compress-Archive -Path "$packagePath\*" -DestinationPath $zipPath -Force
        $zipSize = (Get-Item $zipPath).Length / 1MB
        Write-Host "  ✓ ZIP created: $zipPath ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green
    }
    catch {
        Write-Host "  ✗ Failed to create ZIP: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return @{
        PackagePath = $packagePath
        ZipPath = $zipPath
        Size = $packageSizeMB
    }
}

function Test-ProjectStructure {
    <#
    .SYNOPSIS
        Tests project structure
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Validating project structure..." -ForegroundColor Cyan
    
    $requiredComponents = @(
        "Install-WindowsTerminalSetup-Simple.ps1",
        "Install-WindowsTerminalSetup-Enhanced.ps1",
        "modules",
        "configs",
        "docs",
        "README.md"
    )
    
    $missingComponents = @()
    foreach ($component in $requiredComponents) {
        $componentPath = Join-Path $PSScriptRoot $component
        if (Test-Path $componentPath) {
            Write-Host "  ✓ $component" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $component (missing)" -ForegroundColor Red
            $missingComponents += $component
        }
    }
    
    if ($missingComponents.Count -eq 0) {
        Write-Host "All required components present" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Missing components: $($missingComponents -join ', ')" -ForegroundColor Red
        return $false
    }
}

function Test-ScriptExecution {
    <#
    .SYNOPSIS
        Tests main script execution
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing script execution..." -ForegroundColor Cyan
    
    $scriptPath = Join-Path $PSScriptRoot "Install-WindowsTerminalSetup-Simple.ps1"
    if (Test-Path $scriptPath) {
        try {
            Write-Host "  Testing Install-WindowsTerminalSetup-Simple.ps1..." -ForegroundColor Gray
            $result = & $scriptPath -DryRun 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✓ Script executed successfully" -ForegroundColor Green
                return $true
            } else {
                Write-Host "  ✗ Script failed with exit code $LASTEXITCODE" -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Host "  ✗ Script execution error: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "  ✗ Main script not found" -ForegroundColor Red
        return $false
    }
}

function Main {
    <#
    .SYNOPSIS
        Main deployment function
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Windows Terminal & PowerShell Setup - Simple Deployment" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Create output directory
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
    }
    
    # Validate project structure
    $structureValid = Test-ProjectStructure
    Write-Host ""
    
    # Test script execution
    $executionValid = Test-ScriptExecution
    Write-Host ""
    
    # Create package if requested and validation passed
    if ($CreatePackage) {
        if ($structureValid -and $executionValid) {
            $packageInfo = New-DeploymentPackage
            Write-Host ""
            Write-Host "Deployment completed successfully!" -ForegroundColor Green
            Write-Host "Package ready for distribution: $($packageInfo.PackagePath)" -ForegroundColor White
        } else {
            Write-Host "Deployment validation failed. Package not created." -ForegroundColor Red
            exit 1
        }
    } else {
        if ($structureValid -and $executionValid) {
            Write-Host "Validation completed successfully!" -ForegroundColor Green
            Write-Host "Ready for package creation. Use -CreatePackage to create deployment package." -ForegroundColor White
        } else {
            Write-Host "Validation failed. Please fix issues before deployment." -ForegroundColor Red
            exit 1
        }
    }
}

# Execute main function
Main
