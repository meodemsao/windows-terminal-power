# SystemCheck.psm1 - System compatibility and prerequisite validation for Windows Terminal Setup

# Import Logger module
Import-Module (Join-Path $PSScriptRoot "Logger.psm1") -Force

function Test-WindowsVersion {
    <#
    .SYNOPSIS
        Tests if the Windows version is compatible
    
    .DESCRIPTION
        Checks for Windows 10 version 1903 (build 18362) or later, or Windows 11
    #>
    [CmdletBinding()]
    param()
    
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $version = [System.Version]$osInfo.Version
        $buildNumber = $osInfo.BuildNumber
        
        Write-Log "Detected OS: $($osInfo.Caption) (Build $buildNumber)" -Level Debug
        
        # Windows 11 starts at build 22000
        if ($buildNumber -ge 22000) {
            Write-Log "Windows 11 detected - fully compatible" -Level Success
            return $true
        }
        
        # Windows 10 - check for minimum build 18362 (version 1903)
        if ($version.Major -eq 10 -and $buildNumber -ge 18362) {
            Write-Log "Windows 10 version 1903+ detected - compatible" -Level Success
            return $true
        }
        
        # Older versions
        if ($version.Major -eq 10) {
            Write-Log "Windows 10 build $buildNumber detected - requires build 18362+ (version 1903)" -Level Error
            return $false
        }
        
        Write-Log "Unsupported Windows version: $($osInfo.Caption)" -Level Error
        return $false
    }
    catch {
        Write-Log "Failed to detect Windows version: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-PowerShellVersion {
    <#
    .SYNOPSIS
        Tests PowerShell version compatibility
    
    .DESCRIPTION
        Checks for PowerShell 5.1+ (minimum) and recommends PowerShell 7+
    #>
    [CmdletBinding()]
    param()
    
    try {
        $psVersion = $PSVersionTable.PSVersion
        Write-Log "Detected PowerShell version: $psVersion" -Level Debug
        
        # Check for minimum version 5.1
        if ($psVersion.Major -ge 7) {
            Write-Log "PowerShell 7+ detected - excellent compatibility" -Level Success
            return $true
        }
        elseif ($psVersion.Major -eq 5 -and $psVersion.Minor -ge 1) {
            Write-Log "PowerShell 5.1 detected - compatible but PowerShell 7+ recommended" -Level Warning
            return $true
        }
        else {
            Write-Log "PowerShell version $psVersion is too old - requires 5.1+" -Level Error
            return $false
        }
    }
    catch {
        Write-Log "Failed to detect PowerShell version: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-InternetConnectivity {
    <#
    .SYNOPSIS
        Tests internet connectivity for package downloads
    #>
    [CmdletBinding()]
    param()
    
    $testUrls = @(
        "https://www.microsoft.com",
        "https://github.com",
        "https://chocolatey.org"
    )
    
    foreach ($url in $testUrls) {
        try {
            Write-Log "Testing connectivity to $url..." -Level Debug
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -UseBasicParsing
            
            if ($response.StatusCode -eq 200) {
                Write-Log "Internet connectivity confirmed via $url" -Level Success
                return $true
            }
        }
        catch {
            Write-Log "Failed to connect to $url : $($_.Exception.Message)" -Level Debug
            continue
        }
    }
    
    Write-Log "No internet connectivity detected" -Level Error
    return $false
}

function Test-DiskSpace {
    <#
    .SYNOPSIS
        Tests available disk space
    
    .PARAMETER RequiredSpaceGB
        Required space in GB (default: 2)
    
    .PARAMETER Path
        Path to check (default: system drive)
    #>
    [CmdletBinding()]
    param(
        [double]$RequiredSpaceGB = 2.0,
        [string]$Path = $env:SystemDrive
    )
    
    try {
        $drive = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $Path }
        
        if (-not $drive) {
            Write-Log "Could not find drive $Path" -Level Error
            return $false
        }
        
        $freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::Round($drive.Size / 1GB, 2)
        
        Write-Log "Drive $Path : $freeSpaceGB GB free of $totalSpaceGB GB total" -Level Debug
        
        if ($freeSpaceGB -ge $RequiredSpaceGB) {
            Write-Log "Sufficient disk space available: $freeSpaceGB GB (required: $RequiredSpaceGB GB)" -Level Success
            return $true
        }
        else {
            Write-Log "Insufficient disk space: $freeSpaceGB GB available, $RequiredSpaceGB GB required" -Level Error
            return $false
        }
    }
    catch {
        Write-Log "Failed to check disk space: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Tests if running with administrator privileges
    #>
    [CmdletBinding()]
    param()
    
    try {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($isAdmin) {
            Write-Log "Running with administrator privileges" -Level Success
        }
        else {
            Write-Log "Running without administrator privileges" -Level Warning
        }
        
        return $isAdmin
    }
    catch {
        Write-Log "Failed to check administrator privileges: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Gathers comprehensive system information
    #>
    [CmdletBinding()]
    param()
    
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
        $processorInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        
        $systemInfo = @{
            OSName = $osInfo.Caption
            OSVersion = $osInfo.Version
            OSBuild = $osInfo.BuildNumber
            OSArchitecture = $osInfo.OSArchitecture
            ComputerName = $computerInfo.Name
            TotalMemoryGB = [math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)
            ProcessorName = $processorInfo.Name
            ProcessorCores = $processorInfo.NumberOfCores
            ProcessorLogicalProcessors = $processorInfo.NumberOfLogicalProcessors
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            PowerShellEdition = $PSVersionTable.PSEdition
            ExecutionPolicy = Get-ExecutionPolicy
            CurrentUser = $env:USERNAME
            UserDomain = $env:USERDOMAIN
            IsAdmin = Test-AdminPrivileges
        }
        
        Write-Log "System information gathered successfully" -Level Debug
        return $systemInfo
    }
    catch {
        Write-Log "Failed to gather system information: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Test-ExecutionPolicy {
    <#
    .SYNOPSIS
        Tests and optionally sets PowerShell execution policy
    
    .PARAMETER SetIfRestricted
        Automatically set execution policy if too restrictive
    #>
    [CmdletBinding()]
    param(
        [switch]$SetIfRestricted
    )
    
    try {
        $currentPolicy = Get-ExecutionPolicy
        Write-Log "Current execution policy: $currentPolicy" -Level Debug
        
        $restrictivePolicies = @("Restricted", "AllSigned")
        
        if ($currentPolicy -in $restrictivePolicies) {
            Write-Log "Execution policy '$currentPolicy' may prevent script execution" -Level Warning
            
            if ($SetIfRestricted) {
                try {
                    Write-Log "Attempting to set execution policy to RemoteSigned..." -Level Info
                    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                    Write-Log "Execution policy updated to RemoteSigned" -Level Success
                    return $true
                }
                catch {
                    Write-Log "Failed to update execution policy: $($_.Exception.Message)" -Level Error
                    return $false
                }
            }
            else {
                Write-Log "Consider running: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -Level Info
                return $false
            }
        }
        else {
            Write-Log "Execution policy '$currentPolicy' is suitable" -Level Success
            return $true
        }
    }
    catch {
        Write-Log "Failed to check execution policy: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-WindowsTerminalInstalled {
    <#
    .SYNOPSIS
        Tests if Windows Terminal is installed
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Check for Windows Terminal via Get-AppxPackage
        $wtPackage = Get-AppxPackage -Name "Microsoft.WindowsTerminal" -ErrorAction SilentlyContinue
        
        if ($wtPackage) {
            Write-Log "Windows Terminal detected: Version $($wtPackage.Version)" -Level Success
            return $true
        }
        
        # Check for Windows Terminal Preview
        $wtPreview = Get-AppxPackage -Name "Microsoft.WindowsTerminalPreview" -ErrorAction SilentlyContinue
        
        if ($wtPreview) {
            Write-Log "Windows Terminal Preview detected: Version $($wtPreview.Version)" -Level Success
            return $true
        }
        
        # Check if wt.exe is available in PATH
        $wtCommand = Get-Command wt -ErrorAction SilentlyContinue
        
        if ($wtCommand) {
            Write-Log "Windows Terminal command found in PATH: $($wtCommand.Source)" -Level Success
            return $true
        }
        
        Write-Log "Windows Terminal not detected" -Level Info
        return $false
    }
    catch {
        Write-Log "Failed to check Windows Terminal installation: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-PowerShell7Installed {
    <#
    .SYNOPSIS
        Tests if PowerShell 7+ is installed
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Check if pwsh.exe is available
        $pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
        
        if ($pwshCommand) {
            # Get PowerShell 7 version
            $ps7Version = & pwsh -Command '$PSVersionTable.PSVersion.ToString()'
            Write-Log "PowerShell 7 detected: Version $ps7Version" -Level Success
            return $true
        }
        
        Write-Log "PowerShell 7 not detected" -Level Info
        return $false
    }
    catch {
        Write-Log "Failed to check PowerShell 7 installation: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Test-ToolInstallation {
    <#
    .SYNOPSIS
        Tests if a specific tool is installed and working
    
    .PARAMETER ToolName
        Name of the tool to test
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )
    
    $testCommands = @{
        "git" = "git --version"
        "curl" = "curl --version"
        "lazygit" = "lazygit --version"
        "oh-my-posh" = "oh-my-posh --version"
        "fzf" = "fzf --version"
        "eza" = "eza --version"
        "bat" = "bat --version"
        "lsd" = "lsd --version"
        "neovim" = "nvim --version"
        "zoxide" = "zoxide --version"
        "fnm" = "fnm --version"
        "pyenv" = "pyenv --version"
    }
    
    if (-not $testCommands.ContainsKey($ToolName)) {
        Write-Log "No test command defined for tool: $ToolName" -Level Warning
        return $false
    }
    
    try {
        $command = $testCommands[$ToolName]
        Write-Log "Testing $ToolName with command: $command" -Level Debug
        
        $result = Invoke-Expression $command 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Log "$ToolName is installed and working: $($result | Select-Object -First 1)" -Level Success
            return $true
        }
        else {
            Write-Log "$ToolName test failed with exit code $exitCode" -Level Warning
            return $false
        }
    }
    catch {
        Write-Log "$ToolName is not installed or not working: $($_.Exception.Message)" -Level Debug
        return $false
    }
}

function Test-Installation {
    <#
    .SYNOPSIS
        Tests installation of multiple tools with comprehensive validation

    .PARAMETER InstalledTools
        Array of tool names to test

    .PARAMETER DetailedResults
        Return detailed validation results instead of just boolean
    #>
    [CmdletBinding()]
    param(
        [string[]]$InstalledTools,
        [switch]$DetailedResults
    )

    $results = @{}
    $overallSuccess = $true

    Write-Log "Starting comprehensive installation validation for $($InstalledTools.Count) tools..." -Level Info

    foreach ($tool in $InstalledTools) {
        try {
            Write-Log "Validating $tool..." -Level Debug

            if ($DetailedResults) {
                $results[$tool] = Test-ToolInstallationDetailed -ToolName $tool
                if (-not $results[$tool].Success) {
                    $overallSuccess = $false
                }
            }
            else {
                $results[$tool] = Test-ToolInstallation -ToolName $tool
                if (-not $results[$tool]) {
                    $overallSuccess = $false
                }
            }
        }
        catch {
            Write-Log "Error validating $tool : $($_.Exception.Message)" -Level Error
            if ($DetailedResults) {
                $results[$tool] = @{
                    Success = $false
                    Error = $_.Exception.Message
                    Tool = $tool
                }
            }
            else {
                $results[$tool] = $false
            }
            $overallSuccess = $false
        }
    }

    if ($DetailedResults) {
        $results["_Summary"] = @{
            OverallSuccess = $overallSuccess
            TotalTools = $InstalledTools.Count
            SuccessfulTools = ($results.Values | Where-Object { $_.Success -eq $true }).Count
            FailedTools = ($results.Values | Where-Object { $_.Success -eq $false }).Count
            ValidationTime = Get-Date
        }
    }

    $successCount = if ($DetailedResults) { $results["_Summary"].SuccessfulTools } else { ($results.Values | Where-Object { $_ -eq $true }).Count }
    Write-Log "Installation validation completed: $successCount/$($InstalledTools.Count) tools validated successfully" -Level Info

    return $results
}

function Test-ToolInstallationDetailed {
    <#
    .SYNOPSIS
        Performs detailed validation of a tool installation

    .PARAMETER ToolName
        Name of the tool to test
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    $result = @{
        Tool = $ToolName
        Success = $false
        Version = $null
        Path = $null
        FunctionalityTest = $false
        Error = $null
        Warnings = @()
        ValidationTime = Get-Date
    }

    try {
        # Basic command availability test
        $command = Get-Command $ToolName -ErrorAction SilentlyContinue
        if (-not $command) {
            $result.Error = "Command '$ToolName' not found in PATH"
            return $result
        }

        $result.Path = $command.Source

        # Version test
        $versionResult = Test-ToolVersion -ToolName $ToolName
        if ($versionResult.Success) {
            $result.Version = $versionResult.Version
        }
        else {
            $result.Warnings += "Could not determine version: $($versionResult.Error)"
        }

        # Functionality test
        $functionalityResult = Test-ToolFunctionality -ToolName $ToolName
        $result.FunctionalityTest = $functionalityResult.Success
        if (-not $functionalityResult.Success) {
            $result.Warnings += "Functionality test failed: $($functionalityResult.Error)"
        }

        # Overall success determination
        $result.Success = ($command -ne $null) -and $functionalityResult.Success

        if ($result.Success) {
            Write-Log "$ToolName validation successful: $($result.Version)" -Level Success
        }
        else {
            Write-Log "$ToolName validation failed" -Level Warning
        }

    }
    catch {
        $result.Error = $_.Exception.Message
        Write-Log "Error during detailed validation of $ToolName : $($_.Exception.Message)" -Level Error
    }

    return $result
}

function Test-ToolVersion {
    <#
    .SYNOPSIS
        Tests tool version retrieval
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    $versionCommands = @{
        "git" = "git --version"
        "curl" = "curl --version"
        "lazygit" = "lazygit --version"
        "oh-my-posh" = "oh-my-posh --version"
        "fzf" = "fzf --version"
        "eza" = "eza --version"
        "bat" = "bat --version"
        "lsd" = "lsd --version"
        "nvim" = "nvim --version"
        "zoxide" = "zoxide --version"
        "fnm" = "fnm --version"
        "pyenv" = "pyenv --version"
    }

    try {
        $command = $versionCommands[$ToolName]
        if (-not $command) {
            return @{ Success = $false; Error = "No version command defined for $ToolName" }
        }

        $output = Invoke-Expression $command 2>&1
        if ($LASTEXITCODE -eq 0) {
            $version = ($output | Select-Object -First 1).ToString().Trim()
            return @{ Success = $true; Version = $version }
        }
        else {
            return @{ Success = $false; Error = "Version command failed with exit code $LASTEXITCODE" }
        }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Test-ToolFunctionality {
    <#
    .SYNOPSIS
        Tests basic functionality of a tool
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    try {
        switch ($ToolName) {
            "git" {
                # Test git help command
                $output = git help 2>&1
                return @{ Success = ($LASTEXITCODE -eq 0); Error = if ($LASTEXITCODE -ne 0) { $output } else { $null } }
            }
            "curl" {
                # Test curl help
                $output = curl --help 2>&1
                return @{ Success = ($LASTEXITCODE -eq 0); Error = if ($LASTEXITCODE -ne 0) { $output } else { $null } }
            }
            "oh-my-posh" {
                # Test oh-my-posh themes list
                $output = oh-my-posh get shell 2>&1
                return @{ Success = ($LASTEXITCODE -eq 0); Error = if ($LASTEXITCODE -ne 0) { $output } else { $null } }
            }
            default {
                # Generic help test
                $output = & $ToolName --help 2>&1
                return @{ Success = ($LASTEXITCODE -eq 0); Error = if ($LASTEXITCODE -ne 0) { $output } else { $null } }
            }
        }
    }
    catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Install-WindowsTerminal {
    <#
    .SYNOPSIS
        Installs Windows Terminal
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Installing Windows Terminal..." -Level Info
        
        # Try winget first
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $result = winget install Microsoft.WindowsTerminal --accept-package-agreements --accept-source-agreements 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Windows Terminal installed successfully via winget" -Level Success
                return $true
            }
        }
        
        # Fallback to Microsoft Store
        Write-Log "Attempting to install via Microsoft Store..." -Level Info
        Start-Process "ms-windows-store://pdp/?productid=9n0dx20hk701"
        Write-Log "Microsoft Store opened. Please install Windows Terminal manually." -Level Warning
        
        return $false
    }
    catch {
        Write-Log "Failed to install Windows Terminal: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Install-PowerShell7 {
    <#
    .SYNOPSIS
        Installs PowerShell 7
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Installing PowerShell 7..." -Level Info
        
        # Try winget first
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $result = winget install Microsoft.PowerShell --accept-package-agreements --accept-source-agreements 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "PowerShell 7 installed successfully via winget" -Level Success
                return $true
            }
        }
        
        # Fallback to direct download
        Write-Log "Winget failed, attempting direct download..." -Level Warning
        $downloadUrl = "https://github.com/PowerShell/PowerShell/releases/latest/download/PowerShell-7-win-x64.msi"
        $tempFile = Join-Path $env:TEMP "PowerShell-7-win-x64.msi"
        
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempFile
        Start-Process msiexec.exe -ArgumentList "/i", $tempFile, "/quiet" -Wait
        
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        
        Write-Log "PowerShell 7 installation completed" -Level Success
        return $true
    }
    catch {
        Write-Log "Failed to install PowerShell 7: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-SystemDiagnostics {
    <#
    .SYNOPSIS
        Performs comprehensive system diagnostics for troubleshooting
    #>
    [CmdletBinding()]
    param()

    $diagnostics = @{
        Timestamp = Get-Date
        SystemInfo = @{}
        Compatibility = @{}
        Environment = @{}
        Recommendations = @()
        Errors = @()
    }

    try {
        Write-Log "Performing comprehensive system diagnostics..." -Level Info

        # System Information
        $diagnostics.SystemInfo = Get-SystemInfo

        # Compatibility Checks
        $diagnostics.Compatibility.WindowsVersion = Test-WindowsVersion
        $diagnostics.Compatibility.PowerShellVersion = Test-PowerShellVersion
        $diagnostics.Compatibility.InternetConnectivity = Test-InternetConnectivity
        $diagnostics.Compatibility.DiskSpace = Test-DiskSpace -RequiredSpaceGB 2
        $diagnostics.Compatibility.AdminPrivileges = Test-AdminPrivileges
        $diagnostics.Compatibility.ExecutionPolicy = Test-ExecutionPolicy

        # Environment Checks
        $diagnostics.Environment.WindowsTerminal = Test-WindowsTerminalInstalled
        $diagnostics.Environment.PowerShell7 = Test-PowerShell7Installed
        $diagnostics.Environment.PackageManagers = Test-PackageManagerAvailability

        # Generate recommendations
        $diagnostics.Recommendations = Get-SystemRecommendations -Diagnostics $diagnostics

        Write-Log "System diagnostics completed successfully" -Level Success
    }
    catch {
        $diagnostics.Errors += "Failed to complete system diagnostics: $($_.Exception.Message)"
        Write-Log "System diagnostics failed: $($_.Exception.Message)" -Level Error
    }

    return $diagnostics
}

