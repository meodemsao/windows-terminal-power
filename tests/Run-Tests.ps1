#Requires -Version 5.1
<#
.SYNOPSIS
    Test runner for Windows Terminal & PowerShell Setup project

.DESCRIPTION
    Comprehensive test runner that executes unit tests, integration tests, and generates reports.
    Supports different test categories, coverage analysis, and CI/CD integration.

.PARAMETER TestType
    Type of tests to run (Unit, Integration, All)

.PARAMETER ModuleName
    Specific module to test (optional)

.PARAMETER GenerateCoverage
    Generate code coverage report

.PARAMETER OutputFormat
    Output format for test results (NUnitXml, JUnitXml, Console)

.PARAMETER OutputPath
    Path for test result output files

.PARAMETER Detailed
    Show detailed test output

.PARAMETER PassThru
    Return test results object

.EXAMPLE
    .\Run-Tests.ps1
    Run all tests with default settings

.EXAMPLE
    .\Run-Tests.ps1 -TestType Unit -ModuleName Logger
    Run unit tests for Logger module only

.EXAMPLE
    .\Run-Tests.ps1 -GenerateCoverage -OutputFormat NUnitXml -OutputPath "TestResults"
    Run all tests with coverage and XML output
#>

[CmdletBinding()]
param(
    [ValidateSet("Unit", "Integration", "All")]
    [string]$TestType = "All",
    
    [string]$ModuleName = "",
    
    [switch]$GenerateCoverage,
    
    [ValidateSet("Console", "NUnitXml", "JUnitXml")]
    [string]$OutputFormat = "Console",
    
    [string]$OutputPath = "TestResults",
    
    [switch]$Detailed,
    
    [switch]$PassThru
)

# Script variables
$script:ProjectRoot = Split-Path $PSScriptRoot -Parent
$script:TestsRoot = $PSScriptRoot
$script:ModulesRoot = Join-Path $script:ProjectRoot "modules"
$script:TestResults = $null

function Initialize-TestEnvironment {
    <#
    .SYNOPSIS
        Initializes the test environment
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Initializing test environment..." -ForegroundColor Cyan
    
    # Check if Pester is available
    $pesterModule = Get-Module -ListAvailable -Name Pester
    if (-not $pesterModule) {
        Write-Warning "Pester module not found. Installing Pester..."
        try {
            Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
            Write-Host "Pester installed successfully" -ForegroundColor Green
        }
        catch {
            throw "Failed to install Pester: $($_.Exception.Message)"
        }
    }
    
    # Import Pester
    Import-Module Pester -Force
    
    # Check Pester version
    $pesterVersion = (Get-Module Pester).Version
    Write-Host "Using Pester version: $pesterVersion" -ForegroundColor Gray
    
    if ($pesterVersion.Major -lt 5) {
        Write-Warning "Pester version 5.0+ is recommended for best results"
    }
    
    # Create output directory if needed
    if ($OutputPath -and -not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "Created output directory: $OutputPath" -ForegroundColor Gray
    }
    
    # Verify project structure
    $requiredPaths = @(
        $script:ProjectRoot,
        $script:ModulesRoot,
        (Join-Path $script:TestsRoot "Unit"),
        (Join-Path $script:TestsRoot "Integration")
    )
    
    foreach ($path in $requiredPaths) {
        if (-not (Test-Path $path)) {
            throw "Required path not found: $path"
        }
    }
    
    Write-Host "Test environment initialized successfully" -ForegroundColor Green
}

function Get-TestFiles {
    <#
    .SYNOPSIS
        Gets list of test files to execute
    #>
    [CmdletBinding()]
    param(
        [string]$Type,
        [string]$Module
    )
    
    $testFiles = @()
    
    switch ($Type) {
        "Unit" {
            $unitPath = Join-Path $script:TestsRoot "Unit"
            if ($Module) {
                $testFiles = Get-ChildItem -Path $unitPath -Filter "*$Module*.Tests.ps1" -Recurse
            } else {
                $testFiles = Get-ChildItem -Path $unitPath -Filter "*.Tests.ps1" -Recurse
            }
        }
        "Integration" {
            $integrationPath = Join-Path $script:TestsRoot "Integration"
            if ($Module) {
                $testFiles = Get-ChildItem -Path $integrationPath -Filter "*$Module*.Tests.ps1" -Recurse
            } else {
                $testFiles = Get-ChildItem -Path $integrationPath -Filter "*.Tests.ps1" -Recurse
            }
        }
        "All" {
            if ($Module) {
                $testFiles = Get-ChildItem -Path $script:TestsRoot -Filter "*$Module*.Tests.ps1" -Recurse
            } else {
                $testFiles = Get-ChildItem -Path $script:TestsRoot -Filter "*.Tests.ps1" -Recurse
            }
        }
    }
    
    return $testFiles
}

