# API Documentation

This document provides comprehensive API documentation for all modules and functions in the Windows Terminal & PowerShell Setup project.

## 📚 Module Overview

The project follows a modular architecture with the following core modules:

```
modules/
├── Core/
│   ├── Logger.psm1              # Logging and diagnostics
│   ├── PackageManager.psm1      # Package management abstraction
│   ├── SystemCheck.psm1         # System validation and diagnostics
│   ├── BackupRestore.psm1       # Configuration backup and restore
│   ├── ErrorHandler.psm1        # Error handling and recovery
│   └── UserInterface-Simple.psm1 # User interface components
├── Installers/
│   └── GitInstaller.psm1        # Tool-specific installers
└── Configurators/
    └── (Future configuration modules)
```

## 🔧 Core Modules

### Logger.psm1

Provides comprehensive logging functionality with multiple severity levels and output targets.

#### Functions

##### `Start-LogSession`
Initializes a new logging session with file output.

**Syntax**:
```powershell
Start-LogSession [-LogFile] <String> [[-LogLevel] <String>] [<CommonParameters>]
```

**Parameters**:
- `LogFile` (String, Mandatory): Path to the log file
- `LogLevel` (String, Optional): Minimum log level (Debug, Info, Warning, Error). Default: Info

**Returns**: Boolean indicating success

**Example**:
```powershell
$logFile = Join-Path $env:TEMP "installation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-LogSession -LogFile $logFile -LogLevel "Debug"
```

##### `Write-Log`
Writes a log entry with specified severity level.

**Syntax**:
```powershell
Write-Log [-Message] <String> [[-Level] <String>] [<CommonParameters>]
```

**Parameters**:
- `Message` (String, Mandatory): Log message content
- `Level` (String, Optional): Log level (Debug, Info, Warning, Error, Success). Default: Info

**Returns**: None

**Example**:
```powershell
Write-Log "Installation started" -Level Info
Write-Log "Package download failed" -Level Error
Write-Log "Installation completed successfully" -Level Success
```

##### `Stop-LogSession`
Closes the current logging session and finalizes the log file.

**Syntax**:
```powershell
Stop-LogSession [<CommonParameters>]
```

**Returns**: None

**Example**:
```powershell
Stop-LogSession
```

### UserInterface-Simple.psm1

Provides enhanced user interface components for interactive installation.

#### Functions

##### `Initialize-UserInterface`
Initializes the user interface system and displays the welcome banner.

**Syntax**:
```powershell
Initialize-UserInterface [<CommonParameters>]
```

**Returns**: Boolean indicating success

**Example**:
```powershell
if (Initialize-UserInterface) {
    Write-Host "UI initialized successfully"
}
```

##### `Show-ProgressBar`
Displays a visual progress bar with percentage completion and time estimates.

**Syntax**:
```powershell
Show-ProgressBar [-CurrentStep] <Int32> [-TotalSteps] <Int32> [-CurrentTask] <String> [[-Width] <Int32>] [<CommonParameters>]
```

**Parameters**:
- `CurrentStep` (Int32, Mandatory): Current step number (1-based)
- `TotalSteps` (Int32, Mandatory): Total number of steps
- `CurrentTask` (String, Mandatory): Description of current task
- `Width` (Int32, Optional): Width of progress bar in characters. Default: 50

**Returns**: None

**Example**:
```powershell
Show-ProgressBar -CurrentStep 3 -TotalSteps 10 -CurrentTask "Installing Git"
```

##### `Show-StepHeader`
Displays a formatted header for installation steps.

**Syntax**:
```powershell
Show-StepHeader [-StepNumber] <Int32> [-StepTitle] <String> [[-StepDescription] <String>] [<CommonParameters>]
```

**Parameters**:
- `StepNumber` (Int32, Mandatory): Step number
- `StepTitle` (String, Mandatory): Step title
- `StepDescription` (String, Optional): Additional step description

**Returns**: None

**Example**:
```powershell
Show-StepHeader -StepNumber 1 -StepTitle "System Check" -StepDescription "Validating system requirements"
```

##### `Get-UserChoice`
Prompts user for input with validation and default options.

**Syntax**:
```powershell
Get-UserChoice [-Prompt] <String> [[-Choices] <String[]>] [[-Default] <String>] [-AllowEmpty] [<CommonParameters>]
```

