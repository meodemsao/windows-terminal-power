# Windows Terminal & PowerShell Setup - Installation Instructions

## Quick Start
1. Extract this package to a directory of your choice
2. Open PowerShell as Administrator (recommended)
3. Navigate to the extracted directory
4. Run: `.\Install-WindowsTerminalSetup-Simple.ps1`

## Alternative Installation
For advanced users with more customization options:
`.\Install-WindowsTerminalSetup-Enhanced.ps1`

## System Requirements
- Windows 10 version 1903 (build 18362) or later
- PowerShell 5.1 or later (PowerShell 7+ recommended)
- Internet connection for downloading tools
- Administrator privileges (recommended)

## What This Package Installs
- **Windows Terminal** - Modern terminal application
- **Git** - Version control system
- **curl** - Command-line data transfer tool
- **lazygit** - Simple terminal UI for git commands
- **Nerd Fonts** - Patched fonts with icons
- **Oh My Posh** - Prompt theme engine
- **fzf** - Command-line fuzzy finder
- **eza** - Modern replacement for ls
- **bat** - Cat clone with syntax highlighting
- **lsd** - Next gen ls command
- **LazyVim** - Neovim configuration
- **zoxide** - Smarter cd command
- **fnm** - Fast Node.js version manager
- **pyenv** - Python version management

## Documentation
- **Installation Guide**: `docs/INSTALLATION_GUIDE.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`
- **API Documentation**: `docs/API_DOCUMENTATION.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **FAQ**: `docs/FAQ.md`
- **Usage Examples**: `docs/USAGE_EXAMPLES.md`

## Package Managers Supported
- **winget** (Windows Package Manager) - Preferred
- **chocolatey** - Alternative package manager
- **scoop** - Command-line installer

## Installation Options
The installer will automatically:
1. Detect your system configuration
2. Check for existing installations
3. Choose the best installation method
4. Configure tools with sensible defaults
5. Create backups of existing configurations

## Customization
After installation, you can customize:
- Windows Terminal settings in `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
- PowerShell profile in `$PROFILE`
- Oh My Posh themes
- Tool-specific configurations

## Support
For issues and questions:
1. Check the troubleshooting guide: `docs/TROUBLESHOOTING.md`
2. Review the FAQ: `docs/FAQ.md`
3. Check the project repository for updates

## Package Information
- **Version**: 1.0.0
- **Created**: $(Get-Date)
- **Deployment Type**: Production
- **Tested On**: Windows 10/11, PowerShell 5.1+

## License
This project is licensed under the MIT License. See the LICENSE file for details.

---

**Ready to transform your terminal experience? Run the installer and enjoy! 🚀**
