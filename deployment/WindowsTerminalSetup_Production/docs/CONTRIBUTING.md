# Contributing Guide

Thank you for your interest in contributing to the Windows Terminal & PowerShell Setup project! This guide will help you get started with development, testing, and submitting contributions.

## 🚀 Getting Started

### Prerequisites for Development

- **Windows 10/11** with PowerShell 5.1 or later
- **Git** for version control
- **Code Editor** (VS Code recommended with PowerShell extension)
- **Package Managers** (winget, chocolatey, or scoop for testing)

### Development Environment Setup

1. **Fork and Clone the Repository**
   ```powershell
   git clone https://github.com/yourusername/windows-terminal-setup.git
   cd windows-terminal-setup
   ```

2. **Install Development Dependencies**
   ```powershell
   # Install Pester for testing (if not already installed)
   Install-Module -Name Pester -Force -SkipPublisherCheck
   
   # Install PSScriptAnalyzer for code quality
   Install-Module -Name PSScriptAnalyzer -Force
   ```

3. **Set Up Development Environment**
   ```powershell
   # Set execution policy for development
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Test the development environment
   .\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun
   ```

## 📁 Project Structure

Understanding the project organization:

```
windows-terminal-setup/
├── docs/                           # Documentation
│   ├── INSTALLATION_GUIDE.md       # User installation guide
│   ├── TROUBLESHOOTING.md          # Troubleshooting guide
│   ├── API_DOCUMENTATION.md        # API reference
│   ├── CONTRIBUTING.md             # This file
│   ├── ARCHITECTURE.md             # Architecture documentation
│   └── FAQ.md                      # Frequently asked questions
├── modules/                        # PowerShell modules
│   ├── Core/                       # Core functionality modules
│   │   ├── Logger.psm1             # Logging system
│   │   ├── PackageManager.psm1     # Package management
│   │   ├── SystemCheck.psm1        # System validation
│   │   ├── BackupRestore.psm1      # Backup/restore functionality
│   │   ├── ErrorHandler.psm1       # Error handling
│   │   └── UserInterface-Simple.psm1 # UI components
│   ├── Installers/                 # Tool-specific installers
│   │   └── GitInstaller.psm1       # Git installation module
│   └── Configurators/              # Configuration modules
├── tests/                          # Test files
│   ├── Unit/                       # Unit tests
│   ├── Integration/                # Integration tests
│   └── TestHelpers/                # Test utilities
├── scripts/                        # Utility scripts
├── Install-WindowsTerminalSetup-Enhanced.ps1  # Main interactive script
├── Install-WindowsTerminalSetup-Simple.ps1    # Simplified script
├── Demo-EnhancedUI.ps1             # UI demonstration script
└── README.md                       # Project overview
```

## 🛠️ Development Guidelines

### Code Style and Standards

#### PowerShell Coding Standards

1. **Function Naming**: Use approved PowerShell verbs
   ```powershell
   # Good
   function Get-SystemInformation { }
   function Set-Configuration { }
   function Test-PackageInstalled { }
   
   # Avoid
   function RetrieveSystemInfo { }
   function ConfigureSystem { }
   ```

2. **Parameter Validation**: Always validate parameters
   ```powershell
   function Install-Package {
       [CmdletBinding()]
       param(
           [Parameter(Mandatory = $true)]
           [ValidateNotNullOrEmpty()]
           [string]$PackageName,
           
           [Parameter(Mandatory = $false)]
           [ValidateSet("winget", "choco", "scoop")]
           [string]$PreferredManager = "winget"
       )
   }
   ```

3. **Error Handling**: Use try-catch blocks and proper error reporting
   ```powershell
   function Install-Tool {
       try {
           # Installation logic
           Write-Log "Installing $ToolName" -Level Info
           # ... installation code ...
           Write-Log "Successfully installed $ToolName" -Level Success
       }
       catch {
           Write-Log "Failed to install $ToolName: $($_.Exception.Message)" -Level Error
           throw
       }
   }
   ```

