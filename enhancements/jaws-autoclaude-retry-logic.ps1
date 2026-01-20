# ============================================================================
# CLAUDE RETRY LOGIC MODULE
# Enhancement from Auto-Claude v2.7.4: Terminal recreation with retry mechanism
# Add this to ralph-jaws-v4.ps1 or import as module
# ============================================================================

<#
.SYNOPSIS
    Provides resilient Claude CLI invocation with automatic retry on failure.

.DESCRIPTION
    Auto-Claude v2.7.4 added terminal recreation logic with retry mechanism.
    This module brings that reliability to JAWS/RALPH.
    
    Features:
    - Configurable retry attempts
    - Exponential backoff option
    - Detailed failure logging
    - Integration with rabbit hole detection

.EXAMPLE
    $result = Invoke-ClaudeWithRetry -Prompt "Your prompt here"
    
.EXAMPLE
    $result = Invoke-ClaudeWithRetry -Prompt $prompt -MaxRetries 5 -UseExponentialBackoff
#>

# ============================================================================
# CONFIGURATION
# ============================================================================

$script:ClaudeRetryConfig = @{
    DefaultMaxRetries = 3
    DefaultRetryDelaySeconds = 5
    MaxRetryDelaySeconds = 60
    ExponentialBackoffMultiplier = 2
    LogRetries = $true
}

# ============================================================================
# MAIN RETRY FUNCTION
# ============================================================================

function Invoke-ClaudeWithRetry {
    <#
    .SYNOPSIS
        Invokes Claude CLI with automatic retry on failure.
    
    .PARAMETER Prompt
        The prompt to send to Claude.
    
    .PARAMETER MaxRetries
        Maximum number of retry attempts. Default: 3
    
    .PARAMETER RetryDelaySeconds
        Initial delay between retries in seconds. Default: 5
    
    .PARAMETER UseExponentialBackoff
        If set, delay doubles after each failed attempt.
    
    .PARAMETER ClaudeCommand
        The Claude CLI command to use. Default: "claude"
    
    .PARAMETER SkipPermissions
        If set, uses --dangerously-skip-permissions flag.
    
    .OUTPUTS
        String containing Claude's response, or throws on final failure.
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [int]$MaxRetries = $script:ClaudeRetryConfig.DefaultMaxRetries,
        
        [int]$RetryDelaySeconds = $script:ClaudeRetryConfig.DefaultRetryDelaySeconds,
        
        [switch]$UseExponentialBackoff,
        
        [string]$ClaudeCommand = "claude",
        
        [switch]$SkipPermissions = $true
    )
    
    $currentDelay = $RetryDelaySeconds
    $lastError = $null
    $allErrors = @()
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        $startTime = Get-Date
        
        try {
            # Build command arguments
            $args = @()
            if ($SkipPermissions) {
                $args += "--dangerously-skip-permissions"
            }
            $args += "-p"
            $args += $Prompt
            
            # Execute Claude
            $result = & $ClaudeCommand @args 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
            
            $duration = (Get-Date) - $startTime
            
            # Check for success
            if ($exitCode -eq 0 -and $result -and $result.Trim().Length -gt 0) {
                if ($attempt -gt 1 -and $script:ClaudeRetryConfig.LogRetries) {
                    Write-Host "  [RETRY] Succeeded on attempt $attempt after $($duration.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
                }
                return $result
            }
            
            # Capture failure info
            $lastError = @{
                Attempt = $attempt
                ExitCode = $exitCode
                Duration = $duration.TotalSeconds
                Output = $result
                Timestamp = Get-Date
            }
            $allErrors += $lastError
            
            if ($script:ClaudeRetryConfig.LogRetries) {
                Write-Host "  [RETRY] Attempt $attempt/$MaxRetries failed (exit: $exitCode, took: $($duration.TotalSeconds.ToString('F1'))s)" -ForegroundColor Yellow
            }
            
        }
        catch {
            $lastError = @{
                Attempt = $attempt
                Exception = $_.Exception.Message
                Duration = ((Get-Date) - $startTime).TotalSeconds
                Timestamp = Get-Date
            }
            $allErrors += $lastError
            
            if ($script:ClaudeRetryConfig.LogRetries) {
                Write-Host "  [RETRY] Attempt $attempt/$MaxRetries threw exception: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Don't sleep after last attempt
        if ($attempt -lt $MaxRetries) {
            if ($script:ClaudeRetryConfig.LogRetries) {
                Write-Host "  [RETRY] Waiting ${currentDelay}s before retry..." -ForegroundColor DarkGray
            }
            Start-Sleep -Seconds $currentDelay
            
            # Apply exponential backoff if enabled
            if ($UseExponentialBackoff) {
                $currentDelay = [Math]::Min(
                    $currentDelay * $script:ClaudeRetryConfig.ExponentialBackoffMultiplier,
                    $script:ClaudeRetryConfig.MaxRetryDelaySeconds
                )
            }
        }
    }
    
    # All retries exhausted
    $errorSummary = @{
        TotalAttempts = $MaxRetries
        AllErrors = $allErrors
        LastError = $lastError
        Timestamp = Get-Date
    }
    
    # Log detailed failure info
    Write-Host ""
    Write-Host "  [RETRY] ALL ATTEMPTS EXHAUSTED" -ForegroundColor Red
    Write-Host "  Total attempts: $MaxRetries" -ForegroundColor Red
    if ($lastError.Exception) {
        Write-Host "  Last error: $($lastError.Exception)" -ForegroundColor Red
    }
    elseif ($lastError.ExitCode) {
        Write-Host "  Last exit code: $($lastError.ExitCode)" -ForegroundColor Red
    }
    Write-Host ""
    
    throw "Claude invocation failed after $MaxRetries attempts. Last error: $($lastError | ConvertTo-Json -Compress)"
}

