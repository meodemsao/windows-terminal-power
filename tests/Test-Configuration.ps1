#Requires -Version 5.1
<#
.SYNOPSIS
    Test configuration and validation script for different Windows environments

.DESCRIPTION
    Validates the testing environment and provides configuration for running tests
    across different Windows versions, PowerShell versions, and system configurations.

.PARAMETER ValidateEnvironment
    Validate the current environment for testing

.PARAMETER GenerateReport
    Generate a comprehensive environment report

.PARAMETER CheckDependencies
    Check all required dependencies for testing

.PARAMETER SetupCI
    Setup configuration for CI/CD environments

.EXAMPLE
    .\Test-Configuration.ps1 -ValidateEnvironment
    Validate current environment for testing

.EXAMPLE
    .\Test-Configuration.ps1 -GenerateReport -CheckDependencies
    Generate full environment report with dependency check
#>

[CmdletBinding()]
param(
    [switch]$ValidateEnvironment,
    [switch]$GenerateReport,
    [switch]$CheckDependencies,
    [switch]$SetupCI
)

# Test configuration constants
$script:TestConfig = @{
    MinimumPowerShellVersion = [Version]"5.1.0"
    MinimumWindowsBuild = 18362  # Windows 10 1903
    RequiredModules = @("Pester")
    OptionalModules = @("PSScriptAnalyzer", "platyPS")
    TestCategories = @("Unit", "Integration", "Performance", "Security")
    SupportedPackageManagers = @("winget", "choco", "scoop")
    TestTimeouts = @{
        Unit = 300          # 5 minutes
        Integration = 1200  # 20 minutes
        Performance = 600   # 10 minutes
        Security = 900      # 15 minutes
    }
}

function Test-SystemCompatibility {
    <#
    .SYNOPSIS
        Tests system compatibility for running tests
    #>
    [CmdletBinding()]
    param()
    
    $compatibility = @{
        Overall = $true
        Issues = @()
        Warnings = @()
        Information = @()
    }
    
    Write-Host "Testing system compatibility..." -ForegroundColor Cyan
    
    # Test Windows version
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $buildNumber = [int]$osInfo.BuildNumber
        
        if ($buildNumber -ge $script:TestConfig.MinimumWindowsBuild) {
            $compatibility.Information += "Windows version: $($osInfo.Caption) (build $buildNumber) - Compatible"
        } else {
            $compatibility.Overall = $false
            $compatibility.Issues += "Windows build $buildNumber is below minimum required build $($script:TestConfig.MinimumWindowsBuild)"
        }
    }
    catch {
        $compatibility.Overall = $false
        $compatibility.Issues += "Failed to determine Windows version: $($_.Exception.Message)"
    }
    
    # Test PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion -ge $script:TestConfig.MinimumPowerShellVersion) {
        $compatibility.Information += "PowerShell version: $psVersion - Compatible"
    } else {
        $compatibility.Overall = $false
        $compatibility.Issues += "PowerShell version $psVersion is below minimum required version $($script:TestConfig.MinimumPowerShellVersion)"
    }
    
    # Test execution policy
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")) {
        $compatibility.Information += "Execution policy: $executionPolicy - Compatible"
    } else {
        $compatibility.Warnings += "Execution policy '$executionPolicy' may prevent test execution"
    }
    
    # Test available memory
    try {
        $memory = Get-CimInstance -ClassName Win32_ComputerSystem
        $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        
        if ($totalMemoryGB -ge 4) {
            $compatibility.Information += "Available memory: $totalMemoryGB GB - Sufficient"
        } else {
            $compatibility.Warnings += "Available memory: $totalMemoryGB GB - May be insufficient for comprehensive testing"
        }
    }
    catch {
        $compatibility.Warnings += "Failed to determine available memory: $($_.Exception.Message)"
    }
    
    # Test disk space
    try {
        $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
        $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
        
        if ($freeSpaceGB -ge 2) {
            $compatibility.Information += "Free disk space: $freeSpaceGB GB - Sufficient"
        } else {
            $compatibility.Warnings += "Free disk space: $freeSpaceGB GB - May be insufficient for test artifacts"
        }
    }
    catch {
        $compatibility.Warnings += "Failed to determine disk space: $($_.Exception.Message)"
    }
    
    # Test internet connectivity
    try {
        $testUrls = @("https://www.microsoft.com", "https://github.com")
        $connected = $false
        
        foreach ($url in $testUrls) {
            try {
                $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    $connected = $true
                    break
                }
            }
            catch {
                continue
            }
        }
        
        if ($connected) {
            $compatibility.Information += "Internet connectivity: Available"
        } else {
            $compatibility.Warnings += "Internet connectivity: Not available - Some tests may fail"
        }
    }
    catch {
        $compatibility.Warnings += "Failed to test internet connectivity: $($_.Exception.Message)"
    }
    
    # Test package managers
    $availableManagers = @()
    foreach ($manager in $script:TestConfig.SupportedPackageManagers) {
        if (Get-Command $manager -ErrorAction SilentlyContinue) {
            $availableManagers += $manager
        }
    }
    
    if ($availableManagers.Count -gt 0) {
        $compatibility.Information += "Package managers available: $($availableManagers -join ', ')"
    } else {
        $compatibility.Warnings += "No supported package managers found - Integration tests may be limited"
    }
    
    return $compatibility
}

