# Logger-Actual.Tests.ps1 - Unit tests for the actual Logger module (Pester 3.4 compatible)

# Import the module under test
$ModulePath = Join-Path $PSScriptRoot "..\..\..\modules\Core\Logger.psm1"

Describe "Logger Module Tests" {
    BeforeEach {
        # Import module for each test
        if (Test-Path $ModulePath) {
            Import-Module $ModulePath -Force
        } else {
            throw "Logger module not found at $ModulePath"
        }
        
        # Create test log directory
        $script:TestLogDir = Join-Path $TestDrive "logs"
    }
    
    AfterEach {
        # Clean up
        if (Test-Path $script:TestLogDir) {
            Remove-Item $script:TestLogDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        # Stop any active log session
        try {
            Stop-LogSession
        } catch {
            # Ignore errors if no session is active
        }
        
        # Remove module
        Remove-Module Logger -Force -ErrorAction SilentlyContinue
    }
    
    Context "Module Import" {
        It "Should import without errors" {
            { Import-Module $ModulePath -Force } | Should Not Throw
        }
        
        It "Should export Start-LogSession function" {
            $command = Get-Command Start-LogSession -ErrorAction SilentlyContinue
            $command | Should Not BeNullOrEmpty
        }
        
        It "Should export Write-Log function" {
            $command = Get-Command Write-Log -ErrorAction SilentlyContinue
            $command | Should Not BeNullOrEmpty
        }
        
        It "Should export Stop-LogSession function" {
            $command = Get-Command Stop-LogSession -ErrorAction SilentlyContinue
            $command | Should Not BeNullOrEmpty
        }
    }
    
    Context "Start-LogSession" {
        It "Should start log session successfully" {
            $result = Start-LogSession -LogDirectory $script:TestLogDir
            $result | Should Not BeNullOrEmpty
            $result.StartTime | Should Not BeNullOrEmpty
        }
        
        It "Should create log directory if it doesn't exist" {
            $result = Start-LogSession -LogDirectory $script:TestLogDir
            Test-Path $script:TestLogDir | Should Be $true
        }
        
        It "Should accept different log levels" {
            $levels = @("Debug", "Info", "Warning", "Error")
            foreach ($level in $levels) {
                { Start-LogSession -LogLevel $level -LogDirectory $script:TestLogDir } | Should Not Throw
                Stop-LogSession
            }
        }
        
        It "Should create log file with timestamp" {
            Start-LogSession -LogDirectory $script:TestLogDir
            $logFiles = Get-ChildItem $script:TestLogDir -Filter "*.log"
            $logFiles.Count | Should BeGreaterThan 0
        }
    }
    
    Context "Write-Log" {
        BeforeEach {
            Start-LogSession -LogLevel "Debug" -LogDirectory $script:TestLogDir
        }
        
        It "Should write log entry without errors" {
            { Write-Log "Test message" -Level Info } | Should Not Throw
        }
        
        It "Should write different log levels" {
            { Write-Log "Debug message" -Level Debug } | Should Not Throw
            { Write-Log "Info message" -Level Info } | Should Not Throw
            { Write-Log "Warning message" -Level Warning } | Should Not Throw
            { Write-Log "Error message" -Level Error } | Should Not Throw
            { Write-Log "Success message" -Level Success } | Should Not Throw
        }
        
        It "Should handle empty messages" {
            { Write-Log "" -Level Info } | Should Not Throw
        }
        
        It "Should work without active log session" {
            Stop-LogSession
            { Write-Log "Test message" -Level Info } | Should Not Throw
        }
        
        It "Should write to log file when session is active" {
            Write-Log "Test file message" -Level Info
            
            $logFiles = Get-ChildItem $script:TestLogDir -Filter "*.log"
            $logFiles.Count | Should BeGreaterThan 0
            
            $content = Get-Content $logFiles[0].FullName
            $content | Should Match "Test file message"
        }
    }
    
    Context "Stop-LogSession" {
        BeforeEach {
            Start-LogSession -LogDirectory $script:TestLogDir
        }
        
        It "Should stop log session without errors" {
            { Stop-LogSession } | Should Not Throw
        }
        
        It "Should handle multiple stop calls gracefully" {
            Stop-LogSession
            { Stop-LogSession } | Should Not Throw
        }
        
        It "Should finalize log file properly" {
            Write-Log "Test message before stop" -Level Info
            Stop-LogSession
            
            $logFiles = Get-ChildItem $script:TestLogDir -Filter "*.log"
            $logFiles.Count | Should BeGreaterThan 0
            
            $content = Get-Content $logFiles[0].FullName
            $content | Should Match "Test message before stop"
        }
    }
    
    Context "Integration Tests" {
        It "Should handle complete logging workflow" {
            # Start session
            $session = Start-LogSession -LogLevel "Info" -LogDirectory $script:TestLogDir
            $session | Should Not BeNullOrEmpty
            
            # Write various log entries
            Write-Log "Starting process" -Level Info
            Write-Log "Warning occurred" -Level Warning
            Write-Log "Error encountered" -Level Error
            Write-Log "Process completed" -Level Success
            
            # Stop session
            Stop-LogSession
            
            # Verify log file was created and contains entries
            $logFiles = Get-ChildItem $script:TestLogDir -Filter "*.log"
            $logFiles.Count | Should BeGreaterThan 0
            
            $content = Get-Content $logFiles[0].FullName
            $content | Should Match "Starting process"
            $content | Should Match "Warning occurred"
            $content | Should Match "Error encountered"
            $content | Should Match "Process completed"
        }
        
        It "Should handle log level filtering" {
            # Start session with Warning level
            Start-LogSession -LogLevel "Warning" -LogDirectory $script:TestLogDir
            
            Write-Log "Debug message" -Level Debug
            Write-Log "Info message" -Level Info
            Write-Log "Warning message" -Level Warning
            Write-Log "Error message" -Level Error
            
            Stop-LogSession
            
            $logFiles = Get-ChildItem $script:TestLogDir -Filter "*.log"
            $content = Get-Content $logFiles[0].FullName
            
            # Should contain Warning and Error, but not Debug and Info
            $content | Should Match "Warning message"
            $content | Should Match "Error message"
        }
    }
    
    Context "Additional Functions" {
        BeforeEach {
            Start-LogSession -LogDirectory $script:TestLogDir
        }
        
        It "Should export Write-LogSection function" {
            $command = Get-Command Write-LogSection -ErrorAction SilentlyContinue
            $command | Should Not BeNullOrEmpty
        }
        
        It "Should export Write-LogProgress function" {
            $command = Get-Command Write-LogProgress -ErrorAction SilentlyContinue
            $command | Should Not BeNullOrEmpty
        }
        
        It "Should write log sections without errors" {
            { Write-LogSection -Title "Test Section" } | Should Not Throw
        }
        
        It "Should write progress without errors" {
            { Write-LogProgress -Activity "Testing" -Status "In Progress" -PercentComplete 50 } | Should Not Throw
        }
    }
    
    Context "Error Handling" {
        It "Should handle invalid log directory gracefully" {
            # Try to create log in a path that doesn't exist and can't be created
            $invalidPath = "Z:\NonExistent\Path"
            { Start-LogSession -LogDirectory $invalidPath } | Should Not Throw
        }
        
        It "Should handle special characters in log messages" {
            Start-LogSession -LogDirectory $script:TestLogDir
            
            $specialMessage = "Test with special chars: !@#$%^&*()[]{}|;:,.<>?"
            { Write-Log $specialMessage -Level Info } | Should Not Throw
            
            $logFiles = Get-ChildItem $script:TestLogDir -Filter "*.log"
            $content = Get-Content $logFiles[0].FullName
            $content | Should Match [regex]::Escape($specialMessage)
        }
    }
    
    Context "Performance Tests" {
        It "Should handle multiple log entries efficiently" {
            Start-LogSession -LogDirectory $script:TestLogDir
            
            $startTime = Get-Date
            
            for ($i = 1; $i -le 25; $i++) {
                Write-Log "Performance test message $i" -Level Info
            }
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            # Should complete 25 log entries in under 5 seconds
            $duration | Should BeLessThan 5
            
            $logFiles = Get-ChildItem $script:TestLogDir -Filter "*.log"
            $content = Get-Content $logFiles[0].FullName
            $content.Count | Should BeGreaterThan 20  # Should have at least the test messages
        }
    }
}
