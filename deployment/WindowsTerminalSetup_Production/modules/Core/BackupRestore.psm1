# BackupRestore.psm1 - Configuration backup and restore functionality for Windows Terminal Setup

# Import Logger module
Import-Module (Join-Path $PSScriptRoot "Logger.psm1") -Force

# Module variables
$script:BackupRootDir = Join-Path $env:USERPROFILE ".windows-terminal-setup\backups"

function New-BackupDirectory {
    <#
    .SYNOPSIS
        Creates a new backup directory with timestamp
    
    .PARAMETER CustomPath
        Custom backup directory path (optional)
    #>
    [CmdletBinding()]
    param(
        [string]$CustomPath = $null
    )
    
    try {
        if ($CustomPath) {
            $backupDir = $CustomPath
        }
        else {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backupDir = Join-Path $script:BackupRootDir $timestamp
        }
        
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Write-Log "Created backup directory: $backupDir" -Level Success
        }
        
        # Create backup manifest file
        $manifest = @{
            BackupDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            BackupDirectory = $backupDir
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            BackupFiles = @()
        }
        
        $manifestPath = Join-Path $backupDir "backup-manifest.json"
        $manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $manifestPath -Encoding UTF8
        
        Write-Log "Backup manifest created: $manifestPath" -Level Debug
        
        return $backupDir
    }
    catch {
        Write-Log "Failed to create backup directory: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Backup-Configuration {
    <#
    .SYNOPSIS
        Backs up a configuration file or directory
    
    .PARAMETER ConfigPath
        Path to the configuration file or directory to backup
    
    .PARAMETER BackupDir
        Backup directory to store the file
    
    .PARAMETER BackupName
        Custom name for the backup file (optional)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $true)]
        [string]$BackupDir,
        
        [string]$BackupName = $null
    )
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            Write-Log "Configuration path does not exist: $ConfigPath" -Level Warning
            return $false
        }
        
        if (-not (Test-Path $BackupDir)) {
            Write-Log "Backup directory does not exist: $BackupDir" -Level Error
            return $false
        }
        
        # Determine backup filename
        if ($BackupName) {
            $backupFileName = $BackupName
        }
        else {
            $configItem = Get-Item $ConfigPath
            $backupFileName = "$($configItem.Name).backup"
        }
        
        $backupPath = Join-Path $BackupDir $backupFileName
        
        # Backup file or directory
        if (Test-Path $ConfigPath -PathType Container) {
            # Directory backup
            Write-Log "Backing up directory: $ConfigPath" -Level Info
            Copy-Item -Path $ConfigPath -Destination $backupPath -Recurse -Force
        }
        else {
            # File backup
            Write-Log "Backing up file: $ConfigPath" -Level Info
            Copy-Item -Path $ConfigPath -Destination $backupPath -Force
        }
        
        # Update backup manifest
        Update-BackupManifest -BackupDir $BackupDir -OriginalPath $ConfigPath -BackupPath $backupPath
        
        Write-Log "Successfully backed up $ConfigPath to $backupPath" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to backup $ConfigPath : $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Restore-Configuration {
    <#
    .SYNOPSIS
        Restores configurations from a backup directory with comprehensive error handling

    .PARAMETER BackupDir
        Backup directory containing the files to restore

    .PARAMETER SelectiveRestore
        Only restore specific files (optional)

    .PARAMETER ValidateBeforeRestore
        Validate backup integrity before restoring

    .PARAMETER CreateRestorePoint
        Create a restore point before making changes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupDir,

        [string[]]$SelectiveRestore = @(),

        [switch]$ValidateBeforeRestore,

        [switch]$CreateRestorePoint
    )

    $restoreResult = @{
        Success = $false
        BackupDir = $BackupDir
        RestoredFiles = @()
        FailedFiles = @()
        ValidationErrors = @()
        RestorePointPath = $null
        StartTime = Get-Date
        EndTime = $null
    }

    try {
        Write-Log "Starting configuration restore from: $BackupDir" -Level Info

        # Validate backup directory
        if (-not (Test-Path $BackupDir)) {
            $restoreResult.ValidationErrors += "Backup directory does not exist: $BackupDir"
            Write-Log $restoreResult.ValidationErrors[-1] -Level Error
            return $restoreResult
        }

        # Read and validate backup manifest
        $manifestPath = Join-Path $BackupDir "backup-manifest.json"
        if (-not (Test-Path $manifestPath)) {
            $restoreResult.ValidationErrors += "Backup manifest not found: $manifestPath"
            Write-Log $restoreResult.ValidationErrors[-1] -Level Error
            return $restoreResult
        }

        try {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            Write-Log "Restoring from backup created on $($manifest.BackupDate)" -Level Info
        }
        catch {
            $restoreResult.ValidationErrors += "Failed to parse backup manifest: $($_.Exception.Message)"
            Write-Log $restoreResult.ValidationErrors[-1] -Level Error
            return $restoreResult
        }

        # Validate backup integrity if requested
        if ($ValidateBeforeRestore) {
            $validationResult = Test-BackupIntegrity -BackupDir $BackupDir -Manifest $manifest
            if (-not $validationResult.Success) {
                $restoreResult.ValidationErrors += $validationResult.Errors
                Write-Log "Backup validation failed: $($validationResult.Errors -join '; ')" -Level Error
                return $restoreResult
            }
            Write-Log "Backup integrity validation passed" -Level Success
        }

        # Create restore point if requested
        if ($CreateRestorePoint) {
            $restoreResult.RestorePointPath = New-BackupDirectory
            Write-Log "Created restore point: $($restoreResult.RestorePointPath)" -Level Info

            # Backup current configurations before restoring
            foreach ($backupFile in $manifest.BackupFiles) {
                if (Test-Path $backupFile.OriginalPath) {
                    try {
                        Backup-Configuration -ConfigPath $backupFile.OriginalPath -BackupDir $restoreResult.RestorePointPath
                    }
                    catch {
                        Write-Log "Warning: Could not backup current state of $($backupFile.OriginalPath): $($_.Exception.Message)" -Level Warning
                    }
                }
            }
        }

        # Perform restoration
        $restoredCount = 0
        $failedCount = 0

        foreach ($backupFile in $manifest.BackupFiles) {
            # Check if selective restore is requested
            if ($SelectiveRestore.Count -gt 0) {
                $shouldRestore = $false
                foreach ($pattern in $SelectiveRestore) {
                    if ($backupFile.OriginalPath -like "*$pattern*") {
                        $shouldRestore = $true
                        break
                    }
                }
                if (-not $shouldRestore) {
                    continue
                }
            }

            $fileRestoreResult = Restore-SingleFile -BackupFile $backupFile -BackupDir $BackupDir

            if ($fileRestoreResult.Success) {
                $restoreResult.RestoredFiles += $fileRestoreResult
                $restoredCount++
                Write-Log "Successfully restored: $($backupFile.OriginalPath)" -Level Success
            }
            else {
                $restoreResult.FailedFiles += $fileRestoreResult
                $failedCount++
                Write-Log "Failed to restore $($backupFile.OriginalPath): $($fileRestoreResult.Error)" -Level Error
            }
        }

        $restoreResult.EndTime = Get-Date
        $restoreResult.Success = ($failedCount -eq 0)

        Write-Log "Restore completed. Restored: $restoredCount, Failed: $failedCount" -Level Info

        if ($restoreResult.Success) {
            Write-Log "Configuration restore completed successfully" -Level Success
        }
        else {
            Write-Log "Configuration restore completed with errors" -Level Warning
            if ($restoreResult.RestorePointPath) {
                Write-Log "Restore point available at: $($restoreResult.RestorePointPath)" -Level Info
            }
        }

        return $restoreResult
    }
    catch {
        $restoreResult.ValidationErrors += "Critical error during restore: $($_.Exception.Message)"
        $restoreResult.EndTime = Get-Date
        Write-Log $restoreResult.ValidationErrors[-1] -Level Error
        return $restoreResult
    }
}