function Test-Dependencies {
    <#
    .SYNOPSIS
        Tests required and optional dependencies
    #>
    [CmdletBinding()]
    param()
    
    $dependencies = @{
        Required = @()
        Optional = @()
        Missing = @()
        Issues = @()
    }
    
    Write-Host "Checking dependencies..." -ForegroundColor Cyan
    
    # Check required modules
    foreach ($module in $script:TestConfig.RequiredModules) {
        $moduleInfo = Get-Module -ListAvailable -Name $module | Select-Object -First 1
        
        if ($moduleInfo) {
            $dependencies.Required += @{
                Name = $module
                Version = $moduleInfo.Version
                Status = "Available"
            }
        } else {
            $dependencies.Missing += $module
            $dependencies.Issues += "Required module '$module' is not installed"
        }
    }
    
    # Check optional modules
    foreach ($module in $script:TestConfig.OptionalModules) {
        $moduleInfo = Get-Module -ListAvailable -Name $module | Select-Object -First 1
        
        if ($moduleInfo) {
            $dependencies.Optional += @{
                Name = $module
                Version = $moduleInfo.Version
                Status = "Available"
            }
        } else {
            $dependencies.Optional += @{
                Name = $module
                Version = "Not installed"
                Status = "Missing"
            }
        }
    }
    
    # Check .NET Framework version (for PowerShell 5.1)
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        try {
            $dotNetVersion = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release -ErrorAction SilentlyContinue
            if ($dotNetVersion -and $dotNetVersion.Release -ge 461808) {  # .NET 4.7.2
                $dependencies.Required += @{
                    Name = ".NET Framework"
                    Version = "4.7.2+"
                    Status = "Available"
                }
            } else {
                $dependencies.Issues += ".NET Framework 4.7.2 or later is recommended for PowerShell 5.1"
            }
        }
        catch {
            $dependencies.Issues += "Failed to determine .NET Framework version: $($_.Exception.Message)"
        }
    }
    
    return $dependencies
}

function Install-MissingDependencies {
    <#
    .SYNOPSIS
        Installs missing required dependencies
    #>
    [CmdletBinding()]
    param(
        [array]$MissingModules
    )
    
    if ($MissingModules.Count -eq 0) {
        Write-Host "No missing dependencies to install" -ForegroundColor Green
        return $true
    }
    
    Write-Host "Installing missing dependencies..." -ForegroundColor Yellow
    
    $installSuccess = $true
    
    foreach ($module in $MissingModules) {
        try {
            Write-Host "Installing $module..." -ForegroundColor Gray
            Install-Module -Name $module -Force -SkipPublisherCheck -Scope CurrentUser
            Write-Host "Successfully installed $module" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install $module : $($_.Exception.Message)"
            $installSuccess = $false
        }
    }
    
    return $installSuccess
}

function New-TestEnvironmentReport {
    <#
    .SYNOPSIS
        Generates a comprehensive test environment report
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Generating test environment report..." -ForegroundColor Cyan
    
    $report = @{
        Timestamp = Get-Date
        System = @{}
        PowerShell = @{}
        Dependencies = @{}
        Compatibility = @{}
        Configuration = $script:TestConfig
    }
    
    # System information
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
        
        $report.System = @{
            OperatingSystem = $osInfo.Caption
            Version = $osInfo.Version
            BuildNumber = $osInfo.BuildNumber
            Architecture = $osInfo.OSArchitecture
            TotalMemoryGB = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)
            Manufacturer = $computerInfo.Manufacturer
            Model = $computerInfo.Model
        }
    }
    catch {
        $report.System.Error = $_.Exception.Message
    }
    
    # PowerShell information
    $report.PowerShell = @{
        Version = $PSVersionTable.PSVersion
        Edition = $PSVersionTable.PSEdition
        Platform = $PSVersionTable.Platform
        ExecutionPolicy = Get-ExecutionPolicy
        Host = $Host.Name
        Culture = $Host.CurrentCulture
    }
    
    # Test compatibility
    $report.Compatibility = Test-SystemCompatibility
    
    # Dependencies
    $report.Dependencies = Test-Dependencies
    
    # Package managers
    $packageManagers = @()
    foreach ($manager in $script:TestConfig.SupportedPackageManagers) {
        $command = Get-Command $manager -ErrorAction SilentlyContinue
        if ($command) {
            try {
                $version = & $manager --version 2>$null | Select-Object -First 1
                $packageManagers += @{
                    Name = $manager
                    Version = $version
                    Path = $command.Source
                }
            }
            catch {
                $packageManagers += @{
                    Name = $manager
                    Version = "Unknown"
                    Path = $command.Source
                }
            }
        }
    }
    $report.PackageManagers = $packageManagers
    
    return $report
}

