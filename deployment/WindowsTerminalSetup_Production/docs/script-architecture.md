# Script Architecture Design

## Overview
This document outlines the architecture design for the Windows Terminal and PowerShell installation script, including modular structure, error handling, logging, and user interaction patterns.

## Project Structure
```
windows-terminal-setup/
├── Install-WindowsTerminalSetup.ps1     # Main installation script
├── modules/
│   ├── Core/
│   │   ├── Logger.psm1                  # Logging functionality
│   │   ├── PackageManager.psm1          # Package manager detection/handling
│   │   ├── SystemCheck.psm1             # System compatibility checks
│   │   └── BackupRestore.psm1           # Configuration backup/restore
│   ├── Installers/
│   │   ├── GitInstaller.psm1            # Git installation and configuration
│   │   ├── FontInstaller.psm1           # Nerd Fonts installation
│   │   ├── TerminalInstaller.psm1       # Windows Terminal installation
│   │   ├── PowerShellInstaller.psm1     # PowerShell 7 installation
│   │   ├── CliToolsInstaller.psm1       # CLI tools (eza, bat, fzf, etc.)
│   │   └── DevToolsInstaller.psm1       # Development tools (fnm, pyenv, lazyvim)
│   └── Configurators/
│       ├── TerminalConfigurator.psm1    # Windows Terminal configuration
│       ├── ProfileConfigurator.psm1     # PowerShell profile setup
│       ├── ToolConfigurator.psm1        # Individual tool configurations
│       └── EnvironmentConfigurator.psm1 # Environment variables and PATH
├── configs/
│   ├── terminal-settings.json           # Default Windows Terminal settings
│   ├── powershell-profile.ps1           # Default PowerShell profile
│   ├── oh-my-posh-theme.json           # Custom Oh-My-Posh theme
│   └── tool-configs/                    # Individual tool configuration files
├── docs/
│   ├── requirements-analysis.md
│   ├── installation-methods.md
│   ├── configuration-requirements.md
│   └── script-architecture.md
└── tests/
    ├── Test-Installation.ps1            # Installation validation tests
    ├── Test-Configuration.ps1           # Configuration validation tests
    └── Test-Rollback.ps1               # Rollback functionality tests
```

## Main Script Architecture

### Install-WindowsTerminalSetup.ps1
```powershell
#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$SkipPrerequisites,
    [switch]$SkipBackup,
    [switch]$Force,
    [string]$LogLevel = "Info",
    [string[]]$IncludeTools = @(),
    [string[]]$ExcludeTools = @(),
    [switch]$DryRun,
    [switch]$Uninstall
)

# Main execution flow
function Main {
    try {
        Initialize-Setup
        Test-SystemCompatibility
        Backup-ExistingConfigurations
        Install-Prerequisites
        Install-CoreTools
        Install-DevelopmentTools
        Configure-Environment
        Validate-Installation
        Show-CompletionSummary
    }
    catch {
        Handle-CriticalError $_
        Invoke-Rollback
    }
}
```

## Core Modules

### 1. Logger.psm1
**Purpose**: Centralized logging with multiple output levels and file logging
```powershell
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Debug", "Info", "Warning", "Error", "Success")]$Level = "Info",
        [switch]$NoConsole
    )
}

function Start-LogSession { }
function Stop-LogSession { }
function Get-LogPath { }
```

### 2. PackageManager.psm1
**Purpose**: Package manager detection, installation, and tool installation
```powershell
function Test-PackageManager {
    param([ValidateSet("Winget", "Chocolatey", "Scoop")]$Manager)
}

function Install-PackageManager {
    param([ValidateSet("Winget", "Chocolatey", "Scoop")]$Manager)
}

function Install-Package {
    param(
        [string]$PackageName,
        [string]$WingetId,
        [string]$ChocolateyName,
        [string]$ScoopName,
        [string]$ManualUrl
    )
}
```

### 3. SystemCheck.psm1
**Purpose**: System compatibility and prerequisite validation
```powershell
function Test-WindowsVersion { }
function Test-PowerShellVersion { }
function Test-InternetConnectivity { }
function Test-DiskSpace { }
function Test-AdminPrivileges { }
function Get-SystemInfo { }
```

### 4. BackupRestore.psm1
**Purpose**: Configuration backup and restore functionality
```powershell
function Backup-Configuration {
    param([string]$ConfigPath, [string]$BackupDir)
}

function Restore-Configuration {
    param([string]$BackupDir)
}

function New-BackupDirectory { }
function Remove-BackupDirectory { }
```

## Installer Modules

### 1. GitInstaller.psm1
```powershell
function Install-Git { }
function Configure-Git {
    param([string]$UserName, [string]$UserEmail)
}
function Test-GitInstallation { }
```

