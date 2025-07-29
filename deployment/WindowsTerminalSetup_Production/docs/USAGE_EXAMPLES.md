# Usage Examples and Best Practices

This guide provides practical examples and best practices for using the Windows Terminal & PowerShell Setup script in various scenarios.

## 🚀 Basic Usage Examples

### Example 1: First-Time Interactive Installation

Perfect for individual developers setting up their personal development environment.

```powershell
# Download the script
git clone https://github.com/yourusername/windows-terminal-setup.git
cd windows-terminal-setup

# Run interactive installation
.\Install-WindowsTerminalSetup-Enhanced.ps1
```

**What happens**:
1. Welcome banner and system compatibility check
2. Interactive tool selection menu
3. Configuration options (theme, font, settings)
4. Installation confirmation
5. Progress tracking during installation
6. Comprehensive summary report

**Best for**: First-time users, personal setups, learning the available options

### Example 2: Quick Preview (Dry Run)

Use this to see what would be installed without making any changes.

```powershell
# Preview installation without changes
.\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun

# Preview with debug information
.\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun -LogLevel Debug
```

**What happens**:
- All installation steps are simulated
- No actual packages are installed
- No configurations are changed
- Detailed log of what would happen

**Best for**: Testing, validation, understanding the process

### Example 3: Automated Installation

For environments where user interaction isn't possible or desired.

```powershell
# Fully automated with defaults
.\Install-WindowsTerminalSetup-Enhanced.ps1 -Interactive:$false

# Automated without UI components
.\Install-WindowsTerminalSetup-Enhanced.ps1 -SkipUI -Interactive:$false

# Automated dry run for CI/CD validation
.\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun -Interactive:$false -SkipUI
```

**Best for**: CI/CD pipelines, automated deployments, scripted setups

## 🏢 Enterprise and Team Scenarios

### Example 4: Corporate Environment Setup

For organizations with specific requirements and restrictions.

```powershell
# Corporate setup with proxy configuration
$env:HTTP_PROXY = "http://proxy.company.com:8080"
$env:HTTPS_PROXY = "http://proxy.company.com:8080"

# Run with corporate-friendly settings
.\Install-WindowsTerminalSetup-Enhanced.ps1 -Interactive:$false -LogLevel Info

# Verify installation in corporate environment
.\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun -LogLevel Debug
```

**Additional considerations**:
- Check IT policies before installation
- Test in development environment first
- Consider package manager restrictions
- Review security implications

### Example 5: Team Standardization

Ensuring consistent development environments across team members.

```powershell
# Create team setup script
$teamTools = @("git", "oh-my-posh", "fzf", "eza", "bat", "lazygit")
$teamConfig = @{
    Theme = "One Half Dark"
    Font = "CascadiaCode Nerd Font"
    CreateBackup = $true
    InstallPowerShell7 = $true
}

# Document team standards
Write-Host "Team Standard Tools: $($teamTools -join ', ')"
Write-Host "Standard Theme: $($teamConfig.Theme)"

# Run installation (team members would run this)
.\Install-WindowsTerminalSetup-Enhanced.ps1
```

**Best practices**:
- Document team standards
- Provide setup instructions
- Test on different team member machines
- Create troubleshooting guide for team

### Example 6: Multiple Machine Deployment

For system administrators managing multiple Windows machines.

```powershell
# Create deployment script
$machines = @("DEV-PC-01", "DEV-PC-02", "DEV-PC-03")

foreach ($machine in $machines) {
    Write-Host "Deploying to $machine..."
    
    # Copy script to remote machine
    Copy-Item -Path ".\Install-WindowsTerminalSetup-Enhanced.ps1" -Destination "\\$machine\C$\Temp\"
    
    # Execute remotely (requires appropriate permissions)
    Invoke-Command -ComputerName $machine -ScriptBlock {
        Set-Location "C:\Temp"
        .\Install-WindowsTerminalSetup-Enhanced.ps1 -Interactive:$false -SkipUI
    }
}
```

**Requirements**:
- Administrative access to target machines
- PowerShell remoting enabled
- Network connectivity
- Appropriate security permissions

## 🔧 Advanced Usage Scenarios

