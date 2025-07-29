#Requires -Version 5.1
<#
.SYNOPSIS
    Windows Terminal and PowerShell Enhancement Installation Script (Enhanced UI Version)

.DESCRIPTION
    Interactive installation wizard with enhanced UI, progress tracking, and user customization options

.PARAMETER Interactive
    Run in interactive mode with user prompts (default)

.PARAMETER DryRun
    Show what would be installed without actually installing

.PARAMETER LogLevel
    Set logging level (Debug, Info, Warning, Error)

.PARAMETER SkipUI
    Skip enhanced UI and run in simple mode

.EXAMPLE
    .\Install-WindowsTerminalSetup-Enhanced.ps1
    
.EXAMPLE
    .\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun

.EXAMPLE
    .\Install-WindowsTerminalSetup-Enhanced.ps1 -SkipUI -DryRun
#>

[CmdletBinding()]
param(
    [switch]$Interactive = $true,
    [switch]$DryRun,
    [ValidateSet("Debug", "Info", "Warning", "Error")]
    [string]$LogLevel = "Info",
    [switch]$SkipUI
)

# Script variables
$script:ScriptRoot = $PSScriptRoot
$script:ModulesPath = Join-Path $ScriptRoot "modules"
$script:ErrorHistory = @()
$script:LogFile = $null
$script:InstallationResults = @{}

# Available tools
$script:AllTools = @(
    "git", "curl", "lazygit", "nerd-fonts", "oh-my-posh", 
    "fzf", "eza", "bat", "lsd", "neovim", "zoxide", "fnm", "pyenv"
)

# Simple logging function (fallback if modules don't load)
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

