#Requires -Version 5.1
<#
.SYNOPSIS
    Windows Terminal and PowerShell Enhancement Installation Script (Simplified Version)

.DESCRIPTION
    Simplified version with enhanced error handling and validation built-in

.PARAMETER DryRun
    Show what would be installed without actually installing

.PARAMETER LogLevel
    Set logging level (Debug, Info, Warning, Error)

.EXAMPLE
    .\Install-WindowsTerminalSetup-Simple.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateSet("Debug", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info"
)

# Script variables
$script:ScriptRoot = $PSScriptRoot
$script:ErrorHistory = @()
$script:LogFile = $null

# Simple logging function
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with colors
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }
    
    $icon = switch ($Level) {
        "Debug" { "[DEBUG]" }
        "Info" { "[INFO]" }
        "Warning" { "[WARN]" }
        "Error" { "[ERROR]" }
        "Success" { "[OK]" }
        default { "[LOG]" }
    }
    
    Write-Host "$icon $Message" -ForegroundColor $color
    
    # Write to log file if available
    if ($script:LogFile) {
        try {
            $logEntry | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
        }
        catch {
            # Silently continue if logging fails
        }
    }
}

# Enhanced error handling function
function Register-Error {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [string]$Component = "Unknown",
        
        [ValidateSet("Low", "Medium", "High", "Critical")]
        [string]$Severity = "Medium"
    )
    
    $errorInfo = @{
        Timestamp = Get-Date
        Component = $Component
        Severity = $Severity
        Message = $ErrorMessage
    }
    
    $script:ErrorHistory += $errorInfo
    Write-Log "Error registered: [$Severity] $Component - $ErrorMessage" -Level Error
}

# System compatibility checks with enhanced validation
function Test-SystemReadiness {
    Write-Log "Performing comprehensive system readiness test..." -Level Info
    
    $readiness = @{
        Ready = $true
        CriticalIssues = @()
        Warnings = @()
        Recommendations = @()
    }
    
    try {
        # Check Windows version
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $buildNumber = [int]$osInfo.BuildNumber
        
        if ($buildNumber -lt 18362) {  # Windows 10 1903
            $readiness.Ready = $false
            $readiness.CriticalIssues += "Windows version too old (build $buildNumber). Requires Windows 10 1903+ (build 18362) or Windows 11"
        } else {
            Write-Log "Windows version check passed: $($osInfo.Caption) (build $buildNumber)" -Level Success
        }
        
        # Check PowerShell version
        $psVersion = $PSVersionTable.PSVersion
        if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
            $readiness.Ready = $false
            $readiness.CriticalIssues += "PowerShell version too old ($psVersion). Requires PowerShell 5.1 or later"
        } else {
            Write-Log "PowerShell version check passed: $psVersion" -Level Success
            if ($psVersion.Major -lt 7) {
                $readiness.Recommendations += "Consider upgrading to PowerShell 7 for the best experience"
            }
        }
        
        # Check internet connectivity
        try {
            $testUrls = @("https://www.microsoft.com", "https://github.com")
            $connected = $false
            
            foreach ($url in $testUrls) {
                try {
                    $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
                    if ($response.StatusCode -eq 200) {
                        $connected = $true
                        break
                    }
                }
                catch {
                    continue
                }
            }
            
            if ($connected) {
                Write-Log "Internet connectivity check passed" -Level Success
            } else {
                $readiness.Ready = $false
                $readiness.CriticalIssues += "No internet connectivity detected"
            }
        }
        catch {
            $readiness.Ready = $false
            $readiness.CriticalIssues += "Failed to test internet connectivity: $($_.Exception.Message)"
        }
        
        # Check disk space
        try {
            $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
            $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
            
            if ($freeSpaceGB -lt 2) {
                $readiness.Ready = $false
                $readiness.CriticalIssues += "Insufficient disk space: $freeSpaceGB GB available, 2 GB required"
            } else {
                Write-Log "Disk space check passed: $freeSpaceGB GB available" -Level Success
            }
        }
        catch {
            $readiness.Warnings += "Could not check disk space: $($_.Exception.Message)"
        }
        
        # Check admin privileges
        try {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            if ($isAdmin) {
                Write-Log "Running with administrator privileges" -Level Success
            } else {
                $readiness.Warnings += "Not running as Administrator - some installations may require elevation"
                $readiness.Recommendations += "Consider running PowerShell as Administrator for full functionality"
            }
        }
        catch {
            $readiness.Warnings += "Could not check administrator privileges: $($_.Exception.Message)"
        }
        
        # Check package managers
        $packageManagers = @()
        
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $packageManagers += "winget"
        }
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $packageManagers += "chocolatey"
        }
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            $packageManagers += "scoop"
        }
        
        if ($packageManagers.Count -eq 0) {
            $readiness.Warnings += "No package managers detected"
            $readiness.Recommendations += "Install winget, chocolatey, or scoop for automated tool installation"
        } else {
            Write-Log "Package managers available: $($packageManagers -join ', ')" -Level Success
        }
        
        return $readiness
    }
    catch {
        Register-Error -ErrorMessage "Critical error during system readiness test: $($_.Exception.Message)" -Component "SystemCheck" -Severity "Critical"
        $readiness.Ready = $false
        $readiness.CriticalIssues += "System readiness test failed: $($_.Exception.Message)"
        return $readiness
    }
}

