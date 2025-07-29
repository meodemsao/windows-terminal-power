# UserInterface.psm1 - Enhanced user interface and progress tracking for Windows Terminal Setup

# Module variables
$script:ProgressState = @{
    CurrentStep = 0
    TotalSteps = 0
    CurrentTask = ""
    StartTime = $null
    StepStartTime = $null
}

function Initialize-UserInterface {
    <#
    .SYNOPSIS
        Initializes the user interface system
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Clear screen for clean start
        Clear-Host
        
        # Display welcome banner
        Show-WelcomeBanner
        
        # Initialize progress tracking
        $script:ProgressState.StartTime = Get-Date
        
        return $true
    }
    catch {
        Write-Warning "Failed to initialize user interface: $($_.Exception.Message)"
        return $false
    }
}

function Show-WelcomeBanner {
    <#
    .SYNOPSIS
        Displays the welcome banner with ASCII art and information
    #>
    [CmdletBinding()]
    param()
    
    $banner = @"

╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗███████╗               ║
║    ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔════╝               ║
║    ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║███████╗               ║
║    ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║╚════██║               ║
║    ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝███████║               ║
║     ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚══════╝               ║
║                                                                              ║
║                    TERMINAL & POWERSHELL SETUP                              ║
║                                                                              ║
║    Transform your command-line experience with modern tools and themes      ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

"@
    
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "Welcome to the Windows Terminal & PowerShell Enhancement Setup!" -ForegroundColor Green
    Write-Host "This installer will configure your terminal with modern CLI tools and themes." -ForegroundColor White
    Write-Host ""
}

function Show-ProgressBar {
    <#
    .SYNOPSIS
        Displays a visual progress bar with percentage and status
    
    .PARAMETER CurrentStep
        Current step number
    
    .PARAMETER TotalSteps
        Total number of steps
    
    .PARAMETER CurrentTask
        Description of current task
    
    .PARAMETER Width
        Width of the progress bar (default: 50)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$CurrentStep,
        
        [Parameter(Mandatory = $true)]
        [int]$TotalSteps,
        
        [Parameter(Mandatory = $true)]
        [string]$CurrentTask,
        
        [int]$Width = 50
    )
    
    # Update progress state
    $script:ProgressState.CurrentStep = $CurrentStep
    $script:ProgressState.TotalSteps = $TotalSteps
    $script:ProgressState.CurrentTask = $CurrentTask
    $script:ProgressState.StepStartTime = Get-Date
    
    # Calculate percentage
    $percentage = if ($TotalSteps -gt 0) { [math]::Round(($CurrentStep / $TotalSteps) * 100, 1) } else { 0 }
    
    # Calculate filled and empty portions
    $filled = [math]::Round(($percentage / 100) * $Width)
    $empty = $Width - $filled
    
    # Create progress bar
    $progressBar = "#" * $filled + "-" * $empty
    
    # Calculate elapsed time
    $elapsed = if ($script:ProgressState.StartTime) { 
        (Get-Date) - $script:ProgressState.StartTime 
    } else { 
        New-TimeSpan 
    }
    
    # Estimate remaining time
    $estimatedTotal = if ($percentage -gt 0) {
        $elapsed.TotalSeconds * (100 / $percentage)
    } else {
        0
    }
    $remaining = [math]::Max(0, $estimatedTotal - $elapsed.TotalSeconds)
    
    # Format time strings
    $elapsedStr = "{0:mm\:ss}" -f $elapsed
    $remainingStr = if ($remaining -gt 0) { "{0:mm\:ss}" -f ([TimeSpan]::FromSeconds($remaining)) } else { "00:00" }
    
    # Display progress information
    Write-Host ""
    Write-Host "┌─ Progress: Step $CurrentStep of $TotalSteps ($percentage%)" -ForegroundColor Yellow
    Write-Host "│"
    Write-Host "│  [$progressBar] $percentage%" -ForegroundColor Green
    Write-Host "│"
    Write-Host "│  Current Task: $CurrentTask" -ForegroundColor White
    Write-Host "│  Elapsed: $elapsedStr | Remaining: ~$remainingStr" -ForegroundColor Gray
    Write-Host "└─────────────────────────────────────────────────────────────" -ForegroundColor Yellow
    Write-Host ""
    
    # Also use built-in Write-Progress for compatibility
    Write-Progress -Activity "Windows Terminal Setup" -Status $CurrentTask -PercentComplete $percentage
}

