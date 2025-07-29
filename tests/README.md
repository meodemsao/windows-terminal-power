# Testing Framework Documentation

This directory contains the comprehensive testing framework for the Windows Terminal & PowerShell Setup project.

## 📁 Directory Structure

```
tests/
├── Unit/                           # Unit tests for individual modules
│   └── Core/                       # Core module tests
│       ├── Logger-Actual.Tests.ps1 # Logger module tests
│       ├── Logger-Simple.Tests.ps1 # Simplified Logger tests
│       └── UserInterface.Tests.ps1 # UI module tests
├── Integration/                    # Integration tests
│   └── InstallationScript.Tests.ps1 # Main script integration tests
├── TestHelpers/                    # Test utility functions (future)
├── TestResults/                    # Test output directory (auto-created)
├── Run-Tests.ps1                   # Main test runner script
├── Test-Configuration.ps1          # Environment validation and setup
└── README.md                       # This file
```

## 🚀 Quick Start

### Running All Tests
```powershell
# Run all tests with default settings
.\tests\Run-Tests.ps1

# Run with detailed output
.\tests\Run-Tests.ps1 -Detailed

# Generate test results file
.\tests\Run-Tests.ps1 -OutputFormat NUnitXml -OutputPath "TestResults"
```

### Running Specific Test Types
```powershell
# Run only unit tests
.\tests\Run-Tests.ps1 -TestType Unit

# Run only integration tests
.\tests\Run-Tests.ps1 -TestType Integration

# Run tests for specific module
.\tests\Run-Tests.ps1 -TestType Unit -ModuleName Logger
```

### Environment Validation
```powershell
# Validate test environment
.\tests\Test-Configuration.ps1 -ValidateEnvironment

# Check dependencies
.\tests\Test-Configuration.ps1 -CheckDependencies

# Generate environment report
.\tests\Test-Configuration.ps1 -GenerateReport
```

## 🧪 Test Categories

### Unit Tests
Test individual modules and functions in isolation.

**Location**: `tests/Unit/`

**Coverage**:
- ✅ Logger module functionality
- ✅ UserInterface module components
- 🔄 SystemCheck module (planned)
- 🔄 PackageManager module (planned)
- 🔄 BackupRestore module (planned)

**Example**:
```powershell
.\tests\Run-Tests.ps1 -TestType Unit -ModuleName Logger-Actual
```

### Integration Tests
Test complete workflows and module interactions.

**Location**: `tests/Integration/`

**Coverage**:
- ✅ Main installation script execution
- ✅ System compatibility validation
- ✅ Error handling and recovery
- ✅ Cross-PowerShell version compatibility
- ✅ Performance and reliability testing

**Example**:
```powershell
.\tests\Run-Tests.ps1 -TestType Integration
```

### Performance Tests
Validate performance characteristics and resource usage.

**Included in**: Unit and Integration tests

**Coverage**:
- Execution time validation
- Memory usage monitoring
- Concurrent execution testing
- Large-scale operation testing

### Security Tests
Validate security aspects and best practices.

**Included in**: CI/CD pipeline

**Coverage**:
- Script analysis for security issues
- Credential handling validation
- Input validation testing
- Privilege escalation checks

## 🛠️ Test Framework Features

### Cross-Pester Version Compatibility
The test framework supports both Pester 3.x/4.x and Pester 5.x:

- **Automatic Detection**: Detects Pester version and uses appropriate API
- **Unified Interface**: Same command-line interface regardless of Pester version
- **Graceful Fallback**: Falls back to legacy API when needed

### Comprehensive Reporting
- **Console Output**: Real-time test progress and results
- **XML Reports**: NUnitXml and JUnitXml formats for CI/CD integration
- **Coverage Analysis**: Code coverage reporting (Pester 5+ only)
- **Performance Metrics**: Execution time and resource usage tracking

### Environment Validation
- **System Compatibility**: Windows version, PowerShell version, memory, disk space
- **Dependency Checking**: Required and optional module availability
- **Network Connectivity**: Internet access validation
- **Package Manager Detection**: winget, chocolatey, scoop availability

### Error Handling and Recovery
- **Graceful Degradation**: Tests continue even if some components fail
- **Detailed Error Reporting**: Comprehensive failure analysis
- **Recovery Suggestions**: Actionable recommendations for fixing issues
- **Cleanup Procedures**: Automatic cleanup of test artifacts

## 📊 Test Results and Reporting

### Test Execution Summary
The test runner provides comprehensive summaries including:

- **Test Counts**: Total, passed, failed, skipped tests
- **Success Rate**: Percentage of passing tests
- **Execution Time**: Total and per-test timing
- **Failed Test Details**: Specific failure information with error messages
- **Performance Metrics**: Resource usage and timing analysis

### Example Output
```
================================================================================
                              TEST SUMMARY
================================================================================

Test Execution Results:
  Total Tests: 25
  Passed: 18
  Failed: 7
  Skipped: 0

Execution Time: 00:02.132

Success Rate: 72%

Failed Tests:
  - Logger Module Tests Write-Log Should handle empty messages
    Error: Cannot bind argument to parameter 'Message' because it is an empty string.

Overall Result: FAILED

Recommendations:
  • Review failed test details above
  • Run tests with -Detailed for more information
  • Check test logs for additional context
```

## 🔧 Configuration and Customization