function Test-PackageManagerAvailability {
    <#
    .SYNOPSIS
        Tests availability of package managers
    #>
    [CmdletBinding()]
    param()

    $packageManagers = @{
        Winget = @{ Available = $false; Version = $null; Error = $null }
        Chocolatey = @{ Available = $false; Version = $null; Error = $null }
        Scoop = @{ Available = $false; Version = $null; Error = $null }
    }

    # Test Winget
    try {
        $wingetVersion = winget --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $packageManagers.Winget.Available = $true
            $packageManagers.Winget.Version = $wingetVersion.ToString().Trim()
        }
    }
    catch {
        $packageManagers.Winget.Error = $_.Exception.Message
    }

    # Test Chocolatey
    try {
        $chocoVersion = choco --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $packageManagers.Chocolatey.Available = $true
            $packageManagers.Chocolatey.Version = $chocoVersion.ToString().Trim()
        }
    }
    catch {
        $packageManagers.Chocolatey.Error = $_.Exception.Message
    }

    # Test Scoop
    try {
        $scoopVersion = scoop --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $packageManagers.Scoop.Available = $true
            $packageManagers.Scoop.Version = $scoopVersion.ToString().Trim()
        }
    }
    catch {
        $packageManagers.Scoop.Error = $_.Exception.Message
    }

    return $packageManagers
}