function Show-StepHeader {
    <#
    .SYNOPSIS
        Displays a formatted step header
    
    .PARAMETER StepNumber
        Step number
    
    .PARAMETER StepTitle
        Step title
    
    .PARAMETER StepDescription
        Step description
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$StepNumber,
        
        [Parameter(Mandatory = $true)]
        [string]$StepTitle,
        
        [string]$StepDescription = ""
    )
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ STEP $StepNumber: $($StepTitle.ToUpper().PadRight(69)) ║" -ForegroundColor Cyan
    if ($StepDescription) {
        Write-Host "║ $($StepDescription.PadRight(77)) ║" -ForegroundColor White
    }
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-UserChoice {
    <#
    .SYNOPSIS
        Prompts user for a choice with validation
    
    .PARAMETER Prompt
        The prompt message
    
    .PARAMETER Choices
        Array of valid choices
    
    .PARAMETER Default
        Default choice if user presses Enter
    
    .PARAMETER AllowEmpty
        Allow empty input
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [string[]]$Choices = @(),
        
        [string]$Default = "",
        
        [switch]$AllowEmpty
    )
    
    do {
        Write-Host ""
        Write-Host "┌─ User Input Required" -ForegroundColor Yellow
        Write-Host "│"
        Write-Host "│  $Prompt" -ForegroundColor White
        
        if ($Choices.Count -gt 0) {
            Write-Host "│"
            for ($i = 0; $i -lt $Choices.Count; $i++) {
                $choice = $Choices[$i]
                $indicator = if ($choice -eq $Default) { " (default)" } else { "" }
                Write-Host "│    [$($i + 1)] $choice$indicator" -ForegroundColor Cyan
            }
        }
        
        if ($Default) {
            Write-Host "│"
            Write-Host "│  Press Enter for default: $Default" -ForegroundColor Gray
        }
        
        Write-Host "│"
        Write-Host -NoNewline "└─ Your choice: " -ForegroundColor Yellow
        
        $input = Read-Host
        
        # Handle empty input
        if ([string]::IsNullOrWhiteSpace($input)) {
            if ($Default) {
                return $Default
            }
            elseif ($AllowEmpty) {
                return ""
            }
            else {
                Write-Host "   Please provide a valid input." -ForegroundColor Red
                continue
            }
        }
        
        # Handle numeric choices
        if ($Choices.Count -gt 0) {
            $numericChoice = $null
            if ([int]::TryParse($input, [ref]$numericChoice)) {
                if ($numericChoice -ge 1 -and $numericChoice -le $Choices.Count) {
                    return $Choices[$numericChoice - 1]
                }
            }
            
            # Handle text choices (case-insensitive)
            $matchingChoice = $Choices | Where-Object { $_ -like "$input*" }
            if ($matchingChoice) {
                return $matchingChoice[0]
            }
            
            Write-Host "   Invalid choice. Please select from the available options." -ForegroundColor Red
        }
        else {
            return $input
        }
    } while ($true)
}

function Get-YesNoChoice {
    <#
    .SYNOPSIS
        Prompts user for a Yes/No choice
    
    .PARAMETER Prompt
        The prompt message
    
    .PARAMETER Default
        Default choice (Y or N)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [ValidateSet("Y", "N", "")]
        [string]$Default = "Y"
    )
    
    $choices = @("Yes", "No")
    $defaultChoice = if ($Default -eq "Y") { "Yes" } else { "No" }
    
    $result = Get-UserChoice -Prompt $Prompt -Choices $choices -Default $defaultChoice
    
    return $result -eq "Yes"
}