**Parameters**:
- `Prompt` (String, Mandatory): Prompt message to display
- `Choices` (String[], Optional): Array of valid choices
- `Default` (String, Optional): Default choice if user presses Enter
- `AllowEmpty` (Switch, Optional): Allow empty input

**Returns**: String containing user's choice

**Example**:
```powershell
$theme = Get-UserChoice -Prompt "Select theme" -Choices @("Dark", "Light") -Default "Dark"
$name = Get-UserChoice -Prompt "Enter your name" -AllowEmpty
```

##### `Get-YesNoChoice`
Prompts user for a Yes/No decision with default option.

**Syntax**:
```powershell
Get-YesNoChoice [-Prompt] <String> [[-Default] <String>] [<CommonParameters>]
```

**Parameters**:
- `Prompt` (String, Mandatory): Question to ask the user
- `Default` (String, Optional): Default choice ("Y" or "N"). Default: "Y"

**Returns**: Boolean (True for Yes, False for No)

**Example**:
```powershell
$installPowerShell7 = Get-YesNoChoice -Prompt "Install PowerShell 7?" -Default "Y"
if ($installPowerShell7) {
    # Install PowerShell 7
}
```

##### `Show-ToolSelectionMenu`
Displays an interactive menu for selecting tools to install.

**Syntax**:
```powershell
Show-ToolSelectionMenu [-AvailableTools] <Array> [[-PreselectedTools] <Array>] [<CommonParameters>]
```

**Parameters**:
- `AvailableTools` (Array, Mandatory): List of available tools
- `PreselectedTools` (Array, Optional): Tools selected by default

**Returns**: Array of selected tool names

**Example**:
```powershell
$availableTools = @("git", "oh-my-posh", "fzf", "eza")
$selectedTools = Show-ToolSelectionMenu -AvailableTools $availableTools -PreselectedTools @("git")
```

##### `Show-ConfigurationMenu`
Displays configuration options menu for customizing the installation.

**Syntax**:
```powershell
Show-ConfigurationMenu [<CommonParameters>]
```

**Returns**: Hashtable containing configuration choices

**Example**:
```powershell
$config = Show-ConfigurationMenu
Write-Host "Selected theme: $($config.Theme)"
Write-Host "Selected font: $($config.Font)"
```

##### `Show-InstallationSummary`
Displays a comprehensive summary of installation results.

**Syntax**:
```powershell
Show-InstallationSummary [-Results] <Hashtable> [<CommonParameters>]
```

**Parameters**:
- `Results` (Hashtable, Mandatory): Installation results with success/failure information

**Returns**: None

**Example**:
```powershell
$results = @{
    "git" = @{ Success = $true; Message = "Installed successfully"; Version = "2.42.0" }
    "fzf" = @{ Success = $false; Message = "Package not found"; Version = $null }
}
Show-InstallationSummary -Results $results
```

### SystemCheck.psm1

Provides comprehensive system validation and compatibility checking.

#### Functions

##### `Test-SystemReadiness`
Performs comprehensive system compatibility validation.

**Syntax**:
```powershell
Test-SystemReadiness [<CommonParameters>]
```

**Returns**: Hashtable with readiness status and detailed information

**Example**:
```powershell
$readiness = Test-SystemReadiness
if ($readiness.Ready) {
    Write-Host "System is ready for installation"
} else {
    Write-Host "Critical issues found:"
    $readiness.CriticalIssues | ForEach-Object { Write-Host "  - $_" }
}
```

**Return Object Structure**:
```powershell
@{
    Ready = $true/$false                    # Overall readiness status
    CriticalIssues = @("issue1", "issue2") # Issues that prevent installation
    Warnings = @("warning1", "warning2")   # Non-critical warnings
    Recommendations = @("rec1", "rec2")     # Improvement suggestions
}
```

##### `Test-PackageManagerAvailability`
Checks for available package managers and their versions.

**Syntax**:
```powershell
Test-PackageManagerAvailability [<CommonParameters>]
```

**Returns**: Hashtable with package manager information

**Example**:
```powershell
$packageManagers = Test-PackageManagerAvailability
if ($packageManagers.winget.Available) {
    Write-Host "winget version: $($packageManagers.winget.Version)"
}
```

