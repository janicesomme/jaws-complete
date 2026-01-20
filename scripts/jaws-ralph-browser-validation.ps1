# ============================================================================
# RALPH BROWSER VALIDATION MODULE
# Automatically validates UI tasks using Claude in Chrome tools
# Add to scripts/ folder, import into ralph-jaws-v4.ps1
# ============================================================================

# New parameter to add to ralph-jaws-v4.ps1:
# [switch]$AutoBrowserValidation = $true,
# [string]$AppUrl = "http://localhost:3000"

# ============================================================================
# TASK TYPE DETECTION
# ============================================================================

function Get-TaskType {
    <#
    .SYNOPSIS
    Detects if a task is UI, Backend, or Both from PRD.
    #>
    param(
        [string]$TaskId,
        [string]$PRDPath = "PRD.md"
    )
    
    if (-not (Test-Path $PRDPath)) {
        return "Unknown"
    }
    
    $prd = Get-Content $PRDPath -Raw
    $escapedId = [regex]::Escape($TaskId)
    
    # Find task section
    if ($prd -match "###\s+$escapedId[\s\S]*?\*\*TYPE:\*\*\s*(UI|Backend|Both)") {
        return $Matches[1]
    }
    
    # Fallback: guess based on keywords in task name/description
    if ($prd -match "###\s+$escapedId:\s*(.+?)(?=\r?\n)") {
        $taskName = $Matches[1].ToLower()
        
        $uiKeywords = @("form", "page", "dashboard", "button", "ui", "frontend", "display", "view", "screen", "modal", "popup", "menu", "navigation", "layout")
        
        foreach ($keyword in $uiKeywords) {
            if ($taskName -match $keyword) {
                return "UI"
            }
        }
    }
    
    return "Backend"
}

function Test-TaskNeedsBrowserValidation {
    param(
        [string]$TaskId,
        [string]$PRDPath = "PRD.md"
    )
    
    $taskType = Get-TaskType -TaskId $TaskId -PRDPath $PRDPath
    return ($taskType -eq "UI" -or $taskType -eq "Both")
}

# ============================================================================
# BROWSER VALIDATION PROMPT GENERATOR
# ============================================================================

function Get-BrowserValidationPrompt {
    <#
    .SYNOPSIS
    Generates a prompt for Claude to validate UI using browser tools.
    #>
    param(
        [string]$TaskId,
        [string]$TaskName,
        [string]$AppUrl = "http://localhost:3000",
        [string]$VerifyField = ""
    )
    
    $prompt = @"
## AUTOMATIC BROWSER VALIDATION

You just completed a UI task. Now validate it actually works.

**Task:** $TaskId - $TaskName
**App URL:** $AppUrl

### Step 1: Navigate
Use the navigate tool to go to the relevant page.

### Step 2: Read Page Structure  
Use read_page to see what elements exist.

### Step 3: Test the Feature
Based on what this task does:
- If it's a form: find fields, fill them with test data, submit
- If it's a button: find it, click it, verify response
- If it's a display: verify the expected content appears

Use these tools:
- find query="[description]" to locate elements
- form_input ref="[ref]" value="[test data]" to fill fields
- computer action="left_click" ref="[ref]" to click
- computer action="wait" duration=2 to wait for responses

### Step 4: Screenshot Evidence
Use computer action="screenshot" to capture the result.

### Step 5: Report
State clearly:
- BROWSER VALIDATION: PASS ✓ - [what worked]
- BROWSER VALIDATION: FAIL ✗ - [what's broken]

If FAIL, describe the issue so it can be fixed.

$( if ($VerifyField) { "Additional verify instructions: $VerifyField" } )

Start with Step 1 now.
"@

    return $prompt
}

# ============================================================================
# INTEGRATION INTO RALPH MAIN LOOP
# ============================================================================

function Invoke-BrowserValidation {
    <#
    .SYNOPSIS
    Runs browser validation after a UI task completes.
    Returns pass/fail status.
    #>
    param(
        [hashtable]$Task,
        [string]$AppUrl = "http://localhost:3000",
        [string]$ClaudeCmd = "claude"
    )
    
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "  │  AUTOMATIC BROWSER VALIDATION                                   │" -ForegroundColor Cyan
    Write-Host "  │  Task: $($Task.id) - $($Task.name.Substring(0, [Math]::Min(40, $Task.name.Length)))..." -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
    
    $prompt = Get-BrowserValidationPrompt `
        -TaskId $Task.id `
        -TaskName $Task.name `
        -AppUrl $AppUrl `
        -VerifyField $Task.verify
    
    $result = ""
    try {
        $result = (& $ClaudeCmd --dangerously-skip-permissions -p $prompt 2>&1 | Out-String)
        Write-Host $result
    }
    catch {
        Write-Host "  [ERROR] Browser validation failed: $_" -ForegroundColor Red
        return @{ passed = $false; error = $_.ToString() }
    }
    
    # Check result for pass/fail
    if ($result -match "BROWSER VALIDATION:\s*PASS") {
        Write-Host ""
        Write-Host "  [✓] Browser validation PASSED" -ForegroundColor Green
        return @{ passed = $true }
    }
    elseif ($result -match "BROWSER VALIDATION:\s*FAIL") {
        Write-Host ""
        Write-Host "  [✗] Browser validation FAILED" -ForegroundColor Red
        return @{ passed = $false; error = "See output above" }
    }
    else {
        Write-Host ""
        Write-Host "  [?] Browser validation result unclear" -ForegroundColor Yellow
        return @{ passed = $true; warning = "Could not determine pass/fail" }
    }
}

# ============================================================================
# ADD THIS TO RALPH MAIN LOOP
# ============================================================================

<#
After the existing task completion check, add:

# Browser validation for UI tasks
if ($AutoBrowserValidation) {
    $needsBrowser = Test-TaskNeedsBrowserValidation -TaskId $currentTask.id
    
    if ($needsBrowser -and $verification.isComplete) {
        Write-Host "  UI task detected - running browser validation..." -ForegroundColor Cyan
        
        $browserResult = Invoke-BrowserValidation `
            -Task $currentTask `
            -AppUrl $AppUrl `
            -ClaudeCmd $claudeCmd
        
        if (-not $browserResult.passed) {
            Write-Host "  [!!] Browser validation failed - task NOT complete" -ForegroundColor Yellow
            $state.consecutiveFailures++
            $state.lastError = "Browser validation failed"
            # Don't mark task as complete
            continue
        }
    }
}
#>

# ============================================================================
# EXPORT
# ============================================================================

Write-Host ""
Write-Host "RALPH Browser Validation Module loaded." -ForegroundColor Green
Write-Host ""
Write-Host "Functions:" -ForegroundColor Cyan
Write-Host "  Get-TaskType                    - Detect UI/Backend/Both"
Write-Host "  Test-TaskNeedsBrowserValidation - Check if task needs browser test"
Write-Host "  Get-BrowserValidationPrompt     - Generate validation prompt"
Write-Host "  Invoke-BrowserValidation        - Run the validation"
Write-Host ""
Write-Host "RALPH will automatically validate UI tasks after implementation." -ForegroundColor Green
Write-Host ""