# ============================================================================
# HEALTH CHECK FUNCTION
# ============================================================================

function Test-ClaudeAvailability {
    <#
    .SYNOPSIS
        Tests if Claude CLI is available and responding.
    
    .DESCRIPTION
        Quick health check before starting a build session.
        Returns detailed status information.
    
    .PARAMETER ClaudeCommand
        The Claude CLI command to test. Default: "claude"
    
    .OUTPUTS
        Hashtable with availability status and details.
    #>
    
    param(
        [string]$ClaudeCommand = "claude"
    )
    
    $result = @{
        Available = $false
        Version = $null
        ResponseTime = $null
        Error = $null
        Timestamp = Get-Date
    }
    
    try {
        # Test version command (lightweight)
        $startTime = Get-Date
        $version = & $ClaudeCommand --version 2>&1 | Out-String
        $result.ResponseTime = ((Get-Date) - $startTime).TotalMilliseconds
        
        if ($LASTEXITCODE -eq 0 -and $version) {
            $result.Available = $true
            $result.Version = $version.Trim()
        }
        else {
            $result.Error = "Version check returned exit code $LASTEXITCODE"
        }
    }
    catch {
        $result.Error = $_.Exception.Message
    }
    
    return $result
}

# ============================================================================
# INTEGRATION HELPER
# ============================================================================

function Get-RetryIntegrationCode {
    <#
    .SYNOPSIS
        Returns code snippet to integrate retry logic into RALPH main loop.
    #>
    
    return @'
# ============================================================================
# INTEGRATION INTO RALPH-JAWS MAIN LOOP
# Replace the existing Claude execution block (around line 350) with:
# ============================================================================

# Pre-flight check
$claudeHealth = Test-ClaudeAvailability
if (-not $claudeHealth.Available) {
    Write-Host "  [ERROR] Claude CLI not available: $($claudeHealth.Error)" -ForegroundColor Red
    
    if (-not $AutoPilot) {
        $retry = Read-Host "  Retry? [Y/N]"
        if ($retry.ToUpper() -ne 'Y') {
            Complete-Worktree -Success $false
            exit 1
        }
        continue
    }
}

# Execute with retry
try {
    $result = Invoke-ClaudeWithRetry `
        -Prompt $prompt `
        -MaxRetries 3 `
        -UseExponentialBackoff `
        -SkipPermissions
}
catch {
    Write-Host "  [FATAL] Claude invocation failed completely" -ForegroundColor Red
    $state.consecutiveFailures++
    $state.lastError = $_.Exception.Message
    Save-State $state
    
    # Trigger checkpoint on repeated Claude failures
    if ($state.consecutiveFailures -ge 2) {
        $checkpoint = Request-Checkpoint $state $i "Claude CLI repeated failures"
        if ($checkpoint.action -eq 'abort') {
            Complete-Worktree -Success $false
            exit 1
        }
    }
    continue
}
'@
}

# ============================================================================
# MODULE INFO
# ============================================================================

Write-Host "Claude Retry Logic Module loaded." -ForegroundColor Green
Write-Host "Commands available:"
Write-Host "  Invoke-ClaudeWithRetry  - Execute Claude with automatic retry"
Write-Host "  Test-ClaudeAvailability - Check if Claude CLI is working"
Write-Host "  Get-RetryIntegrationCode - Get code to integrate into RALPH"
