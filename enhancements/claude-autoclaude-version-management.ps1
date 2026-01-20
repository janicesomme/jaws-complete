# ============================================================================
# CLAUDE CLI VERSION MANAGEMENT MODULE
# Enhancement from Auto-Claude v2.7.4: CLI version detection and rollback
# Add this to ralph-jaws-v4.ps1 or import as module
# ============================================================================

<#
.SYNOPSIS
    Manages Claude CLI versions - detect, select, and rollback.

.DESCRIPTION
    Auto-Claude v2.7.4 added Claude Code version rollback feature.
    This module brings that capability to JAWS/RALPH.
    
    Features:
    - Detect all installed Claude CLI versions
    - Select preferred version for builds
    - Store version preference
    - Quick health check across versions

.EXAMPLE
    Get-ClaudeVersions
    Set-ClaudeVersion -Version "1.0.3"
    
.EXAMPLE
    $best = Get-BestClaudeVersion
    Write-Host "Using: $($best.Path)"
#>

# ============================================================================
# CONFIGURATION
# ============================================================================

$script:ClaudeVersionConfig = @{
    PreferenceFile = ".claude-version"
    MinimumVersion = "1.0.0"
    CheckLocations = @(
        # npm global
        "claude",
        # npx
        "npx claude",
        # Windows specific
        "$env:APPDATA\npm\claude.cmd",
        "$env:LOCALAPPDATA\npm\claude.cmd",
        # Common Windows paths
        "C:\Program Files\nodejs\claude.cmd",
        # User npm global (Windows)
        "$env:USERPROFILE\AppData\Roaming\npm\claude.cmd"
    )
}

# ============================================================================
# VERSION DETECTION
# ============================================================================

function Get-ClaudeVersions {
    <#
    .SYNOPSIS
        Discovers all installed Claude CLI versions.
    
    .DESCRIPTION
        Searches multiple locations for Claude CLI installations
        and returns detailed information about each.
    
    .OUTPUTS
        Array of hashtables with version info.
    #>
    
    $versions = @()
    
    Write-Host "  Scanning for Claude CLI installations..." -ForegroundColor Cyan
    
    foreach ($location in $script:ClaudeVersionConfig.CheckLocations) {
        try {
            # Handle "npx claude" specially
            if ($location -eq "npx claude") {
                $versionOutput = npx claude --version 2>&1 | Out-String
                if ($LASTEXITCODE -eq 0 -and $versionOutput) {
                    $versions += @{
                        Path = "npx claude"
                        Command = "npx"
                        Args = @("claude")
                        Version = $versionOutput.Trim()
                        Type = "npx"
                        Available = $true
                    }
                    Write-Host "    [✓] npx claude: $($versionOutput.Trim())" -ForegroundColor Green
                }
                continue
            }
            
            # Standard command check
            $command = $location
            $exists = $false
            
            # Check if it's a path or a command
            if ($location -match "^[A-Za-z]:" -or $location -match "^/") {
                # It's a path
                $exists = Test-Path $location
                if (-not $exists) { continue }
            }
            else {
                # It's a command - check if it exists
                $which = Get-Command $location -ErrorAction SilentlyContinue
                if (-not $which) { continue }
                $exists = $true
                $command = $which.Source
            }
            
            # Get version
            $versionOutput = & $command --version 2>&1 | Out-String
            
            if ($LASTEXITCODE -eq 0 -and $versionOutput) {
                $versionInfo = @{
                    Path = $command
                    Command = $command
                    Args = @()
                    Version = $versionOutput.Trim()
                    Type = if ($location -match "npm") { "npm-global" } else { "local" }
                    Available = $true
                }
                
                # Avoid duplicates
                $isDuplicate = $versions | Where-Object { $_.Path -eq $command -or $_.Version -eq $versionOutput.Trim() }
                if (-not $isDuplicate) {
                    $versions += $versionInfo
                    Write-Host "    [✓] $command : $($versionOutput.Trim())" -ForegroundColor Green
                }
            }
        }
        catch {
            # Silently skip unavailable locations
            continue
        }
    }
    
    if ($versions.Count -eq 0) {
        Write-Host "    [✗] No Claude CLI installations found" -ForegroundColor Red
        Write-Host "    Install with: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    }
    else {
        Write-Host ""
        Write-Host "  Found $($versions.Count) installation(s)" -ForegroundColor Cyan
    }
    
    return $versions
}

# ============================================================================
# VERSION SELECTION
# ============================================================================

function Get-BestClaudeVersion {
    <#
    .SYNOPSIS
        Returns the best available Claude CLI version.
    
    .DESCRIPTION
        Priority order:
        1. User preference (if set and available)
        2. npm global installation
        3. npx (always latest)
    
    .OUTPUTS
        Hashtable with selected version info.
    #>
    
    $versions = Get-ClaudeVersions
    
    if ($versions.Count -eq 0) {
        return $null
    }
    
    # Check for user preference
    if (Test-Path $script:ClaudeVersionConfig.PreferenceFile) {
        $preferred = Get-Content $script:ClaudeVersionConfig.PreferenceFile -Raw
        $preferred = $preferred.Trim()
        
        $match = $versions | Where-Object { $_.Version -like "*$preferred*" -or $_.Path -eq $preferred }
        if ($match) {
            Write-Host "  Using preferred version: $($match[0].Version)" -ForegroundColor Green
            return $match[0]
        }
    }
    
    # Priority: npm-global > local > npx
    $npmGlobal = $versions | Where-Object { $_.Type -eq "npm-global" } | Select-Object -First 1
    if ($npmGlobal) {
        return $npmGlobal
    }
    
    $local = $versions | Where-Object { $_.Type -eq "local" } | Select-Object -First 1
    if ($local) {
        return $local
    }
    
    # Fallback to npx
    return $versions | Where-Object { $_.Type -eq "npx" } | Select-Object -First 1
}

function Set-ClaudeVersion {
    <#
    .SYNOPSIS
        Sets preferred Claude CLI version for this project.
    
    .PARAMETER Version
        Version string or path to prefer.
    
    .EXAMPLE
        Set-ClaudeVersion -Version "1.0.3"
        Set-ClaudeVersion -Version "C:\tools\claude\claude.exe"
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$Version
    )
    
    # Verify it exists
    $versions = Get-ClaudeVersions
    $match = $versions | Where-Object { $_.Version -like "*$Version*" -or $_.Path -eq $Version }
    
    if (-not $match) {
        Write-Host "  [ERROR] Version '$Version' not found in installed versions" -ForegroundColor Red
        Write-Host "  Available versions:" -ForegroundColor Yellow
        $versions | ForEach-Object {
            Write-Host "    - $($_.Version) ($($_.Path))" -ForegroundColor DarkYellow
        }
        return $false
    }
    
    # Save preference
    $match[0].Version | Out-File $script:ClaudeVersionConfig.PreferenceFile -Encoding utf8 -NoNewline
    
    Write-Host "  [OK] Set Claude version preference: $($match[0].Version)" -ForegroundColor Green
    Write-Host "  Saved to: $($script:ClaudeVersionConfig.PreferenceFile)" -ForegroundColor DarkGray
    
    return $true
}

