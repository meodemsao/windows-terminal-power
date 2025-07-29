# Logger.Tests.ps1 - Unit tests for the Logger module

BeforeAll {
    # Import the module under test
    $ModulePath = Join-Path $PSScriptRoot "..\..\..\modules\Core\Logger.psm1"
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        throw "Logger module not found at $ModulePath"
    }
    
    # Test helper functions
    function Get-TestLogFile {
        return Join-Path $TestDrive "test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    }
    
    function Get-LogContent {
        param([string]$LogFile)
        if (Test-Path $LogFile) {
            return Get-Content $LogFile
        }
        return @()
    }
}

Describe "Logger Module" {
    Context "Module Import" {
        It "Should import without errors" {
            { Import-Module $ModulePath -Force } | Should -Not -Throw
        }
        
        It "Should export expected functions" {
            $exportedFunctions = Get-Command -Module (Get-Module Logger) -CommandType Function
            $expectedFunctions = @('Start-LogSession', 'Write-Log', 'Stop-LogSession')
            
            foreach ($function in $expectedFunctions) {
                $exportedFunctions.Name | Should -Contain $function
            }
        }
    }
    
    Context "Start-LogSession" {
        BeforeEach {
            $script:TestLogFile = Get-TestLogFile
        }
        
        AfterEach {
            if (Test-Path $script:TestLogFile) {
                Remove-Item $script:TestLogFile -Force -ErrorAction SilentlyContinue
            }
            Stop-LogSession
        }
        
        It "Should create log file successfully" {
            $result = Start-LogSession -LogFile $script:TestLogFile
            $result | Should -Be $true
            Test-Path $script:TestLogFile | Should -Be $true
        }
        
        It "Should handle invalid log path gracefully" {
            $invalidPath = "Z:\NonExistent\Path\test.log"
            $result = Start-LogSession -LogFile $invalidPath
            $result | Should -Be $false
        }
        
        It "Should accept valid log levels" {
            $validLevels = @("Debug", "Info", "Warning", "Error")
            foreach ($level in $validLevels) {
                { Start-LogSession -LogFile $script:TestLogFile -LogLevel $level } | Should -Not -Throw
                Stop-LogSession
            }
        }
        
        It "Should reject invalid log levels" {
            { Start-LogSession -LogFile $script:TestLogFile -LogLevel "InvalidLevel" } | Should -Throw
        }
        
        It "Should create directory if it doesn't exist" {
            $logDir = Join-Path $TestDrive "NewDirectory"
            $logFile = Join-Path $logDir "test.log"
            
            $result = Start-LogSession -LogFile $logFile
            $result | Should -Be $true
            Test-Path $logDir | Should -Be $true
            Test-Path $logFile | Should -Be $true
        }
    }
    
    Context "Write-Log" {
        BeforeEach {
            $script:TestLogFile = Get-TestLogFile
            Start-LogSession -LogFile $script:TestLogFile -LogLevel "Debug"
        }
        
        AfterEach {
            Stop-LogSession
            if (Test-Path $script:TestLogFile) {
                Remove-Item $script:TestLogFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should write log entry with correct format" {
            Write-Log "Test message" -Level Info
            
            $content = Get-LogContent $script:TestLogFile
            $content | Should -Not -BeNullOrEmpty
            $content[-1] | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Info\] Test message"
        }
        
        It "Should write different log levels correctly" {
            $levels = @("Debug", "Info", "Warning", "Error", "Success")
            
            foreach ($level in $levels) {
                Write-Log "Test $level message" -Level $level
            }
            
            $content = Get-LogContent $script:TestLogFile
            $content.Count | Should -Be $levels.Count
            
            for ($i = 0; $i -lt $levels.Count; $i++) {
                $content[$i] | Should -Match "\[$($levels[$i])\] Test $($levels[$i]) message"
            }
        }
        
        It "Should handle empty messages" {
            Write-Log "" -Level Info
            
            $content = Get-LogContent $script:TestLogFile
            $content[-1] | Should -Match "\[Info\] $"
        }
        
        It "Should handle special characters in messages" {
            $specialMessage = "Test with special chars: !@#$%^&*()[]{}|;:,.<>?"
            Write-Log $specialMessage -Level Info
            
            $content = Get-LogContent $script:TestLogFile
            $content[-1] | Should -Match [regex]::Escape($specialMessage)
        }
        
        It "Should respect log level filtering" {
            Stop-LogSession
            Start-LogSession -LogFile $script:TestLogFile -LogLevel "Warning"
            
            Write-Log "Debug message" -Level Debug
            Write-Log "Info message" -Level Info
            Write-Log "Warning message" -Level Warning
            Write-Log "Error message" -Level Error
            
            $content = Get-LogContent $script:TestLogFile
            $content | Should -Not -Match "Debug message"
            $content | Should -Not -Match "Info message"
            $content | Should -Match "Warning message"
            $content | Should -Match "Error message"
        }
        
        It "Should work without active log session" {
            Stop-LogSession
            { Write-Log "Test message" -Level Info } | Should -Not -Throw
        }
    }
    
    Context "Stop-LogSession" {
        BeforeEach {
            $script:TestLogFile = Get-TestLogFile
            Start-LogSession -LogFile $script:TestLogFile
        }
        
        It "Should stop log session without errors" {
            { Stop-LogSession } | Should -Not -Throw
        }
        
        It "Should handle multiple stop calls gracefully" {
            Stop-LogSession
            { Stop-LogSession } | Should -Not -Throw
        }
        
        It "Should finalize log file properly" {
            Write-Log "Test message before stop" -Level Info
            Stop-LogSession
            
            $content = Get-LogContent $script:TestLogFile
            $content | Should -Match "Test message before stop"
        }
    }
    
    Context "Integration Tests" {
        BeforeEach {
            $script:TestLogFile = Get-TestLogFile
        }
        
        AfterEach {
            Stop-LogSession
            if (Test-Path $script:TestLogFile) {
                Remove-Item $script:TestLogFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should handle complete logging workflow" {
            # Start session
            $result = Start-LogSession -LogFile $script:TestLogFile -LogLevel "Info"
            $result | Should -Be $true
            
            # Write various log entries
            Write-Log "Starting process" -Level Info
            Write-Log "Debug information" -Level Debug
            Write-Log "Warning occurred" -Level Warning
            Write-Log "Error encountered" -Level Error
            Write-Log "Process completed" -Level Success
            
            # Stop session
            Stop-LogSession
            
            # Verify log content
            $content = Get-LogContent $script:TestLogFile
            $content | Should -Match "Starting process"
            $content | Should -Not -Match "Debug information"  # Filtered out by log level
            $content | Should -Match "Warning occurred"
            $content | Should -Match "Error encountered"
            $content | Should -Match "Process completed"
        }
        
        It "Should handle concurrent logging attempts" {
            Start-LogSession -LogFile $script:TestLogFile
            
            # Simulate concurrent writes
            $jobs = @()
            for ($i = 1; $i -le 5; $i++) {
                $jobs += Start-Job -ScriptBlock {
                    param($ModulePath, $Message)
                    Import-Module $ModulePath -Force
                    Write-Log $Message -Level Info
                } -ArgumentList $ModulePath, "Concurrent message $i"
            }
            
            $jobs | Wait-Job | Remove-Job
            
            $content = Get-LogContent $script:TestLogFile
            $content.Count | Should -BeGreaterOrEqual 5
        }
        
        It "Should handle large log messages" {
            Start-LogSession -LogFile $script:TestLogFile
            
            $largeMessage = "A" * 10000  # 10KB message
            Write-Log $largeMessage -Level Info
            
            $content = Get-LogContent $script:TestLogFile
            $content[-1] | Should -Match ([regex]::Escape($largeMessage))
        }
    }
    
    Context "Error Handling" {
        It "Should handle file access errors gracefully" {
            $readOnlyFile = Join-Path $TestDrive "readonly.log"
            New-Item $readOnlyFile -ItemType File -Force
            Set-ItemProperty $readOnlyFile -Name IsReadOnly -Value $true
            
            try {
                $result = Start-LogSession -LogFile $readOnlyFile
                $result | Should -Be $false
            }
            finally {
                Set-ItemProperty $readOnlyFile -Name IsReadOnly -Value $false
                Remove-Item $readOnlyFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should handle disk space issues" {
            # This test would require more complex setup to simulate disk space issues
            # For now, we'll test that the function doesn't crash with invalid paths
            $invalidPath = "\\invalid-server\invalid-share\test.log"
            $result = Start-LogSession -LogFile $invalidPath
            $result | Should -Be $false
        }
    }
    
    Context "Performance Tests" {
        BeforeEach {
            $script:TestLogFile = Get-TestLogFile
            Start-LogSession -LogFile $script:TestLogFile
        }
        
        AfterEach {
            Stop-LogSession
            if (Test-Path $script:TestLogFile) {
                Remove-Item $script:TestLogFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should handle high-frequency logging" {
            $startTime = Get-Date
            
            for ($i = 1; $i -le 100; $i++) {
                Write-Log "Performance test message $i" -Level Info
            }
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            # Should complete 100 log entries in under 5 seconds
            $duration | Should -BeLessThan 5
            
            $content = Get-LogContent $script:TestLogFile
            $content.Count | Should -Be 100
        }
    }
}

AfterAll {
    # Clean up any remaining log sessions
    Stop-LogSession
    
    # Remove the module
    Remove-Module Logger -Force -ErrorAction SilentlyContinue
}
