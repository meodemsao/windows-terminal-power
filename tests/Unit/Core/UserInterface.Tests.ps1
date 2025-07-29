# UserInterface.Tests.ps1 - Unit tests for the UserInterface module

BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot "..\..\..\modules\Core\UserInterface-Simple.psm1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        throw "UserInterface module not found at $ModulePath"
    }
    
    # Mock Write-Host to capture output for testing
    $script:CapturedOutput = @()
    
    function Mock-WriteHost {
        param(
            [Parameter(ValueFromPipeline = $true)]
            [string]$Object = "",
            [string]$ForegroundColor = "White",
            [switch]$NoNewline
        )
        
        $script:CapturedOutput += @{
            Text = $Object
            Color = $ForegroundColor
            NoNewline = $NoNewline.IsPresent
        }
    }
    
    # Mock Read-Host for input testing
    $script:MockedInputs = @()
    $script:InputIndex = 0
    
    function Mock-ReadHost {
        param([string]$Prompt)
        
        if ($script:InputIndex -lt $script:MockedInputs.Count) {
            $input = $script:MockedInputs[$script:InputIndex]
            $script:InputIndex++
            return $input
        }
        return ""
    }
    
    function Reset-Mocks {
        $script:CapturedOutput = @()
        $script:MockedInputs = @()
        $script:InputIndex = 0
    }
    
    function Set-MockedInputs {
        param([string[]]$Inputs)
        $script:MockedInputs = $Inputs
        $script:InputIndex = 0
    }
}

