# GitInstaller.psm1 - Git installation and configuration for Windows Terminal Setup

# Import required modules
Import-Module (Join-Path $PSScriptRoot "..\Core\Logger.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\Core\PackageManager.psm1") -Force

function Install-Git {
    <#
    .SYNOPSIS
        Installs Git using the best available package manager with comprehensive error handling

    .PARAMETER Force
        Force installation even if Git is already installed

    .PARAMETER RetryCount
        Number of retry attempts if installation fails (default: 2)

    .PARAMETER Timeout
        Timeout in seconds for installation process (default: 300)
    #>
    [CmdletBinding()]
    param(
        [switch]$Force,
        [int]$RetryCount = 2,
        [int]$Timeout = 300
    )

    $installationAttempts = 0
    $maxAttempts = $RetryCount + 1

    while ($installationAttempts -lt $maxAttempts) {
        $installationAttempts++

        try {
            Write-Log "Git installation attempt $installationAttempts of $maxAttempts" -Level Info

            # Pre-installation validation
            if (-not $Force -and (Test-GitInstalled)) {
                $existingVersion = Get-GitVersion
                Write-Log "Git is already installed: $existingVersion" -Level Success
                return @{ Success = $true; Message = "Git already installed"; Version = $existingVersion }
            }

            # Check system requirements
            $systemCheck = Test-GitSystemRequirements
            if (-not $systemCheck.Success) {
                throw "System requirements not met: $($systemCheck.Message)"
            }

            Write-Log "Installing Git (attempt $installationAttempts)..." -Level Info

            # Create installation context for rollback
            $installContext = New-InstallationContext -ToolName "Git"

            try {
                # Use the PackageManager module to install Git with timeout
                $installJob = Start-Job -ScriptBlock {
                    param($ToolName, $Force)
                    Import-Module $using:PSScriptRoot\..\Core\PackageManager.psm1 -Force
                    Install-Tool -ToolName $ToolName -Force:$Force
                } -ArgumentList "git", $Force

                $result = Wait-Job $installJob -Timeout $Timeout | Receive-Job
                Remove-Job $installJob -Force

                if ($result) {
                    Write-Log "Git package installation completed" -Level Success

                    # Post-installation verification with retry
                    $verificationResult = Test-GitInstallationWithRetry -MaxRetries 3 -DelaySeconds 5

                    if ($verificationResult.Success) {
                        Write-Log "Git installation verified successfully: $($verificationResult.Version)" -Level Success
                        Complete-InstallationContext -Context $installContext -Success $true
                        return @{
                            Success = $true
                            Message = "Git installed and verified successfully"
                            Version = $verificationResult.Version
                            AttemptNumber = $installationAttempts
                        }
                    }
                    else {
                        throw "Git installation verification failed: $($verificationResult.Message)"
                    }
                }
                else {
                    throw "Git package installation returned false"
                }
            }
            catch {
                # Rollback on failure
                Write-Log "Rolling back Git installation due to error: $($_.Exception.Message)" -Level Warning
                Rollback-InstallationContext -Context $installContext
                throw
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Log "Git installation attempt $installationAttempts failed: $errorMessage" -Level Error

            if ($installationAttempts -lt $maxAttempts) {
                $waitTime = [Math]::Min(30, $installationAttempts * 10)
                Write-Log "Waiting $waitTime seconds before retry..." -Level Warning
                Start-Sleep -Seconds $waitTime
            }
            else {
                # Final failure - provide troubleshooting information
                $troubleshootingInfo = Get-GitTroubleshootingInfo
                Write-Log "Git installation failed after $maxAttempts attempts" -Level Error
                Write-Log "Troubleshooting information:" -Level Info
                foreach ($info in $troubleshootingInfo) {
                    Write-Log "  - $info" -Level Info
                }

                return @{
                    Success = $false
                    Message = "Git installation failed after $maxAttempts attempts: $errorMessage"
                    TroubleshootingInfo = $troubleshootingInfo
                    AttemptNumber = $installationAttempts
                }
            }
        }
    }
}

function Test-GitInstalled {
    <#
    .SYNOPSIS
        Tests if Git is installed and working with enhanced validation
    #>
    [CmdletBinding()]
    param()

    try {
        $gitCommand = Get-Command git -ErrorAction Stop
        $version = git --version 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Log "Git detected: $version" -Level Debug
            return $true
        }
        else {
            Write-Log "Git command failed with exit code: $LASTEXITCODE" -Level Debug
            return $false
        }
    }
    catch {
        Write-Log "Git not found: $($_.Exception.Message)" -Level Debug
        return $false
    }
}