4. **Documentation**: Include comprehensive help documentation
   ```powershell
   function Install-Package {
       <#
       .SYNOPSIS
           Installs a package using the best available package manager
       
       .DESCRIPTION
           This function attempts to install a package using winget, chocolatey, or scoop
           in order of preference, with fallback options and error handling.
       
       .PARAMETER PackageName
           The name of the package to install
       
       .PARAMETER PreferredManager
           The preferred package manager to use (winget, choco, scoop)
       
       .EXAMPLE
           Install-Package -PackageName "git"
           Installs Git using the default package manager
       
       .EXAMPLE
           Install-Package -PackageName "nodejs" -PreferredManager "choco"
           Installs Node.js using Chocolatey specifically
       #>
   }
   ```

#### Module Development Standards

1. **Module Structure**: Follow consistent module organization
   ```powershell
   # Module header
   # ModuleName.psm1 - Description of module functionality
   
   # Module variables (if needed)
   $script:ModuleVariable = @{}
   
   # Private functions (not exported)
   function Private-HelperFunction { }
   
   # Public functions (exported)
   function Public-Function { }
   
   # Export only public functions
   Export-ModuleMember -Function @(
       'Public-Function1',
       'Public-Function2'
   )
   ```

2. **Cross-Platform Compatibility**: Ensure compatibility across PowerShell versions
   ```powershell
   # Check PowerShell version compatibility
   if ($PSVersionTable.PSVersion.Major -lt 5) {
       throw "This module requires PowerShell 5.0 or later"
   }
   
   # Use compatible cmdlets and syntax
   # Avoid PowerShell 7+ specific features in core modules
   ```

### Testing Requirements

#### Unit Testing with Pester

1. **Test File Organization**
   ```
   tests/
   ├── Unit/
   │   ├── Core/
   │   │   ├── Logger.Tests.ps1
   │   │   ├── PackageManager.Tests.ps1
   │   │   └── SystemCheck.Tests.ps1
   │   └── Installers/
   │       └── GitInstaller.Tests.ps1
   ```

2. **Test Structure Example**
   ```powershell
   # Logger.Tests.ps1
   BeforeAll {
       Import-Module "$PSScriptRoot\..\..\modules\Core\Logger.psm1" -Force
   }
   
   Describe "Logger Module" {
       Context "Start-LogSession" {
           It "Should create log file successfully" {
               $logFile = Join-Path $TestDrive "test.log"
               $result = Start-LogSession -LogFile $logFile
               $result | Should -Be $true
               Test-Path $logFile | Should -Be $true
           }
           
           It "Should handle invalid log path gracefully" {
               $invalidPath = "Z:\NonExistent\test.log"
               { Start-LogSession -LogFile $invalidPath } | Should -Not -Throw
           }
       }
       
       Context "Write-Log" {
           BeforeEach {
               $logFile = Join-Path $TestDrive "test.log"
               Start-LogSession -LogFile $logFile
           }
           
           It "Should write log entry with correct format" {
               Write-Log "Test message" -Level Info
               $content = Get-Content $logFile
               $content | Should -Match "\[.*\] \[Info\] Test message"
           }
       }
   }
   ```

3. **Running Tests**
   ```powershell
   # Run all tests
   Invoke-Pester
   
   # Run specific test file
   Invoke-Pester -Path "tests\Unit\Core\Logger.Tests.ps1"
   
   # Run tests with coverage
   Invoke-Pester -CodeCoverage "modules\Core\*.psm1"
   ```

#### Integration Testing

1. **Integration Test Structure**
   ```powershell
   # Integration test example
   Describe "Full Installation Flow" {
       It "Should complete dry run without errors" {
           $result = & "$PSScriptRoot\..\..\Install-WindowsTerminalSetup-Enhanced.ps1" -DryRun -Interactive:$false
           $LASTEXITCODE | Should -Be 0
       }
   }
   ```

### Code Quality Tools

#### PSScriptAnalyzer

1. **Running Analysis**
   ```powershell
   # Analyze all PowerShell files
   Invoke-ScriptAnalyzer -Path . -Recurse
   
   # Analyze specific file
   Invoke-ScriptAnalyzer -Path "Install-WindowsTerminalSetup-Enhanced.ps1"
   
   # Exclude specific rules if needed
   Invoke-ScriptAnalyzer -Path . -ExcludeRule PSAvoidUsingWriteHost
   ```

