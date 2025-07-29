# Windows Terminal & PowerShell Setup

An automated installation script for setting up a modern Windows Terminal environment with essential CLI tools and configurations.

## 🎉 **Project Status: Enhanced UI & Progress Tracking Complete!**

This project now features a **production-ready installation wizard** with:
- ✅ **Interactive UI** with beautiful ASCII banners and progress bars
- ✅ **Comprehensive Error Handling** with automatic recovery and rollback
- ✅ **System Validation** with detailed compatibility checks
- ✅ **User Customization** with tool selection and configuration menus
- ✅ **Professional Logging** with multiple severity levels and file output
- ✅ **Cross-PowerShell Compatibility** (works on both PowerShell 5.1 and 7+)

## Overview

This project provides a comprehensive PowerShell installation wizard that automates the setup of:

- **Windows Terminal** with custom themes and settings
- **PowerShell 7** with enhanced profiles
- **Essential CLI Tools**: git, curl, lazygit, oh-my-posh, fzf, eza, bat, lsd, neovim, zoxide, fnm, pyenv
- **Nerd Fonts** for enhanced terminal display
- **Custom configurations** for optimal developer experience

## ✨ Features

### 🚀 **Installation Experience**
- **Interactive Installation Wizard** with step-by-step guidance
- **Beautiful Progress Tracking** with visual progress bars and time estimates
- **Tool Selection Menu** with descriptions and toggle functionality
- **Configuration Customization** for themes, fonts, and settings
- **Dry-run Mode** to preview changes before installation

### 🛡️ **Reliability & Safety**
- **Comprehensive Error Handling** with automatic recovery suggestions
- **System Compatibility Validation** before installation
- **Configuration Backup & Restore** with rollback capabilities
- **Installation Verification** with functional testing
- **Detailed Logging** with troubleshooting information

### 🎨 **User Experience**
- **Cross-Platform UI** that works in both PowerShell 5.1 and 7+
- **Color-coded Output** with clear status indicators
- **Professional ASCII Banners** and formatted displays
- **Interactive Prompts** with validation and defaults
- **Comprehensive Help** and troubleshooting guidance

## 🚀 Quick Start

### Option 1: Enhanced Interactive Installation (Recommended)
```powershell
# Download and run the enhanced installation wizard
.\Install-WindowsTerminalSetup-Enhanced.ps1
```

### Option 2: Simple Installation
```powershell
# Run the simplified version
.\Install-WindowsTerminalSetup-Simple.ps1 -DryRun
```

### Option 3: Non-Interactive Installation
```powershell
# Run without UI prompts
.\Install-WindowsTerminalSetup-Enhanced.ps1 -Interactive:$false -DryRun
```

## 📋 System Requirements

- **Windows 10** version 1903 (build 18362) or later, or **Windows 11**
- **PowerShell 5.1** or later (PowerShell 7+ recommended)
- **Internet connection** for downloading packages
- **2GB free disk space** (recommended)
- **Package Manager**: winget, chocolatey, or scoop (auto-detected)

## 🛠️ Installed Tools

### Core Infrastructure
| Tool | Description | Purpose |
|------|-------------|---------|
| **Windows Terminal** | Modern terminal application | Enhanced terminal experience |
| **PowerShell 7** | Latest PowerShell version | Modern shell with advanced features |
| **git** | Version control system | Source code management |
| **curl** | Data transfer tool | HTTP requests and downloads |

### CLI Enhancement Tools
| Tool | Description | Purpose |
|------|-------------|---------|
| **oh-my-posh** | Prompt theme engine | Beautiful, informative prompts |
| **fzf** | Fuzzy finder | Interactive file/command search |
| **eza** | Modern `ls` replacement | Enhanced directory listings |
| **bat** | Enhanced `cat` | Syntax highlighting for files |
| **lsd** | Next-gen `ls` with icons | Visual directory listings |
| **zoxide** | Smarter `cd` command | Intelligent directory navigation |

### Development Tools
| Tool | Description | Purpose |
|------|-------------|---------|
| **lazygit** | Terminal UI for git | Visual git interface |
| **neovim** | Modern text editor | Advanced text editing |
| **fnm** | Node.js version manager | Node.js development |
| **pyenv** | Python version manager | Python development |

### Visual Enhancements
| Tool | Description | Purpose |
|------|-------------|---------|
| **Nerd Fonts** | Iconic font collection | Enhanced terminal display |

## 🎛️ Configuration Options

The installation wizard provides customization for:

### **Themes**
- One Half Dark (default)
- One Half Light
- Solarized Dark/Light
- Campbell
- Vintage

### **Fonts**
- CascadiaCode Nerd Font (default)
- FiraCode Nerd Font
- JetBrainsMono Nerd Font
- Hack Nerd Font

### **Installation Options**
- Tool selection (individual or bulk)
- Configuration backup creation
- PowerShell 7 installation
- Git user configuration

## 📖 Usage Examples

### Interactive Installation
```powershell
# Full interactive experience with tool selection and configuration
.\Install-WindowsTerminalSetup-Enhanced.ps1
```