function Get-SystemRecommendations {
    <#
    .SYNOPSIS
        Generates system recommendations based on diagnostics
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Diagnostics
    )

    $recommendations = @()

    try {
        # Windows version recommendations
        if (-not $Diagnostics.Compatibility.WindowsVersion) {
            $recommendations += "Update Windows to version 1903 or later for full compatibility"
        }

        # PowerShell recommendations
        if (-not $Diagnostics.Compatibility.PowerShellVersion) {
            $recommendations += "Update PowerShell to version 5.1 or later"
        }

        if (-not $Diagnostics.Environment.PowerShell7) {
            $recommendations += "Install PowerShell 7 for the best experience"
        }

        # Package manager recommendations
        $availableManagers = $Diagnostics.Environment.PackageManagers
        $hasPackageManager = $availableManagers.Winget.Available -or $availableManagers.Chocolatey.Available -or $availableManagers.Scoop.Available

        if (-not $hasPackageManager) {
            $recommendations += "Install a package manager (Winget recommended) for automated tool installation"
        }

        # Admin privileges
        if (-not $Diagnostics.Compatibility.AdminPrivileges) {
            $recommendations += "Consider running as Administrator for some installations"
        }

        # Disk space
        if (-not $Diagnostics.Compatibility.DiskSpace) {
            $recommendations += "Free up disk space before proceeding with installation"
        }

        # Internet connectivity
        if (-not $Diagnostics.Compatibility.InternetConnectivity) {
            $recommendations += "Check internet connection for package downloads"
        }

        # Windows Terminal
        if (-not $Diagnostics.Environment.WindowsTerminal) {
            $recommendations += "Install Windows Terminal for the best terminal experience"
        }

        return $recommendations
    }
    catch {
        return @("Failed to generate recommendations: $($_.Exception.Message)")
    }
}