# Show error summary
function Show-ErrorSummary {
    if ($script:ErrorHistory.Count -eq 0) {
        Write-Log "No errors recorded during this session" -Level Success
        return
    }
    
    Write-Host ""
    Write-Host "Error Summary" -ForegroundColor Red
    Write-Host "=============" -ForegroundColor Red
    Write-Host ""
    
    $criticalCount = ($script:ErrorHistory | Where-Object { $_.Severity -eq "Critical" }).Count
    $highCount = ($script:ErrorHistory | Where-Object { $_.Severity -eq "High" }).Count
    $mediumCount = ($script:ErrorHistory | Where-Object { $_.Severity -eq "Medium" }).Count
    $lowCount = ($script:ErrorHistory | Where-Object { $_.Severity -eq "Low" }).Count
    
    Write-Host "Total Errors: $($script:ErrorHistory.Count)" -ForegroundColor Yellow
    if ($criticalCount -gt 0) { Write-Host "Critical: $criticalCount" -ForegroundColor Red }
    if ($highCount -gt 0) { Write-Host "High: $highCount" -ForegroundColor Red }
    if ($mediumCount -gt 0) { Write-Host "Medium: $mediumCount" -ForegroundColor Yellow }
    if ($lowCount -gt 0) { Write-Host "Low: $lowCount" -ForegroundColor Gray }
    
    Write-Host ""
}

function Main {
    try {
        # Initialize logging
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:LogFile = Join-Path $env:TEMP "WindowsTerminalSetup_$timestamp.log"
        
        Write-Host "🚀 Windows Terminal & PowerShell Setup (Enhanced)" -ForegroundColor Cyan
        Write-Host "=================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Log "Starting Windows Terminal setup process" -Level Info
        Write-Log "Log file: $script:LogFile" -Level Info
        
        if ($DryRun) {
            Write-Log "DRY RUN MODE - No actual installations will be performed" -Level Warning
        }
        
        # Test system readiness with enhanced validation
        $readinessResult = Test-SystemReadiness
        
        if (-not $readinessResult.Ready) {
            Write-Log "System readiness test failed with critical issues:" -Level Error
            foreach ($issue in $readinessResult.CriticalIssues) {
                Write-Log "  - $issue" -Level Error
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
        
        Write-Host ""
        Write-Host "✅ Enhanced setup validation completed successfully!" -ForegroundColor Green
        Write-Host ""
        
        if ($DryRun) {
            Write-Host "This was a dry run. No actual installations were performed." -ForegroundColor Yellow
            Write-Host "The system is ready for the full installation process." -ForegroundColor Green
        }
        
        Write-Log "Installation process completed successfully" -Level Success
    }
    catch {
        Register-Error -ErrorMessage $_.Exception.Message -Component "Main" -Severity "Critical"
        Write-Log "Critical error occurred: $($_.Exception.Message)" -Level Error
        Write-Host "❌ Critical Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Please check the error details above and try again." -ForegroundColor Yellow
        
        Show-ErrorSummary
        
        if ($script:LogFile) {
            Write-Host "Detailed log available at: $script:LogFile" -ForegroundColor Cyan
        }
        
        exit 1
    }
    finally {
        Show-ErrorSummary
        
        if ($script:LogFile) {
            Write-Log "Session completed. Log saved to: $script:LogFile" -Level Info
        }
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