### Test Configuration
The testing framework can be configured through:

- **Command-line Parameters**: Runtime configuration options
- **Environment Variables**: System-specific settings
- **Configuration Files**: Persistent settings (future enhancement)

### Supported Parameters

#### Run-Tests.ps1
- `-TestType`: Unit, Integration, All
- `-ModuleName`: Specific module to test
- `-GenerateCoverage`: Enable code coverage analysis
- `-OutputFormat`: Console, NUnitXml, JUnitXml
- `-OutputPath`: Directory for test results
- `-Detailed`: Verbose test output
- `-PassThru`: Return test results object

#### Test-Configuration.ps1
- `-ValidateEnvironment`: Check system compatibility
- `-GenerateReport`: Create environment report
- `-CheckDependencies`: Verify required modules
- `-SetupCI`: Initialize CI/CD environment

### Environment Requirements
- **Windows 10** version 1903+ or **Windows 11**
- **PowerShell 5.1** or later (PowerShell 7+ recommended)
- **Pester module** (automatically installed if missing)
- **Internet connectivity** for integration tests
- **2GB free disk space** for test artifacts

## 🚀 CI/CD Integration

### GitHub Actions Workflow
The project includes a comprehensive GitHub Actions workflow (`.github/workflows/test.yml`) that:

- **Multi-OS Testing**: Windows 2019 and 2022
- **Multi-PowerShell Testing**: PowerShell 5.1 and 7.x
- **Code Quality Analysis**: PSScriptAnalyzer integration
- **Security Scanning**: Security-focused analysis
- **Compatibility Testing**: Cross-version validation
- **Documentation Validation**: Documentation completeness checks

### Workflow Jobs
1. **Test**: Execute unit and integration tests
2. **Code Quality**: PSScriptAnalyzer analysis
3. **Security Scan**: Security vulnerability detection
4. **Compatibility Test**: Cross-version compatibility validation
5. **Documentation Check**: Documentation completeness verification

### Artifact Collection
- Test results (XML format)
- Code analysis reports
- Security scan results
- Compatibility test results
- Documentation validation reports

## 🐛 Troubleshooting

### Common Issues

#### Pester Version Conflicts
```powershell
# Remove old Pester versions
Get-Module Pester -ListAvailable | Uninstall-Module -Force

# Install latest Pester
Install-Module Pester -Force -SkipPublisherCheck
```

#### Execution Policy Issues
```powershell
# Set execution policy for testing
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Module Import Failures
```powershell
# Verify module paths
Get-ChildItem "modules" -Recurse -Filter "*.psm1"

# Test manual import
Import-Module ".\modules\Core\Logger.psm1" -Force -Verbose
```

#### Test Discovery Issues
```powershell
# Verify test file naming
Get-ChildItem "tests" -Recurse -Filter "*.Tests.ps1"

# Check test file syntax
$errors = $null
[System.Management.Automation.PSParser]::Tokenize((Get-Content "tests\Unit\Core\Logger-Actual.Tests.ps1" -Raw), [ref]$errors)
$errors
```

### Getting Help

1. **Run Environment Validation**:
   ```powershell
   .\tests\Test-Configuration.ps1 -ValidateEnvironment -GenerateReport
   ```

2. **Enable Debug Logging**:
   ```powershell
   .\tests\Run-Tests.ps1 -Detailed -TestType Unit
   ```

3. **Check System Requirements**:
   ```powershell
   .\tests\Test-Configuration.ps1 -CheckDependencies
   ```

4. **Review Documentation**:
   - [Installation Guide](../docs/INSTALLATION_GUIDE.md)
   - [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)
   - [Contributing Guide](../docs/CONTRIBUTING.md)

## 📈 Test Metrics and Quality Gates

### Quality Thresholds
- **Minimum Test Coverage**: 80% (when coverage is available)
- **Maximum Test Execution Time**: 5 minutes for full suite
- **Maximum Individual Test Time**: 30 seconds
- **Success Rate Threshold**: 95% for CI/CD pipeline

### Performance Benchmarks
- **Unit Tests**: < 2 minutes total execution time
- **Integration Tests**: < 3 minutes total execution time
- **Memory Usage**: < 500MB peak usage during testing
- **Disk Usage**: < 100MB for test artifacts

### Continuous Improvement
The testing framework is continuously improved based on:
- Test execution metrics
- Failure pattern analysis
- Performance monitoring
- Community feedback
- New feature requirements

## 🔮 Future Enhancements

### Planned Features
- **Test Data Management**: Centralized test data and fixtures
- **Parallel Test Execution**: Faster test execution through parallelization
- **Visual Test Reports**: HTML-based test result dashboards
- **Test Categorization**: Additional test categories (smoke, regression, etc.)
- **Mock Framework**: Enhanced mocking capabilities for unit tests
- **Property-Based Testing**: Automated test case generation
- **Load Testing**: Performance testing under various load conditions

### Integration Enhancements
- **Azure DevOps Integration**: Azure Pipelines support
- **Test Result Analytics**: Historical test result analysis
- **Automated Test Generation**: AI-assisted test case creation
- **Cross-Platform Testing**: Linux and macOS compatibility testing

---

**For more information**, see the [Contributing Guide](../docs/CONTRIBUTING.md) or [API Documentation](../docs/API_DOCUMENTATION.md).
