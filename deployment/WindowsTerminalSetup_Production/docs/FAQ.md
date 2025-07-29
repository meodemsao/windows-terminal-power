# Frequently Asked Questions (FAQ)

This document answers common questions about the Windows Terminal & PowerShell Setup project.

## 🚀 General Questions

### Q: What is this project?
**A**: This is an automated PowerShell script that sets up a modern Windows Terminal environment with essential CLI tools, themes, and configurations. It provides a one-click solution to transform your command-line experience on Windows.

### Q: Who is this for?
**A**: This project is designed for:
- **Developers** who want a modern terminal setup
- **System administrators** managing Windows environments
- **PowerShell users** looking to enhance their experience
- **Anyone** who wants better command-line tools on Windows

### Q: What tools does it install?
**A**: The script can install:
- **Core tools**: git, curl, Windows Terminal, PowerShell 7
- **CLI enhancements**: oh-my-posh, fzf, eza, bat, lsd, zoxide
- **Development tools**: lazygit, neovim, fnm, pyenv
- **Visual enhancements**: Nerd Fonts for better display

### Q: Is it safe to use?
**A**: Yes, the script is designed with safety in mind:
- **Dry-run mode** to preview changes before installation
- **Automatic backups** of existing configurations
- **Rollback capabilities** if something goes wrong
- **Comprehensive error handling** and recovery
- **Open source** code that you can review

## 🛠️ Installation Questions

### Q: What are the system requirements?
**A**: You need:
- **Windows 10** version 1903+ or **Windows 11**
- **PowerShell 5.1** or later (PowerShell 7+ recommended)
- **Internet connection** for downloading packages
- **2GB free disk space** (recommended)
- **Package manager** (winget, chocolatey, or scoop)

### Q: Do I need administrator privileges?
**A**: Not necessarily:
- **Most tools** can be installed with user privileges
- **Some tools** may require administrator access
- **The script** will prompt you when elevation is needed
- **You can run** as a regular user and elevate when prompted

### Q: Which package manager should I use?
**A**: The script supports multiple package managers:
- **winget** (recommended) - Pre-installed on Windows 11 and recent Windows 10
- **chocolatey** - Popular third-party package manager
- **scoop** - User-focused package manager

The script will automatically detect and use the best available option.

### Q: Can I choose which tools to install?
**A**: Yes! The interactive installation wizard allows you to:
- **Select individual tools** from the available list
- **Toggle tools on/off** with descriptions
- **Use bulk operations** (select all, deselect all)
- **Preview your selections** before installation

### Q: How long does installation take?
**A**: Installation time varies:
- **System check**: 30 seconds - 1 minute
- **Tool selection**: 1-5 minutes (depending on choices)
- **Installation**: 5-15 minutes (depending on tools selected)
- **Configuration**: 1-3 minutes

Total time is typically **10-25 minutes** for a full installation.

### Q: Can I run the script multiple times?
**A**: Yes, it's safe to re-run:
- **Existing tools** are detected and skipped
- **New tools** can be added to your installation
- **Configurations** can be updated
- **Backups** are created before any changes

## 🔧 Configuration Questions

### Q: Can I customize the Windows Terminal theme?
**A**: Yes, the script offers several theme options:
- **One Half Dark** (default)
- **One Half Light**
- **Solarized Dark/Light**
- **Campbell**
- **Vintage**

You can also manually customize themes after installation.

### Q: What fonts are available?
**A**: The script supports several Nerd Fonts:
- **CascadiaCode Nerd Font** (default)
- **FiraCode Nerd Font**
- **JetBrainsMono Nerd Font**
- **Hack Nerd Font**

These fonts include programming ligatures and icon support.

### Q: Will this overwrite my existing PowerShell profile?
**A**: The script is designed to be safe:
- **Automatic backup** of existing profiles
- **Merge approach** rather than overwrite when possible
- **Restore option** if you want to revert changes
- **Preview mode** to see what would change

### Q: How do I configure Git after installation?
**A**: Git configuration can be done during installation:
- **Interactive prompts** for username and email
- **Automatic configuration** if you provide details
- **Manual configuration** after installation:
  ```powershell
  git config --global user.name "Your Name"
  git config --global user.email "your.email@example.com"
  ```

## 🐛 Troubleshooting Questions

### Q: The script won't run - "execution of scripts is disabled"
**A**: This is a PowerShell execution policy issue:
```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass
powershell -ExecutionPolicy Bypass -File ".\Install-WindowsTerminalSetup-Enhanced.ps1"
```