function Clear-ClaudeVersionPreference {
    <#
    .SYNOPSIS
        Removes version preference, returns to auto-selection.
    #>
    
    if (Test-Path $script:ClaudeVersionConfig.PreferenceFile) {
        Remove-Item $script:ClaudeVersionConfig.PreferenceFile -Force
        Write-Host "  [OK] Cleared version preference - will auto-select" -ForegroundColor Green
    }
    else {
        Write-Host "  No preference file found" -ForegroundColor DarkGray
    }
}

# ============================================================================
# VERSION COMPARISON
# ============================================================================

function Compare-ClaudeVersions {
    <#
    .SYNOPSIS
        Compares two Claude CLI version strings.
    
    .OUTPUTS
        -1 if Version1 < Version2
         0 if equal
         1 if Version1 > Version2
    #>
    
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    # Extract version numbers
    $v1Match = [regex]::Match($Version1, '(\d+)\.(\d+)\.(\d+)')
    $v2Match = [regex]::Match($Version2, '(\d+)\.(\d+)\.(\d+)')
    
    if (-not $v1Match.Success -or -not $v2Match.Success) {
        return 0  # Can't compare, assume equal
    }
    
    for ($i = 1; $i -le 3; $i++) {
        $n1 = [int]$v1Match.Groups[$i].Value
        $n2 = [int]$v2Match.Groups[$i].Value
        
        if ($n1 -lt $n2) { return -1 }
        if ($n1 -gt $n2) { return 1 }
    }
    
    return 0
}