function Get-CodeCoverageFiles {
    <#
    .SYNOPSIS
        Gets list of files for code coverage analysis
    #>
    [CmdletBinding()]
    param()
    
    $coverageFiles = @()
    
    # Include all PowerShell module files
    $coverageFiles += Get-ChildItem -Path $script:ModulesRoot -Filter "*.psm1" -Recurse
    
    # Include main installation scripts
    $mainScripts = @(
        "Install-WindowsTerminalSetup-Enhanced.ps1",
        "Install-WindowsTerminalSetup-Simple.ps1"
    )
    
    foreach ($script in $mainScripts) {
        $scriptPath = Join-Path $script:ProjectRoot $script
        if (Test-Path $scriptPath) {
            $coverageFiles += Get-Item $scriptPath
        }
    }
    
    return $coverageFiles.FullName
}

function Invoke-TestExecution {
    <#
    .SYNOPSIS
        Executes the tests with specified configuration
    #>
    [CmdletBinding()]
    param(
        [array]$TestFiles,
        [array]$CoverageFiles = @()
    )

    Write-Host "Executing tests..." -ForegroundColor Cyan
    Write-Host "Test files: $($TestFiles.Count)" -ForegroundColor Gray

    if ($CoverageFiles.Count -gt 0) {
        Write-Host "Coverage files: $($CoverageFiles.Count)" -ForegroundColor Gray
    }

    # Get Pester version to determine which API to use
    $pesterVersion = (Get-Module Pester).Version

    # Execute tests based on Pester version
    try {
        if ($pesterVersion.Major -ge 5) {
            # Use Pester 5+ configuration API
            $script:TestResults = Invoke-PesterV5 -TestFiles $TestFiles -CoverageFiles $CoverageFiles
        } else {
            # Use legacy Pester 3/4 API
            $script:TestResults = Invoke-PesterLegacy -TestFiles $TestFiles -CoverageFiles $CoverageFiles
        }

        return $script:TestResults
    }
    catch {
        Write-Error "Test execution failed: $($_.Exception.Message)"
        throw
    }
}

function Invoke-PesterV5 {
    <#
    .SYNOPSIS
        Executes tests using Pester 5+ configuration API
    #>
    [CmdletBinding()]
    param(
        [array]$TestFiles,
        [array]$CoverageFiles = @()
    )

    # Configure Pester
    $pesterConfig = @{
        Run = @{
            Path = $TestFiles.FullName
            PassThru = $true
        }
        Output = @{
            Verbosity = if ($Detailed) { "Detailed" } else { "Normal" }
        }
        TestResult = @{
            Enabled = $OutputFormat -ne "Console"
        }
    }

    # Configure output format
    if ($OutputFormat -ne "Console") {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $outputFile = Join-Path $OutputPath "TestResults_$timestamp.xml"

        $pesterConfig.TestResult.OutputPath = $outputFile
        $pesterConfig.TestResult.OutputFormat = $OutputFormat

        Write-Host "Test results will be saved to: $outputFile" -ForegroundColor Gray
    }

    # Configure code coverage
    if ($GenerateCoverage -and $CoverageFiles.Count -gt 0) {
        $pesterConfig.CodeCoverage = @{
            Enabled = $true
            Path = $CoverageFiles
            OutputPath = Join-Path $OutputPath "Coverage_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"
            OutputFormat = "JaCoCo"
        }

        Write-Host "Code coverage will be saved to: $($pesterConfig.CodeCoverage.OutputPath)" -ForegroundColor Gray
    }

    # Create Pester configuration
    $configuration = New-PesterConfiguration

    # Apply configuration
    foreach ($section in $pesterConfig.Keys) {
        foreach ($setting in $pesterConfig[$section].Keys) {
            $configuration[$section][$setting] = $pesterConfig[$section][$setting]
        }
    }

    # Execute tests
    return Invoke-Pester -Configuration $configuration
}

