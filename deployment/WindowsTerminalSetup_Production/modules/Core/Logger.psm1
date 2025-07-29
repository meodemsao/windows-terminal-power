# Logger.psm1 - Comprehensive logging functionality for Windows Terminal Setup

# Module variables
$script:LogLevel = "Info"
$script:LogFile = $null
$script:LogSession = $null
$script:LogLevels = @{
    "Debug" = 0
    "Info" = 1
    "Warning" = 2
    "Error" = 3
    "Success" = 1
}

function Start-LogSession {
    <#
    .SYNOPSIS
        Starts a new logging session
    
    .PARAMETER LogLevel
        Minimum log level to display and write to file
    
    .PARAMETER LogDirectory
        Directory to store log files (defaults to script directory)
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$LogLevel = "Info",
        [string]$LogDirectory = $null
    )
    
    $script:LogLevel = $LogLevel
    
    # Create log directory if not specified
    if (-not $LogDirectory) {
        $LogDirectory = Join-Path $PSScriptRoot "..\..\logs"
    }
    
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
    
    # Create log file with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:LogFile = Join-Path $LogDirectory "WindowsTerminalSetup_$timestamp.log"
    
    # Create session object
    $script:LogSession = @{
        StartTime = Get-Date
        LogFile = $script:LogFile
        LogLevel = $LogLevel
        EntryCount = 0
    }
    
    # Write session header
    $header = @"
================================================================================
Windows Terminal Setup - Log Session Started
================================================================================
Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Log Level: $LogLevel
Log File: $($script:LogFile)
PowerShell Version: $($PSVersionTable.PSVersion)
OS Version: $([System.Environment]::OSVersion.VersionString)
User: $($env:USERNAME)
Computer: $($env:COMPUTERNAME)
================================================================================

"@
    
    $header | Out-File -FilePath $script:LogFile -Encoding UTF8
    
    Write-Log "Log session started" -Level Info
    
    return $script:LogSession
}

function Stop-LogSession {
    <#
    .SYNOPSIS
        Stops the current logging session
    #>
    [CmdletBinding()]
    param()
    
    if ($script:LogSession) {
        $duration = (Get-Date) - $script:LogSession.StartTime
        Write-Log "Log session ended. Duration: $($duration.ToString('hh\:mm\:ss')). Total entries: $($script:LogSession.EntryCount)" -Level Info
        
        $footer = @"

================================================================================
Log Session Ended
================================================================================
End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Duration: $($duration.ToString('hh\:mm\:ss'))
Total Log Entries: $($script:LogSession.EntryCount)
================================================================================
"@
        
        $footer | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
        
        $script:LogSession = $null
    }
}

function Write-Log {
    <#
    .SYNOPSIS
        Writes a log entry to console and file
    
    .PARAMETER Message
        The message to log
    
    .PARAMETER Level
        The log level (Debug, Info, Warning, Error, Success)
    
    .PARAMETER NoConsole
        Skip console output, only write to file
    
    .PARAMETER NoFile
        Skip file output, only write to console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]
        [string]$Level = "Info",
        
        [switch]$NoConsole,
        
        [switch]$NoFile
    )
    
    # Check if we should log this level
    if ($script:LogLevels[$Level] -lt $script:LogLevels[$script:LogLevel]) {
        return
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to file if logging is active and not disabled
    if ($script:LogFile -and (-not $NoFile)) {
        try {
            $logEntry | Out-File -FilePath $script:LogFile -Append -Encoding UTF8
            if ($script:LogSession) {
                $script:LogSession.EntryCount++
            }
        }
        catch {
            Write-Warning "Failed to write to log file: $($_.Exception.Message)"
        }
    }
    
    # Write to console if not disabled
    if (-not $NoConsole) {
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
    }
}

function Get-LogPath {
    <#
    .SYNOPSIS
        Returns the current log file path
    #>
    [CmdletBinding()]
    param()
    
    return $script:LogFile
}

function Get-LogSession {
    <#
    .SYNOPSIS
        Returns the current log session information
    #>
    [CmdletBinding()]
    param()
    
    return $script:LogSession
}

function Set-LogLevel {
    <#
    .SYNOPSIS
        Changes the current log level
    
    .PARAMETER LogLevel
        New log level to set
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$LogLevel
    )
    
    $oldLevel = $script:LogLevel
    $script:LogLevel = $LogLevel
    
    Write-Log "Log level changed from $oldLevel to $LogLevel" -Level Info
    
    if ($script:LogSession) {
        $script:LogSession.LogLevel = $LogLevel
    }
}