function Export-SystemDiagnostics {
    <#
    .SYNOPSIS
        Exports system diagnostics to a file for troubleshooting
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Diagnostics,

        [string]$OutputPath = $null
    )

    try {
        if (-not $OutputPath) {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $OutputPath = Join-Path $env:TEMP "WindowsTerminalSetup_Diagnostics_$timestamp.json"
        }

        $Diagnostics | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

        Write-Log "System diagnostics exported to: $OutputPath" -Level Success
        return $OutputPath
    }
    catch {
        Write-Log "Failed to export system diagnostics: $($_.Exception.Message)" -Level Error
        return $null
    }
}

function Test-SystemReadiness {
    <#
    .SYNOPSIS
        Comprehensive system readiness test with detailed reporting
    #>
    [CmdletBinding()]
    param(
        [switch]$ExportDiagnostics
    )

    Write-Log "Performing comprehensive system readiness test..." -Level Info

    $diagnostics = Get-SystemDiagnostics
    $readiness = @{
        Ready = $true
        CriticalIssues = @()
        Warnings = @()
        Recommendations = $diagnostics.Recommendations
        Diagnostics = $diagnostics
    }

    # Check critical requirements
    if (-not $diagnostics.Compatibility.WindowsVersion) {
        $readiness.Ready = $false
        $readiness.CriticalIssues += "Incompatible Windows version"
    }

    if (-not $diagnostics.Compatibility.PowerShellVersion) {
        $readiness.Ready = $false
        $readiness.CriticalIssues += "Incompatible PowerShell version"
    }

    if (-not $diagnostics.Compatibility.InternetConnectivity) {
        $readiness.Ready = $false
        $readiness.CriticalIssues += "No internet connectivity"
    }

    if (-not $diagnostics.Compatibility.DiskSpace) {
        $readiness.Ready = $false
        $readiness.CriticalIssues += "Insufficient disk space"
    }

    # Check warnings
    if (-not $diagnostics.Compatibility.AdminPrivileges) {
        $readiness.Warnings += "Not running as Administrator - some installations may fail"
    }

    $availableManagers = $diagnostics.Environment.PackageManagers
    $hasPackageManager = $availableManagers.Winget.Available -or $availableManagers.Chocolatey.Available -or $availableManagers.Scoop.Available

    if (-not $hasPackageManager) {
        $readiness.Warnings += "No package manager available - manual installation may be required"
    }

    # Export diagnostics if requested
    if ($ExportDiagnostics) {
        $exportPath = Export-SystemDiagnostics -Diagnostics $diagnostics
        if ($exportPath) {
            $readiness.DiagnosticsFile = $exportPath
        }
    }

    if ($readiness.Ready) {
        Write-Log "System readiness test passed" -Level Success
    }
    else {
        Write-Log "System readiness test failed: $($readiness.CriticalIssues -join ', ')" -Level Error
    }

    return $readiness
}

# Export module functions
Export-ModuleMember -Function @(
    'Test-WindowsVersion',
    'Test-PowerShellVersion',
    'Test-InternetConnectivity',
    'Test-DiskSpace',
    'Test-AdminPrivileges',
    'Get-SystemInfo',
    'Test-ExecutionPolicy',
    'Test-WindowsTerminalInstalled',
    'Test-PowerShell7Installed',
    'Test-ToolInstallation',
    'Test-Installation',
    'Install-WindowsTerminal',
    'Install-PowerShell7',
    'Test-ToolInstallationDetailed',
    'Test-ToolVersion',
    'Test-ToolFunctionality',
    'Get-SystemDiagnostics',
    'Test-PackageManagerAvailability',
    'Get-SystemRecommendations',
    'Export-SystemDiagnostics',
    'Test-SystemReadiness'
)
