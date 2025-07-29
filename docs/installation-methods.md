# Installation Methods Research

## Package Manager Priority and Fallback Strategy

### Primary: Winget (Windows Package Manager)
- **Availability**: Windows 10 1903+ and Windows 11
- **Installation**: Built-in or via Microsoft Store (App Installer)
- **Advantages**: Official Microsoft support, reliable, integrated with Windows
- **Command Format**: `winget install <package-id>`

### Secondary: Chocolatey
- **Availability**: All Windows versions with PowerShell
- **Installation**: Requires manual setup
- **Advantages**: Large package repository, mature ecosystem
- **Command Format**: `choco install <package-name>`

### Tertiary: Scoop
- **Availability**: All Windows versions with PowerShell
- **Installation**: User-level, no admin required
- **Advantages**: Portable installations, user directory
- **Command Format**: `scoop install <package-name>`

### Manual Installation
- **Use Case**: When package managers fail
- **Method**: Direct download and installation
- **Advantages**: Always available, latest versions

## Tool-Specific Installation Methods

### 1. Git
**Primary**: `winget install Git.Git`
**Secondary**: `choco install git`
**Tertiary**: `scoop install git`
**Manual**: Download from https://git-scm.com/download/win
**Validation**: `git --version`

### 2. Curl
**Primary**: Built-in Windows 10 1803+ or `winget install cURL.cURL`
**Secondary**: `choco install curl`
**Tertiary**: `scoop install curl`
**Manual**: Download from https://curl.se/windows/
**Validation**: `curl --version`

### 3. Lazygit
**Primary**: `winget install JesseDuffield.lazygit`
**Secondary**: `choco install lazygit`
**Tertiary**: `scoop install lazygit`
**Manual**: Download from GitHub releases
**Validation**: `lazygit --version`

### 4. Nerd Fonts
**Primary**: `winget install "Cascadia Code PL"` or individual fonts
**Secondary**: `choco install cascadia-code-nerd-font`
**Tertiary**: `scoop bucket add nerd-fonts; scoop install CascadiaCode-NF`
**Manual**: Download from https://www.nerdfonts.com/font-downloads
**Recommended Fonts**:
- CascadiaCode Nerd Font (`winget install "Cascadia Code PL"`)
- FiraCode Nerd Font (`winget install "FiraCode Nerd Font"`)
- JetBrainsMono Nerd Font (`winget install "JetBrains Mono NL"`)

### 5. Oh-My-Posh
**Primary**: `winget install JanDeDobbeleer.OhMyPosh`
**Secondary**: `choco install oh-my-posh`
**Tertiary**: `scoop install oh-my-posh`
**Manual**: Download from GitHub releases
**Validation**: `oh-my-posh --version`

### 6. FZF
**Primary**: `winget install junegunn.fzf`
**Secondary**: `choco install fzf`
**Tertiary**: `scoop install fzf`
**Manual**: Download from GitHub releases
**Validation**: `fzf --version`

### 7. Eza
**Primary**: `winget install eza-community.eza`
**Secondary**: `choco install eza`
**Tertiary**: `scoop install eza`
**Manual**: Download from GitHub releases
**Validation**: `eza --version`

### 8. Bat
**Primary**: `winget install sharkdp.bat`
**Secondary**: `choco install bat`
**Tertiary**: `scoop install bat`
**Manual**: Download from GitHub releases
**Validation**: `bat --version`

### 9. LSD
**Primary**: `winget install Peltoche.lsd`
**Secondary**: `choco install lsd`
**Tertiary**: `scoop install lsd`
**Manual**: Download from GitHub releases
**Validation**: `lsd --version`

### 10. Neovim (for LazyVim)
**Primary**: `winget install Neovim.Neovim`
**Secondary**: `choco install neovim`
**Tertiary**: `scoop install neovim`
**Manual**: Download from https://neovim.io/
**Validation**: `nvim --version`

### 11. Zoxide
**Primary**: `winget install ajeetdsouza.zoxide`
**Secondary**: `choco install zoxide`
**Tertiary**: `scoop install zoxide`
**Manual**: Download from GitHub releases
**Validation**: `zoxide --version`

### 12. FNM
**Primary**: `winget install Schniz.fnm`
**Secondary**: `choco install fnm`
**Tertiary**: `scoop install fnm`
**Manual**: Download from GitHub releases
**Validation**: `fnm --version`

### 13. Pyenv-win
**Primary**: `winget install pyenv-win.pyenv-win`
**Secondary**: `choco install pyenv-win`
**Tertiary**: `scoop install pyenv`
**Manual**: Git clone or download from GitHub
**Validation**: `pyenv --version`

## Windows Terminal Installation
**Primary**: `winget install Microsoft.WindowsTerminal`
**Secondary**: Microsoft Store installation
**Manual**: Download from GitHub releases
**Validation**: Check if Windows Terminal is available in Start Menu

## PowerShell 7 Installation
**Primary**: `winget install Microsoft.PowerShell`
**Secondary**: `choco install powershell-core`
**Tertiary**: Download from GitHub releases
**Manual**: MSI installer from PowerShell releases
**Validation**: `pwsh --version`

## Installation Strategy Implementation

### Pre-Installation Checks
1. **System Compatibility**: Verify Windows version and build
2. **Package Manager Availability**: Check winget, then chocolatey, then scoop
3. **Internet Connectivity**: Verify download capability
4. **Permissions**: Check if running as administrator when needed
5. **Disk Space**: Verify sufficient space available

### Installation Process Flow
1. **Detect Available Package Managers**
2. **Install Missing Prerequisites** (Windows Terminal, PowerShell 7)
3. **Install Core Dependencies** (Git, Nerd Fonts)
4. **Install Primary Tools** (oh-my-posh, fzf, eza, bat, etc.)
5. **Install Development Tools** (fnm, pyenv, neovim)
6. **Install Advanced Tools** (lazygit, lazyvim)
7. **Configure All Tools** (profiles, aliases, themes)
8. **Validate Installation** (version checks, functionality tests)

### Error Handling Strategy
- **Package Not Found**: Try next package manager in priority order
- **Installation Failure**: Log error, continue with next tool
- **Network Issues**: Retry with exponential backoff
- **Permission Denied**: Prompt for administrator privileges
- **Dependency Missing**: Install dependency first, then retry

### Rollback Strategy
- **Backup Existing Configurations**: Before making changes
- **Track Installed Packages**: Maintain installation log
- **Uninstall on Failure**: Remove partially installed tools
- **Restore Configurations**: Revert to backed-up settings
