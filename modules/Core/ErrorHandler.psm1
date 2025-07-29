# ErrorHandler.psm1 - Comprehensive error handling and reporting for Windows Terminal Setup

# Import Logger module
Import-Module (Join-Path $PSScriptRoot "Logger.psm1") -Force

# Module variables
$script:ErrorHistory = @()
$script:ErrorReportPath = $null

function Initialize-ErrorHandler {
    <#
    .SYNOPSIS
        Initializes the error handling system
    
    .PARAMETER ErrorReportDirectory
        Directory to store error reports (optional)
    #>
    [CmdletBinding()]
    param(
        [string]$ErrorReportDirectory = $null
    )
    
    try {
        if (-not $ErrorReportDirectory) {
            $ErrorReportDirectory = Join-Path $env:TEMP "WindowsTerminalSetup_ErrorReports"
        }
        
        if (-not (Test-Path $ErrorReportDirectory)) {
            New-Item -ItemType Directory -Path $ErrorReportDirectory -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:ErrorReportPath = Join-Path $ErrorReportDirectory "ErrorReport_$timestamp.json"
        
        Write-Log "Error handler initialized. Reports will be saved to: $script:ErrorReportPath" -Level Debug
        
        return $true
    }
    catch {
        Write-Log "Failed to initialize error handler: $($_.Exception.Message)" -Level Warning
        return $false
    }
}

function Register-Error {
    <#
    .SYNOPSIS
        Registers an error with detailed context information
    
    .PARAMETER ErrorRecord
        The PowerShell error record
    
    .PARAMETER Context
        Additional context information
    
    .PARAMETER Severity
        Error severity level
    
    .PARAMETER Component
        Component where the error occurred
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [hashtable]$Context = @{},
        
        [ValidateSet("Low", "Medium", "High", "Critical")]
        [string]$Severity = "Medium",
        
        [string]$Component = "Unknown"
    )
    
    try {
        $errorInfo = @{
            Timestamp = Get-Date
            Component = $Component
            Severity = $Severity
            Message = $ErrorRecord.Exception.Message
            FullyQualifiedErrorId = $ErrorRecord.FullyQualifiedErrorId
            CategoryInfo = $ErrorRecord.CategoryInfo.ToString()
            ScriptStackTrace = $ErrorRecord.ScriptStackTrace
            InvocationInfo = @{
                ScriptName = $ErrorRecord.InvocationInfo.ScriptName
                Line = $ErrorRecord.InvocationInfo.ScriptLineNumber
                Command = $ErrorRecord.InvocationInfo.MyCommand.Name
            }
            Context = $Context
            SystemInfo = Get-ErrorSystemInfo
            RecoveryActions = Get-RecoveryActions -ErrorRecord $ErrorRecord -Component $Component
        }
        
        $script:ErrorHistory += $errorInfo
        
        Write-Log "Error registered: [$Severity] $Component - $($ErrorRecord.Exception.Message)" -Level Error
        
        # Auto-export critical errors
        if ($Severity -eq "Critical") {
            Export-ErrorReport -IncludeSystemInfo
        }
        
        return $errorInfo
    }
    catch {
        Write-Log "Failed to register error: $($_.Exception.Message)" -Level Warning
        return $null
    }
}

function Get-ErrorSystemInfo {
    <#
    .SYNOPSIS
        Gathers system information relevant to error diagnosis
    #>
    [CmdletBinding()]
    param()
    
    try {
        return @{
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            PowerShellEdition = $PSVersionTable.PSEdition
            OSVersion = [System.Environment]::OSVersion.VersionString
            MachineName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            CurrentDirectory = Get-Location
            ExecutionPolicy = Get-ExecutionPolicy
            AvailableMemory = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
            ProcessId = $PID
        }
    }
    catch {
        return @{
            Error = "Failed to gather system info: $($_.Exception.Message)"
        }
    }
}

function Get-RecoveryActions {
    <#
    .SYNOPSIS
        Suggests recovery actions based on the error
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [string]$Component = "Unknown"
    )
    
    $actions = @()
    $errorMessage = $ErrorRecord.Exception.Message.ToLower()
    
    try {
        # Network-related errors
        if ($errorMessage -like "*network*" -or $errorMessage -like "*connection*" -or $errorMessage -like "*timeout*") {
            $actions += "Check internet connection"
            $actions += "Verify firewall settings"
            $actions += "Try again with increased timeout"
            $actions += "Use a different network connection"
        }
        
        # Permission-related errors
        if ($errorMessage -like "*access*denied*" -or $errorMessage -like "*permission*" -or $errorMessage -like "*unauthorized*") {
            $actions += "Run PowerShell as Administrator"
            $actions += "Check file/folder permissions"
            $actions += "Verify user account has necessary privileges"
        }
        
        # File-related errors
        if ($errorMessage -like "*file*not*found*" -or $errorMessage -like "*path*not*found*") {
            $actions += "Verify file/path exists"
            $actions += "Check file path spelling"
            $actions += "Ensure file is not moved or deleted"
        }
        
        # Package manager errors
        if ($Component -like "*Package*" -or $errorMessage -like "*package*") {
            $actions += "Update package manager"
            $actions += "Clear package manager cache"
            $actions += "Try alternative package manager"
            $actions += "Install package manually"
        }
        
        # PowerShell execution errors
        if ($errorMessage -like "*execution*policy*") {
            $actions += "Set execution policy: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
            $actions += "Run script with: powershell -ExecutionPolicy Bypass"
        }
        
        # Module loading errors
        if ($errorMessage -like "*module*" -or $errorMessage -like "*import*") {
            $actions += "Verify module path is correct"
            $actions += "Check if module is installed"
            $actions += "Try importing module manually"
            $actions += "Restart PowerShell session"
        }
        
        # Generic recovery actions
        if ($actions.Count -eq 0) {
            $actions += "Restart the application"
            $actions += "Check system requirements"
            $actions += "Review error logs for more details"
            $actions += "Contact support with error details"
        }
        
        return $actions
    }
    catch {
        return @("Unable to generate recovery actions: $($_.Exception.Message)")
    }
}