function Show-ToolSelectionMenu {
    <#
    .SYNOPSIS
        Shows an interactive tool selection menu
    
    .PARAMETER AvailableTools
        Array of available tools
    
    .PARAMETER PreselectedTools
        Array of preselected tools
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$AvailableTools,
        
        [array]$PreselectedTools = @()
    )
    
    $toolDescriptions = @{
        "git" = "Version control system for tracking changes"
        "curl" = "Command-line tool for transferring data"
        "lazygit" = "Simple terminal UI for git commands"
        "nerd-fonts" = "Iconic font aggregator and collection"
        "oh-my-posh" = "Prompt theme engine for any shell"
        "fzf" = "Command-line fuzzy finder"
        "eza" = "Modern replacement for ls command"
        "bat" = "Cat clone with syntax highlighting"
        "lsd" = "Next gen ls command with icons"
        "neovim" = "Hyperextensible Vim-based text editor"
        "zoxide" = "Smarter cd command with frecency"
        "fnm" = "Fast and simple Node.js version manager"
        "pyenv" = "Simple Python version management"
    }
    
    $selectedTools = $PreselectedTools.Clone()
    
    do {
        Clear-Host
        Show-WelcomeBanner
        
        Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                              TOOL SELECTION MENU                             ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "Select the tools you want to install. Use numbers to toggle selection:" -ForegroundColor White
        Write-Host ""
        
        for ($i = 0; $i -lt $AvailableTools.Count; $i++) {
            $tool = $AvailableTools[$i]
            $isSelected = $selectedTools -contains $tool
            $status = if ($isSelected) { "[X]" } else { "[ ]" }
            $color = if ($isSelected) { "Green" } else { "Gray" }
            $description = $toolDescriptions[$tool]
            
            Write-Host "  $($i + 1). $status $tool" -ForegroundColor $color -NoNewline
            if ($description) {
                Write-Host " - $description" -ForegroundColor Gray
            } else {
                Write-Host ""
            }
        }
        
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  • Enter number to toggle tool selection" -ForegroundColor Cyan
        Write-Host "  • Type 'all' to select all tools" -ForegroundColor Cyan
        Write-Host "  • Type 'none' to deselect all tools" -ForegroundColor Cyan
        Write-Host "  • Type 'done' to continue with selected tools" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Selected tools: $($selectedTools.Count)/$($AvailableTools.Count)" -ForegroundColor Green
        Write-Host ""
        
        $input = Get-UserChoice -Prompt "Enter your choice" -AllowEmpty
        
        switch ($input.ToLower()) {
            "all" {
                $selectedTools = $AvailableTools.Clone()
            }
            "none" {
                $selectedTools = @()
            }
            "done" {
                if ($selectedTools.Count -eq 0) {
                    Write-Host "Please select at least one tool to install." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                } else {
                    break
                }
            }
            default {
                $numericChoice = $null
                if ([int]::TryParse($input, [ref]$numericChoice)) {
                    if ($numericChoice -ge 1 -and $numericChoice -le $AvailableTools.Count) {
                        $tool = $AvailableTools[$numericChoice - 1]
                        if ($selectedTools -contains $tool) {
                            $selectedTools = $selectedTools | Where-Object { $_ -ne $tool }
                        } else {
                            $selectedTools += $tool
                        }
                    }
                }
            }
        }
    } while ($true)
    
    return $selectedTools
}