function Restore-SingleFile {
    <#
    .SYNOPSIS
        Restores a single file with error handling
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$BackupFile,

        [Parameter(Mandatory = $true)]
        [string]$BackupDir
    )

    $result = @{
        Success = $false
        OriginalPath = $BackupFile.OriginalPath
        BackupPath = $BackupFile.BackupPath
        Error = $null
        RestoreTime = Get-Date
    }

    try {
        $backupPath = $BackupFile.BackupPath
        $originalPath = $BackupFile.OriginalPath

        # Validate backup file exists
        if (-not (Test-Path $backupPath)) {
            $result.Error = "Backup file not found: $backupPath"
            return $result
        }

        # Ensure target directory exists
        $targetDir = Split-Path $originalPath -Parent
        if (-not (Test-Path $targetDir)) {
            try {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                Write-Log "Created directory: $targetDir" -Level Debug
            }
            catch {
                $result.Error = "Failed to create target directory $targetDir : $($_.Exception.Message)"
                return $result
            }
        }

        # Check if target file is in use
        if (Test-Path $originalPath) {
            try {
                $fileStream = [System.IO.File]::Open($originalPath, 'Open', 'Write')
                $fileStream.Close()
            }
            catch {
                $result.Error = "Target file is in use and cannot be overwritten: $originalPath"
                return $result
            }
        }

        # Perform the restore
        try {
            Copy-Item -Path $backupPath -Destination $originalPath -Force

            # Verify the restore
            if (Test-Path $originalPath) {
                $originalSize = (Get-Item $backupPath).Length
                $restoredSize = (Get-Item $originalPath).Length

                if ($originalSize -eq $restoredSize) {
                    $result.Success = $true
                }
                else {
                    $result.Error = "File size mismatch after restore. Expected: $originalSize, Actual: $restoredSize"
                }
            }
            else {
                $result.Error = "File was not created at target location after copy operation"
            }
        }
        catch {
            $result.Error = "Copy operation failed: $($_.Exception.Message)"
        }

        return $result
    }
    catch {
        $result.Error = "Critical error during file restore: $($_.Exception.Message)"
        return $result
    }
}