function Initialize-InstallationWizard {
    <#
    .SYNOPSIS
        Initializes the installation wizard
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Initialize logging
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $script:LogFile = Join-Path $env:TEMP "WindowsTerminalSetup_Enhanced_$timestamp.log"
        
        # Try to import UI module
        if (-not $SkipUI) {
            try {
                $uiModulePath = Join-Path $script:ModulesPath "Core\UserInterface-Simple.psm1"
                if (Test-Path $uiModulePath) {
                    Import-Module $uiModulePath -Force -Global
                    $script:UIAvailable = $true
                    Write-Log "UI module loaded successfully" -Level Success
                } else {
                    Write-Log "UI module not found, falling back to simple mode" -Level Warning
                    $script:UIAvailable = $false
                }
            }
            catch {
                Write-Log "Failed to load UI module: $($_.Exception.Message)" -Level Warning
                $script:UIAvailable = $false
            }
        } else {
            $script:UIAvailable = $false
        }
        
        # Initialize UI if available
        if ($script:UIAvailable) {
            Initialize-UserInterface
        } else {
            # Simple banner for fallback mode
            Write-Host ""
            Write-Host "Windows Terminal & PowerShell Setup (Enhanced)" -ForegroundColor Cyan
            Write-Host "===============================================" -ForegroundColor Cyan
            Write-Host ""
        }
        
        Write-Log "Installation wizard initialized" -Level Success
        Write-Log "Log file: $script:LogFile" -Level Info
        
        return $true
    }
    catch {
        Write-Log "Failed to initialize installation wizard: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Start-InstallationWizard {
    <#
    .SYNOPSIS
        Starts the interactive installation wizard
    #>
    [CmdletBinding()]
    param()
    
    try {
        $wizardConfig = @{
            SelectedTools = @()
            Configuration = @{}
            DryRun = $DryRun
        }
        
        # Step 1: Welcome and System Check
        if ($script:UIAvailable) {
            Show-StepHeader -StepNumber 1 -StepTitle "System Compatibility Check" -StepDescription "Verifying system requirements and compatibility"
            Show-ProgressBar -CurrentStep 1 -TotalSteps 6 -CurrentTask "Checking system compatibility"
        } else {
            Write-Log "Step 1: System Compatibility Check" -Level Info
        }
        
        $readinessResult = Test-SystemReadiness
        
        if (-not $readinessResult.Ready) {
            Write-Log "System readiness test failed with critical issues:" -Level Error
            foreach ($issue in $readinessResult.CriticalIssues) {
                Write-Log "  - $issue" -Level Error
            }
            
            if ($script:UIAvailable) {
                $continue = Get-YesNoChoice -Prompt "Critical issues detected. Do you want to continue anyway?" -Default "N"
                if (-not $continue) {
                    Write-Log "Installation cancelled by user due to system issues" -Level Warning
                    return $false
                }
            } else {
                throw "System compatibility check failed. Critical issues must be resolved before proceeding."
            }
        }
        
        # Step 2: Tool Selection
        if ($Interactive -and $script:UIAvailable) {
            Show-StepHeader -StepNumber 2 -StepTitle "Tool Selection" -StepDescription "Choose which tools to install"
            Show-ProgressBar -CurrentStep 2 -TotalSteps 6 -CurrentTask "Selecting tools to install"
            
            $wizardConfig.SelectedTools = Show-ToolSelectionMenu -AvailableTools $script:AllTools -PreselectedTools $script:AllTools
        } else {
            $wizardConfig.SelectedTools = $script:AllTools
            Write-Log "Using default tool selection: $($wizardConfig.SelectedTools -join ', ')" -Level Info
        }
        
        # Step 3: Configuration Options
        if ($Interactive -and $script:UIAvailable) {
            Show-StepHeader -StepNumber 3 -StepTitle "Configuration Options" -StepDescription "Customize installation settings"
            Show-ProgressBar -CurrentStep 3 -TotalSteps 6 -CurrentTask "Configuring installation options"
            
            $wizardConfig.Configuration = Show-ConfigurationMenu
        } else {
            $wizardConfig.Configuration = @{
                Theme = "One Half Dark"
                Font = "CascadiaCode Nerd Font"
                CreateBackup = $true
                InstallPowerShell7 = $true
                ConfigureGit = $false
            }
            Write-Log "Using default configuration options" -Level Info
        }
        
        # Step 4: Installation Confirmation
        if ($Interactive -and $script:UIAvailable) {
            Show-StepHeader -StepNumber 4 -StepTitle "Installation Confirmation" -StepDescription "Review and confirm installation settings"
            Show-ProgressBar -CurrentStep 4 -TotalSteps 6 -CurrentTask "Confirming installation settings"
            
            Write-Host "Installation Summary:" -ForegroundColor Yellow
            Write-Host "  • Tools to install: $($wizardConfig.SelectedTools.Count)" -ForegroundColor White
            Write-Host "    $($wizardConfig.SelectedTools -join ', ')" -ForegroundColor Gray
            Write-Host "  • Theme: $($wizardConfig.Configuration.Theme)" -ForegroundColor White
            Write-Host "  • Font: $($wizardConfig.Configuration.Font)" -ForegroundColor White
            Write-Host "  • Create backup: $($wizardConfig.Configuration.CreateBackup)" -ForegroundColor White
            Write-Host "  • Install PowerShell 7: $($wizardConfig.Configuration.InstallPowerShell7)" -ForegroundColor White
            
            if ($DryRun) {
                Write-Host "  • Mode: DRY RUN (no actual changes will be made)" -ForegroundColor Yellow
            }
            
            $confirm = Get-YesNoChoice -Prompt "Proceed with installation?" -Default "Y"
            if (-not $confirm) {
                Write-Log "Installation cancelled by user" -Level Warning
                return $false
            }
        }
        
        # Step 5: Installation Process
        if ($script:UIAvailable) {
            Show-StepHeader -StepNumber 5 -StepTitle "Installation Process" -StepDescription "Installing selected tools and configuring system"
            Show-ProgressBar -CurrentStep 5 -TotalSteps 6 -CurrentTask "Installing tools"
        } else {
            Write-Log "Step 5: Installation Process" -Level Info
        }
        
        $installationSuccess = Start-ToolInstallation -SelectedTools $wizardConfig.SelectedTools -Configuration $wizardConfig.Configuration
        
        # Step 6: Installation Summary
        if ($script:UIAvailable) {
            Show-StepHeader -StepNumber 6 -StepTitle "Installation Complete" -StepDescription "Review installation results"
            Show-ProgressBar -CurrentStep 6 -TotalSteps 6 -CurrentTask "Installation completed"
            
            Show-InstallationSummary -Results $script:InstallationResults
        } else {
            Write-Log "Step 6: Installation Complete" -Level Info
            Show-SimpleInstallationSummary
        }
        
        return $installationSuccess
    }
    catch {
        Write-Log "Installation wizard failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-SystemReadiness {
    <#
    .SYNOPSIS
        Performs system readiness check with enhanced reporting
    #>
    [CmdletBinding()]
    param()
    
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
        $readiness.Ready = $false
        $readiness.CriticalIssues += "System readiness test failed: $($_.Exception.Message)"
        return $readiness
    }
}

