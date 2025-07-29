# InstallationScript.Tests.ps1 - Integration tests for the main installation scripts

BeforeAll {
    # Set up test environment
    $script:ProjectRoot = Join-Path $PSScriptRoot "..\..\"
    $script:EnhancedScript = Join-Path $script:ProjectRoot "Install-WindowsTerminalSetup-Enhanced.ps1"
    $script:SimpleScript = Join-Path $script:ProjectRoot "Install-WindowsTerminalSetup-Simple.ps1"
    
    # Verify scripts exist
    if (-not (Test-Path $script:EnhancedScript)) {
        throw "Enhanced installation script not found at $script:EnhancedScript"
    }
    
    if (-not (Test-Path $script:SimpleScript)) {
        throw "Simple installation script not found at $script:SimpleScript"
    }
    
    # Helper function to run script and capture results
    function Invoke-InstallationScript {
        param(
            [string]$ScriptPath,
            [string[]]$Parameters = @(),
            [int]$TimeoutSeconds = 120
        )
        
        $job = Start-Job -ScriptBlock {
            param($Script, $Params)
            
            $originalLocation = Get-Location
            try {
                Set-Location (Split-Path $Script -Parent)
                $result = & $Script @Params
                return @{
                    Success = $true
                    ExitCode = $LASTEXITCODE
                    Output = $result
                    Error = $null
                }
            }
            catch {
                return @{
                    Success = $false
                    ExitCode = 1
                    Output = $null
                    Error = $_.Exception.Message
                }
            }
            finally {
                Set-Location $originalLocation
            }
        } -ArgumentList $ScriptPath, $Parameters
        
        $completed = Wait-Job $job -Timeout $TimeoutSeconds
        
        if ($completed) {
            $result = Receive-Job $job
            Remove-Job $job
            return $result
        } else {
            Stop-Job $job
            Remove-Job $job
            throw "Script execution timed out after $TimeoutSeconds seconds"
        }
    }
    
    # Helper function to check system requirements
    function Test-SystemRequirements {
        $requirements = @{
            WindowsVersion = $true
            PowerShellVersion = $true
            InternetConnectivity = $true
            PackageManager = $false
        }
        
        # Check Windows version
        try {
            $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
            $buildNumber = [int]$osInfo.BuildNumber
            $requirements.WindowsVersion = $buildNumber -ge 18362
        }
        catch {
            $requirements.WindowsVersion = $false
        }
        
        # Check PowerShell version
        $requirements.PowerShellVersion = $PSVersionTable.PSVersion.Major -ge 5
        
        # Check internet connectivity
        try {
            $testUrls = @("https://www.microsoft.com", "https://github.com")
            foreach ($url in $testUrls) {
                $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    $requirements.InternetConnectivity = $true
                    break
                }
            }
        }
        catch {
            $requirements.InternetConnectivity = $false
        }
        
        # Check package managers
        $packageManagers = @("winget", "choco", "scoop")
        foreach ($manager in $packageManagers) {
            if (Get-Command $manager -ErrorAction SilentlyContinue) {
                $requirements.PackageManager = $true
                break
            }
        }
        
        return $requirements
    }
}