function Test-BackupIntegrity {
    <#
    .SYNOPSIS
        Tests the integrity of a backup
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupDir,

        [Parameter(Mandatory = $true)]
        [object]$Manifest
    )

    $result = @{
        Success = $true
        Errors = @()
        MissingFiles = @()
        CorruptFiles = @()
        ValidatedFiles = 0
    }

    try {
        Write-Log "Validating backup integrity..." -Level Info

        foreach ($backupFile in $Manifest.BackupFiles) {
            $backupPath = $backupFile.BackupPath

            # Check if backup file exists
            if (-not (Test-Path $backupPath)) {
                $result.MissingFiles += $backupPath
                $result.Errors += "Missing backup file: $backupPath"
                $result.Success = $false
                continue
            }

            # Check file size if available in manifest
            if ($backupFile.FileSize) {
                $actualSize = (Get-Item $backupPath).Length
                if ($actualSize -ne $backupFile.FileSize) {
                    $result.CorruptFiles += $backupPath
                    $result.Errors += "File size mismatch for $backupPath. Expected: $($backupFile.FileSize), Actual: $actualSize"
                    $result.Success = $false
                    continue
                }
            }

            $result.ValidatedFiles++
        }

        if ($result.Success) {
            Write-Log "Backup integrity validation passed. Validated $($result.ValidatedFiles) files." -Level Success
        }
        else {
            Write-Log "Backup integrity validation failed. Missing: $($result.MissingFiles.Count), Corrupt: $($result.CorruptFiles.Count)" -Level Error
        }

        return $result
    }
    catch {
        $result.Success = $false
        $result.Errors += "Critical error during backup validation: $($_.Exception.Message)"
        return $result
    }
}