### 2. FontInstaller.psm1
```powershell
function Install-NerdFont {
    param([string]$FontName = "CascadiaCode")
}
function Test-FontInstallation { }
function Get-AvailableFonts { }
```

### 3. TerminalInstaller.psm1
```powershell
function Install-WindowsTerminal { }
function Test-TerminalInstallation { }
function Get-TerminalVersion { }
```

### 4. CliToolsInstaller.psm1
```powershell
function Install-CliTool {
    param([string]$ToolName)
}
function Install-AllCliTools { }
function Test-CliToolInstallation { }
```

## Configuration Modules

### 1. TerminalConfigurator.psm1
```powershell
function Set-TerminalConfiguration {
    param([string]$ConfigPath)
}
function Get-TerminalConfigPath { }
function Merge-TerminalSettings { }
```

### 2. ProfileConfigurator.psm1
```powershell
function Set-PowerShellProfile { }
function Add-ProfileContent { }
function Test-ProfileSyntax { }
```

### 3. EnvironmentConfigurator.psm1
```powershell
function Set-EnvironmentVariable { }
function Add-ToPath { }
function Update-SessionEnvironment { }
```

## Error Handling Strategy

### Error Categories
1. **Critical Errors**: System incompatibility, missing prerequisites
2. **Installation Errors**: Package installation failures
3. **Configuration Errors**: Configuration file issues
4. **Network Errors**: Download/connectivity issues
5. **Permission Errors**: Insufficient privileges

### Error Handling Pattern
```powershell
function Install-Tool {
    param([string]$ToolName)
    
    try {
        Write-Log "Installing $ToolName..." -Level Info
        
        # Installation logic
        $result = Install-Package -PackageName $ToolName
        
        if ($result.Success) {
            Write-Log "$ToolName installed successfully" -Level Success
            return $true
        } else {
            throw "Installation failed: $($result.Error)"
        }
    }
    catch {
        Write-Log "Failed to install $ToolName: $($_.Exception.Message)" -Level Error
        
        # Try fallback method
        if (Install-ToolFallback -ToolName $ToolName) {
            Write-Log "$ToolName installed via fallback method" -Level Warning
            return $true
        }
        
        # Log error and continue
        Add-FailedInstallation -ToolName $ToolName -Error $_.Exception.Message
        return $false
    }
}
```

## User Interaction Patterns

### Interactive Mode
```powershell
function Get-UserPreferences {
    $preferences = @{}
    
    # Tool selection
    $preferences.Tools = Get-ToolSelection
    
    # Configuration options
    $preferences.Theme = Get-ThemeSelection
    $preferences.Font = Get-FontSelection
    
    # Git configuration
    $preferences.GitUser = Read-Host "Git username"
    $preferences.GitEmail = Read-Host "Git email"
    
    return $preferences
}
```

### Progress Tracking
```powershell
function Show-Progress {
    param(
        [int]$CurrentStep,
        [int]$TotalSteps,
        [string]$CurrentTask
    )
    
    $percent = [math]::Round(($CurrentStep / $TotalSteps) * 100)
    Write-Progress -Activity "Windows Terminal Setup" -Status $CurrentTask -PercentComplete $percent
}
```

## Validation and Testing

### Installation Validation
```powershell
function Test-Installation {
    $results = @{}
    
    foreach ($tool in $InstalledTools) {
        $results[$tool] = Test-ToolInstallation -ToolName $tool
    }
    
    return $results
}
```

### Configuration Validation
```powershell
function Test-Configuration {
    $tests = @(
        "Test-TerminalSettings",
        "Test-PowerShellProfile", 
        "Test-EnvironmentVariables",
        "Test-ToolConfigurations"
    )
    
    foreach ($test in $tests) {
        & $test
    }
}
```

## Rollback Mechanism

### Rollback Strategy
```powershell
function Invoke-Rollback {
    param([string]$BackupDirectory)
    
    Write-Log "Starting rollback process..." -Level Warning
    
    # Restore configurations
    Restore-Configuration -BackupDir $BackupDirectory
    
    # Uninstall packages (optional)
    if ($script:RollbackPackages) {
        Uninstall-InstalledPackages
    }
    
    # Clean up environment changes
    Reset-EnvironmentChanges
    
    Write-Log "Rollback completed" -Level Info
}
```

## Configuration Management

### Settings Merging
- **Strategy**: Merge new settings with existing configurations
- **Backup**: Always backup before modification
- **Validation**: Validate JSON/YAML syntax before applying
- **Rollback**: Automatic rollback on configuration errors

### Environment Variables
- **Scope**: User-level environment variables
- **Persistence**: Registry-based for permanent changes
- **Session**: Immediate session updates
- **Cleanup**: Removal capability for uninstall

This architecture provides a robust, modular, and maintainable foundation for the Windows Terminal setup script with comprehensive error handling, logging, and user interaction capabilities.