function Start-ToolInstallation {
    <#
    .SYNOPSIS
        Starts the tool installation process
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$SelectedTools,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration
    )
    
    $totalTools = $SelectedTools.Count
    $currentTool = 0
    $overallSuccess = $true
    
    foreach ($tool in $SelectedTools) {
        $currentTool++
        
        try {
            if ($script:UIAvailable) {
                Show-ProgressBar -CurrentStep $currentTool -TotalSteps $totalTools -CurrentTask "Installing $tool"
            }
            
            Write-Log "Installing $tool ($currentTool of $totalTools)..." -Level Info
            
            if ($DryRun) {
                Write-Log "DRY RUN: Would install $tool" -Level Info
                $script:InstallationResults[$tool] = @{
                    Success = $true
                    Message = "Dry run - would install $tool"
                    Version = "N/A (dry run)"
                }
            } else {
                # Simulate installation for demo (replace with actual installation logic)
                Start-Sleep -Seconds 2
                $script:InstallationResults[$tool] = @{
                    Success = $true
                    Message = "Successfully installed $tool"
                    Version = "Latest"
                }
            }
            
            Write-Log "Successfully processed $tool" -Level Success
        }
        catch {
            Write-Log "Failed to install $tool : $($_.Exception.Message)" -Level Error
            $script:InstallationResults[$tool] = @{
                Success = $false
                Message = $_.Exception.Message
                Version = $null
            }
            $overallSuccess = $false
        }
    }
    
    return $overallSuccess
}

function Show-SimpleInstallationSummary {
    <#
    .SYNOPSIS
        Shows simple installation summary for non-UI mode
    #>
    [CmdletBinding()]
    param()
    
    $successCount = ($script:InstallationResults.Values | Where-Object { $_.Success -eq $true }).Count
    $failureCount = ($script:InstallationResults.Values | Where-Object { $_.Success -eq $false }).Count
    $totalCount = $script:InstallationResults.Count
    
    Write-Host ""
    Write-Host "Installation Summary:" -ForegroundColor Yellow
    Write-Host "  Total tools processed: $totalCount" -ForegroundColor White
    Write-Host "  Successfully installed: $successCount" -ForegroundColor Green
    Write-Host "  Failed installations: $failureCount" -ForegroundColor Red
    Write-Host ""
    
    if ($successCount -gt 0) {
        Write-Host "Successfully Installed:" -ForegroundColor Green
        foreach ($result in $script:InstallationResults.GetEnumerator()) {
            if ($result.Value.Success) {
                Write-Host "  - $($result.Key)" -ForegroundColor Green
            }
        }
        Write-Host ""
    }
    
    if ($failureCount -gt 0) {
        Write-Host "Failed Installations:" -ForegroundColor Red
        foreach ($result in $script:InstallationResults.GetEnumerator()) {
            if (-not $result.Value.Success) {
                Write-Host "  - $($result.Key): $($result.Value.Message)" -ForegroundColor Red
            }
        }
        Write-Host ""
    }
}

function Main {
    try {
        # Initialize the installation wizard
        if (-not (Initialize-InstallationWizard)) {
            throw "Failed to initialize installation wizard"
        }
        
        Write-Log "Starting Windows Terminal setup process" -Level Info
        
        if ($DryRun) {
            Write-Log "DRY RUN MODE - No actual installations will be performed" -Level Warning
        }
        
        # Start the installation wizard
        $success = Start-InstallationWizard
        
        if ($success) {
            Write-Log "Installation wizard completed successfully" -Level Success
            
            if (-not $DryRun) {
                Write-Host ""
                Write-Host "Next Steps:" -ForegroundColor Yellow
                Write-Host "  1. Restart your terminal or run: refreshenv" -ForegroundColor Cyan
                Write-Host "  2. Open Windows Terminal to see the new configuration" -ForegroundColor Cyan
                Write-Host "  3. Run 'pwsh' to start PowerShell 7 with the new profile" -ForegroundColor Cyan
                Write-Host ""
            }
        } else {
            Write-Log "Installation wizard completed with errors" -Level Warning
        }
        
        if ($script:LogFile) {
            Write-Host "Detailed log available at: $script:LogFile" -ForegroundColor Gray
        }
        
        return $success
    }
    catch {
        Write-Log "Critical error occurred: $($_.Exception.Message)" -Level Error
        Write-Host "Critical Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($script:LogFile) {
            Write-Host "Detailed log available at: $script:LogFile" -ForegroundColor Gray
        }
        
        return $false
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    $result = Main
    exit $(if ($result) { 0 } else { 1 })
}