function Update-BackupManifest {
    <#
    .SYNOPSIS
        Updates the backup manifest with a new backup entry
    
    .PARAMETER BackupDir
        Backup directory containing the manifest
    
    .PARAMETER OriginalPath
        Original path of the backed up file
    
    .PARAMETER BackupPath
        Path where the file was backed up
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupDir,
        
        [Parameter(Mandatory = $true)]
        [string]$OriginalPath,
        
        [Parameter(Mandatory = $true)]
        [string]$BackupPath
    )
    
    try {
        $manifestPath = Join-Path $BackupDir "backup-manifest.json"
        
        if (Test-Path $manifestPath) {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
        }
        else {
            Write-Log "Manifest file not found, creating new one" -Level Warning
            return
        }
        
        # Add backup entry
        $backupEntry = @{
            OriginalPath = $OriginalPath
            BackupPath = $BackupPath
            BackupTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            FileSize = (Get-Item $BackupPath).Length
        }
        
        $manifest.BackupFiles += $backupEntry
        
        # Save updated manifest
        $manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $manifestPath -Encoding UTF8
        
        Write-Log "Updated backup manifest with entry for $OriginalPath" -Level Debug
    }
    catch {
        Write-Log "Failed to update backup manifest: $($_.Exception.Message)" -Level Error
    }
}

function Get-TerminalConfigPath {
    <#
    .SYNOPSIS
        Gets the Windows Terminal configuration file path
    #>
    [CmdletBinding()]
    param()
    
    # Try to find Windows Terminal settings.json
    $possiblePaths = @(
        # Windows Terminal (Store version)
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
        # Windows Terminal Preview (Store version)
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json",
        # Windows Terminal (Portable/Unpackaged)
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            Write-Log "Found Windows Terminal config: $path" -Level Debug
            return $path
        }
    }
    
    Write-Log "Windows Terminal configuration file not found" -Level Warning
    return $null
}

function Backup-WindowsTerminalConfig {
    <#
    .SYNOPSIS
        Backs up Windows Terminal configuration
    
    .PARAMETER BackupDir
        Backup directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupDir
    )
    
    $configPath = Get-TerminalConfigPath
    if ($configPath) {
        return Backup-Configuration -ConfigPath $configPath -BackupDir $BackupDir -BackupName "windows-terminal-settings.json.backup"
    }
    else {
        Write-Log "No Windows Terminal configuration to backup" -Level Warning
        return $false
    }
}

function Backup-PowerShellProfile {
    <#
    .SYNOPSIS
        Backs up PowerShell profile
    
    .PARAMETER BackupDir
        Backup directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupDir
    )
    
    $profiles = @(
        $PROFILE,  # Current PowerShell profile
        "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",  # Windows PowerShell 5.1
        "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"  # PowerShell 7+
    )
    
    $backedUp = $false
    
    foreach ($profilePath in $profiles) {
        if (Test-Path $profilePath) {
            $profileName = Split-Path $profilePath -Leaf
            $backupName = "$profileName.backup"
            
            if (Backup-Configuration -ConfigPath $profilePath -BackupDir $BackupDir -BackupName $backupName) {
                $backedUp = $true
                Write-Log "Backed up PowerShell profile: $profilePath" -Level Success
            }
        }
    }
    
    if (-not $backedUp) {
        Write-Log "No PowerShell profiles found to backup" -Level Warning
    }
    
    return $backedUp
}

