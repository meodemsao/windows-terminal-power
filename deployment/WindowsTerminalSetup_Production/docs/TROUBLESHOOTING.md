# Troubleshooting Guide

This guide helps you resolve common issues when installing and using the Windows Terminal & PowerShell Setup script.

## 🚨 Common Installation Issues

### 1. Execution Policy Errors

**Problem**: PowerShell prevents script execution with error:
```
execution of scripts is disabled on this system
```

**Solutions**:

#### Option A: Temporary Policy Change (Recommended)
```powershell
# Set policy for current user only
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Run the script
.\Install-WindowsTerminalSetup-Enhanced.ps1

# Optionally restore original policy
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser
```

#### Option B: Bypass for Single Execution
```powershell
# Run script with bypass
powershell -ExecutionPolicy Bypass -File ".\Install-WindowsTerminalSetup-Enhanced.ps1"
```

#### Option C: Unblock Downloaded Files
```powershell
# If downloaded from internet, unblock the file
Unblock-File -Path ".\Install-WindowsTerminalSetup-Enhanced.ps1"
```

### 2. Package Manager Issues

#### Problem: "No package managers detected"

**Diagnosis**:
```powershell
# Check if winget is available
winget --version

# Check if chocolatey is available
choco --version

# Check if scoop is available
scoop --version
```

**Solutions**:

#### Install Windows Package Manager (winget)
```powershell
# Method 1: Microsoft Store
# Search for "App Installer" and install/update

# Method 2: Direct download
$wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
Invoke-WebRequest -Uri $wingetUrl -OutFile "winget-installer.msixbundle"
Add-AppxPackage -Path "winget-installer.msixbundle"
```

#### Install Chocolatey
```powershell
# Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### Install Scoop
```powershell
# Run as regular user
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

### 3. Internet Connectivity Issues

**Problem**: "No internet connectivity detected"

**Diagnosis**:
```powershell
# Test connectivity
Test-NetConnection -ComputerName "github.com" -Port 443
Test-NetConnection -ComputerName "www.microsoft.com" -Port 443

# Check proxy settings
netsh winhttp show proxy
```

**Solutions**:

#### Configure Proxy (if behind corporate firewall)
```powershell
# Set proxy for current session
$proxy = "http://proxy.company.com:8080"
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($proxy)

# Configure winget proxy
winget settings --proxy $proxy

# Configure chocolatey proxy
choco config set proxy $proxy
```

#### Bypass SSL Issues
```powershell
# Temporarily bypass SSL (use with caution)
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
```

### 4. Permission and Access Issues

#### Problem: "Access denied" or "Permission denied"

**Solutions**:

#### Run as Administrator
```powershell
# Right-click PowerShell and select "Run as Administrator"
# Then run the script
.\Install-WindowsTerminalSetup-Enhanced.ps1
```

#### Check Antivirus Software
- Temporarily disable real-time protection
- Add script directory to antivirus exclusions
- Check quarantine for blocked files

#### Windows Defender SmartScreen
```powershell
# If Windows blocks the script, click "More info" then "Run anyway"
# Or temporarily disable SmartScreen (not recommended)
```

### 5. Module Import Errors

**Problem**: "The specified module was not loaded"

**Diagnosis**:
```powershell
# Check if module files exist
Test-Path ".\modules\Core\UserInterface-Simple.psm1"
Test-Path ".\modules\Core\Logger.psm1"

# Check module syntax
Get-Content ".\modules\Core\UserInterface-Simple.psm1" | Select-String "syntax error"
```

**Solutions**:

#### Use Simple Mode
```powershell
# If UI module fails, use simple mode
.\Install-WindowsTerminalSetup-Enhanced.ps1 -SkipUI
```

#### Manual Module Import
```powershell
# Test module import manually
Import-Module ".\modules\Core\UserInterface-Simple.psm1" -Force -Verbose
```

#### File Encoding Issues
```powershell
# Re-save modules with UTF-8 encoding
Get-Content ".\modules\Core\UserInterface-Simple.psm1" | Out-File -Encoding UTF8 ".\modules\Core\UserInterface-Simple-Fixed.psm1"
```

## 🔧 Tool-Specific Issues

### Git Installation Problems

**Problem**: Git installation fails or git commands not recognized

**Solutions**:
```powershell
# Manual git installation
winget install Git.Git

# Add git to PATH manually
$gitPath = "C:\Program Files\Git\bin"
$env:PATH += ";$gitPath"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, "User")

# Verify installation
git --version
```

### Oh-My-Posh Issues

**Problem**: Prompt doesn't change or shows encoding issues

**Solutions**:
```powershell
# Install manually
winget install JanDeDobbeleer.OhMyPosh

# Set up profile manually
oh-my-posh init pwsh | Invoke-Expression

# Fix font issues - install a Nerd Font
winget install "Cascadia Code PL"
```

### PowerShell 7 Issues

**Problem**: PowerShell 7 not installing or not accessible

**Solutions**:
```powershell
# Manual installation
winget install Microsoft.PowerShell

# Check installation
pwsh --version

# Add to PATH if needed
$ps7Path = "C:\Program Files\PowerShell\7"
$env:PATH += ";$ps7Path"
```

### Windows Terminal Issues

**Problem**: Windows Terminal not installing or not opening