function Get-GitVersion {
    <#
    .SYNOPSIS
        Gets the installed Git version
    #>
    [CmdletBinding()]
    param()

    try {
        if (Test-GitInstalled) {
            $version = git --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $version.ToString().Trim()
            }
        }
        return $null
    }
    catch {
        return $null
    }
}

function Test-GitSystemRequirements {
    <#
    .SYNOPSIS
        Tests if system meets Git installation requirements
    #>
    [CmdletBinding()]
    param()

    try {
        $requirements = @{
            Success = $true
            Message = ""
            Details = @()
        }

        # Check Windows version
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $buildNumber = [int]$osInfo.BuildNumber

        if ($buildNumber -lt 10240) {  # Windows 10 minimum
            $requirements.Success = $false
            $requirements.Message += "Windows 10 or later required. "
            $requirements.Details += "Current build: $buildNumber, Required: 10240+"
        }

        # Check available disk space (Git needs ~300MB)
        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)

        if ($freeSpaceGB -lt 1) {
            $requirements.Success = $false
            $requirements.Message += "Insufficient disk space. "
            $requirements.Details += "Available: $freeSpaceGB GB, Required: 1 GB"
        }

        # Check if running in compatible shell
        if ($env:TERM -eq "dumb") {
            $requirements.Details += "Warning: Running in limited terminal environment"
        }

        if ($requirements.Success) {
            $requirements.Message = "System requirements met"
        }

        return $requirements
    }
    catch {
        return @{
            Success = $false
            Message = "Failed to check system requirements: $($_.Exception.Message)"
            Details = @()
        }
    }
}

function Test-GitInstallationWithRetry {
    <#
    .SYNOPSIS
        Tests Git installation with retry logic
    #>
    [CmdletBinding()]
    param(
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 5
    )

    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            Write-Log "Verifying Git installation (attempt $i of $MaxRetries)..." -Level Debug

            if (Test-GitInstalled) {
                $version = Get-GitVersion

                # Additional validation - test basic Git functionality
                $tempDir = Join-Path $env:TEMP "git-test-$(Get-Random)"
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

                try {
                    Push-Location $tempDir
                    $initResult = git init 2>&1

                    if ($LASTEXITCODE -eq 0) {
                        Write-Log "Git functionality test passed" -Level Debug
                        return @{
                            Success = $true
                            Version = $version
                            Message = "Git installation verified and functional"
                        }
                    }
                    else {
                        throw "Git init failed: $initResult"
                    }
                }
                finally {
                    Pop-Location
                    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }

            if ($i -lt $MaxRetries) {
                Write-Log "Git verification failed, retrying in $DelaySeconds seconds..." -Level Warning
                Start-Sleep -Seconds $DelaySeconds
            }
        }
        catch {
            Write-Log "Git verification attempt $i failed: $($_.Exception.Message)" -Level Warning
            if ($i -lt $MaxRetries) {
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }

    return @{
        Success = $false
        Version = $null
        Message = "Git installation verification failed after $MaxRetries attempts"
    }
}

function Get-GitTroubleshootingInfo {
    <#
    .SYNOPSIS
        Provides troubleshooting information for Git installation issues
    #>
    [CmdletBinding()]
    param()

    $troubleshooting = @()

    try {
        # Check if Git is in PATH
        $gitInPath = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitInPath) {
            $troubleshooting += "Git not found in PATH. Try restarting your terminal or running 'refreshenv'"
        }

        # Check common installation locations
        $commonPaths = @(
            "${env:ProgramFiles}\Git\bin\git.exe",
            "${env:ProgramFiles(x86)}\Git\bin\git.exe",
            "$env:LOCALAPPDATA\Programs\Git\bin\git.exe"
        )

        $foundPaths = $commonPaths | Where-Object { Test-Path $_ }
        if ($foundPaths) {
            $troubleshooting += "Git found at: $($foundPaths -join ', ')"
            $troubleshooting += "Add Git to PATH or restart terminal"
        }

        # Check package manager status
        $packageManagers = @("winget", "choco", "scoop")
        foreach ($pm in $packageManagers) {
            if (Get-Command $pm -ErrorAction SilentlyContinue) {
                $troubleshooting += "Try manual installation: $pm install git"
            }
        }

        # Check Windows version
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        if ([int]$osInfo.BuildNumber -lt 10240) {
            $troubleshooting += "Windows version may be too old. Consider updating Windows"
        }

        # Check antivirus interference
        $troubleshooting += "Check if antivirus software is blocking the installation"
        $troubleshooting += "Try running PowerShell as Administrator"
        $troubleshooting += "Manual download: https://git-scm.com/download/win"

        return $troubleshooting
    }
    catch {
        return @("Unable to generate troubleshooting information: $($_.Exception.Message)")
    }
}

