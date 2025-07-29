# Logger-Simple.Tests.ps1 - Simplified unit tests for the Logger module (Pester 3.4 compatible)

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
        
        # Create test log file
        $script:TestLogFile = Join-Path $TestDrive "test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    }
    
    AfterEach {
        # Clean up
        if (Test-Path $script:TestLogFile) {
            Remove-Item $script:TestLogFile -Force -ErrorAction SilentlyContinue
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
        It "Should create log file successfully" {
            $result = Start-LogSession -LogFile $script:TestLogFile
            $result | Should Be $true
            Test-Path $script:TestLogFile | Should Be $true
        }
        
        It "Should handle invalid log path gracefully" {
            $invalidPath = "Z:\NonExistent\Path\test.log"
            $result = Start-LogSession -LogFile $invalidPath
            $result | Should Be $false
        }
        
        It "Should create directory if it doesn't exist" {
            $logDir = Join-Path $TestDrive "NewDirectory"
            $logFile = Join-Path $logDir "test.log"
            
            $result = Start-LogSession -LogFile $logFile
            $result | Should Be $true
            Test-Path $logDir | Should Be $true
            Test-Path $logFile | Should Be $true
        }
    }
    
    Context "Write-Log" {
        BeforeEach {
            Start-LogSession -LogFile $script:TestLogFile -LogLevel "Debug"
        }
        
        It "Should write log entry with correct format" {
            Write-Log "Test message" -Level Info
            
            $content = Get-Content $script:TestLogFile
            $content | Should Not BeNullOrEmpty
            $content[-1] | Should Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Info\] Test message"
        }
        
        It "Should write different log levels correctly" {
            Write-Log "Debug message" -Level Debug
            Write-Log "Info message" -Level Info
            Write-Log "Warning message" -Level Warning
            Write-Log "Error message" -Level Error
            Write-Log "Success message" -Level Success
            
            $content = Get-Content $script:TestLogFile
            $content.Count | Should Be 5
            
            $content[0] | Should Match "\[Debug\] Debug message"
            $content[1] | Should Match "\[Info\] Info message"
            $content[2] | Should Match "\[Warning\] Warning message"
            $content[3] | Should Match "\[Error\] Error message"
            $content[4] | Should Match "\[Success\] Success message"
        }
        
        It "Should handle empty messages" {
            Write-Log "" -Level Info
            
            $content = Get-Content $script:TestLogFile
            $content[-1] | Should Match "\[Info\] $"
        }
        
        It "Should work without active log session" {
            Stop-LogSession
            { Write-Log "Test message" -Level Info } | Should Not Throw
        }
    }
    
    Context "Stop-LogSession" {
        BeforeEach {
            Start-LogSession -LogFile $script:TestLogFile
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
            
            $content = Get-Content $script:TestLogFile
            $content | Should Match "Test message before stop"
        }
    }
    
    Context "Integration Tests" {
        It "Should handle complete logging workflow" {
            # Start session
            $result = Start-LogSession -LogFile $script:TestLogFile -LogLevel "Info"
            $result | Should Be $true
            
            # Write various log entries
            Write-Log "Starting process" -Level Info
            Write-Log "Warning occurred" -Level Warning
            Write-Log "Error encountered" -Level Error
            Write-Log "Process completed" -Level Success
            
            # Stop session
            Stop-LogSession
            
            # Verify log content
            $content = Get-Content $script:TestLogFile
            $content | Should Match "Starting process"
            $content | Should Match "Warning occurred"
            $content | Should Match "Error encountered"
            $content | Should Match "Process completed"
        }
        
        It "Should handle large log messages" {
            Start-LogSession -LogFile $script:TestLogFile
            
            $largeMessage = "A" * 1000  # 1KB message
            Write-Log $largeMessage -Level Info
            
            $content = Get-Content $script:TestLogFile
            $content[-1] | Should Match ([regex]::Escape($largeMessage))
        }
    }
    
    Context "Error Handling" {
        It "Should handle file access errors gracefully" {
            $readOnlyFile = Join-Path $TestDrive "readonly.log"
            New-Item $readOnlyFile -ItemType File -Force
            
            try {
                Set-ItemProperty $readOnlyFile -Name IsReadOnly -Value $true
                $result = Start-LogSession -LogFile $readOnlyFile
                $result | Should Be $false
            }
            finally {
                Set-ItemProperty $readOnlyFile -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                Remove-Item $readOnlyFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should handle invalid paths" {
            $invalidPath = "\\invalid-server\invalid-share\test.log"
            $result = Start-LogSession -LogFile $invalidPath
            $result | Should Be $false
        }
    }
    
    Context "Performance Tests" {
        It "Should handle multiple log entries efficiently" {
            Start-LogSession -LogFile $script:TestLogFile
            
            $startTime = Get-Date
            
            for ($i = 1; $i -le 50; $i++) {
                Write-Log "Performance test message $i" -Level Info
            }
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            # Should complete 50 log entries in under 3 seconds
            $duration | Should BeLessThan 3
            
            $content = Get-Content $script:TestLogFile
            $content.Count | Should Be 50
        }
    }
}