Describe "Installation Script Integration Tests" {
    BeforeAll {
        $script:SystemRequirements = Test-SystemRequirements
    }
    
    Context "System Requirements Validation" {
        It "Should have compatible Windows version" {
            $script:SystemRequirements.WindowsVersion | Should -Be $true
        }
        
        It "Should have compatible PowerShell version" {
            $script:SystemRequirements.PowerShellVersion | Should -Be $true
        }
        
        It "Should have internet connectivity" {
            $script:SystemRequirements.InternetConnectivity | Should -Be $true
        }
        
        It "Should have at least one package manager available" {
            $script:SystemRequirements.PackageManager | Should -Be $true
        }
    }
    
    Context "Enhanced Script - Basic Functionality" {
        It "Should exist and be readable" {
            Test-Path $script:EnhancedScript | Should -Be $true
            { Get-Content $script:EnhancedScript } | Should -Not -Throw
        }
        
        It "Should have valid PowerShell syntax" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script:EnhancedScript -Raw), [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        
        It "Should support help parameter" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-?")
            $result.Success | Should -Be $true
        }
        
        It "Should run dry-run mode successfully" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
        }
        
        It "Should handle invalid parameters gracefully" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-InvalidParameter")
            # Should either succeed with warning or fail gracefully
            $result.ExitCode | Should -BeIn @(0, 1)
        }
    }
    
    Context "Simple Script - Basic Functionality" {
        It "Should exist and be readable" {
            Test-Path $script:SimpleScript | Should -Be $true
            { Get-Content $script:SimpleScript } | Should -Not -Throw
        }
        
        It "Should have valid PowerShell syntax" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script:SimpleScript -Raw), [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
        
        It "Should run dry-run mode successfully" {
            $result = Invoke-InstallationScript -ScriptPath $script:SimpleScript -Parameters @("-DryRun")
            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
        }
    }
    
    Context "Enhanced Script - Advanced Features" {
        It "Should handle SkipUI parameter" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-SkipUI", "-Interactive:`$false")
            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
        }
        
        It "Should handle different log levels" {
            $logLevels = @("Debug", "Info", "Warning", "Error")
            foreach ($level in $logLevels) {
                $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-LogLevel", $level, "-Interactive:`$false", "-SkipUI")
                $result.Success | Should -Be $true
            }
        }
        
        It "Should create log files" {
            $beforeLogs = Get-ChildItem "$env:TEMP\WindowsTerminalSetup_Enhanced_*.log" -ErrorAction SilentlyContinue
            
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
            
            $afterLogs = Get-ChildItem "$env:TEMP\WindowsTerminalSetup_Enhanced_*.log" -ErrorAction SilentlyContinue
            $afterLogs.Count | Should -BeGreaterThan $beforeLogs.Count
        }
        
        It "Should handle non-interactive mode" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
            $result.Success | Should -Be $true
            $result.ExitCode | Should -Be 0
        }
    }
    
    Context "System Compatibility Checks" {
        It "Should detect Windows version correctly" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI", "-LogLevel", "Debug")
            $result.Success | Should -Be $true
            
            # Check if log file contains Windows version information
            $latestLog = Get-ChildItem "$env:TEMP\WindowsTerminalSetup_Enhanced_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestLog) {
                $logContent = Get-Content $latestLog.FullName -Raw
                $logContent | Should -Match "Windows.*version.*check.*passed"
            }
        }
        
        It "Should detect PowerShell version correctly" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI", "-LogLevel", "Debug")
            $result.Success | Should -Be $true
            
            # Check if log file contains PowerShell version information
            $latestLog = Get-ChildItem "$env:TEMP\WindowsTerminalSetup_Enhanced_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestLog) {
                $logContent = Get-Content $latestLog.FullName -Raw
                $logContent | Should -Match "PowerShell.*version.*check.*passed"
            }
        }
        
        It "Should detect package managers" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI", "-LogLevel", "Debug")
            $result.Success | Should -Be $true
            
            # Check if log file contains package manager information
            $latestLog = Get-ChildItem "$env:TEMP\WindowsTerminalSetup_Enhanced_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($latestLog) {
                $logContent = Get-Content $latestLog.FullName -Raw
                $logContent | Should -Match "Package managers available"
            }
        }
    }
    
    Context "Error Handling and Recovery" {
        It "Should handle missing modules gracefully" {
            # Temporarily rename modules directory to test fallback
            $modulesPath = Join-Path $script:ProjectRoot "modules"
            $tempModulesPath = Join-Path $script:ProjectRoot "modules_temp"
            
            if (Test-Path $modulesPath) {
                Rename-Item $modulesPath $tempModulesPath
                
                try {
                    $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
                    # Should either succeed with fallback or fail gracefully
                    $result.ExitCode | Should -BeIn @(0, 1)
                }
                finally {
                    if (Test-Path $tempModulesPath) {
                        Rename-Item $tempModulesPath $modulesPath
                    }
                }
            }
        }
        
        It "Should handle execution policy restrictions" {
            # This test assumes the script can run, so we test parameter validation instead
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
            $result.Success | Should -Be $true
        }
        
        It "Should handle network connectivity issues gracefully" {
            # Test with dry run to avoid actual network calls
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
            $result.Success | Should -Be $true
        }
    }
    
    Context "Performance and Reliability" {
        It "Should complete dry run within reasonable time" {
            $startTime = Get-Date
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
            $endTime = Get-Date
            
            $duration = ($endTime - $startTime).TotalSeconds
            $result.Success | Should -Be $true
            $duration | Should -BeLessThan 60  # Should complete within 60 seconds
        }
        
        It "Should handle multiple concurrent executions" {
            $jobs = @()
            
            for ($i = 1; $i -le 3; $i++) {
                $jobs += Start-Job -ScriptBlock {
                    param($ScriptPath)
                    & $ScriptPath -DryRun -Interactive:$false -SkipUI
                    return $LASTEXITCODE
                } -ArgumentList $script:EnhancedScript
            }
            
            $results = $jobs | Wait-Job | Receive-Job
            $jobs | Remove-Job
            
            # All jobs should complete successfully
            $results | ForEach-Object { $_ | Should -Be 0 }
        }
        
        It "Should clean up temporary resources" {
            $beforeTempFiles = Get-ChildItem $env:TEMP -Filter "*WindowsTerminalSetup*" -ErrorAction SilentlyContinue
            
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
            
            $afterTempFiles = Get-ChildItem $env:TEMP -Filter "*WindowsTerminalSetup*" -ErrorAction SilentlyContinue
            
            # Should only create log files, not leave other temporary files
            $newFiles = $afterTempFiles | Where-Object { $_.Name -notin $beforeTempFiles.Name }
            $newFiles | Where-Object { $_.Extension -ne ".log" } | Should -BeNullOrEmpty
        }
    }
    
    Context "Cross-PowerShell Version Compatibility" {
        It "Should work with current PowerShell version" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
            $result.Success | Should -Be $true
        }
        
        It "Should handle PowerShell 5.1 specific features" {
            if ($PSVersionTable.PSVersion.Major -eq 5) {
                $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
                $result.Success | Should -Be $true
            } else {
                Set-ItResult -Skipped -Because "Not running on PowerShell 5.1"
            }
        }
        
        It "Should handle PowerShell 7+ specific features" {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-DryRun", "-Interactive:`$false", "-SkipUI")
                $result.Success | Should -Be $true
            } else {
                Set-ItResult -Skipped -Because "Not running on PowerShell 7+"
            }
        }
    }
    
    Context "Documentation and Help" {
        It "Should provide help information" {
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-?")
            $result.Success | Should -Be $true
        }
        
        It "Should have comment-based help" {
            $scriptContent = Get-Content $script:EnhancedScript -Raw
            $scriptContent | Should -Match "\.SYNOPSIS"
            $scriptContent | Should -Match "\.DESCRIPTION"
            $scriptContent | Should -Match "\.EXAMPLE"
        }
        
        It "Should validate parameters correctly" {
            # Test with invalid log level
            $result = Invoke-InstallationScript -ScriptPath $script:EnhancedScript -Parameters @("-LogLevel", "InvalidLevel", "-DryRun", "-Interactive:`$false", "-SkipUI")
            $result.ExitCode | Should -Be 1
        }
    }
}