function Backup-GitConfig {
    <#
    .SYNOPSIS
        Backs up Git configuration
    
    .PARAMETER BackupDir
        Backup directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupDir
    )
    
    $gitConfigPath = Join-Path $env:USERPROFILE ".gitconfig"
    
    if (Test-Path $gitConfigPath) {
        return Backup-Configuration -ConfigPath $gitConfigPath -BackupDir $BackupDir -BackupName "gitconfig.backup"
    }
    else {
        Write-Log "No Git configuration to backup" -Level Warning
        return $false
    }
}

function Backup-AllConfigurations {
    <#
    .SYNOPSIS
        Backs up all relevant configurations
    
    .PARAMETER BackupDir
        Backup directory (will be created if not specified)
    #>
    [CmdletBinding()]
    param(
        [string]$BackupDir = $null
    )
    
    if (-not $BackupDir) {
        $BackupDir = New-BackupDirectory
        if (-not $BackupDir) {
            Write-Log "Failed to create backup directory" -Level Error
            return $false
        }
    }
    
    Write-Log "Starting comprehensive configuration backup..." -Level Info
    
    $backupResults = @{
        WindowsTerminal = Backup-WindowsTerminalConfig -BackupDir $BackupDir
        PowerShellProfile = Backup-PowerShellProfile -BackupDir $BackupDir
        GitConfig = Backup-GitConfig -BackupDir $BackupDir
    }
    
    $successCount = ($backupResults.Values | Where-Object { $_ -eq $true }).Count
    $totalCount = $backupResults.Count
    
    Write-Log "Backup completed: $successCount/$totalCount configurations backed up" -Level Info
    Write-Log "Backup location: $BackupDir" -Level Success
    
    return $BackupDir
}

function Remove-BackupDirectory {
    <#
    .SYNOPSIS
        Removes a backup directory
    
    .PARAMETER BackupDir
        Backup directory to remove
    
    .PARAMETER Force
        Force removal without confirmation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupDir,
        
        [switch]$Force
    )
    
    try {
        if (-not (Test-Path $BackupDir)) {
            Write-Log "Backup directory does not exist: $BackupDir" -Level Warning
            return $true
        }
        
        if (-not $Force) {
            $confirmation = Read-Host "Are you sure you want to remove backup directory '$BackupDir'? (y/N)"
            if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
                Write-Log "Backup removal cancelled by user" -Level Info
                return $false
            }
        }
        
        Remove-Item -Path $BackupDir -Recurse -Force
        Write-Log "Backup directory removed: $BackupDir" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to remove backup directory: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-BackupDirectories {
    <#
    .SYNOPSIS
        Lists all available backup directories
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not (Test-Path $script:BackupRootDir)) {
            Write-Log "No backup root directory found: $script:BackupRootDir" -Level Info
            return @()
        }
        
        $backupDirs = Get-ChildItem -Path $script:BackupRootDir -Directory | Sort-Object Name -Descending
        
        $backupInfo = @()
        foreach ($dir in $backupDirs) {
            $manifestPath = Join-Path $dir.FullName "backup-manifest.json"
            if (Test-Path $manifestPath) {
                $manifest = Get-Content $manifestPath | ConvertFrom-Json
                $backupInfo += @{
                    Path = $dir.FullName
                    Name = $dir.Name
                    Date = $manifest.BackupDate
                    FileCount = $manifest.BackupFiles.Count
                }
            }
            else {
                $backupInfo += @{
                    Path = $dir.FullName
                    Name = $dir.Name
                    Date = $dir.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                    FileCount = "Unknown"
                }
            }
        }
        
        return $backupInfo
    }
    catch {
        Write-Log "Failed to get backup directories: $($_.Exception.Message)" -Level Error
        return @()
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'New-BackupDirectory',
    'Backup-Configuration',
    'Restore-Configuration',
    'Get-TerminalConfigPath',
    'Backup-WindowsTerminalConfig',
    'Backup-PowerShellProfile',
    'Backup-GitConfig',
    'Backup-AllConfigurations',
    'Remove-BackupDirectory',
    'Get-BackupDirectories'
)