##### `Get-SystemDiagnostics`
Collects comprehensive system diagnostic information.

**Syntax**:
```powershell
Get-SystemDiagnostics [<CommonParameters>]
```

**Returns**: Hashtable with detailed system information

**Example**:
```powershell
$diagnostics = Get-SystemDiagnostics
$diagnostics | ConvertTo-Json -Depth 3 | Out-File "system-diagnostics.json"
```

### PackageManager.psm1

Provides abstraction layer for multiple package managers.

#### Functions

##### `Install-Package`
Installs a package using the best available package manager.

**Syntax**:
```powershell
Install-Package [-PackageName] <String> [[-PreferredManager] <String>] [[-TimeoutSeconds] <Int32>] [<CommonParameters>]
```

**Parameters**:
- `PackageName` (String, Mandatory): Name of package to install
- `PreferredManager` (String, Optional): Preferred package manager (winget, choco, scoop)
- `TimeoutSeconds` (Int32, Optional): Installation timeout. Default: 300

**Returns**: Hashtable with installation result

**Example**:
```powershell
$result = Install-Package -PackageName "git" -PreferredManager "winget"
if ($result.Success) {
    Write-Host "Git installed successfully"
} else {
    Write-Host "Installation failed: $($result.Message)"
}
```

##### `Test-PackageInstalled`
Checks if a package is already installed.

**Syntax**:
```powershell
Test-PackageInstalled [-PackageName] <String> [<CommonParameters>]
```

**Parameters**:
- `PackageName` (String, Mandatory): Name of package to check

**Returns**: Boolean indicating if package is installed

**Example**:
```powershell
if (Test-PackageInstalled -PackageName "git") {
    Write-Host "Git is already installed"
} else {
    Install-Package -PackageName "git"
}
```

### BackupRestore.psm1

Provides configuration backup and restore functionality.

#### Functions

##### `New-ConfigurationBackup`
Creates a backup of current configurations.

**Syntax**:
```powershell
New-ConfigurationBackup [[-BackupPath] <String>] [<CommonParameters>]
```

**Parameters**:
- `BackupPath` (String, Optional): Custom backup directory path

**Returns**: String containing backup directory path

**Example**:
```powershell
$backupPath = New-ConfigurationBackup
Write-Host "Backup created at: $backupPath"
```

##### `Restore-Configuration`
Restores configurations from a backup.

**Syntax**:
```powershell
Restore-Configuration [-BackupPath] <String> [<CommonParameters>]
```

**Parameters**:
- `BackupPath` (String, Mandatory): Path to backup directory

**Returns**: Boolean indicating success

**Example**:
```powershell
$success = Restore-Configuration -BackupPath "C:\Temp\Backup_20231201_120000"
if ($success) {
    Write-Host "Configuration restored successfully"
}
```

### ErrorHandler.psm1

Provides advanced error handling and recovery mechanisms.

#### Functions

##### `Register-Error`
Registers an error with context information for later analysis.

**Syntax**:
```powershell
Register-Error [-ErrorMessage] <String> [[-Component] <String>] [[-Severity] <String>] [<CommonParameters>]
```

**Parameters**:
- `ErrorMessage` (String, Mandatory): Error description
- `Component` (String, Optional): Component where error occurred
- `Severity` (String, Optional): Error severity (Low, Medium, High, Critical)

**Returns**: None

**Example**:
```powershell
try {
    Install-Package -PackageName "nonexistent-package"
} catch {
    Register-Error -ErrorMessage $_.Exception.Message -Component "PackageInstaller" -Severity "High"
}
```

##### `Get-ErrorSummary`
Retrieves summary of all registered errors.

**Syntax**:
```powershell
Get-ErrorSummary [<CommonParameters>]
```

**Returns**: Array of error objects

**Example**:
```powershell
$errors = Get-ErrorSummary
Write-Host "Total errors: $($errors.Count)"
$errors | Where-Object Severity -eq "Critical" | ForEach-Object {
    Write-Host "Critical error in $($_.Component): $($_.Message)"
}
```

## 🛠️ Installer Modules

### GitInstaller.psm1

Specialized installer for Git with enhanced configuration and validation.

#### Functions

##### `Install-Git`
Installs Git with comprehensive validation and configuration.