**Solutions**:
```powershell
# Install from Microsoft Store
start ms-windows-store://pdp/?productid=9N0DX20HK701

# Or install via winget
winget install Microsoft.WindowsTerminal

# Reset Windows Terminal settings
Remove-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
```

## 🐛 Script-Specific Issues

### UI Module Failures

**Problem**: Enhanced UI doesn't work properly

**Solutions**:
```powershell
# Use simple mode
.\Install-WindowsTerminalSetup-Enhanced.ps1 -SkipUI

# Use simplified script
.\Install-WindowsTerminalSetup-Simple.ps1

# Check PowerShell version compatibility
$PSVersionTable.PSVersion
```

### Progress Bar Issues

**Problem**: Progress bars don't display correctly

**Solutions**:
```powershell
# Check terminal compatibility
$Host.UI.RawUI.WindowSize

# Use basic progress mode
$ProgressPreference = "SilentlyContinue"

# Update PowerShell if needed
winget install Microsoft.PowerShell
```

### Configuration Backup Failures

**Problem**: Cannot create backups of existing configurations

**Solutions**:
```powershell
# Check permissions on config directories
Test-Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

# Manual backup
$backupPath = "$env:TEMP\TerminalBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force
Copy-Item "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\*" -Destination $backupPath -Recurse
```

## 🔍 Diagnostic Tools

### System Information Collection

```powershell
# Collect system diagnostics
$diagnostics = @{
    OSVersion = (Get-CimInstance Win32_OperatingSystem).Caption
    PSVersion = $PSVersionTable.PSVersion
    ExecutionPolicy = Get-ExecutionPolicy
    PackageManagers = @()
    NetworkConnectivity = @()
    DiskSpace = (Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq $env:SystemDrive).FreeSpace / 1GB
}

# Check package managers
if (Get-Command winget -ErrorAction SilentlyContinue) { $diagnostics.PackageManagers += "winget" }
if (Get-Command choco -ErrorAction SilentlyContinue) { $diagnostics.PackageManagers += "chocolatey" }
if (Get-Command scoop -ErrorAction SilentlyContinue) { $diagnostics.PackageManagers += "scoop" }

# Test connectivity
try { 
    Invoke-WebRequest "https://github.com" -UseBasicParsing -TimeoutSec 10
    $diagnostics.NetworkConnectivity += "GitHub: OK"
} catch { 
    $diagnostics.NetworkConnectivity += "GitHub: Failed - $($_.Exception.Message)"
}

$diagnostics | ConvertTo-Json -Depth 2
```

### Log Analysis

```powershell
# Find recent installation logs
Get-ChildItem "$env:TEMP\WindowsTerminalSetup_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# Search for errors in logs
$logFile = Get-ChildItem "$env:TEMP\WindowsTerminalSetup_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-Content $logFile.FullName | Select-String "ERROR"
```

### Environment Validation

```powershell
# Check environment variables
$env:PATH -split ';' | Where-Object { $_ -like "*git*" -or $_ -like "*PowerShell*" }

# Check installed programs
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
    Where-Object DisplayName -like "*git*" | 
    Select-Object DisplayName, DisplayVersion

# Check Windows features
Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like "*WSL*"
```

## 🆘 Getting Additional Help

### Self-Help Resources

1. **Enable Debug Logging**:
   ```powershell
   .\Install-WindowsTerminalSetup-Enhanced.ps1 -LogLevel Debug -DryRun
   ```

2. **Check Documentation**:
   - [Installation Guide](INSTALLATION_GUIDE.md)
   - [API Documentation](API_DOCUMENTATION.md)
   - [Contributing Guide](CONTRIBUTING.md)

3. **Community Resources**:
   - GitHub Issues: Report bugs and get help
   - GitHub Discussions: Community Q&A
   - Stack Overflow: Tag questions with `windows-terminal-setup`

### Professional Support

For enterprise environments or complex issues:

1. **Custom Installation Scripts**: Tailored for your environment
2. **Automated Deployment**: CI/CD integration and mass deployment
3. **Training and Support**: Team training and ongoing support

### Reporting Issues

When reporting issues, please include:

1. **System Information**:
   ```powershell
   # Run this and include output
   Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory
   $PSVersionTable
   ```

2. **Error Details**:
   - Complete error message
   - Steps to reproduce
   - Expected vs actual behavior

3. **Log Files**:
   - Attach relevant log files from `%TEMP%`
   - Include debug logs if available

4. **Environment Details**:
   - Package managers installed
   - Network configuration (proxy, firewall)
   - Antivirus software
   - Corporate environment restrictions

### Emergency Recovery

If the installation causes issues:

1. **Restore from Backup**:
   ```powershell
   # Find backup directory
   Get-ChildItem "$env:TEMP\*Backup*" | Sort-Object LastWriteTime -Descending

   # Restore Windows Terminal settings
   $backupPath = "path\to\backup"
   Copy-Item "$backupPath\*" -Destination "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" -Recurse -Force
   ```

2. **Reset PowerShell Profile**:
   ```powershell
   # Backup current profile
   Copy-Item $PROFILE "$PROFILE.backup"

   # Reset to default
   Remove-Item $PROFILE -Force
   ```

3. **Uninstall Tools**:
   ```powershell
   # Remove via package manager
   winget uninstall --all
   choco uninstall all -y
   scoop uninstall *
   ```

---

**Need more help?** Check our [FAQ](FAQ.md) or [contact support](mailto:support@example.com).