### Q: "No package managers detected" error
**A**: Install a package manager:
- **winget**: Update Windows or install from Microsoft Store
- **chocolatey**: Visit [chocolatey.org/install](https://chocolatey.org/install)
- **scoop**: Visit [scoop.sh](https://scoop.sh/)

### Q: Installation fails with network errors
**A**: Check your network configuration:
- **Internet connectivity**: Ensure you can access GitHub and Microsoft servers
- **Proxy settings**: Configure proxy if behind corporate firewall
- **Firewall**: Ensure PowerShell can make outbound connections
- **Antivirus**: Check if antivirus is blocking downloads

### Q: Some tools didn't install correctly
**A**: The script provides detailed error information:
- **Check the log file** in `%TEMP%` for detailed error messages
- **Run with debug logging**: `-LogLevel Debug`
- **Try manual installation** of failed tools
- **Check the troubleshooting guide** for specific tool issues

### Q: How do I uninstall everything?
**A**: You can remove tools individually:
```powershell
# Via winget
winget uninstall <package-name>

# Via chocolatey
choco uninstall <package-name>

# Via scoop
scoop uninstall <package-name>
```

For configurations, restore from the automatic backup created during installation.

## 🔄 Usage Questions

### Q: How do I update the installed tools?
**A**: Use your package manager's update commands:
```powershell
# Update all winget packages
winget upgrade --all

# Update all chocolatey packages
choco upgrade all

# Update all scoop packages
scoop update *
```

### Q: Can I use this in a corporate environment?
**A**: Yes, with considerations:
- **Check IT policies** regarding software installation
- **Use dry-run mode** to preview changes
- **Test in development environment** first
- **Consider proxy and firewall** configurations
- **Review security implications** with your IT team

### Q: How do I customize the PowerShell prompt?
**A**: The script installs oh-my-posh for prompt customization:
```powershell
# List available themes
oh-my-posh get themes

# Set a different theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\theme-name.omp.json" | Invoke-Expression

# Add to your profile to make permanent
Add-Content $PROFILE "oh-my-posh init pwsh --config 'theme-path' | Invoke-Expression"
```

### Q: What are the new commands I can use?
**A**: After installation, you'll have access to:
- **`fzf`** - Fuzzy finder for files and commands
- **`eza`** or **`exa`** - Enhanced file listing
- **`bat`** - Better cat with syntax highlighting
- **`lsd`** - Modern ls with icons
- **`z <directory>`** - Smart directory navigation
- **`lazygit`** - Terminal UI for git

## 📚 Advanced Questions

### Q: Can I contribute to this project?
**A**: Absolutely! See our [Contributing Guide](CONTRIBUTING.md) for:
- **Development setup** instructions
- **Coding standards** and guidelines
- **Testing requirements**
- **Pull request process**

### Q: How do I add support for a new tool?
**A**: You can extend the project by:
1. **Creating a new installer module** in `modules/Installers/`
2. **Following the existing patterns** for package installation
3. **Adding appropriate tests** for your installer
4. **Updating documentation** with the new tool
5. **Submitting a pull request** for review

### Q: Can I create custom installation profiles?
**A**: Currently, you can:
- **Use the interactive menu** to select tools
- **Modify the script** to change default selections
- **Create wrapper scripts** for specific configurations

Future versions may include predefined profiles for different use cases.

### Q: Is there a way to automate this for multiple machines?
**A**: Yes, for automated deployment:
```powershell
# Non-interactive installation with defaults
.\Install-WindowsTerminalSetup-Enhanced.ps1 -Interactive:$false

# Skip UI for CI/CD environments
.\Install-WindowsTerminalSetup-Enhanced.ps1 -SkipUI -Interactive:$false

# Use configuration files (future feature)
.\Install-WindowsTerminalSetup-Enhanced.ps1 -ConfigFile "corporate-config.json"
```

### Q: How do I report bugs or request features?
**A**: Use our GitHub repository:
- **Bug reports**: Create an issue with system info and error details
- **Feature requests**: Describe the feature and use cases
- **Questions**: Use GitHub Discussions for general questions

## 🔐 Security Questions

### Q: Is it safe to run scripts from the internet?
**A**: Always exercise caution:
- **Review the code** before running (it's open source)
- **Use dry-run mode** first to see what would happen
- **Check the source** - only download from official repositories
- **Verify checksums** if provided
- **Run in a test environment** first

### Q: What data does the script collect?
**A**: The script does not collect or transmit personal data:
- **Local logging only** - logs stay on your machine
- **No telemetry** or usage tracking
- **No network communication** except for downloading packages
- **Open source** - you can verify this yourself

### Q: Can I run this offline?
**A**: Partially:
- **The script itself** can run offline in dry-run mode
- **Package downloads** require internet connectivity
- **Some tools** may be available locally if already downloaded
- **Configuration changes** can work offline

## 📞 Getting Help

### Q: Where can I get more help?
**A**: Several resources are available:
- **[Installation Guide](INSTALLATION_GUIDE.md)** - Comprehensive setup instructions
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions
- **[API Documentation](API_DOCUMENTATION.md)** - Technical reference
- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Community Q&A

### Q: How do I contact the maintainers?
**A**: You can reach us through:
- **GitHub Issues** - For bugs and feature requests
- **GitHub Discussions** - For questions and ideas
- **Email** - [maintainer@example.com](mailto:maintainer@example.com) for sensitive issues

### Q: Is commercial support available?
**A**: For enterprise needs:
- **Custom installations** tailored to your environment
- **Training and support** for your team
- **Automated deployment** solutions
- **Priority support** for critical issues

Contact us for enterprise support options.

---

**Don't see your question here?** Check our other documentation or ask in [GitHub Discussions](https://github.com/yourusername/windows-terminal-setup/discussions).