function Invoke-PesterLegacy {
    <#
    .SYNOPSIS
        Executes tests using legacy Pester 3/4 API
    #>
    [CmdletBinding()]
    param(
        [array]$TestFiles,
        [array]$CoverageFiles = @()
    )

    $pesterParams = @{
        Script = $TestFiles.FullName
        PassThru = $true
    }

    # Configure output format for legacy Pester
    if ($OutputFormat -ne "Console") {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $outputFile = Join-Path $OutputPath "TestResults_$timestamp.xml"

        $pesterParams.OutputFile = $outputFile
        $pesterParams.OutputFormat = $OutputFormat

        Write-Host "Test results will be saved to: $outputFile" -ForegroundColor Gray
    }

    # Configure code coverage for legacy Pester
    if ($GenerateCoverage -and $CoverageFiles.Count -gt 0) {
        $pesterParams.CodeCoverage = $CoverageFiles
        $pesterParams.CodeCoverageOutputFile = Join-Path $OutputPath "Coverage_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"

        Write-Host "Code coverage will be saved to: $($pesterParams.CodeCoverageOutputFile)" -ForegroundColor Gray
    }

    # Execute tests
    return Invoke-Pester @pesterParams
}

function Show-TestSummary {
    <#
    .SYNOPSIS
        Displays test execution summary
    #>
    [CmdletBinding()]
    param(
        [object]$Results
    )
    
    if (-not $Results) {
        Write-Warning "No test results to display"
        return
    }
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                              TEST SUMMARY                                     " -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Test execution summary (handle both Pester v3/4 and v5 result formats)
    $totalTests = if ($Results.TotalCount) { $Results.TotalCount } else { $Results.TestResult.Count }
    $passedTests = if ($Results.PassedCount) { $Results.PassedCount } else { ($Results.TestResult | Where-Object Result -eq "Passed").Count }
    $failedTests = if ($Results.FailedCount) { $Results.FailedCount } else { ($Results.TestResult | Where-Object Result -eq "Failed").Count }
    $skippedTests = if ($Results.SkippedCount) { $Results.SkippedCount } else { ($Results.TestResult | Where-Object Result -eq "Skipped").Count }
    
    Write-Host "Test Execution Results:" -ForegroundColor White
    Write-Host "  Total Tests: $totalTests" -ForegroundColor Gray
    Write-Host "  Passed: $passedTests" -ForegroundColor Green
    Write-Host "  Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Gray" })
    Write-Host "  Skipped: $skippedTests" -ForegroundColor Yellow
    Write-Host ""
    
    # Execution time (handle both Pester versions)
    $duration = if ($Results.Duration) { $Results.Duration } else { $Results.Time }
    if ($duration) {
        $durationStr = if ($duration.ToString) { $duration.ToString('mm\:ss\.fff') } else { $duration }
        Write-Host "Execution Time: $durationStr" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Success rate
    $successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
    $successColor = switch ($successRate) {
        { $_ -ge 95 } { "Green" }
        { $_ -ge 80 } { "Yellow" }
        default { "Red" }
    }
    Write-Host "Success Rate: $successRate%" -ForegroundColor $successColor
    Write-Host ""
    
    # Failed tests details (handle both Pester versions)
    if ($failedTests -gt 0) {
        Write-Host "Failed Tests:" -ForegroundColor Red

        $failedTestList = if ($Results.Failed) {
            $Results.Failed
        } else {
            $Results.TestResult | Where-Object Result -eq "Failed"
        }

        $failedTestList | ForEach-Object {
            $testName = if ($_.FullName) { $_.FullName } else { "$($_.Describe) $($_.Context) $($_.Name)" }
            Write-Host "  - $testName" -ForegroundColor Red

            $errorMessage = if ($_.ErrorRecord) {
                $_.ErrorRecord.Exception.Message
            } elseif ($_.FailureMessage) {
                $_.FailureMessage
            }

            if ($errorMessage) {
                Write-Host "    Error: $errorMessage" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
    
    # Code coverage summary
    if ($Results.CodeCoverage) {
        $coverage = $Results.CodeCoverage
        $coveragePercent = if ($coverage.NumberOfCommandsAnalyzed -gt 0) {
            [math]::Round(($coverage.NumberOfCommandsExecuted / $coverage.NumberOfCommandsAnalyzed) * 100, 2)
        } else { 0 }
        
        Write-Host "Code Coverage:" -ForegroundColor White
        Write-Host "  Commands Analyzed: $($coverage.NumberOfCommandsAnalyzed)" -ForegroundColor Gray
        Write-Host "  Commands Executed: $($coverage.NumberOfCommandsExecuted)" -ForegroundColor Gray
        Write-Host "  Coverage Percentage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { "Green" } else { "Yellow" })
        Write-Host ""
        
        # Missed commands
        if ($coverage.MissedCommands.Count -gt 0) {
            Write-Host "Missed Commands (first 10):" -ForegroundColor Yellow
            $coverage.MissedCommands | Select-Object -First 10 | ForEach-Object {
                Write-Host "  - Line $($_.Line): $($_.Command)" -ForegroundColor Gray
            }
            if ($coverage.MissedCommands.Count -gt 10) {
                Write-Host "  ... and $($coverage.MissedCommands.Count - 10) more" -ForegroundColor Gray
            }
            Write-Host ""
        }
    }
    
    # Overall result
    $overallResult = if ($failedTests -eq 0) { "PASSED" } else { "FAILED" }
    $resultColor = if ($failedTests -eq 0) { "Green" } else { "Red" }
    
    Write-Host "Overall Result: $overallResult" -ForegroundColor $resultColor
    Write-Host ""
    
    # Recommendations
    if ($failedTests -gt 0) {
        Write-Host "Recommendations:" -ForegroundColor Yellow
        Write-Host "  • Review failed test details above" -ForegroundColor Cyan
        Write-Host "  • Run tests with -Detailed for more information" -ForegroundColor Cyan
        Write-Host "  • Check test logs for additional context" -ForegroundColor Cyan
        Write-Host ""
    }
    
    if ($GenerateCoverage -and $Results.CodeCoverage -and $coveragePercent -lt 80) {
        Write-Host "Coverage Recommendations:" -ForegroundColor Yellow
        Write-Host "  • Add tests for missed commands" -ForegroundColor Cyan
        Write-Host "  • Target coverage above 80%" -ForegroundColor Cyan
        Write-Host ""
    }
}

function Main {
    <#
    .SYNOPSIS
        Main execution function
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Windows Terminal & PowerShell Setup - Test Runner" -ForegroundColor Cyan
        Write-Host "=================================================" -ForegroundColor Cyan
        Write-Host ""
        
        # Initialize test environment
        Initialize-TestEnvironment
        
        # Get test files
        Write-Host "Discovering test files..." -ForegroundColor Cyan
        $testFiles = Get-TestFiles -Type $TestType -Module $ModuleName
        
        if ($testFiles.Count -eq 0) {
            Write-Warning "No test files found matching criteria"
            Write-Host "  Test Type: $TestType" -ForegroundColor Gray
            if ($ModuleName) {
                Write-Host "  Module: $ModuleName" -ForegroundColor Gray
            }
            return
        }
        
        Write-Host "Found $($testFiles.Count) test file(s)" -ForegroundColor Green
        
        # Get coverage files if needed
        $coverageFiles = @()
        if ($GenerateCoverage) {
            Write-Host "Discovering files for code coverage..." -ForegroundColor Cyan
            $coverageFiles = Get-CodeCoverageFiles
            Write-Host "Found $($coverageFiles.Count) file(s) for coverage analysis" -ForegroundColor Green
        }
        
        # Execute tests
        $results = Invoke-TestExecution -TestFiles $testFiles -CoverageFiles $coverageFiles
        
        # Show summary
        Show-TestSummary -Results $results
        
        # Return results if requested
        if ($PassThru) {
            return $results
        }
        
        # Set exit code based on results
        if ($results.FailedCount -gt 0) {
            exit 1
        } else {
            exit 0
        }
    }
    catch {
        Write-Error "Test execution failed: $($_.Exception.Message)"
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        exit 1
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