function Export-ErrorReport {
    <#
    .SYNOPSIS
        Exports error report to file
    
    .PARAMETER IncludeSystemInfo
        Include detailed system information
    
    .PARAMETER OutputPath
        Custom output path for the report
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeSystemInfo,
        [string]$OutputPath = $null
    )
    
    try {
        if (-not $OutputPath) {
            $OutputPath = $script:ErrorReportPath
        }
        
        if (-not $OutputPath) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $OutputPath = Join-Path $env:TEMP "WindowsTerminalSetup_ErrorReport_$timestamp.json"
        }
        
        $report = @{
            ReportGenerated = Get-Date
            TotalErrors = $script:ErrorHistory.Count
            CriticalErrors = ($script:ErrorHistory | Where-Object { $_.Severity -eq "Critical" }).Count
            HighSeverityErrors = ($script:ErrorHistory | Where-Object { $_.Severity -eq "High" }).Count
            Errors = $script:ErrorHistory
        }
        
        if ($IncludeSystemInfo) {
            $report.SystemDiagnostics = Get-ErrorSystemInfo
        }
        
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log "Error report exported to: $OutputPath" -Level Success
        return $OutputPath
    }
    catch {
        Write-Log "Failed to export error report: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Show-ErrorSummary {
    <#
    .SYNOPSIS
        Displays a summary of errors encountered
    #>
    [CmdletBinding()]
    param()
    
    try {
        if ($script:ErrorHistory.Count -eq 0) {
            Write-Host "No errors recorded during this session." -ForegroundColor Green
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
        Write-Host "Recent Errors:" -ForegroundColor Yellow
        
        $recentErrors = $script:ErrorHistory | Sort-Object Timestamp -Descending | Select-Object -First 5
        foreach ($error in $recentErrors) {
            $timeStr = $error.Timestamp.ToString("HH:mm:ss")
            Write-Host "[$timeStr] [$($error.Severity)] $($error.Component): $($error.Message)" -ForegroundColor Red
        }
        
        if ($script:ErrorReportPath) {
            Write-Host ""
            Write-Host "Detailed error report: $script:ErrorReportPath" -ForegroundColor Cyan
        }
        
        Write-Host ""
    }
    catch {
        Write-Log "Failed to display error summary: $($_.Exception.Message)" -Level Warning
    }
}

function Invoke-ErrorRecovery {
    <#
    .SYNOPSIS
        Attempts automatic error recovery based on error patterns
    
    .PARAMETER ErrorRecord
        The error to attempt recovery for
    
    .PARAMETER Component
        Component where the error occurred
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        
        [string]$Component = "Unknown"
    )
    
    try {
        Write-Log "Attempting automatic error recovery for: $($ErrorRecord.Exception.Message)" -Level Info
        
        $errorMessage = $ErrorRecord.Exception.Message.ToLower()
        $recoveryAttempted = $false
        
        # Attempt specific recovery actions
        if ($errorMessage -like "*execution*policy*") {
            try {
                Write-Log "Attempting to set execution policy..." -Level Info
                Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                $recoveryAttempted = $true
                Write-Log "Execution policy recovery successful" -Level Success
            }
            catch {
                Write-Log "Execution policy recovery failed: $($_.Exception.Message)" -Level Warning
            }
        }
        
        if ($errorMessage -like "*module*not*found*" -and $Component -like "*Core*") {
            try {
                Write-Log "Attempting to reload core modules..." -Level Info
                $modulesPath = Join-Path $PSScriptRoot ".."
                Get-ChildItem -Path $modulesPath -Filter "*.psm1" -Recurse | ForEach-Object {
                    Import-Module $_.FullName -Force -ErrorAction SilentlyContinue
                }
                $recoveryAttempted = $true
                Write-Log "Module reload recovery attempted" -Level Success
            }
            catch {
                Write-Log "Module reload recovery failed: $($_.Exception.Message)" -Level Warning
            }
        }
        
        return @{
            RecoveryAttempted = $recoveryAttempted
            Success = $recoveryAttempted  # Simple success indicator
            Actions = Get-RecoveryActions -ErrorRecord $ErrorRecord -Component $Component
        }
    }
    catch {
        Write-Log "Error recovery attempt failed: $($_.Exception.Message)" -Level Error
        return @{
            RecoveryAttempted = $false
            Success = $false
            Actions = @("Manual intervention required")
        }
    }
}

function Clear-ErrorHistory {
    <#
    .SYNOPSIS
        Clears the error history
    #>
    [CmdletBinding()]
    param()
    
    $script:ErrorHistory = @()
    Write-Log "Error history cleared" -Level Info
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-ErrorHandler',
    'Register-Error',
    'Get-RecoveryActions',
    'Export-ErrorReport',
    'Show-ErrorSummary',
    'Invoke-ErrorRecovery',
    'Clear-ErrorHistory'
)