function Show-EnvironmentReport {
    <#
    .SYNOPSIS
        Displays the environment report in a readable format
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Report
    )
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                         TEST ENVIRONMENT REPORT                              " -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # System Information
    Write-Host "System Information:" -ForegroundColor White
    if ($Report.System.Error) {
        Write-Host "  Error: $($Report.System.Error)" -ForegroundColor Red
    } else {
        Write-Host "  OS: $($Report.System.OperatingSystem)" -ForegroundColor Gray
        Write-Host "  Version: $($Report.System.Version) (Build $($Report.System.BuildNumber))" -ForegroundColor Gray
        Write-Host "  Architecture: $($Report.System.Architecture)" -ForegroundColor Gray
        Write-Host "  Memory: $($Report.System.TotalMemoryGB) GB" -ForegroundColor Gray
        Write-Host "  Computer: $($Report.System.Manufacturer) $($Report.System.Model)" -ForegroundColor Gray
    }
    Write-Host ""
    
    # PowerShell Information
    Write-Host "PowerShell Information:" -ForegroundColor White
    Write-Host "  Version: $($Report.PowerShell.Version)" -ForegroundColor Gray
    Write-Host "  Edition: $($Report.PowerShell.Edition)" -ForegroundColor Gray
    if ($Report.PowerShell.Platform) {
        Write-Host "  Platform: $($Report.PowerShell.Platform)" -ForegroundColor Gray
    }
    Write-Host "  Execution Policy: $($Report.PowerShell.ExecutionPolicy)" -ForegroundColor Gray
    Write-Host "  Host: $($Report.PowerShell.Host)" -ForegroundColor Gray
    Write-Host ""
    
    # Compatibility Status
    Write-Host "Compatibility Status:" -ForegroundColor White
    if ($Report.Compatibility.Overall) {
        Write-Host "  Overall: Compatible" -ForegroundColor Green
    } else {
        Write-Host "  Overall: Issues Found" -ForegroundColor Red
    }
    
    if ($Report.Compatibility.Issues.Count -gt 0) {
        Write-Host "  Issues:" -ForegroundColor Red
        $Report.Compatibility.Issues | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor Red
        }
    }
    
    if ($Report.Compatibility.Warnings.Count -gt 0) {
        Write-Host "  Warnings:" -ForegroundColor Yellow
        $Report.Compatibility.Warnings | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor Yellow
        }
    }
    
    if ($Report.Compatibility.Information.Count -gt 0) {
        Write-Host "  Information:" -ForegroundColor Gray
        $Report.Compatibility.Information | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor Gray
        }
    }
    Write-Host ""
    
    # Dependencies
    Write-Host "Dependencies:" -ForegroundColor White
    
    if ($Report.Dependencies.Required.Count -gt 0) {
        Write-Host "  Required Modules:" -ForegroundColor Gray
        $Report.Dependencies.Required | ForEach-Object {
            Write-Host "    - $($_.Name) ($($_.Version)) - $($_.Status)" -ForegroundColor Green
        }
    }
    
    if ($Report.Dependencies.Optional.Count -gt 0) {
        Write-Host "  Optional Modules:" -ForegroundColor Gray
        $Report.Dependencies.Optional | ForEach-Object {
            $color = if ($_.Status -eq "Available") { "Green" } else { "Yellow" }
            Write-Host "    - $($_.Name) ($($_.Version)) - $($_.Status)" -ForegroundColor $color
        }
    }
    
    if ($Report.Dependencies.Missing.Count -gt 0) {
        Write-Host "  Missing Required:" -ForegroundColor Red
        $Report.Dependencies.Missing | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor Red
        }
    }
    Write-Host ""
    
    # Package Managers
    if ($Report.PackageManagers.Count -gt 0) {
        Write-Host "Package Managers:" -ForegroundColor White
        $Report.PackageManagers | ForEach-Object {
            Write-Host "  - $($_.Name) ($($_.Version))" -ForegroundColor Green
        }
    } else {
        Write-Host "Package Managers: None detected" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Test Configuration
    Write-Host "Test Configuration:" -ForegroundColor White
    Write-Host "  Minimum PowerShell: $($Report.Configuration.MinimumPowerShellVersion)" -ForegroundColor Gray
    Write-Host "  Minimum Windows Build: $($Report.Configuration.MinimumWindowsBuild)" -ForegroundColor Gray
    Write-Host "  Test Categories: $($Report.Configuration.TestCategories -join ', ')" -ForegroundColor Gray
    Write-Host "  Test Timeouts:" -ForegroundColor Gray
    $Report.Configuration.TestTimeouts.GetEnumerator() | ForEach-Object {
        Write-Host "    $($_.Key): $($_.Value) seconds" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Recommendations
    Write-Host "Recommendations:" -ForegroundColor Yellow
    
    if ($Report.Dependencies.Missing.Count -gt 0) {
        Write-Host "  • Install missing required modules: $($Report.Dependencies.Missing -join ', ')" -ForegroundColor Cyan
    }
    
    if ($Report.Compatibility.Issues.Count -gt 0) {
        Write-Host "  • Resolve compatibility issues before running tests" -ForegroundColor Cyan
    }
    
    if ($Report.PackageManagers.Count -eq 0) {
        Write-Host "  • Install a package manager (winget, chocolatey, or scoop) for integration tests" -ForegroundColor Cyan
    }
    
    $optionalMissing = $Report.Dependencies.Optional | Where-Object { $_.Status -eq "Missing" }
    if ($optionalMissing.Count -gt 0) {
        Write-Host "  • Consider installing optional modules: $($optionalMissing.Name -join ', ')" -ForegroundColor Cyan
    }
    
    Write-Host ""
}

function Initialize-CIEnvironment {
    <#
    .SYNOPSIS
        Initializes environment for CI/CD testing
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Initializing CI/CD environment..." -ForegroundColor Cyan
    
    # Install required modules
    $dependencies = Test-Dependencies
    if ($dependencies.Missing.Count -gt 0) {
        $success = Install-MissingDependencies -MissingModules $dependencies.Missing
        if (-not $success) {
            throw "Failed to install required dependencies for CI environment"
        }
    }
    
    # Set execution policy if needed
    $currentPolicy = Get-ExecutionPolicy
    if ($currentPolicy -notin @("RemoteSigned", "Unrestricted", "Bypass")) {
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Host "Set execution policy to RemoteSigned" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to set execution policy: $($_.Exception.Message)"
        }
    }
    
    # Create test results directory
    $testResultsPath = Join-Path $PSScriptRoot "TestResults"
    if (-not (Test-Path $testResultsPath)) {
        New-Item -ItemType Directory -Path $testResultsPath -Force | Out-Null
        Write-Host "Created test results directory: $testResultsPath" -ForegroundColor Green
    }
    
    Write-Host "CI/CD environment initialized successfully" -ForegroundColor Green
}

