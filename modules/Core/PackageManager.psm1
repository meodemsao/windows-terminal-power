# PackageManager.psm1 - Package manager detection and handling for Windows Terminal Setup

# Import Logger module
Import-Module (Join-Path $PSScriptRoot "Logger.psm1") -Force

# Module variables
$script:AvailableManagers = @()
$script:PreferredManager = $null

# Tool package definitions
$script:PackageDefinitions = @{
    "git" = @{
        Winget = "Git.Git"
        Chocolatey = "git"
        Scoop = "git"
        ManualUrl = "https://git-scm.com/download/win"
    }
    "curl" = @{
        Winget = "cURL.cURL"
        Chocolatey = "curl"
        Scoop = "curl"
        ManualUrl = "https://curl.se/windows/"
        BuiltIn = $true  # Available in Windows 10 1803+
    }
    "lazygit" = @{
        Winget = "JesseDuffield.lazygit"
        Chocolatey = "lazygit"
        Scoop = "lazygit"
        ManualUrl = "https://github.com/jesseduffield/lazygit/releases"
    }
    "nerd-fonts" = @{
        Winget = @("Cascadia Code PL", "FiraCode Nerd Font")
        Chocolatey = "cascadia-code-nerd-font"
        Scoop = @("CascadiaCode-NF", "FiraCode-NF")
        ManualUrl = "https://www.nerdfonts.com/font-downloads"
    }
    "oh-my-posh" = @{
        Winget = "JanDeDobbeleer.OhMyPosh"
        Chocolatey = "oh-my-posh"
        Scoop = "oh-my-posh"
        ManualUrl = "https://github.com/JanDeDobbeleer/oh-my-posh/releases"
    }
    "fzf" = @{
        Winget = "junegunn.fzf"
        Chocolatey = "fzf"
        Scoop = "fzf"
        ManualUrl = "https://github.com/junegunn/fzf/releases"
    }
    "eza" = @{
        Winget = "eza-community.eza"
        Chocolatey = "eza"
        Scoop = "eza"
        ManualUrl = "https://github.com/eza-community/eza/releases"
    }
    "bat" = @{
        Winget = "sharkdp.bat"
        Chocolatey = "bat"
        Scoop = "bat"
        ManualUrl = "https://github.com/sharkdp/bat/releases"
    }
    "lsd" = @{
        Winget = "Peltoche.lsd"
        Chocolatey = "lsd"
        Scoop = "lsd"
        ManualUrl = "https://github.com/Peltoche/lsd/releases"
    }
    "neovim" = @{
        Winget = "Neovim.Neovim"
        Chocolatey = "neovim"
        Scoop = "neovim"
        ManualUrl = "https://neovim.io/"
    }
    "zoxide" = @{
        Winget = "ajeetdsouza.zoxide"
        Chocolatey = "zoxide"
        Scoop = "zoxide"
        ManualUrl = "https://github.com/ajeetdsouza/zoxide/releases"
    }
    "fnm" = @{
        Winget = "Schniz.fnm"
        Chocolatey = "fnm"
        Scoop = "fnm"
        ManualUrl = "https://github.com/Schniz/fnm/releases"
    }
    "pyenv" = @{
        Winget = "pyenv-win.pyenv-win"
        Chocolatey = "pyenv-win"
        Scoop = "pyenv"
        ManualUrl = "https://github.com/pyenv-win/pyenv-win"
    }
}

function Test-PackageManager {
    <#
    .SYNOPSIS
        Tests if a specific package manager is available
    
    .PARAMETER Manager
        Package manager to test (Winget, Chocolatey, Scoop)
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Winget", "Chocolatey", "Scoop")]
        [string]$Manager
    )
    
    switch ($Manager) {
        "Winget" {
            try {
                $null = Get-Command winget -ErrorAction Stop
                $version = winget --version
                Write-Log "Winget detected: $version" -Level Debug
                return $true
            }
            catch {
                Write-Log "Winget not available: $($_.Exception.Message)" -Level Debug
                return $false
            }
        }
        "Chocolatey" {
            try {
                $null = Get-Command choco -ErrorAction Stop
                $version = choco --version
                Write-Log "Chocolatey detected: $version" -Level Debug
                return $true
            }
            catch {
                Write-Log "Chocolatey not available: $($_.Exception.Message)" -Level Debug
                return $false
            }
        }
        "Scoop" {
            try {
                $null = Get-Command scoop -ErrorAction Stop
                $version = scoop --version
                Write-Log "Scoop detected: $version" -Level Debug
                return $true
            }
            catch {
                Write-Log "Scoop not available: $($_.Exception.Message)" -Level Debug
                return $false
            }
        }
    }
    
    return $false
}