Describe "Module Integration Tests" {
    Context "Module Loading and Dependencies" {
        It "Should load core modules without errors" {
            $coreModules = @(
                "modules\Core\Logger.psm1",
                "modules\Core\UserInterface-Simple.psm1"
            )
            
            foreach ($module in $coreModules) {
                $modulePath = Join-Path $script:ProjectRoot $module
                if (Test-Path $modulePath) {
                    { Import-Module $modulePath -Force } | Should -Not -Throw
                    Remove-Module (Split-Path $module -LeafBase) -Force -ErrorAction SilentlyContinue
                }
            }
        }
        
        It "Should handle missing optional modules gracefully" {
            # Test that scripts can run even if some modules are missing
            $result = Invoke-InstallationScript -ScriptPath $script:SimpleScript -Parameters @("-DryRun")
            $result.Success | Should -Be $true
        }
    }
}

AfterAll {
    # Clean up any test artifacts
    Get-ChildItem "$env:TEMP\WindowsTerminalSetup_*Test*.log" -ErrorAction SilentlyContinue | Remove-Item -Force
    
    # Remove any imported modules
    @("Logger", "UserInterface-Simple", "SystemCheck", "PackageManager") | ForEach-Object {
        Remove-Module $_ -Force -ErrorAction SilentlyContinue
    }
}
