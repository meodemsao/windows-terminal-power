#Requires -Version 5.1
<#
.SYNOPSIS
    Windows Terminal and PowerShell Enhancement Installation Script

.DESCRIPTION
    Automates the installation and configuration of Windows Terminal, PowerShell 7, and essential CLI tools

.PARAMETER DryRun
    Show what would be installed without actually installing

.PARAMETER LogLevel
    Set logging level (Debug, Info, Warning, Error)

.EXAMPLE
    .\Install-WindowsTerminalSetup.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateSet("Debug", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

# Script variables
$script:ScriptRoot = $PSScriptRoot
$script:ModulesPath = Join-Path $ScriptRoot "modules"

function Main {
    try {
        Write-Host "🚀 Windows Terminal & PowerShell Setup" -ForegroundColor Cyan
        Write-Host "=======================================" -ForegroundColor Cyan
        Write-Host ""

        # Import core modules inside Main function
        Write-Host "Importing core modules..." -ForegroundColor Gray

        $loggerPath = Join-Path $script:ModulesPath "Core\Logger.psm1"
        $packageManagerPath = Join-Path $script:ModulesPath "Core\PackageManager.psm1"
        $systemCheckPath = Join-Path $script:ModulesPath "Core\SystemCheck.psm1"
        $backupRestorePath = Join-Path $script:ModulesPath "Core\BackupRestore.psm1"

        # Verify module files exist
        $moduleFiles = @($loggerPath, $packageManagerPath, $systemCheckPath, $backupRestorePath)
        foreach ($moduleFile in $moduleFiles) {
            if (-not (Test-Path $moduleFile)) {
                throw "Module file not found: $moduleFile"
            }
        }

        # Import modules in dependency order
        Import-Module $loggerPath -Force -ErrorAction Stop
        Import-Module $packageManagerPath -Force -ErrorAction Stop
        Import-Module $systemCheckPath -Force -ErrorAction Stop
        Import-Module $backupRestorePath -Force -ErrorAction Stop

        Write-Host "Core modules imported successfully" -ForegroundColor Green

        # Test if functions are available
        $availableFunctions = Get-Command Start-LogSession -ErrorAction SilentlyContinue
        if (-not $availableFunctions) {
            Write-Host "Warning: Start-LogSession function not available after import" -ForegroundColor Yellow
            Write-Host "Available Logger functions:" -ForegroundColor Gray
            Get-Command -Module Logger* | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
        }

        Write-Host ""

        # Start logging session
        if (Get-Command Start-LogSession -ErrorAction SilentlyContinue) {
            $logSession = Start-LogSession -LogLevel $LogLevel
        } else {
            Write-Host "Proceeding without logging session due to module import issues" -ForegroundColor Yellow
            $logSession = $null
        }
        Write-Log "Starting Windows Terminal setup process" -Level Info
        
        if ($DryRun) {
            Write-Log "DRY RUN MODE - No actual installations will be performed" -Level Warning
        }
        
        # Test system compatibility with enhanced validation
        Write-Log "Performing comprehensive system compatibility checks..." -Level Info

        $readinessResult = Test-SystemReadiness -ExportDiagnostics

        if (-not $readinessResult.Ready) {
            Write-Log "System readiness test failed with critical issues:" -Level Error
            foreach ($issue in $readinessResult.CriticalIssues) {
                Write-Log "  - $issue" -Level Error
            }

            if ($readinessResult.DiagnosticsFile) {
                Write-Log "Detailed diagnostics exported to: $($readinessResult.DiagnosticsFile)" -Level Info
            }

            throw "System compatibility check failed. Critical issues must be resolved before proceeding."
        }

        # Display warnings and recommendations
        if ($readinessResult.Warnings.Count -gt 0) {
            Write-Log "System compatibility warnings:" -Level Warning
            foreach ($warning in $readinessResult.Warnings) {
                Write-Log "  - $warning" -Level Warning
            }
        }

        if ($readinessResult.Recommendations.Count -gt 0) {
            Write-Log "System recommendations:" -Level Info
            foreach ($recommendation in $readinessResult.Recommendations) {
                Write-Log "  - $recommendation" -Level Info
            }
        }

        Write-Log "System compatibility checks completed successfully" -Level Success

        # Initialize package manager with enhanced error handling
        Write-Log "Initializing package manager..." -Level Info
        if (Initialize-PackageManager) {
            $availableManagers = Get-AvailableManagers
            Write-Log "Package manager initialized successfully. Available: $($availableManagers -join ', ')" -Level Success
        } else {
            Write-Log "No package manager available. Manual installation may be required." -Level Warning
            Write-Log "Consider installing winget, chocolatey, or scoop for automated installations." -Level Info
        }
        
        Write-Host ""
        Write-Host "✅ Setup completed successfully!" -ForegroundColor Green
        Write-Host ""
        
        Write-Log "Installation process completed" -Level Success
    }
    catch {
        # Handle case where Write-Log might not be available
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log "Critical error occurred: $($_.Exception.Message)" -Level Error
        }
        Write-Host "❌ Critical Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please check the error details above and try again." -ForegroundColor Yellow
        exit 1
    }
    finally {
        if ($logSession) {
            Stop-LogSession
        }
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