function Show-ConfigurationMenu {
    <#
    .SYNOPSIS
        Shows configuration options menu
    #>
    [CmdletBinding()]
    param()
    
    $config = @{
        Theme = "One Half Dark"
        Font = "CascadiaCode Nerd Font"
        CreateBackup = $true
        InstallPowerShell7 = $true
        ConfigureGit = $true
    }
    
    Clear-Host
    Show-WelcomeBanner
    
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                            CONFIGURATION OPTIONS                             ║" -ForegroundColor Blue
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
    
    # Theme selection
    $themes = @("One Half Dark", "One Half Light", "Solarized Dark", "Solarized Light", "Campbell", "Vintage")
    $config.Theme = Get-UserChoice -Prompt "Select Windows Terminal theme:" -Choices $themes -Default $config.Theme
    
    # Font selection
    $fonts = @("CascadiaCode Nerd Font", "FiraCode Nerd Font", "JetBrainsMono Nerd Font", "Hack Nerd Font")
    $config.Font = Get-UserChoice -Prompt "Select terminal font:" -Choices $fonts -Default $config.Font
    
    # Backup option
    $config.CreateBackup = Get-YesNoChoice -Prompt "Create backup of existing configurations?" -Default "Y"
    
    # PowerShell 7 installation
    $config.InstallPowerShell7 = Get-YesNoChoice -Prompt "Install PowerShell 7 (recommended)?" -Default "Y"
    
    # Git configuration
    if ($config.ConfigureGit) {
        $config.ConfigureGit = Get-YesNoChoice -Prompt "Configure Git with your user information?" -Default "Y"
        
        if ($config.ConfigureGit) {
            $config.GitUserName = Get-UserChoice -Prompt "Enter your Git username:" -AllowEmpty
            $config.GitUserEmail = Get-UserChoice -Prompt "Enter your Git email:" -AllowEmpty
        }
    }
    
    return $config
}

function Show-InstallationSummary {
    <#
    .SYNOPSIS
        Shows installation summary with results
    
    .PARAMETER Results
        Installation results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )
    
    Clear-Host
    
    $successCount = ($Results.Values | Where-Object { $_.Success -eq $true }).Count
    $failureCount = ($Results.Values | Where-Object { $_.Success -eq $false }).Count
    $totalCount = $Results.Count
    
    if ($successCount -eq $totalCount) {
        $headerColor = "Green"
        $statusIcon = "✓"
        $statusText = "INSTALLATION COMPLETED SUCCESSFULLY"
    } elseif ($successCount -gt 0) {
        $headerColor = "Yellow"
        $statusIcon = "⚠"
        $statusText = "INSTALLATION COMPLETED WITH WARNINGS"
    } else {
        $headerColor = "Red"
        $statusIcon = "✗"
        $statusText = "INSTALLATION FAILED"
    }
    
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor $headerColor
    Write-Host "║ $statusIcon $($statusText.PadRight(75)) ║" -ForegroundColor $headerColor
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor $headerColor
    Write-Host ""
    
    Write-Host "Installation Summary:" -ForegroundColor White
    Write-Host "  • Total tools processed: $totalCount" -ForegroundColor Gray
    Write-Host "  • Successfully installed: $successCount" -ForegroundColor Green
    Write-Host "  • Failed installations: $failureCount" -ForegroundColor Red
    Write-Host ""
    
    if ($successCount -gt 0) {
        Write-Host "[+] Successfully Installed:" -ForegroundColor Green
        foreach ($result in $Results.GetEnumerator()) {
            if ($result.Value.Success) {
                $version = if ($result.Value.Version) { " ($($result.Value.Version))" } else { "" }
                Write-Host "    - $($result.Key)$version" -ForegroundColor Green
            }
        }
        Write-Host ""
    }

    if ($failureCount -gt 0) {
        Write-Host "[-] Failed Installations:" -ForegroundColor Red
        foreach ($result in $Results.GetEnumerator()) {
            if (-not $result.Value.Success) {
                Write-Host "    - $($result.Key): $($result.Value.Message)" -ForegroundColor Red
            }
        }
        Write-Host ""
    }
}

# Export module functions
Export-ModuleMember -Function @(
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
