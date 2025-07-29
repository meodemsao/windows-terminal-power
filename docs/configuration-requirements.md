# Configuration Requirements

## Overview
This document defines all configuration requirements for Windows Terminal, PowerShell profiles, and individual tools in the installation script.

## Windows Terminal Configuration

### Settings.json Location
- **Windows 11/10**: `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`
- **Portable/Unpackaged**: `%LOCALAPPDATA%\Microsoft\Windows Terminal\settings.json`

### Required Settings
```json
{
    "defaultProfile": "{PowerShell 7 GUID}",
    "profiles": {
        "defaults": {
            "fontFace": "CascadiaCode Nerd Font",
            "fontSize": 11,
            "colorScheme": "One Half Dark"
        },
        "list": [
            {
                "name": "PowerShell 7",
                "commandline": "pwsh.exe",
                "source": "Windows.Terminal.PowershellCore",
                "fontFace": "CascadiaCode Nerd Font"
            }
        ]
    },
    "schemes": [
        {
            "name": "One Half Dark",
            "background": "#282C34",
            "foreground": "#DCDFE4"
        }
    ]
}
```

### Theme Configuration
- **Default Color Scheme**: One Half Dark or Campbell Powershell
- **Font**: CascadiaCode Nerd Font or FiraCode Nerd Font
- **Font Size**: 11pt (adjustable)
- **Cursor**: Bar or vintage
- **Transparency**: Optional (10-20% acrylic)

## PowerShell Profile Configuration

### Profile Location
- **PowerShell 7**: `$PROFILE` → `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- **Windows PowerShell 5.1**: `%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

### Required Profile Content
```powershell
# Oh-My-Posh initialization
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression

# Zoxide initialization
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# FNM initialization
fnm env --use-on-cd | Out-String | Invoke-Expression

# FZF key bindings
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Aliases
Set-Alias -Name ls -Value eza
Set-Alias -Name ll -Value 'eza -la'
Set-Alias -Name la -Value 'eza -a'
Set-Alias -Name cat -Value bat
Set-Alias -Name z -Value __zoxide_z

# Custom functions
function which($command) { Get-Command -Name $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path }
function touch($file) { "" | Out-File $file -Encoding UTF8 }
```

## Tool-Specific Configurations

### 1. Oh-My-Posh
**Config Location**: Theme files in `$env:POSH_THEMES_PATH`
**Default Theme**: `paradox.omp.json` or `atomic.omp.json`
**Custom Theme**: Optional custom theme file
**Environment Variables**:
- `POSH_THEMES_PATH`: Path to theme directory

### 2. Git Configuration
**Global Config Commands**:
```bash
git config --global user.name "User Name"
git config --global user.email "user@example.com"
git config --global init.defaultBranch main
git config --global core.autocrlf true
git config --global credential.helper manager-core
```

### 3. Lazygit Configuration
**Config Location**: `%APPDATA%\lazygit\config.yml`
**Basic Config**:
```yaml
gui:
  theme:
    lightTheme: false
    activeBorderColor:
      - '#ff9e64'
      - bold
    inactiveBorderColor:
      - '#a9b1d6'
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
```

### 4. FZF Configuration
**Environment Variables**:
- `FZF_DEFAULT_OPTS`: `--height 40% --layout=reverse --border`
- `FZF_DEFAULT_COMMAND`: `fd --type f --hidden --follow --exclude .git`
**PowerShell Integration**: PSFzf module installation and configuration

### 5. Eza Configuration
**Aliases Required**:
- `ls` → `eza`
- `ll` → `eza -la`
- `la` → `eza -a`
- `tree` → `eza --tree`
**Default Options**: `--icons --git`

### 6. Bat Configuration
**Config Location**: `%APPDATA%\bat\config`
**Default Settings**:
```
--theme="OneHalfDark"
--style="numbers,changes,header"
--paging=never
```
**Alias**: `cat` → `bat`

### 7. LSD Configuration
**Config Location**: `%APPDATA%\lsd\config.yaml`
**Basic Config**:
```yaml
classic: false
blocks:
  - permission
  - user
  - group
  - size
  - date
  - name
color:
  when: auto
date: relative
dereference: false
display: all
icons:
  when: auto
  theme: fancy
indicators: false
layout: grid
recursion:
  enabled: false
  depth: 1
size: default
sorting:
  column: name
  reverse: false
  dir-grouping: first
symlink-arrow: ⇒
total-size: false
```

### 8. Zoxide Configuration
**Database Location**: `%LOCALAPPDATA%\zoxide\db.zo`
**PowerShell Integration**: Automatic via `zoxide init powershell`
**Alias**: `z` command for smart directory jumping

### 9. FNM Configuration
**Environment Variables**:
- `FNM_DIR`: Installation directory
- `FNM_MULTISHELL_PATH`: Shell integration path
**Default Node Version**: Latest LTS
**PowerShell Integration**: `fnm env --use-on-cd`

### 10. Pyenv Configuration
**Environment Variables**:
- `PYENV_ROOT`: `%USERPROFILE%\.pyenv`
- `PYENV_HOME`: `%USERPROFILE%\.pyenv\pyenv-win`
**PATH Addition**: `%PYENV_ROOT%\bin;%PYENV_ROOT%\shims`
**Default Python Version**: Latest stable (3.11+)

### 11. LazyVim Configuration
**Config Location**: `%LOCALAPPDATA%\nvim\`
**Installation Method**: Git clone LazyVim starter
**Required Dependencies**:
- Node.js (via FNM)
- Python (via Pyenv)
- Git
**Basic Config**: LazyVim default configuration with minimal customization

## Environment Variables Summary

### Required Environment Variables
```powershell
# Oh-My-Posh
$env:POSH_THEMES_PATH = "$(oh-my-posh get shell-theme-path)"

# FZF
$env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"

# Pyenv
$env:PYENV_ROOT = "$env:USERPROFILE\.pyenv"
$env:PYENV_HOME = "$env:USERPROFILE\.pyenv\pyenv-win"

# FNM
$env:FNM_DIR = "$env:LOCALAPPDATA\fnm"
```

### PATH Modifications
```powershell
# Add to PATH
$env:PATH += ";$env:PYENV_ROOT\bin;$env:PYENV_ROOT\shims"
$env:PATH += ";$env:FNM_DIR"
$env:PATH += ";$env:LOCALAPPDATA\Microsoft\WindowsApps"
```

## Configuration Backup Strategy

### Files to Backup Before Modification
1. **Windows Terminal**: `settings.json`
2. **PowerShell Profile**: `Microsoft.PowerShell_profile.ps1`
3. **Git Config**: `.gitconfig`
4. **Existing Tool Configs**: Any existing configuration files

### Backup Location
- **Backup Directory**: `%USERPROFILE%\.windows-terminal-setup\backups\{timestamp}`
- **Backup Format**: Original filename with `.backup` extension
- **Restore Script**: Automated restore capability

## Configuration Validation

### Post-Configuration Checks
1. **Windows Terminal**: Verify font rendering and theme application
2. **PowerShell Profile**: Test all aliases and functions
3. **Oh-My-Posh**: Verify prompt rendering with icons
4. **Tool Integration**: Test each tool's functionality
5. **Environment Variables**: Verify all required variables are set

### Validation Commands
```powershell
# Test aliases
ls, ll, la, cat

# Test functions
which git, touch test.txt

# Test integrations
z ~, fzf, oh-my-posh --version

# Test development tools
fnm list, pyenv versions, nvim --version
```