function Main {
    <#
    .SYNOPSIS
        Main execution function
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Windows Terminal & PowerShell Setup - Test Configuration" -ForegroundColor Cyan
    Write-Host "=========================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $exitCode = 0
    
    try {
        if ($SetupCI) {
            Initialize-CIEnvironment
        }
        
        if ($ValidateEnvironment -or $GenerateReport) {
            $report = New-TestEnvironmentReport
            
            if ($GenerateReport) {
                Show-EnvironmentReport -Report $report
                
                # Save report to file
                $reportFile = Join-Path $PSScriptRoot "TestEnvironmentReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding UTF8
                Write-Host "Report saved to: $reportFile" -ForegroundColor Gray
            }
            
            if ($ValidateEnvironment) {
                if (-not $report.Compatibility.Overall) {
                    Write-Host "Environment validation failed" -ForegroundColor Red
                    $exitCode = 1
                } else {
                    Write-Host "Environment validation passed" -ForegroundColor Green
                }
            }
        }
        
        if ($CheckDependencies) {
            $dependencies = Test-Dependencies
            
            if ($dependencies.Missing.Count -gt 0) {
                Write-Host "Missing required dependencies: $($dependencies.Missing -join ', ')" -ForegroundColor Red
                
                $install = Read-Host "Install missing dependencies? (y/N)"
                if ($install -eq 'y' -or $install -eq 'Y') {
                    $success = Install-MissingDependencies -MissingModules $dependencies.Missing
                    if (-not $success) {
                        $exitCode = 1
                    }
                } else {
                    $exitCode = 1
                }
            } else {
                Write-Host "All required dependencies are available" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Error "Configuration failed: $($_.Exception.Message)"
        $exitCode = 1
    }
    
    exit $exitCode
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