Describe "UserInterface Module" {
    Context "Module Import" {
        It "Should import without errors" {
            { Import-Module $ModulePath -Force } | Should -Not -Throw
        }
        
        It "Should export expected functions" {
            $exportedFunctions = Get-Command -Module (Get-Module UserInterface-Simple) -CommandType Function
            $expectedFunctions = @(
                'Initialize-UserInterface',
                'Show-WelcomeBanner',
                'Show-ProgressBar',
                'Show-StepHeader',
                'Get-UserChoice',
                'Get-YesNoChoice',
                'Show-ToolSelectionMenu',
                'Show-ConfigurationMenu',
                'Show-InstallationSummary'
            )
            
            foreach ($function in $expectedFunctions) {
                $exportedFunctions.Name | Should -Contain $function
            }
        }
    }
    
    Context "Initialize-UserInterface" {
        BeforeEach {
            Reset-Mocks
            Mock Write-Host { Mock-WriteHost @args }
            Mock Clear-Host { }
        }
        
        It "Should initialize successfully" {
            $result = Initialize-UserInterface
            $result | Should -Be $true
        }
        
        It "Should clear the screen" {
            Initialize-UserInterface
            Should -Invoke Clear-Host -Times 1
        }
        
        It "Should display welcome banner" {
            Mock Show-WelcomeBanner { }
            Initialize-UserInterface
            Should -Invoke Show-WelcomeBanner -Times 1
        }
        
        It "Should handle errors gracefully" {
            Mock Clear-Host { throw "Clear-Host failed" }
            $result = Initialize-UserInterface
            $result | Should -Be $false
        }
    }
    
    Context "Show-WelcomeBanner" {
        BeforeEach {
            Reset-Mocks
            Mock Write-Host { Mock-WriteHost @args }
        }
        
        It "Should display banner without errors" {
            { Show-WelcomeBanner } | Should -Not -Throw
        }
        
        It "Should display project title" {
            Show-WelcomeBanner
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "WINDOWS TERMINAL.*POWERSHELL SETUP" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should use appropriate colors" {
            Show-WelcomeBanner
            $cyanOutput = $script:CapturedOutput | Where-Object { $_.Color -eq "Cyan" }
            $cyanOutput | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Show-ProgressBar" {
        BeforeEach {
            Reset-Mocks
            Mock Write-Host { Mock-WriteHost @args }
            Mock Write-Progress { }
        }
        
        It "Should display progress bar without errors" {
            { Show-ProgressBar -CurrentStep 5 -TotalSteps 10 -CurrentTask "Testing" } | Should -Not -Throw
        }
        
        It "Should calculate percentage correctly" {
            Show-ProgressBar -CurrentStep 5 -TotalSteps 10 -CurrentTask "Testing"
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "50%" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle edge cases" {
            { Show-ProgressBar -CurrentStep 0 -TotalSteps 10 -CurrentTask "Starting" } | Should -Not -Throw
            { Show-ProgressBar -CurrentStep 10 -TotalSteps 10 -CurrentTask "Complete" } | Should -Not -Throw
        }
        
        It "Should handle zero total steps" {
            { Show-ProgressBar -CurrentStep 1 -TotalSteps 0 -CurrentTask "Testing" } | Should -Not -Throw
        }
        
        It "Should use Write-Progress for compatibility" {
            Show-ProgressBar -CurrentStep 3 -TotalSteps 10 -CurrentTask "Testing"
            Should -Invoke Write-Progress -Times 1
        }
        
        It "Should display current task" {
            Show-ProgressBar -CurrentStep 3 -TotalSteps 10 -CurrentTask "Installing Git"
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "Installing Git" }
            $output | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Show-StepHeader" {
        BeforeEach {
            Reset-Mocks
            Mock Write-Host { Mock-WriteHost @args }
        }
        
        It "Should display step header without errors" {
            { Show-StepHeader -StepNumber 1 -StepTitle "Test Step" } | Should -Not -Throw
        }
        
        It "Should display step number and title" {
            Show-StepHeader -StepNumber 2 -StepTitle "System Check"
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "STEP 2.*SYSTEM CHECK" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should display description when provided" {
            Show-StepHeader -StepNumber 1 -StepTitle "Test" -StepDescription "Test Description"
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "Test Description" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should use appropriate formatting" {
            Show-StepHeader -StepNumber 1 -StepTitle "Test"
            $separators = $script:CapturedOutput | Where-Object { $_.Text -match "={50,}" }
            $separators.Count | Should -BeGreaterOrEqual 2
        }
    }
    
    Context "Get-UserChoice" {
        BeforeEach {
            Reset-Mocks
            Mock Write-Host { Mock-WriteHost @args }
            Mock Read-Host { Mock-ReadHost @args }
        }
        
        It "Should return user input" {
            Set-MockedInputs @("test input")
            $result = Get-UserChoice -Prompt "Enter something"
            $result | Should -Be "test input"
        }
        
        It "Should return default when empty input provided" {
            Set-MockedInputs @("")
            $result = Get-UserChoice -Prompt "Enter something" -Default "default value"
            $result | Should -Be "default value"
        }
        
        It "Should handle numeric choices" {
            Set-MockedInputs @("2")
            $choices = @("Option 1", "Option 2", "Option 3")
            $result = Get-UserChoice -Prompt "Choose option" -Choices $choices
            $result | Should -Be "Option 2"
        }
        
        It "Should handle text-based choices" {
            Set-MockedInputs @("opt")
            $choices = @("Option 1", "Option 2", "Option 3")
            $result = Get-UserChoice -Prompt "Choose option" -Choices $choices
            $result | Should -Be "Option 1"
        }
        
        It "Should allow empty input when specified" {
            Set-MockedInputs @("")
            $result = Get-UserChoice -Prompt "Optional input" -AllowEmpty
            $result | Should -Be ""
        }
        
        It "Should display choices when provided" {
            Set-MockedInputs @("1")
            $choices = @("Choice A", "Choice B")
            Get-UserChoice -Prompt "Select" -Choices $choices
            
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "Choice A" }
            $output | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Get-YesNoChoice" {
        BeforeEach {
            Reset-Mocks
            Mock Get-UserChoice { 
                param($Prompt, $Choices, $Default)
                if ($script:MockedInputs.Count -gt $script:InputIndex) {
                    return $script:MockedInputs[$script:InputIndex++]
                }
                return $Default
            }
        }
        
        It "Should return true for Yes" {
            Set-MockedInputs @("Yes")
            $result = Get-YesNoChoice -Prompt "Continue?"
            $result | Should -Be $true
        }
        
        It "Should return false for No" {
            Set-MockedInputs @("No")
            $result = Get-YesNoChoice -Prompt "Continue?"
            $result | Should -Be $false
        }
        
        It "Should use default when no input" {
            Set-MockedInputs @()
            $result = Get-YesNoChoice -Prompt "Continue?" -Default "Y"
            $result | Should -Be $true
        }
        
        It "Should handle N default" {
            Set-MockedInputs @()
            $result = Get-YesNoChoice -Prompt "Continue?" -Default "N"
            $result | Should -Be $false
        }
    }
    
    Context "Show-InstallationSummary" {
        BeforeEach {
            Reset-Mocks
            Mock Write-Host { Mock-WriteHost @args }
            Mock Clear-Host { }
        }
        
        It "Should display summary without errors" {
            $results = @{
                "git" = @{ Success = $true; Message = "Installed"; Version = "2.42.0" }
                "fzf" = @{ Success = $false; Message = "Failed"; Version = $null }
            }
            
            { Show-InstallationSummary -Results $results } | Should -Not -Throw
        }
        
        It "Should show success count" {
            $results = @{
                "tool1" = @{ Success = $true; Message = "OK"; Version = "1.0" }
                "tool2" = @{ Success = $true; Message = "OK"; Version = "2.0" }
                "tool3" = @{ Success = $false; Message = "Failed"; Version = $null }
            }
            
            Show-InstallationSummary -Results $results
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "Successfully installed: 2" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should show failure count" {
            $results = @{
                "tool1" = @{ Success = $true; Message = "OK"; Version = "1.0" }
                "tool2" = @{ Success = $false; Message = "Failed"; Version = $null }
            }
            
            Show-InstallationSummary -Results $results
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "Failed installations: 1" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should display appropriate status for all success" {
            $results = @{
                "tool1" = @{ Success = $true; Message = "OK"; Version = "1.0" }
                "tool2" = @{ Success = $true; Message = "OK"; Version = "2.0" }
            }
            
            Show-InstallationSummary -Results $results
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "INSTALLATION COMPLETED SUCCESSFULLY" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should display appropriate status for mixed results" {
            $results = @{
                "tool1" = @{ Success = $true; Message = "OK"; Version = "1.0" }
                "tool2" = @{ Success = $false; Message = "Failed"; Version = $null }
            }
            
            Show-InstallationSummary -Results $results
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "INSTALLATION COMPLETED WITH WARNINGS" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should list successful installations" {
            $results = @{
                "git" = @{ Success = $true; Message = "OK"; Version = "2.42.0" }
                "fzf" = @{ Success = $true; Message = "OK"; Version = "0.44.1" }
            }
            
            Show-InstallationSummary -Results $results
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "git.*2\.42\.0" }
            $output | Should -Not -BeNullOrEmpty
        }
        
        It "Should list failed installations" {
            $results = @{
                "tool1" = @{ Success = $false; Message = "Package not found"; Version = $null }
            }
            
            Show-InstallationSummary -Results $results
            $output = $script:CapturedOutput | Where-Object { $_.Text -match "tool1.*Package not found" }
            $output | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Integration Tests" {
        BeforeEach {
            Reset-Mocks
            Mock Write-Host { Mock-WriteHost @args }
            Mock Clear-Host { }
            Mock Write-Progress { }
        }
        
        It "Should handle complete UI workflow" {
            # Initialize UI
            $initResult = Initialize-UserInterface
            $initResult | Should -Be $true
            
            # Show step header
            { Show-StepHeader -StepNumber 1 -StepTitle "Test Step" } | Should -Not -Throw
            
            # Show progress
            { Show-ProgressBar -CurrentStep 1 -TotalSteps 3 -CurrentTask "Testing" } | Should -Not -Throw
            
            # Show summary
            $results = @{
                "test" = @{ Success = $true; Message = "OK"; Version = "1.0" }
            }
            { Show-InstallationSummary -Results $results } | Should -Not -Throw
        }
    }
    
    Context "Error Handling" {
        BeforeEach {
            Reset-Mocks
        }
        
        It "Should handle Write-Host failures gracefully" {
            Mock Write-Host { throw "Write-Host failed" }
            
            # Functions should not throw even if Write-Host fails
            { Show-WelcomeBanner } | Should -Not -Throw
            { Show-StepHeader -StepNumber 1 -StepTitle "Test" } | Should -Not -Throw
        }
        
        It "Should handle invalid parameters gracefully" {
            Mock Write-Host { Mock-WriteHost @args }
            
            # Should handle negative step numbers
            { Show-ProgressBar -CurrentStep -1 -TotalSteps 10 -CurrentTask "Test" } | Should -Not -Throw
            
            # Should handle steps greater than total
            { Show-ProgressBar -CurrentStep 15 -TotalSteps 10 -CurrentTask "Test" } | Should -Not -Throw
        }
    }
    
    Context "Performance Tests" {
        BeforeEach {
            Reset-Mocks
            Mock Write-Host { }
            Mock Write-Progress { }
        }
        
        It "Should handle rapid progress updates efficiently" {
            $startTime = Get-Date
            
            for ($i = 1; $i -le 50; $i++) {
                Show-ProgressBar -CurrentStep $i -TotalSteps 50 -CurrentTask "Step $i"
            }
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            # Should complete 50 progress updates in under 2 seconds
            $duration | Should -BeLessThan 2
        }
        
        It "Should handle large installation summaries efficiently" {
            $results = @{}
            for ($i = 1; $i -le 100; $i++) {
                $results["tool$i"] = @{ 
                    Success = ($i % 2 -eq 0)
                    Message = "Test message $i"
                    Version = "1.$i.0"
                }
            }
            
            $startTime = Get-Date
            Show-InstallationSummary -Results $results
            $endTime = Get-Date
            
            $duration = ($endTime - $startTime).TotalSeconds
            # Should handle 100 tools in under 1 second
            $duration | Should -BeLessThan 1
        }
    }
}

AfterAll {
    # Remove the module
    Remove-Module UserInterface-Simple -Force -ErrorAction SilentlyContinue
}