### Example 7: Custom Tool Selection

For users who want specific tools only.

```powershell
# Minimal developer setup
# (This would be done through the interactive menu, but shown conceptually)

# Tools for web development
$webDevTools = @("git", "oh-my-posh", "fzf", "bat", "fnm")

# Tools for Python development  
$pythonDevTools = @("git", "oh-my-posh", "fzf", "bat", "pyenv", "neovim")

# Tools for system administration
$sysAdminTools = @("git", "oh-my-posh", "fzf", "eza", "bat", "lsd")

Write-Host "Select tools based on your development focus"
.\Install-WindowsTerminalSetup-Enhanced.ps1
```

### Example 8: Troubleshooting and Recovery

When things go wrong, use these approaches.

```powershell
# Enable maximum logging for troubleshooting
.\Install-WindowsTerminalSetup-Enhanced.ps1 -LogLevel Debug -DryRun

# Check system diagnostics
$diagnostics = @{
    OSVersion = (Get-CimInstance Win32_OperatingSystem).Caption
    PSVersion = $PSVersionTable.PSVersion
    ExecutionPolicy = Get-ExecutionPolicy
    AvailableSpace = (Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq $env:SystemDrive).FreeSpace / 1GB
}

$diagnostics | ConvertTo-Json

# Test package managers
@("winget", "choco", "scoop") | ForEach-Object {
    $available = Get-Command $_ -ErrorAction SilentlyContinue
    Write-Host "$_`: $($available -ne $null)"
}

# Find and review log files
Get-ChildItem "$env:TEMP\WindowsTerminalSetup_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
```

### Example 9: Incremental Updates

Adding new tools to an existing installation.

```powershell
# Check what's currently installed
$installedTools = @()
if (Get-Command git -ErrorAction SilentlyContinue) { $installedTools += "git" }
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { $installedTools += "oh-my-posh" }
if (Get-Command fzf -ErrorAction SilentlyContinue) { $installedTools += "fzf" }

Write-Host "Currently installed: $($installedTools -join ', ')"

# Run script to add new tools (existing tools will be skipped)
.\Install-WindowsTerminalSetup-Enhanced.ps1
```

## 📋 Best Practices

### Pre-Installation Best Practices

1. **System Preparation**
   ```powershell
   # Check system requirements
   $osInfo = Get-CimInstance Win32_OperatingSystem
   Write-Host "OS: $($osInfo.Caption) Build: $($osInfo.BuildNumber)"
   
   # Check PowerShell version
   Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
   
   # Check available disk space
   $freeSpace = (Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq $env:SystemDrive).FreeSpace / 1GB
   Write-Host "Free space: $([math]::Round($freeSpace, 2)) GB"
   ```

2. **Backup Existing Configurations**
   ```powershell
   # Manual backup before installation
   $backupPath = "$env:USERPROFILE\Desktop\TerminalBackup_$(Get-Date -Format 'yyyyMMdd')"
   New-Item -ItemType Directory -Path $backupPath -Force
   
   # Backup PowerShell profile
   if (Test-Path $PROFILE) {
       Copy-Item $PROFILE "$backupPath\PowerShell_Profile.ps1"
   }
   
   # Backup Windows Terminal settings
   $terminalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
   if (Test-Path $terminalSettings) {
       Copy-Item $terminalSettings "$backupPath\WindowsTerminal_settings.json"
   }
   ```

3. **Network and Security Preparation**
   ```powershell
   # Test internet connectivity
   Test-NetConnection -ComputerName "github.com" -Port 443
   Test-NetConnection -ComputerName "www.microsoft.com" -Port 443
   
   # Check execution policy
   Get-ExecutionPolicy -List
   
   # Set appropriate execution policy if needed
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### During Installation Best Practices

1. **Monitor Progress and Logs**
   ```powershell
   # Run with appropriate logging level
   .\Install-WindowsTerminalSetup-Enhanced.ps1 -LogLevel Info
   
   # Monitor log file in real-time (in another PowerShell window)
   $logFile = Get-ChildItem "$env:TEMP\WindowsTerminalSetup_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
   Get-Content $logFile.FullName -Wait
   ```