function Install-PackageManager {
    <#
    .SYNOPSIS
        Installs a package manager if possible
    
    .PARAMETER Manager
        Package manager to install
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Winget", "Chocolatey", "Scoop")]
        [string]$Manager
    )
    
    Write-Log "Attempting to install $Manager..." -Level Info
    
    switch ($Manager) {
        "Winget" {
            try {
                # Try to install via Microsoft Store
                Write-Log "Installing Winget via App Installer..." -Level Info
                Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget" -Wait
                
                # Wait a moment and test
                Start-Sleep -Seconds 5
                if (Test-PackageManager -Manager "Winget") {
                    Write-Log "Winget installed successfully" -Level Success
                    return $true
                }
                
                Write-Log "Winget installation via App Installer failed" -Level Warning
                return $false
            }
            catch {
                Write-Log "Failed to install Winget: $($_.Exception.Message)" -Level Error
                return $false
            }
        }
        "Chocolatey" {
            try {
                Write-Log "Installing Chocolatey..." -Level Info
                Set-ExecutionPolicy Bypass -Scope Process -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                
                # Refresh environment
                $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
                
                if (Test-PackageManager -Manager "Chocolatey") {
                    Write-Log "Chocolatey installed successfully" -Level Success
                    return $true
                }
                
                Write-Log "Chocolatey installation failed" -Level Error
                return $false
            }
            catch {
                Write-Log "Failed to install Chocolatey: $($_.Exception.Message)" -Level Error
                return $false
            }
        }
        "Scoop" {
            try {
                Write-Log "Installing Scoop..." -Level Info
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                Invoke-RestMethod get.scoop.sh | Invoke-Expression
                
                if (Test-PackageManager -Manager "Scoop") {
                    Write-Log "Scoop installed successfully" -Level Success
                    return $true
                }
                
                Write-Log "Scoop installation failed" -Level Error
                return $false
            }
            catch {
                Write-Log "Failed to install Scoop: $($_.Exception.Message)" -Level Error
                return $false
            }
        }
    }
    
    return $false
}

function Initialize-PackageManager {
    <#
    .SYNOPSIS
        Initializes package manager availability and sets preferred manager
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Detecting available package managers..." -Level Info
    
    $script:AvailableManagers = @()
    
    # Test in order of preference
    $managers = @("Winget", "Chocolatey", "Scoop")
    
    foreach ($manager in $managers) {
        if (Test-PackageManager -Manager $manager) {
            $script:AvailableManagers += $manager
            Write-Log "$manager is available" -Level Success
        }
    }
    
    if ($script:AvailableManagers.Count -eq 0) {
        Write-Log "No package managers detected. Attempting to install Winget..." -Level Warning
        
        if (Install-PackageManager -Manager "Winget") {
            $script:AvailableManagers += "Winget"
        }
        elseif (Install-PackageManager -Manager "Chocolatey") {
            $script:AvailableManagers += "Chocolatey"
        }
        elseif (Install-PackageManager -Manager "Scoop") {
            $script:AvailableManagers += "Scoop"
        }
    }
    
    if ($script:AvailableManagers.Count -gt 0) {
        $script:PreferredManager = $script:AvailableManagers[0]
        Write-Log "Using $($script:PreferredManager) as preferred package manager" -Level Info
        return $true
    }
    else {
        Write-Log "No package managers available" -Level Error
        return $false
    }
}