function Configure-Git {
    <#
    .SYNOPSIS
        Configures Git with user information and recommended settings
    
    .PARAMETER UserName
        Git user name
    
    .PARAMETER UserEmail
        Git user email
    
    .PARAMETER Interactive
        Prompt for user input if parameters not provided
    #>
    [CmdletBinding()]
    param(
        [string]$UserName = "",
        [string]$UserEmail = "",
        [switch]$Interactive
    )
    
    try {
        if (-not (Test-GitInstalled)) {
            Write-Log "Git is not installed. Cannot configure." -Level Error
            return $false
        }
        
        Write-Log "Configuring Git..." -Level Info
        
        # Get user information if not provided
        if ($Interactive -or (-not $UserName -or -not $UserEmail)) {
            if (-not $UserName) {
                $UserName = Read-Host "Enter your Git username"
            }
            if (-not $UserEmail) {
                $UserEmail = Read-Host "Enter your Git email"
            }
        }
        
        # Set user configuration if provided
        if ($UserName) {
            Write-Log "Setting Git user.name to: $UserName" -Level Info
            git config --global user.name $UserName
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to set Git user.name" -Level Error
                return $false
            }
        }
        
        if ($UserEmail) {
            Write-Log "Setting Git user.email to: $UserEmail" -Level Info
            git config --global user.email $UserEmail
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to set Git user.email" -Level Error
                return $false
            }
        }
        
        # Set recommended Git configurations
        $gitConfigs = @{
            "init.defaultBranch" = "main"
            "core.autocrlf" = "true"
            "core.editor" = "code --wait"
            "pull.rebase" = "false"
            "credential.helper" = "manager-core"
            "core.longpaths" = "true"
        }
        
        foreach ($config in $gitConfigs.GetEnumerator()) {
            Write-Log "Setting Git $($config.Key) to: $($config.Value)" -Level Debug
            git config --global $config.Key $config.Value
            
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Warning: Failed to set Git $($config.Key)" -Level Warning
            }
        }
        
        Write-Log "Git configuration completed successfully" -Level Success
        return $true
    }
    catch {
        Write-Log "Exception during Git configuration: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-GitConfiguration {
    <#
    .SYNOPSIS
        Gets current Git configuration
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not (Test-GitInstalled)) {
            Write-Log "Git is not installed" -Level Warning
            return $null
        }
        
        $config = @{}
        
        # Get user configuration
        $userName = git config --global user.name 2>$null
        $userEmail = git config --global user.email 2>$null
        
        if ($userName) { $config["user.name"] = $userName }
        if ($userEmail) { $config["user.email"] = $userEmail }
        
        # Get other important configurations
        $importantConfigs = @(
            "init.defaultBranch",
            "core.autocrlf",
            "core.editor",
            "pull.rebase",
            "credential.helper",
            "core.longpaths"
        )
        
        foreach ($configKey in $importantConfigs) {
            $value = git config --global $configKey 2>$null
            if ($value) {
                $config[$configKey] = $value
            }
        }
        
        return $config
    }
    catch {
        Write-Log "Failed to get Git configuration: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Test-GitConfiguration {
    <#
    .SYNOPSIS
        Tests if Git is properly configured
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not (Test-GitInstalled)) {
            Write-Log "Git is not installed" -Level Error
            return $false
        }
        
        $config = Get-GitConfiguration
        
        if (-not $config) {
            Write-Log "Failed to retrieve Git configuration" -Level Error
            return $false
        }
        
        # Check required configurations
        $requiredConfigs = @("user.name", "user.email")
        $missingConfigs = @()
        
        foreach ($required in $requiredConfigs) {
            if (-not $config.ContainsKey($required) -or -not $config[$required]) {
                $missingConfigs += $required
            }
        }
        
        if ($missingConfigs.Count -gt 0) {
            Write-Log "Missing Git configurations: $($missingConfigs -join ', ')" -Level Warning
            return $false
        }
        
        Write-Log "Git is properly configured" -Level Success
        return $true
    }
    catch {
        Write-Log "Exception during Git configuration test: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Install-GitCredentialManager {
    <#
    .SYNOPSIS
        Installs Git Credential Manager if not already installed
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Checking Git Credential Manager..." -Level Info
        
        # Check if Git Credential Manager is already configured
        $credentialHelper = git config --global credential.helper 2>$null
        
        if ($credentialHelper -and $credentialHelper -like "*manager*") {
            Write-Log "Git Credential Manager is already configured: $credentialHelper" -Level Success
            return $true
        }
        
        # Try to install Git Credential Manager
        Write-Log "Installing Git Credential Manager..." -Level Info
        
        # Check if winget is available
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $result = winget install Microsoft.GitCredentialManagerCore --accept-package-agreements --accept-source-agreements 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Git Credential Manager installed successfully" -Level Success
                
                # Configure it
                git config --global credential.helper manager-core
                return $true
            }
        }
        
        # Fallback: Set to manager-core (should work if Git for Windows is installed)
        Write-Log "Setting credential helper to manager-core..." -Level Info
        git config --global credential.helper manager-core
        
        Write-Log "Git Credential Manager configuration completed" -Level Success
        return $true
    }
    catch {
        Write-Log "Exception during Git Credential Manager installation: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Show-GitStatus {
    <#
    .SYNOPSIS
        Shows Git installation and configuration status
    #>
    [CmdletBinding()]
    param()
    
    Write-Host ""
    Write-Host "Git Status:" -ForegroundColor Cyan
    Write-Host "===========" -ForegroundColor Cyan
    
    # Check installation
    if (Test-GitInstalled) {
        $version = git --version
        Write-Host "✅ Git installed: $version" -ForegroundColor Green
        
        # Check configuration
        $config = Get-GitConfiguration
        
        if ($config -and $config.ContainsKey("user.name") -and $config.ContainsKey("user.email")) {
            Write-Host "✅ Git configured:" -ForegroundColor Green
            Write-Host "   User: $($config['user.name']) <$($config['user.email'])>" -ForegroundColor Green
            
            # Show other configurations
            $otherConfigs = $config.GetEnumerator() | Where-Object { $_.Key -notin @("user.name", "user.email") }
            if ($otherConfigs) {
                Write-Host "   Additional settings:" -ForegroundColor Green
                foreach ($cfg in $otherConfigs) {
                    Write-Host "     $($cfg.Key): $($cfg.Value)" -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host "⚠️  Git not fully configured (missing user.name or user.email)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "❌ Git not installed" -ForegroundColor Red
    }
    
    Write-Host ""
}

function New-InstallationContext {
    <#
    .SYNOPSIS
        Creates a new installation context for rollback tracking
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    $context = @{
        ToolName = $ToolName
        StartTime = Get-Date
        PreInstallState = @{}
        InstallActions = @()
        TempFiles = @()
        RegistryChanges = @()
        PathChanges = @()
    }

    # Capture pre-installation state
    try {
        $context.PreInstallState.GitInstalled = Test-GitInstalled
        $context.PreInstallState.GitVersion = Get-GitVersion
        $context.PreInstallState.PathVariable = $env:PATH

        Write-Log "Installation context created for $ToolName" -Level Debug
    }
    catch {
        Write-Log "Warning: Could not fully capture pre-installation state: $($_.Exception.Message)" -Level Warning
    }

    return $context
}

function Complete-InstallationContext {
    <#
    .SYNOPSIS
        Marks an installation context as successfully completed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context,

        [Parameter(Mandatory = $true)]
        [bool]$Success
    )

    $Context.EndTime = Get-Date
    $Context.Success = $Success
    $Context.Duration = $Context.EndTime - $Context.StartTime

    if ($Success) {
        Write-Log "Installation context completed successfully for $($Context.ToolName) in $($Context.Duration.TotalSeconds) seconds" -Level Success
    }
    else {
        Write-Log "Installation context marked as failed for $($Context.ToolName)" -Level Error
    }
}

function Rollback-InstallationContext {
    <#
    .SYNOPSIS
        Rolls back changes made during installation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )

    try {
        Write-Log "Starting rollback for $($Context.ToolName)..." -Level Warning

        # Clean up temporary files
        foreach ($tempFile in $Context.TempFiles) {
            if (Test-Path $tempFile) {
                Remove-Item -Path $tempFile -Force -Recurse -ErrorAction SilentlyContinue
                Write-Log "Removed temporary file: $tempFile" -Level Debug
            }
        }

        # Restore PATH if changed
        if ($Context.PathChanges.Count -gt 0) {
            $env:PATH = $Context.PreInstallState.PathVariable
            Write-Log "Restored PATH variable" -Level Debug
        }

        # Note: Package uninstallation is typically not performed automatically
        # as it may affect other dependencies. Users should manually uninstall if needed.

        Write-Log "Rollback completed for $($Context.ToolName)" -Level Success
    }
    catch {
        Write-Log "Rollback failed for $($Context.ToolName): $($_.Exception.Message)" -Level Error
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Install-Git',
    'Test-GitInstalled',
    'Configure-Git',
    'Get-GitConfiguration',
    'Test-GitConfiguration',
    'Install-GitCredentialManager',
    'Show-GitStatus',
    'Get-GitVersion',
    'Test-GitSystemRequirements',
    'Test-GitInstallationWithRetry',
    'Get-GitTroubleshootingInfo',
    'New-InstallationContext',
    'Complete-InstallationContext',
    'Rollback-InstallationContext'
)