function Write-LogSection {
    <#
    .SYNOPSIS
        Writes a section header to the log
    
    .PARAMETER Title
        Section title
    
    .PARAMETER Level
        Log level for the section
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $separator = "=" * 60
    $centeredTitle = $Title.PadLeft(($Title.Length + 60) / 2).PadRight(60)
    
    Write-Log $separator -Level $Level
    Write-Log $centeredTitle -Level $Level
    Write-Log $separator -Level $Level
}

function Write-LogProgress {
    <#
    .SYNOPSIS
        Writes progress information to the log
    
    .PARAMETER Activity
        Current activity description
    
    .PARAMETER Status
        Current status
    
    .PARAMETER PercentComplete
        Percentage complete (0-100)
    #>
    [CmdletBinding()]
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete
    )
    
    $progressMessage = "Progress: $Activity - $Status ($PercentComplete percent)"
    Write-Log $progressMessage -Level Debug
}

function Export-LogSummary {
    <#
    .SYNOPSIS
        Exports a summary of the log session
    
    .PARAMETER OutputPath
        Path to save the summary file
    #>
    [CmdletBinding()]
    param(
        [string]$OutputPath
    )
    
    if (-not $script:LogFile -or -not (Test-Path $script:LogFile)) {
        Write-Warning "No log file available for summary export"
        return
    }
    
    if (-not $OutputPath) {
        $OutputPath = $script:LogFile -replace '\.log$', '_summary.txt'
    }
    
    try {
        $logContent = Get-Content $script:LogFile
        
        # Count log levels
        $errorCount = ($logContent | Where-Object { $_ -match '\[Error\]' }).Count
        $warningCount = ($logContent | Where-Object { $_ -match '\[Warning\]' }).Count
        $infoCount = ($logContent | Where-Object { $_ -match '\[Info\]' }).Count
        $successCount = ($logContent | Where-Object { $_ -match '\[Success\]' }).Count
        
        # Extract errors and warnings
        $errors = $logContent | Where-Object { $_ -match '\[Error\]' }
        $warnings = $logContent | Where-Object { $_ -match '\[Warning\]' }
        
        $summary = @"
Windows Terminal Setup - Log Summary
=====================================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Log File: $($script:LogFile)

Statistics:
-----------
Total Entries: $($script:LogSession.EntryCount)
Errors: $errorCount
Warnings: $warningCount
Info: $infoCount
Success: $successCount

$(if ($errors.Count -gt 0) {
"Errors Found:
--------------
$($errors -join "`n")

"})

$(if ($warnings.Count -gt 0) {
"Warnings Found:
---------------
$($warnings -join "`n")

"})

End of Summary
"@
        
        $summary | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Log summary exported to: $OutputPath" -Level Success
        
        return $OutputPath
    }
    catch {
        Write-Log "Failed to export log summary: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Clear-OldLogs {
    <#
    .SYNOPSIS
        Clears old log files to prevent disk space issues
    
    .PARAMETER LogDirectory
        Directory containing log files
    
    .PARAMETER DaysToKeep
        Number of days of logs to keep (default: 30)
    #>
    [CmdletBinding()]
    param(
        [string]$LogDirectory = (Join-Path $PSScriptRoot "..\..\logs"),
        [int]$DaysToKeep = 30
    )
    
    if (-not (Test-Path $LogDirectory)) {
        return
    }
    
    try {
        $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
        $oldLogs = Get-ChildItem -Path $LogDirectory -Filter "*.log" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        if ($oldLogs.Count -gt 0) {
            Write-Log "Cleaning up $($oldLogs.Count) old log files (older than $DaysToKeep days)" -Level Info
            $oldLogs | Remove-Item -Force
            Write-Log "Old log files cleaned up successfully" -Level Success
        }
    }
    catch {
        Write-Log "Failed to clean up old log files: $($_.Exception.Message)" -Level Warning
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Start-LogSession',
    'Stop-LogSession', 
    'Write-Log',
    'Get-LogPath',
    'Get-LogSession',
    'Set-LogLevel',
    'Write-LogSection',
    'Write-LogProgress',
    'Export-LogSummary',
    'Clear-OldLogs'
)