function Install-Package {
    <#
    .SYNOPSIS
        Installs a package using the best available package manager
    
    .PARAMETER PackageName
        Name of the package/tool to install
    
    .PARAMETER Force
        Force installation even if already installed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName,
        
        [switch]$Force
    )
    
    if (-not $script:PackageDefinitions.ContainsKey($PackageName)) {
        Write-Log "Unknown package: $PackageName" -Level Error
        return $false
    }
    
    $packageDef = $script:PackageDefinitions[$PackageName]
    
    # Check if it's a built-in tool (like curl on Windows 10+)
    if ($packageDef.BuiltIn -and (Test-BuiltInTool -ToolName $PackageName)) {
        Write-Log "$PackageName is built-in and available" -Level Success
        return $true
    }
    
    # Try each available package manager
    foreach ($manager in $script:AvailableManagers) {
        if ($packageDef.ContainsKey($manager)) {
            $packageId = $packageDef[$manager]
            
            # Handle multiple package options (like fonts)
            if ($packageId -is [array]) {
                $success = $false
                foreach ($id in $packageId) {
                    if (Install-WithManager -Manager $manager -PackageId $id -Force:$Force) {
                        $success = $true
                        break
                    }
                }
                if ($success) {
                    return $true
                }
            }
            else {
                if (Install-WithManager -Manager $manager -PackageId $packageId -Force:$Force) {
                    return $true
                }
            }
        }
    }
    
    # If all package managers failed, try manual installation
    Write-Log "All package managers failed for $PackageName. Manual installation may be required." -Level Warning
    Write-Log "Manual download URL: $($packageDef.ManualUrl)" -Level Info
    
    return $false
}

function Install-WithManager {
    <#
    .SYNOPSIS
        Installs a package with a specific package manager
    
    .PARAMETER Manager
        Package manager to use
    
    .PARAMETER PackageId
        Package identifier for the manager
    
    .PARAMETER Force
        Force installation
    #>
    [CmdletBinding()]
    param(
        [string]$Manager,
        [string]$PackageId,
        [switch]$Force
    )
    
    try {
        Write-Log "Installing $PackageId using $Manager..." -Level Info
        
        switch ($Manager) {
            "Winget" {
                $args = @("install", $PackageId, "--accept-package-agreements", "--accept-source-agreements")
                if ($Force) { $args += "--force" }
                
                $result = & winget @args 2>&1
                $exitCode = $LASTEXITCODE
                
                if ($exitCode -eq 0) {
                    Write-Log "$PackageId installed successfully with Winget" -Level Success
                    return $true
                }
                else {
                    Write-Log "Winget installation failed for $PackageId. Exit code: $exitCode. Output: $result" -Level Warning
                    return $false
                }
            }
            "Chocolatey" {
                $args = @("install", $PackageId, "-y")
                if ($Force) { $args += "--force" }
                
                $result = & choco @args 2>&1
                $exitCode = $LASTEXITCODE
                
                if ($exitCode -eq 0) {
                    Write-Log "$PackageId installed successfully with Chocolatey" -Level Success
                    return $true
                }
                else {
                    Write-Log "Chocolatey installation failed for $PackageId. Exit code: $exitCode. Output: $result" -Level Warning
                    return $false
                }
            }
            "Scoop" {
                $args = @("install", $PackageId)
                
                $result = & scoop @args 2>&1
                $exitCode = $LASTEXITCODE
                
                if ($exitCode -eq 0) {
                    Write-Log "$PackageId installed successfully with Scoop" -Level Success
                    return $true
                }
                else {
                    Write-Log "Scoop installation failed for $PackageId. Exit code: $exitCode. Output: $result" -Level Warning
                    return $false
                }
            }
        }
    }
    catch {
        Write-Log "Exception during $Manager installation of ${PackageId}: $($_.Exception.Message)" -Level Error
        return $false
    }
    
    return $false
}

function Test-BuiltInTool {
    <#
    .SYNOPSIS
        Tests if a built-in tool is available
    
    .PARAMETER ToolName
        Name of the tool to test
    #>
    [CmdletBinding()]
    param(
        [string]$ToolName
    )
    
    switch ($ToolName) {
        "curl" {
            try {
                $null = Get-Command curl -ErrorAction Stop
                return $true
            }
            catch {
                return $false
            }
        }
    }
    
    return $false
}

function Get-AvailableManagers {
    <#
    .SYNOPSIS
        Returns list of available package managers
    #>
    [CmdletBinding()]
    param()
    
    return $script:AvailableManagers
}

function Get-PreferredManager {
    <#
    .SYNOPSIS
        Returns the preferred package manager
    #>
    [CmdletBinding()]
    param()
    
    return $script:PreferredManager
}