### Automated Installation
```powershell
# Non-interactive with default settings
.\Install-WindowsTerminalSetup-Enhanced.ps1 -Interactive:$false

# Dry run to preview changes
.\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun

# Skip UI for automated environments
.\Install-WindowsTerminalSetup-Enhanced.ps1 -SkipUI -DryRun
```

### Advanced Options
```powershell
# Enable debug logging
.\Install-WindowsTerminalSetup-Enhanced.ps1 -LogLevel Debug

# Simple mode fallback
.\Install-WindowsTerminalSetup-Simple.ps1 -DryRun
```

## 🔧 Architecture

### **Modular Design**
```
modules/
├── Core/
│   ├── Logger.psm1              # Professional logging system
│   ├── PackageManager.psm1      # Multi-manager package handling
│   ├── SystemCheck.psm1         # Comprehensive system validation
│   ├── BackupRestore.psm1       # Configuration backup/restore
│   ├── ErrorHandler.psm1        # Advanced error handling
│   └── UserInterface-Simple.psm1 # Enhanced UI components
├── Installers/
│   └── GitInstaller.psm1        # Tool-specific installers
└── Configurators/
    └── (Future configuration modules)
```

### **Installation Scripts**
- `Install-WindowsTerminalSetup-Enhanced.ps1` - Full-featured interactive wizard
- `Install-WindowsTerminalSetup-Simple.ps1` - Simplified version with built-in functions
- `Install-WindowsTerminalSetup.ps1` - Original modular version

## 🛡️ Error Handling & Recovery

### **Comprehensive Validation**
- Pre-installation system compatibility checks
- Package manager availability detection
- Internet connectivity verification
- Disk space validation
- Administrator privilege detection

### **Error Recovery**
- Automatic retry logic with exponential backoff
- Installation context tracking for rollback
- Detailed error reporting with troubleshooting suggestions
- Recovery action recommendations based on error patterns

### **Backup & Restore**
- Automatic configuration backup before changes
- Selective restore capabilities
- Backup integrity validation
- Restore point creation for safe rollback

## 🐛 Troubleshooting

### **Common Issues**

1. **Execution Policy Error**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Package Manager Not Found**:
   - Install winget from Microsoft Store
   - Or install Chocolatey: https://chocolatey.org/install
   - Or install Scoop: https://scoop.sh/

3. **Permission Denied**:
   - Run PowerShell as Administrator
   - Check antivirus software settings

4. **Module Import Errors**:
   - Ensure all module files are present
   - Check file permissions
   - Try running with `-SkipUI` flag

### **Getting Help**

- **Detailed Logs**: Check generated log files in `%TEMP%`
- **Debug Mode**: Run with `-LogLevel Debug` for detailed information
- **System Diagnostics**: The script automatically exports system diagnostics on critical errors
- **Error Reports**: Comprehensive error reports with recovery suggestions

## 🧪 Testing

The installation scripts have been tested on:
- ✅ **Windows 11 Pro** (build 26100)
- ✅ **PowerShell 5.1** and **PowerShell 7+**
- ✅ **Multiple package managers** (winget, chocolatey, scoop)
- ✅ **Various system configurations** and privilege levels
- ✅ **Error scenarios** and recovery procedures

## 📚 Comprehensive Documentation

This project includes extensive documentation for both users and developers:

### 📖 **User Documentation**
- **[Installation Guide](docs/INSTALLATION_GUIDE.md)** - Complete step-by-step installation instructions
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Usage Examples](docs/USAGE_EXAMPLES.md)** - Practical examples and best practices
- **[FAQ](docs/FAQ.md)** - Frequently asked questions and answers

### 🛠️ **Developer Documentation**
- **[API Documentation](docs/API_DOCUMENTATION.md)** - Comprehensive function reference and module documentation
- **[Contributing Guide](docs/CONTRIBUTING.md)** - Development guidelines, coding standards, and contribution process
- **[Architecture Guide](docs/ARCHITECTURE.md)** - System design, technical decisions, and architecture overview

### 📋 **Quick Reference**
| Document | Purpose | Audience |
|----------|---------|----------|
| [Installation Guide](docs/INSTALLATION_GUIDE.md) | Complete setup instructions | End users |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Problem resolution | End users |
| [Usage Examples](docs/USAGE_EXAMPLES.md) | Practical scenarios | End users |
| [FAQ](docs/FAQ.md) | Common questions | End users |
| [API Documentation](docs/API_DOCUMENTATION.md) | Technical reference | Developers |
| [Contributing](docs/CONTRIBUTING.md) | Development guide | Contributors |
| [Architecture](docs/ARCHITECTURE.md) | System design | Developers |

## 🚀 Next Steps

Upcoming development phases:
- [x] **Documentation Creation** - ✅ **COMPLETE** - Comprehensive user guides and API documentation
- [ ] **Testing Framework Development** - Automated testing across Windows versions
- [ ] **Quality Assurance** - Multi-environment validation and performance testing
- [ ] **Final Integration** - Production deployment preparation

## 🤝 Contributing

Contributions are welcome! The project follows a modular architecture making it easy to:
- Add new tool installers
- Enhance UI components
- Improve error handling
- Add configuration options

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to all the amazing tool creators in the CLI community
- Inspired by modern terminal setups and dotfiles repositories
- Built with ❤️ for the Windows development community
- Enhanced with comprehensive error handling and user experience focus