2. **Configuration File** (`.vscode/settings.json`)
   ```json
   {
       "powershell.scriptAnalysis.enable": true,
       "powershell.scriptAnalysis.settingsPath": ".vscode/PSScriptAnalyzerSettings.psd1"
   }
   ```

## 🔄 Contribution Workflow

### 1. Issue Creation

Before starting development:

1. **Check Existing Issues**: Search for similar issues or feature requests
2. **Create New Issue**: Use appropriate issue templates
   - Bug Report: Include system info, steps to reproduce, expected vs actual behavior
   - Feature Request: Describe the feature, use cases, and proposed implementation
   - Documentation: Specify what documentation needs improvement

### 2. Development Process

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/add-new-tool-installer
   git checkout -b bugfix/fix-package-manager-detection
   git checkout -b docs/improve-installation-guide
   ```

2. **Make Changes**
   - Follow coding standards
   - Add appropriate tests
   - Update documentation
   - Test thoroughly

3. **Commit Guidelines**
   ```bash
   # Use conventional commit format
   git commit -m "feat: add support for Scoop package manager"
   git commit -m "fix: resolve PowerShell 5.1 compatibility issue"
   git commit -m "docs: update API documentation for new functions"
   git commit -m "test: add unit tests for SystemCheck module"
   ```

### 3. Testing Before Submission

1. **Run All Tests**
   ```powershell
   # Unit tests
   Invoke-Pester -Path "tests\Unit"
   
   # Integration tests
   Invoke-Pester -Path "tests\Integration"
   
   # Code analysis
   Invoke-ScriptAnalyzer -Path . -Recurse
   ```

2. **Manual Testing**
   ```powershell
   # Test dry run
   .\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun
   
   # Test UI components
   .\Demo-EnhancedUI.ps1
   
   # Test error scenarios
   .\Install-WindowsTerminalSetup-Enhanced.ps1 -DryRun -LogLevel Debug
   ```

### 4. Pull Request Process

1. **Create Pull Request**
   - Use descriptive title and description
   - Reference related issues
   - Include testing information
   - Add screenshots for UI changes

2. **PR Template Checklist**
   - [ ] Code follows project style guidelines
   - [ ] Self-review completed
   - [ ] Tests added/updated and passing
   - [ ] Documentation updated
   - [ ] No breaking changes (or clearly documented)
   - [ ] Tested on multiple PowerShell versions

3. **Review Process**
   - Address reviewer feedback
   - Update tests and documentation as needed
   - Ensure CI/CD checks pass

## 🧪 Testing Guidelines

### Test Categories

1. **Unit Tests**: Test individual functions in isolation
2. **Integration Tests**: Test module interactions
3. **End-to-End Tests**: Test complete installation flows
4. **Compatibility Tests**: Test across PowerShell versions

### Test Data and Mocking

```powershell
# Example of mocking external dependencies
Describe "Package Installation" {
    BeforeAll {
        Mock Invoke-Expression { return "Package installed successfully" }
        Mock Test-Path { return $true }
    }
    
    It "Should install package successfully" {
        $result = Install-Package -PackageName "test-package"
        $result.Success | Should -Be $true
    }
}
```

## 📚 Documentation Standards

### Documentation Types

1. **Code Documentation**: Inline comments and function help
2. **API Documentation**: Comprehensive function reference
3. **User Guides**: Step-by-step instructions for end users
4. **Developer Guides**: Technical documentation for contributors

### Documentation Updates

When making changes:
- Update relevant API documentation
- Add examples for new features
- Update troubleshooting guides for new issues
- Keep README.md current with new features

## 🚀 Release Process

### Version Management

- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update version numbers in relevant files
- Create release notes with changes

### Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] Version numbers updated
- [ ] Release notes prepared
- [ ] Backward compatibility verified

## 🤝 Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help newcomers get started
- Focus on the project's goals

### Getting Help

- **GitHub Discussions**: Ask questions and share ideas
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check existing guides first

## 📞 Contact

For questions about contributing:
- **GitHub Issues**: Technical questions and bug reports
- **GitHub Discussions**: General questions and ideas
- **Email**: [maintainer@example.com](mailto:maintainer@example.com) for sensitive issues

---

Thank you for contributing to the Windows Terminal & PowerShell Setup project! Your contributions help make the Windows development experience better for everyone.