function Install-Tool {
    <#
    .SYNOPSIS
        High-level function to install a tool with comprehensive error handling

    .PARAMETER ToolName
        Name of the tool to install

    .PARAMETER Force
        Force installation

    .PARAMETER RetryCount
        Number of retry attempts (default: 2)

    .PARAMETER Timeout
        Timeout in seconds for installation (default: 300)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [switch]$Force,

        [int]$RetryCount = 2,

        [int]$Timeout = 300
    )

    $installationResult = @{
        Success = $false
        ToolName = $ToolName
        Message = ""
        AttemptCount = 0
        InstallationMethod = ""
        Version = $null
        TroubleshootingInfo = @()
        Duration = $null
    }

    $startTime = Get-Date

    try {
        Write-Log "Starting installation of tool: $ToolName" -Level Info

        # Pre-installation validation
        if (-not $script:PackageDefinitions.ContainsKey($ToolName)) {
            $installationResult.Message = "Unknown tool: $ToolName"
            Write-Log $installationResult.Message -Level Error
            return $installationResult
        }

        # Check if already installed (unless forced)
        if (-not $Force) {
            $existingInstallation = Test-ExistingInstallation -ToolName $ToolName
            if ($existingInstallation.Installed) {
                $installationResult.Success = $true
                $installationResult.Message = "Tool already installed: $($existingInstallation.Version)"
                $installationResult.Version = $existingInstallation.Version
                $installationResult.InstallationMethod = "Already Installed"
                Write-Log $installationResult.Message -Level Success
                return $installationResult
            }
        }

        # Attempt installation with retry logic
        $maxAttempts = $RetryCount + 1

        for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
            $installationResult.AttemptCount = $attempt

            try {
                Write-Log "Installation attempt $attempt of $maxAttempts for $ToolName" -Level Info

                $packageResult = Install-PackageWithTimeout -PackageName $ToolName -Force:$Force -Timeout $Timeout

                if ($packageResult.Success) {
                    # Verify installation
                    $verificationResult = Test-InstallationVerification -ToolName $ToolName

                    if ($verificationResult.Success) {
                        $installationResult.Success = $true
                        $installationResult.Message = "Successfully installed and verified $ToolName"
                        $installationResult.InstallationMethod = $packageResult.Method
                        $installationResult.Version = $verificationResult.Version
                        $installationResult.Duration = (Get-Date) - $startTime

                        Write-Log "Successfully installed $ToolName using $($packageResult.Method): $($verificationResult.Version)" -Level Success
                        return $installationResult
                    }
                    else {
                        throw "Installation verification failed: $($verificationResult.Message)"
                    }
                }
                else {
                    throw "Package installation failed: $($packageResult.Message)"
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-Log "Installation attempt $attempt failed for $ToolName : $errorMessage" -Level Warning

                if ($attempt -lt $maxAttempts) {
                    $waitTime = [Math]::Min(30, $attempt * 10)
                    Write-Log "Waiting $waitTime seconds before retry..." -Level Info
                    Start-Sleep -Seconds $waitTime
                }
                else {
                    # Final failure
                    $installationResult.Message = "Installation failed after $maxAttempts attempts: $errorMessage"
                    $installationResult.TroubleshootingInfo = Get-InstallationTroubleshooting -ToolName $ToolName -Error $errorMessage
                    $installationResult.Duration = (Get-Date) - $startTime

                    Write-Log $installationResult.Message -Level Error
                    Write-Log "Troubleshooting information for $ToolName :" -Level Info
                    foreach ($info in $installationResult.TroubleshootingInfo) {
                        Write-Log "  - $info" -Level Info
                    }
                }
            }
        }
    }
    catch {
        $installationResult.Message = "Critical error during installation: $($_.Exception.Message)"
        $installationResult.Duration = (Get-Date) - $startTime
        Write-Log $installationResult.Message -Level Error
    }

    return $installationResult
}

function Install-PackageWithTimeout {
    <#
    .SYNOPSIS
        Installs a package with timeout handling
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageName,

        [switch]$Force,

        [int]$Timeout = 300
    )

    try {
        # Use existing Install-Package function but with timeout
        $job = Start-Job -ScriptBlock {
            param($PackageName, $Force, $ModulePath)
            Import-Module $ModulePath -Force
            Install-Package -PackageName $PackageName -Force:$Force
        } -ArgumentList $PackageName, $Force, $PSCommandPath

        $result = Wait-Job $job -Timeout $Timeout | Receive-Job
        $jobState = $job.State

        Remove-Job $job -Force

        if ($jobState -eq "Completed" -and $result) {
            return @{
                Success = $true
                Method = $script:PreferredManager
                Message = "Package installed successfully"
            }
        }
        elseif ($jobState -eq "Running") {
            return @{
                Success = $false
                Method = $null
                Message = "Installation timed out after $Timeout seconds"
            }
        }
        else {
            return @{
                Success = $false
                Method = $null
                Message = "Installation job failed or returned false"
            }
        }
    }
    catch {
        return @{
            Success = $false
            Method = $null
            Message = "Exception during package installation: $($_.Exception.Message)"
        }
    }
}