2. **Handle Interruptions Gracefully**
   ```powershell
   # If installation is interrupted, check what was completed
   $tools = @("git", "oh-my-posh", "fzf", "eza", "bat", "lsd", "zoxide")
   $installed = $tools | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }
   $missing = $tools | Where-Object { -not (Get-Command $_ -ErrorAction SilentlyContinue) }
   
   Write-Host "Installed: $($installed -join ', ')"
   Write-Host "Missing: $($missing -join ', ')"
   
   # Re-run installation to complete missing tools
   .\Install-WindowsTerminalSetup-Enhanced.ps1
   ```

### Post-Installation Best Practices

1. **Verify Installation**
   ```powershell
   # Test installed tools
   git --version
   oh-my-posh --version
   fzf --version
   
   # Test PowerShell profile
   . $PROFILE
   
   # Test Windows Terminal (if installed)
   wt --version
   ```

2. **Customize and Configure**
   ```powershell
   # Configure Git (if not done during installation)
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   
   # Explore oh-my-posh themes
   oh-my-posh get themes
   
   # Test new commands
   fzf --help
   eza --help
   bat --help
   ```

3. **Update and Maintain**
   ```powershell
   # Regular updates
   winget upgrade --all
   choco upgrade all
   scoop update *
   
   # Update oh-my-posh themes
   oh-my-posh get themes --update
   
   # Keep PowerShell updated
   winget upgrade Microsoft.PowerShell
   ```

## 🔄 Maintenance and Updates

### Regular Maintenance Script

```powershell
# Create a maintenance script for regular updates
$maintenanceScript = @'
# Windows Terminal Setup Maintenance Script
Write-Host "Starting maintenance..." -ForegroundColor Green

# Update package managers
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Updating winget packages..." -ForegroundColor Yellow
    winget upgrade --all
}

if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Updating chocolatey packages..." -ForegroundColor Yellow
    choco upgrade all -y
}

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "Updating scoop packages..." -ForegroundColor Yellow
    scoop update *
}

# Update oh-my-posh themes
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Write-Host "Updating oh-my-posh themes..." -ForegroundColor Yellow
    oh-my-posh get themes --update
}

Write-Host "Maintenance completed!" -ForegroundColor Green
'@

$maintenanceScript | Out-File -FilePath "$env:USERPROFILE\Desktop\UpdateTerminalTools.ps1" -Encoding UTF8
Write-Host "Maintenance script created at: $env:USERPROFILE\Desktop\UpdateTerminalTools.ps1"
```

### Backup and Restore Procedures

```powershell
# Create backup procedure
function Backup-TerminalConfiguration {
    $backupPath = "$env:USERPROFILE\Documents\TerminalBackups\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupPath -Force
    
    # Backup PowerShell profile
    if (Test-Path $PROFILE) {
        Copy-Item $PROFILE "$backupPath\PowerShell_Profile.ps1"
    }
    
    # Backup Windows Terminal settings
    $terminalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $terminalSettings) {
        Copy-Item $terminalSettings "$backupPath\WindowsTerminal_settings.json"
    }
    
    Write-Host "Backup created at: $backupPath"
    return $backupPath
}

# Create restore procedure
function Restore-TerminalConfiguration {
    param([string]$BackupPath)
    
    if (Test-Path "$BackupPath\PowerShell_Profile.ps1") {
        Copy-Item "$BackupPath\PowerShell_Profile.ps1" $PROFILE -Force
        Write-Host "PowerShell profile restored"
    }
    
    if (Test-Path "$BackupPath\WindowsTerminal_settings.json") {
        $terminalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        Copy-Item "$BackupPath\WindowsTerminal_settings.json" $terminalSettings -Force
        Write-Host "Windows Terminal settings restored"
    }
}
```

## 📞 Getting Help

If you encounter issues with any of these examples:

1. **Check the logs** in `%TEMP%` for detailed error information
2. **Run with debug logging** using `-LogLevel Debug`
3. **Review the troubleshooting guide** at [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
4. **Ask for help** in GitHub Discussions or Issues

---

**Next Steps**: Explore the [API Documentation](API_DOCUMENTATION.md) for advanced customization or check the [Contributing Guide](CONTRIBUTING.md) to help improve the project.