**Syntax**:
```powershell
Install-Git [[-ConfigureUser] <Boolean>] [[-UserName] <String>] [[-UserEmail] <String>] [<CommonParameters>]
```

**Parameters**:
- `ConfigureUser` (Boolean, Optional): Whether to configure Git user information
- `UserName` (String, Optional): Git user name
- `UserEmail` (String, Optional): Git user email

**Returns**: Hashtable with installation result

**Example**:
```powershell
$result = Install-Git -ConfigureUser $true -UserName "John Doe" -UserEmail "john@example.com"
if ($result.Success) {
    Write-Host "Git installed and configured successfully"
}
```

##### `Test-GitInstallation`
Validates Git installation and configuration.

**Syntax**:
```powershell
Test-GitInstallation [<CommonParameters>]
```

**Returns**: Hashtable with validation results

**Example**:
```powershell
$validation = Test-GitInstallation
if ($validation.IsInstalled) {
    Write-Host "Git version: $($validation.Version)"
    Write-Host "User configured: $($validation.UserConfigured)"
}
```

## 📝 Usage Patterns

### Basic Module Usage

```powershell
# Import required modules
Import-Module ".\modules\Core\Logger.psm1"
Import-Module ".\modules\Core\UserInterface-Simple.psm1"

# Initialize logging
Start-LogSession -LogFile "installation.log" -LogLevel "Info"

# Initialize UI
Initialize-UserInterface

# Show progress
Show-ProgressBar -CurrentStep 1 -TotalSteps 5 -CurrentTask "Starting installation"

# Get user input
$proceed = Get-YesNoChoice -Prompt "Continue with installation?"

# Log completion
Write-Log "Installation completed" -Level Success
Stop-LogSession
```

### Error Handling Pattern

```powershell
Import-Module ".\modules\Core\ErrorHandler.psm1"

try {
    # Perform installation task
    $result = Install-Package -PackageName "example-tool"
    
    if (-not $result.Success) {
        Register-Error -ErrorMessage $result.Message -Component "PackageInstaller" -Severity "High"
    }
} catch {
    Register-Error -ErrorMessage $_.Exception.Message -Component "PackageInstaller" -Severity "Critical"
}

# Review errors at end
$errors = Get-ErrorSummary
if ($errors.Count -gt 0) {
    Write-Host "Installation completed with $($errors.Count) errors"
}
```

### Complete Installation Flow

```powershell
# Import all required modules
$modules = @(
    ".\modules\Core\Logger.psm1",
    ".\modules\Core\UserInterface-Simple.psm1",
    ".\modules\Core\SystemCheck.psm1",
    ".\modules\Core\PackageManager.psm1"
)

foreach ($module in $modules) {
    Import-Module $module -Force
}

# Initialize systems
Start-LogSession -LogFile "installation.log"
Initialize-UserInterface

# Check system readiness
$readiness = Test-SystemReadiness
if (-not $readiness.Ready) {
    Write-Log "System not ready: $($readiness.CriticalIssues -join ', ')" -Level Error
    return
}

# Get user choices
$tools = Show-ToolSelectionMenu -AvailableTools @("git", "oh-my-posh", "fzf")
$config = Show-ConfigurationMenu

# Install tools
$results = @{}
for ($i = 0; $i -lt $tools.Count; $i++) {
    $tool = $tools[$i]
    Show-ProgressBar -CurrentStep ($i + 1) -TotalSteps $tools.Count -CurrentTask "Installing $tool"
    $results[$tool] = Install-Package -PackageName $tool
}

# Show summary
Show-InstallationSummary -Results $results
Stop-LogSession
```

## 🔗 Related Documentation

- **[Installation Guide](INSTALLATION_GUIDE.md)** - End-user installation instructions
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions
- **[Contributing Guide](CONTRIBUTING.md)** - Development guidelines and standards
- **[Architecture Guide](ARCHITECTURE.md)** - System design and architecture decisions
- **[FAQ](FAQ.md)** - Frequently asked questions

## 📞 Support

For API-related questions or issues:
- **GitHub Issues**: Report bugs or request features
- **GitHub Discussions**: Ask questions and share ideas
- **Documentation**: Check other guides in the `docs/` folder

---

*This API documentation is automatically updated with each release. Last updated: $(Get-Date -Format 'yyyy-MM-dd')*