function Test-ExistingInstallation {
    <#
    .SYNOPSIS
        Tests if a tool is already installed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    try {
        $command = Get-Command $ToolName -ErrorAction SilentlyContinue
        if ($command) {
            # Try to get version
            $version = $null
            try {
                switch ($ToolName) {
                    "git" { $version = (git --version 2>&1).ToString().Trim() }
                    "curl" { $version = (curl --version 2>&1 | Select-Object -First 1).ToString().Trim() }
                    default { $version = (& $ToolName --version 2>&1 | Select-Object -First 1).ToString().Trim() }
                }
            }
            catch {
                $version = "Version unknown"
            }

            return @{
                Installed = $true
                Version = $version
                Path = $command.Source
            }
        }
        else {
            return @{
                Installed = $false
                Version = $null
                Path = $null
            }
        }
    }
    catch {
        return @{
            Installed = $false
            Version = $null
            Path = $null
            Error = $_.Exception.Message
        }
    }
}

function Test-InstallationVerification {
    <#
    .SYNOPSIS
        Verifies that a tool was installed correctly
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName
    )

    try {
        # Wait a moment for installation to complete
        Start-Sleep -Seconds 2

        # Refresh environment variables
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

        # Test command availability
        $command = Get-Command $ToolName -ErrorAction SilentlyContinue
        if (-not $command) {
            return @{
                Success = $false
                Message = "Command '$ToolName' not found after installation"
                Version = $null
            }
        }

        # Test basic functionality
        try {
            switch ($ToolName) {
                "git" {
                    $output = git --version 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return @{
                            Success = $true
                            Message = "Git installation verified"
                            Version = $output.ToString().Trim()
                        }
                    }
                }
                default {
                    $output = & $ToolName --version 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return @{
                            Success = $true
                            Message = "$ToolName installation verified"
                            Version = ($output | Select-Object -First 1).ToString().Trim()
                        }
                    }
                }
            }

            return @{
                Success = $false
                Message = "Tool command failed verification test"
                Version = $null
            }
        }
        catch {
            return @{
                Success = $false
                Message = "Exception during verification: $($_.Exception.Message)"
                Version = $null
            }
        }
    }
    catch {
        return @{
            Success = $false
            Message = "Critical error during verification: $($_.Exception.Message)"
            Version = $null
        }
    }
}

function Get-InstallationTroubleshooting {
    <#
    .SYNOPSIS
        Provides troubleshooting information for installation failures
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [string]$Error = ""
    )

    $troubleshooting = @()

    try {
        # General troubleshooting
        $troubleshooting += "Check internet connection"
        $troubleshooting += "Try running PowerShell as Administrator"
        $troubleshooting += "Restart terminal and try again"

        # Package manager specific
        if ($script:AvailableManagers.Count -eq 0) {
            $troubleshooting += "No package managers available - install winget, chocolatey, or scoop"
        }
        else {
            $troubleshooting += "Available package managers: $($script:AvailableManagers -join ', ')"
        }

        # Tool specific troubleshooting
        $packageDef = $script:PackageDefinitions[$ToolName]
        if ($packageDef -and $packageDef.ManualUrl) {
            $troubleshooting += "Manual download available: $($packageDef.ManualUrl)"
        }

        # Error specific troubleshooting
        if ($Error -like "*timeout*") {
            $troubleshooting += "Installation timed out - try increasing timeout or check network speed"
        }

        if ($Error -like "*access*denied*" -or $Error -like "*permission*") {
            $troubleshooting += "Permission denied - run as Administrator"
        }

        if ($Error -like "*not found*") {
            $troubleshooting += "Package not found - check package name or try different package manager"
        }

        return $troubleshooting
    }
    catch {
        return @("Unable to generate troubleshooting information: $($_.Exception.Message)")
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Test-PackageManager',
    'Install-PackageManager',
    'Initialize-PackageManager',
    'Install-Package',
    'Install-Tool',
    'Get-AvailableManagers',
    'Get-PreferredManager'
)
