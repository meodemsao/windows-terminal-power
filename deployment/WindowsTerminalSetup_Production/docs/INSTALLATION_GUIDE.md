# Windows Terminal & PowerShell Setup - Installation Guide

This comprehensive guide will walk you through installing and configuring your Windows Terminal environment using our automated installation script.

## 📋 Prerequisites

### System Requirements
- **Operating System**: Windows 10 version 1903 (build 18362) or later, or Windows 11
- **PowerShell**: Version 5.1 or later (PowerShell 7+ recommended)
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 2GB free disk space for all tools and configurations
- **Network**: Internet connection for downloading packages
- **Permissions**: User account (Administrator privileges recommended but not required)

### Package Manager Requirements
The script supports multiple package managers and will automatically detect available ones:

#### Option 1: Windows Package Manager (winget) - Recommended
- **Pre-installed** on Windows 11 and recent Windows 10 updates
- **Manual Installation**: Download from Microsoft Store or [GitHub releases](https://github.com/microsoft/winget-cli/releases)
- **Verification**: Run `winget --version` in PowerShell

#### Option 2: Chocolatey
- **Installation**: Visit [chocolatey.org/install](https://chocolatey.org/install)
- **Quick Install**:
  ```powershell
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
  ```
- **Verification**: Run `choco --version` in PowerShell

#### Option 3: Scoop
- **Installation**: Visit [scoop.sh](https://scoop.sh/)
- **Quick Install**:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  irm get.scoop.sh | iex
  ```
- **Verification**: Run `scoop --version` in PowerShell

## 🚀 Installation Methods

### Method 1: Interactive Installation (Recommended)

This method provides the full user experience with tool selection, configuration options, and progress tracking.

1. **Download the Script**
   ```powershell
   # Option A: Clone the repository
   git clone https://github.com/yourusername/windows-terminal-setup.git
   cd windows-terminal-setup
   
   # Option B: Download directly
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/windows-terminal-setup/main/Install-WindowsTerminalSetup-Enhanced.ps1" -OutFile "Install-WindowsTerminalSetup-Enhanced.ps1"
   ```

2. **Set Execution Policy** (if needed)
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Run the Interactive Installation**
   ```powershell
   .\Install-WindowsTerminalSetup-Enhanced.ps1
   ```

4. **Follow the Installation Wizard**
   - System compatibility check
   - Tool selection menu
   - Configuration options
   - Installation confirmation
   - Progress tracking
   - Installation summary

### Method 2: Automated Installation

For automated environments or when you want to use default settings:

```powershell
# Non-interactive installation with defaults
.\Install-WindowsTerminalSetup-Enhanced.ps1 -Interactive:$false

# Preview what would be installed (dry run)
.\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun

# Skip UI components for CI/CD environments
.\Install-WindowsTerminalSetup-Enhanced.ps1 -SkipUI -Interactive:$false
```

### Method 3: Simple Installation

If you encounter issues with the enhanced version:

```powershell
# Use the simplified version
.\Install-WindowsTerminalSetup-Simple.ps1 -DryRun
```

## 🎛️ Configuration Options

### Tool Selection
The installation wizard allows you to select which tools to install:

#### Core Tools (Recommended)
- **git** - Version control system
- **curl** - Data transfer utility
- **Windows Terminal** - Modern terminal application
- **PowerShell 7** - Latest PowerShell version

#### CLI Enhancement Tools
- **oh-my-posh** - Beautiful prompt themes
- **fzf** - Fuzzy finder for files and commands
- **eza** - Modern replacement for `ls` command
- **bat** - Enhanced `cat` with syntax highlighting
- **lsd** - Next-generation `ls` with icons
- **zoxide** - Intelligent directory navigation

#### Development Tools
- **lazygit** - Terminal UI for git operations
- **neovim** - Modern text editor
- **fnm** - Fast Node.js version manager
- **pyenv** - Python version management

#### Visual Enhancements
- **Nerd Fonts** - Icon fonts for enhanced display

### Theme Selection
Choose from popular Windows Terminal themes:
- **One Half Dark** (default) - Dark theme with vibrant colors
- **One Half Light** - Light variant of One Half
- **Solarized Dark** - Popular dark theme
- **Solarized Light** - Light variant of Solarized
- **Campbell** - Classic Windows Terminal theme
- **Vintage** - Retro terminal appearance

### Font Selection
Select from optimized programming fonts:
- **CascadiaCode Nerd Font** (default) - Microsoft's programming font with icons
- **FiraCode Nerd Font** - Popular font with ligatures
- **JetBrainsMono Nerd Font** - JetBrains' programming font
- **Hack Nerd Font** - Clean, readable programming font

### Additional Options
- **Create Backup** - Backup existing configurations before changes
- **Install PowerShell 7** - Install the latest PowerShell version
- **Configure Git** - Set up Git with your user information

## 📊 Installation Process

### Step 1: System Compatibility Check
The script performs comprehensive validation:
- Windows version compatibility
- PowerShell version verification
- Internet connectivity test
- Package manager availability
- Disk space verification
- Administrator privilege detection

### Step 2: Tool Selection
Interactive menu for choosing tools:
- Browse available tools with descriptions
- Toggle individual tools on/off
- Select all or deselect all options
- View selection summary

### Step 3: Configuration Options
Customize your installation:
- Select Windows Terminal theme
- Choose programming font
- Configure backup options
- Set PowerShell and Git preferences

### Step 4: Installation Confirmation
Review your selections:
- Summary of tools to install
- Configuration choices
- Estimated installation time
- Final confirmation prompt

### Step 5: Installation Process
Automated installation with progress tracking:
- Real-time progress bars
- Current task display
- Time estimates
- Error handling and recovery

### Step 6: Installation Summary
Comprehensive results report:
- Successfully installed tools
- Failed installations with reasons
- Configuration changes made
- Next steps and recommendations

## 🔧 Post-Installation Setup

### 1. Restart Your Terminal
After installation, restart Windows Terminal or PowerShell to load new configurations:
```powershell
# Refresh environment variables
refreshenv

# Or restart your terminal application
```

### 2. Verify Installation
Check that tools are properly installed:
```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Verify installed tools
git --version
oh-my-posh --version
fzf --version
```

### 3. Configure Git (if selected)
If you chose to configure Git during installation:
```powershell
# Verify Git configuration
git config --global user.name
git config --global user.email

# Configure if not set during installation
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 4. Explore New Features
Try out your enhanced terminal:
```powershell
# Use fuzzy finder
fzf

# Enhanced file listing
eza -la
# or
lsd -la

# Better cat with syntax highlighting
bat filename.txt

# Smart directory navigation
z <partial-directory-name>
```

## 🎨 Customization

### Windows Terminal Settings
The installation automatically configures Windows Terminal. To further customize:

1. Open Windows Terminal
2. Press `Ctrl + ,` to open settings
3. Modify themes, fonts, and key bindings as desired

### PowerShell Profile
The script creates an enhanced PowerShell profile. To customize:
```powershell
# Edit your PowerShell profile
notepad $PROFILE

# Or use your preferred editor
code $PROFILE
```

### Oh-My-Posh Themes
Change your prompt theme:
```powershell
# List available themes
oh-my-posh get themes

# Set a different theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\theme-name.omp.json" | Invoke-Expression
```

## 📝 Logging and Diagnostics

### Log Files
Installation logs are automatically created:
- **Location**: `%TEMP%\WindowsTerminalSetup_Enhanced_YYYYMMDD_HHMMSS.log`
- **Content**: Detailed installation progress, errors, and system information
- **Retention**: Logs are kept for troubleshooting purposes

### Debug Mode
For detailed troubleshooting information:
```powershell
.\Install-WindowsTerminalSetup-Enhanced.ps1 -LogLevel Debug
```

### System Diagnostics
The script automatically exports system diagnostics on errors:
- System information
- Package manager status
- Error context and recovery suggestions
- Troubleshooting recommendations

## 🔄 Updating and Maintenance

### Updating Tools
Most tools can be updated through their respective package managers:
```powershell
# Update via winget
winget upgrade --all

# Update via chocolatey
choco upgrade all

# Update via scoop
scoop update *
```

### Re-running the Script
You can safely re-run the installation script:
- Existing tools will be detected and skipped
- New tools can be added
- Configurations can be updated
- Backups will be created before changes

### Uninstalling Tools
To remove installed tools:
```powershell
# Via winget
winget uninstall <package-name>

# Via chocolatey
choco uninstall <package-name>

# Via scoop
scoop uninstall <package-name>
```

## 🆘 Getting Help

### Built-in Help
```powershell
# Get script help
Get-Help .\Install-WindowsTerminalSetup-Enhanced.ps1 -Full

# View available parameters
Get-Help .\Install-WindowsTerminalSetup-Enhanced.ps1 -Parameter *
```

### Community Support
- **Issues**: Report problems on GitHub Issues
- **Discussions**: Join community discussions
- **Documentation**: Check the docs folder for additional guides

### Professional Support
For enterprise deployments or custom configurations, consider:
- Custom installation scripts
- Automated deployment solutions
- Training and support services

---

**Next**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.