function Test-ClaudeVersionMinimum {
    <#
    .SYNOPSIS
        Checks if installed version meets minimum requirement.
    #>
    
    param(
        [string]$MinimumVersion = $script:ClaudeVersionConfig.MinimumVersion
    )
    
    $best = Get-BestClaudeVersion
    if (-not $best) {
        Write-Host "  [ERROR] No Claude CLI found" -ForegroundColor Red
        return $false
    }
    
    $comparison = Compare-ClaudeVersions $best.Version $MinimumVersion
    
    if ($comparison -lt 0) {
        Write-Host "  [WARNING] Claude CLI version $($best.Version) is below minimum $MinimumVersion" -ForegroundColor Yellow
        Write-Host "  Update with: npm update -g @anthropic-ai/claude-code" -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "  [OK] Claude CLI version $($best.Version) meets minimum $MinimumVersion" -ForegroundColor Green
    return $true
}

# ============================================================================
# INTERACTIVE SELECTOR
# ============================================================================

function Select-ClaudeVersion {
    <#
    .SYNOPSIS
        Interactive version selector when multiple versions found.
    
    .DESCRIPTION
        Presents menu to select preferred Claude CLI version.
        Used when Auto-Claude detects multiple installations.
    #>
    
    $versions = Get-ClaudeVersions
    
    if ($versions.Count -eq 0) {
        Write-Host "  No Claude CLI installations found" -ForegroundColor Red
        return $null
    }
    
    if ($versions.Count -eq 1) {
        Write-Host "  Only one version available: $($versions[0].Version)" -ForegroundColor Green
        return $versions[0]
    }
    
    Write-Host ""
    Write-Host "  Multiple Claude CLI versions found. Select one:" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $versions.Count; $i++) {
        $v = $versions[$i]
        $marker = if ($v.Type -eq "npm-global") { "(recommended)" } else { "" }
        Write-Host "    [$($i + 1)] $($v.Version) - $($v.Type) $marker" -ForegroundColor White
        Write-Host "        Path: $($v.Path)" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    $choice = Read-Host "  Enter number (1-$($versions.Count)) or press Enter for recommended"
    
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $selected = Get-BestClaudeVersion
    }
    else {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $versions.Count) {
            $selected = $versions[$index]
        }
        else {
            Write-Host "  Invalid selection, using recommended" -ForegroundColor Yellow
            $selected = Get-BestClaudeVersion
        }
    }
    
    Write-Host ""
    Write-Host "  Selected: $($selected.Version)" -ForegroundColor Green
    
    # Offer to save preference
    $save = Read-Host "  Save as default for this project? [Y/n]"
    if ($save.ToUpper() -ne 'N') {
        Set-ClaudeVersion -Version $selected.Version
    }
    
    return $selected
}

# ============================================================================
# GET CLAUDE COMMAND FOR RALPH
# ============================================================================

function Get-ClaudeCommand {
    <#
    .SYNOPSIS
        Returns the Claude command string for use in RALPH.
    
    .DESCRIPTION
        This replaces the simple Get-ClaudeCommand in ralph-jaws-v4.ps1
        with version-aware selection.
    
    .OUTPUTS
        String command or hashtable with command + args for npx.
    #>
    
    $version = Get-BestClaudeVersion
    
    if (-not $version) {
        Write-Host "  [WARNING] No Claude CLI found, falling back to 'claude'" -ForegroundColor Yellow
        return "claude"
    }
    
    if ($version.Type -eq "npx") {
        # For npx, we need to handle differently
        return @{
            Type = "npx"
            Command = "npx"
            Args = @("claude")
        }
    }
    
    return $version.Path
}

# ============================================================================
# INTEGRATION HELPER
# ============================================================================

function Get-VersionIntegrationCode {
    <#
    .SYNOPSIS
        Returns code snippet to integrate into RALPH.
    #>
    
    return @'
# ============================================================================
# INTEGRATION INTO RALPH-JAWS
# Replace the Get-ClaudeCommand function and update invocation:
# ============================================================================

# At top of script, add parameter:
# [string]$ClaudeVersion = $null

# Replace Get-ClaudeCommand with:
function Get-ClaudeCommand {
    # Import version management if available
    $versionModule = Join-Path $PSScriptRoot "claude-version-management.ps1"
    if (Test-Path $versionModule) {
        . $versionModule
        $version = Get-BestClaudeVersion
        if ($version) {
            Write-Host "  Using Claude CLI: $($version.Version)" -ForegroundColor DarkGray
            return $version.Path
        }
    }
    
    # Fallback to simple detection
    return "claude"
}

# Update Claude invocation to handle npx:
$claudeCmd = Get-ClaudeCommand
$result = ""

if ($claudeCmd -is [hashtable] -and $claudeCmd.Type -eq "npx") {
    # npx invocation
    $result = (& $claudeCmd.Command $claudeCmd.Args --dangerously-skip-permissions -p $prompt 2>&1 | Out-String)
}
else {
    # Direct invocation
    $result = (& $claudeCmd --dangerously-skip-permissions -p $prompt 2>&1 | Out-String)
}
'@
}

# ============================================================================
# MODULE INFO
# ============================================================================

Write-Host "Claude CLI Version Management Module loaded." -ForegroundColor Green
Write-Host "Commands available:"
Write-Host "  Get-ClaudeVersions            - List all installed versions"
Write-Host "  Get-BestClaudeVersion         - Get recommended version"
Write-Host "  Set-ClaudeVersion             - Set preferred version"
Write-Host "  Clear-ClaudeVersionPreference - Reset to auto-select"
Write-Host "  Select-ClaudeVersion          - Interactive selector"
Write-Host "  Test-ClaudeVersionMinimum     - Check minimum version"
Write-Host "  Get-ClaudeCommand             - Get command for RALPH"
Write-Host "  Get-VersionIntegrationCode    - Get integration code"
