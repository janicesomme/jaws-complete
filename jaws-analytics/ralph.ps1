param(
    [int]$MaxIterations = 10,
    [int]$SleepSeconds = 2,
    [switch]$GenerateDocs,
    [switch]$Verbose,
    [switch]$AutoPilot,
    [int]$CheckpointEvery = 3,
    [int]$MaxConsecutiveFailures = 3,
    [string]$StateFile = "ralph-state.json",
    [switch]$SkipAnalytics,
    [string]$AnalyticsWebhook = "http://localhost:5678/webhook/analyze-build",
    [string]$ProjectName = "",
    [string]$ClientName = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Banner
Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RALPH-JAWS v3 - Ultimate Agent Harness                              " -ForegroundColor Cyan
Write-Host "  Cole Medin Harness + Rasmus Widing PRP + JAWS Documentation         " -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Configuration:"
Write-Host "  - Max Iterations:        $MaxIterations"
Write-Host "  - Checkpoint Every:      $CheckpointEvery iterations"
Write-Host "  - Max Consecutive Fails: $MaxConsecutiveFailures (rabbit hole detection)"
Write-Host "  - AutoPilot Mode:        $AutoPilot"
Write-Host "  - Generate Docs:         $GenerateDocs"
Write-Host ""

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

function Initialize-State {
    if (Test-Path $StateFile) {
        $state = Get-Content $StateFile -Raw | ConvertFrom-Json
        Write-Host "  Resuming from previous session (iteration $($state.currentIteration))" -ForegroundColor Yellow
        return $state
    }
    
    $newState = @{
        projectName = ""
        startedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        currentIteration = 0
        completedTasks = @()
        failedTasks = @()
        skippedTasks = @()
        currentTaskId = ""
        consecutiveFailures = 0
        learnings = @()
        lastError = ""
        checkpointHistory = @()
    }
    return $newState
}

function Save-State {
    param($state)
    $state | ConvertTo-Json -Depth 10 | Out-File -FilePath $StateFile -Encoding utf8
}

# ============================================================================
# TASK MANAGEMENT
# ============================================================================

function Get-CurrentTask {
    if (-not (Test-Path "PRD.md")) {
        return $null
    }
    
    $prd = Get-Content "PRD.md" -Raw
    
    # Match pattern: ### US-XXX: Title
    $pattern = '###\s+(US-\d+):\s+(.+?)(?=\r?\n)'
    $taskMatches = [regex]::Matches($prd, $pattern)
    
    foreach ($match in $taskMatches) {
        $taskId = $match.Groups[1].Value
        $taskName = $match.Groups[2].Value.Trim()
        
        # Skip if marked as SKIPPED
        if ($prd -match "\[SKIPPED\]\s*###\s+$taskId") {
            continue
        }
        
        # Find this task's section and check if it has incomplete items
        $escapedTaskId = [regex]::Escape($taskId)
        $sections = $prd -split "###\s+$escapedTaskId"
        if ($sections.Count -lt 2) { continue }
        
        $taskSection = $sections[1]
        $nextTaskSplit = $taskSection -split "###\s+US-"
        $taskSection = $nextTaskSplit[0]
        
        if ($taskSection -match '\[\s\]') {
            # Count criteria
            $uncheckedMatches = [regex]::Matches($taskSection, '\[\s\]')
            $checkedMatches = [regex]::Matches($taskSection, '\[x\]')
            $total = $uncheckedMatches.Count + $checkedMatches.Count
            $complete = $checkedMatches.Count
            
            return @{
                id = $taskId
                name = $taskName
                hasIncomplete = $true
                criteriaTotal = $total
                criteriaComplete = $complete
                progress = if ($total -gt 0) { [math]::Round(($complete / $total) * 100) } else { 0 }
            }
        }
    }
    
    return $null
}

function Get-TaskFailureCount {
    param($state, $taskId)
    $failures = @($state.failedTasks | Where-Object { $_.taskId -eq $taskId })
    return $failures.Count
}

# ============================================================================
# CHECKPOINT SYSTEM
# ============================================================================

function Request-Checkpoint {
    param($state, $iteration, $reason)
    
    if ($AutoPilot) {
        Write-Host "  [AutoPilot] Skipping checkpoint: $reason" -ForegroundColor DarkGray
        return @{ action = 'continue' }
    }
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "  CHECKPOINT - Human Review Required                                  " -ForegroundColor Magenta
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Reason: $reason"
    Write-Host "  Iteration: $iteration of $MaxIterations"
    Write-Host "  Completed Tasks: $($state.completedTasks.Count)" -ForegroundColor Green
    Write-Host "  Skipped Tasks: $($state.skippedTasks.Count)" -ForegroundColor Yellow
    Write-Host "  Failed Attempts: $($state.failedTasks.Count)" -ForegroundColor Red
    Write-Host ""
    
    if ($state.consecutiveFailures -gt 0) {
        Write-Host "  WARNING: Consecutive failures: $($state.consecutiveFailures)" -ForegroundColor Red
        Write-Host "  Last error: $($state.lastError)" -ForegroundColor Red
        Write-Host ""
    }
    
    Write-Host "  Options:" -ForegroundColor Cyan
    Write-Host "    [C] Continue - proceed with next iteration"
    Write-Host "    [S] Skip task - mark current task as skipped"
    Write-Host "    [R] Retry with guidance - provide hints"
    Write-Host "    [A] Abort - stop execution"
    Write-Host "    [P] AutoPilot - continue without checkpoints"
    Write-Host ""
    
    $choice = Read-Host "  Your choice"
    
    $state.checkpointHistory += @{
        iteration = $iteration
        reason = $reason
        choice = $choice
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    Save-State $state
    
    switch ($choice.ToUpper()) {
        'C' { return @{ action = 'continue' } }
        'S' { return @{ action = 'skip' } }
        'R' { 
            $guidance = Read-Host "  Enter guidance for the agent"
            return @{ action = 'retry'; guidance = $guidance }
        }
        'A' { return @{ action = 'abort' } }
        'P' { 
            $script:AutoPilot = $true
            return @{ action = 'continue' }
        }
        default { return @{ action = 'continue' } }
    }
}

# ============================================================================
# RABBIT HOLE DETECTION
# ============================================================================

function Test-RabbitHole {
    param($state)
    
    if ($state.consecutiveFailures -ge $MaxConsecutiveFailures) {
        Write-Host ""
        Write-Host "  !!! RABBIT HOLE DETECTED !!!" -ForegroundColor Red
        Write-Host "  Agent has failed $($state.consecutiveFailures) times on task $($state.currentTaskId)" -ForegroundColor Red
        Write-Host ""
        return $true
    }
    return $false
}

# ============================================================================
# CONTEXT BUILDING
# ============================================================================

function Get-CompressedContext {
    param($state, $currentTask)
    
    $context = @"
## Quick Context

Current Task: $($currentTask.id) - $($currentTask.name)
Progress: $($currentTask.criteriaComplete)/$($currentTask.criteriaTotal) criteria ($($currentTask.progress)%)
Attempts on this task: $(Get-TaskFailureCount $state $currentTask.id)
Tasks completed: $($state.completedTasks -join ', ')
"@
    
    if ($state.learnings.Count -gt 0) {
        $recentLearnings = $state.learnings | Select-Object -Last 5
        $context += "`n`nKey Learnings:`n"
        foreach ($learning in $recentLearnings) {
            $context += "- $learning`n"
        }
    }
    
    if ($state.lastError -and $state.consecutiveFailures -gt 0) {
        $context += "`n`nPrevious Attempt Failed: $($state.lastError)`nTry a DIFFERENT approach.`n"
    }
    
    return $context
}

# ============================================================================
# TASK VERIFICATION
# ============================================================================

function Test-TaskCompletion {
    param($taskId)

    $prd = Get-Content "PRD.md" -Raw

    $escapedTaskId = [regex]::Escape($taskId)
    $sections = $prd -split "###\s+$escapedTaskId"
    if ($sections.Count -lt 2) {
        return @{ isComplete = $false; checkedCount = 0; uncheckedCount = 0 }
    }

    $taskSection = $sections[1]
    $nextTaskSplit = $taskSection -split "###\s+US-"
    $taskSection = $nextTaskSplit[0]

    $unchecked = [regex]::Matches($taskSection, '\[\s\]')
    $checked = [regex]::Matches($taskSection, '\[x\]')

    return @{
        isComplete = ($unchecked.Count -eq 0 -and $checked.Count -gt 0)
        checkedCount = $checked.Count
        uncheckedCount = $unchecked.Count
    }
}

# ============================================================================
# ANALYTICS INTEGRATION
# ============================================================================

function Invoke-AnalyticsTrigger {
    param($buildPath, $projectName, $clientName, $webhookUrl)

    Write-Host ""
    Write-Host "  Triggering analytics generation..." -ForegroundColor Cyan

    try {
        $body = @{
            build_path = $buildPath
            project_name = $projectName
            client_name = $clientName
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop

        Write-Host "  Analytics webhook called successfully!" -ForegroundColor Green
        Write-Host "  Response: $($response.status)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Dashboard URL: http://localhost:3000" -ForegroundColor Cyan
        Write-Host ""

        return $true
    }
    catch {
        Write-Host "  Warning: Analytics webhook failed: $_" -ForegroundColor Yellow
        Write-Host "  (This is optional - build completed successfully)" -ForegroundColor DarkGray
        Write-Host ""
        return $false
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Verify PRD exists
if (-not (Test-Path "PRD.md")) {
    Write-Host "ERROR: PRD.md not found in current directory." -ForegroundColor Red
    Write-Host "Create a PRD first using the /prd skill." -ForegroundColor Yellow
    exit 1
}

# Initialize state
$state = Initialize-State
Save-State $state

# Create progress.txt if needed
if (-not (Test-Path "progress.txt")) {
    $progressContent = @"
# Progress Log

## Project Info
- Created: $(Get-Date -Format "yyyy-MM-dd HH:mm")
- Project: See PRD.md
- Harness: RALPH-JAWS v3

## Learnings

## Iteration Log

---
"@
    $progressContent | Out-File -FilePath "progress.txt" -Encoding utf8
}

# Create AGENTS.md if needed
if (-not (Test-Path "AGENTS.md")) {
    $agentsContent = @"
# Agent Knowledge Base

## Project Patterns

## Naming Conventions

## Common Gotchas

## Reusable Patterns

---
"@
    $agentsContent | Out-File -FilePath "AGENTS.md" -Encoding utf8
}

# Create docs folder if generating docs
if ($GenerateDocs -and -not (Test-Path "docs")) {
    New-Item -ItemType Directory -Path "docs" | Out-Null
}

Write-Host "Starting RALPH execution..." -ForegroundColor Green
Write-Host ""

$humanGuidance = $null

# Main Loop
for ($i = ($state.currentIteration + 1); $i -le $MaxIterations; $i++) {
    $state.currentIteration = $i
    Save-State $state
    
    # Get current task
    $currentTask = Get-CurrentTask
    
    if ($null -eq $currentTask) {
        Write-Host ""
        Write-Host "=======================================================================" -ForegroundColor Green
        Write-Host "  ALL TASKS COMPLETE!                                                 " -ForegroundColor Green
        Write-Host "=======================================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Iterations used: $i"
        Write-Host "  Tasks completed: $($state.completedTasks.Count)"
        Write-Host "  Tasks skipped: $($state.skippedTasks.Count)"
        Write-Host ""

        if ($GenerateDocs) {
            Write-Host "Generating documentation..." -ForegroundColor Cyan
            $docsPrompt = "Generate documentation for the completed project. Read PRD.md, progress.txt, and AGENTS.md. Create: docs/README.md (plain English), docs/TECHNICAL.md (technical breakdown), docs/CLIENT-PITCH.md (client presentation), docs/TROUBLESHOOTING.md (common issues), docs/SETUP.md (setup guide)."
            & claude --dangerously-skip-permissions -p $docsPrompt 2>&1 | Out-String | Write-Host
        }

        # Trigger analytics unless skipped
        if (-not $SkipAnalytics) {
            $buildPath = Get-Location | Select-Object -ExpandProperty Path
            $resolvedProjectName = if ($ProjectName) { $ProjectName } else { Split-Path $buildPath -Leaf }
            $resolvedClientName = if ($ClientName) { $ClientName } else { "Internal" }
            Invoke-AnalyticsTrigger -buildPath $buildPath -projectName $resolvedProjectName -clientName $resolvedClientName -webhookUrl $AnalyticsWebhook
        }

        Write-Host "<promise>COMPLETE</promise>"
        exit 0
    }
    
    $state.currentTaskId = $currentTask.id
    
    # Check for rabbit hole
    if (Test-RabbitHole $state) {
        $checkpoint = Request-Checkpoint $state $i "Rabbit hole detected on $($currentTask.id)"
        
        switch ($checkpoint.action) {
            'abort' { 
                Write-Host "Aborted by user." -ForegroundColor Yellow
                exit 1 
            }
            'skip' {
                Write-Host "Skipping task $($currentTask.id)" -ForegroundColor Yellow
                $prd = Get-Content "PRD.md" -Raw
                $prd = $prd -replace "(###\s+$($currentTask.id):)", "[SKIPPED] `$1"
                $prd | Out-File "PRD.md" -Encoding utf8
                $state.skippedTasks += $currentTask.id
                $state.consecutiveFailures = 0
                Save-State $state
                continue
            }
            'retry' {
                $state.consecutiveFailures = 0
                $humanGuidance = $checkpoint.guidance
            }
        }
    }
    
    # Periodic checkpoint
    if (($i % $CheckpointEvery -eq 0) -and ($i -gt 0) -and (-not $AutoPilot)) {
        $checkpoint = Request-Checkpoint $state $i "Periodic review (every $CheckpointEvery iterations)"
        
        if ($checkpoint.action -eq 'abort') {
            Write-Host "Aborted by user." -ForegroundColor Yellow
            exit 1
        }
        if ($checkpoint.action -eq 'skip') {
            $prd = Get-Content "PRD.md" -Raw
            $prd = $prd -replace "(###\s+$($currentTask.id):)", "[SKIPPED] `$1"
            $prd | Out-File "PRD.md" -Encoding utf8
            $state.skippedTasks += $currentTask.id
            Save-State $state
            continue
        }
        if ($checkpoint.action -eq 'retry') {
            $humanGuidance = $checkpoint.guidance
        }
    }
    
    # Display iteration header
    Write-Host "=======================================================================" -ForegroundColor DarkGray
    Write-Host "  ITERATION $i of $MaxIterations" -ForegroundColor White
    Write-Host "  Task: $($currentTask.id) - $($currentTask.name)" -ForegroundColor Cyan
    Write-Host "  Progress: $($currentTask.criteriaComplete)/$($currentTask.criteriaTotal) ($($currentTask.progress)%)" -ForegroundColor DarkGray
    Write-Host "=======================================================================" -ForegroundColor DarkGray
    Write-Host ""
    
    # Build context
    $compressedContext = Get-CompressedContext $state $currentTask
    
    # Add human guidance if provided
    $guidanceSection = ""
    if ($humanGuidance) {
        $guidanceSection = "`n`n## HUMAN GUIDANCE (Follow this!)`n$humanGuidance`n"
        $humanGuidance = $null
    }
    
    $prompt = @"
You are RALPH, an autonomous coding agent for n8n workflows, Supabase, and full-stack apps.

$compressedContext
$guidanceSection

## Your Mission

Complete task $($currentTask.id): $($currentTask.name)

## Steps

1. Read PRD.md - find task $($currentTask.id) and its acceptance criteria
2. Read AGENTS.md - check for project patterns
3. Implement the task
4. Verify it works

## Rules

- ONLY mark complete if verified
- Mark complete in PRD.md - change [ ] to [x] for criteria you verified
- One task only

## After Completion

Update progress.txt with what you did and learned.
Update AGENTS.md if you found a reusable pattern.

If ALL tasks in PRD are complete, output: <promise>COMPLETE</promise>
"@

    # Execute Claude
    $startTime = Get-Date
    
    if ($Verbose) {
        Write-Host "  Sending prompt to Claude..." -ForegroundColor DarkGray
    }
    
    $result = ""
    try {
        $result = (& claude --dangerously-skip-permissions -p $prompt 2>&1 | Out-String)
    }
    catch {
        Write-Host "  Error calling Claude: $_" -ForegroundColor Red
        $state.consecutiveFailures++
        $state.lastError = $_.ToString()
        Save-State $state
        continue
    }
    
    $duration = (Get-Date) - $startTime
    
    Write-Host $result
    Write-Host ""
    Write-Host "  Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor DarkGray
    
    # Verify completion
    $verification = Test-TaskCompletion $currentTask.id
    
    if ($verification.isComplete) {
        Write-Host "  [OK] Task $($currentTask.id) verified complete" -ForegroundColor Green
        $state.completedTasks += $currentTask.id
        $state.consecutiveFailures = 0
        $state.lastError = ""
    }
    else {
        Write-Host "  [!!] Task $($currentTask.id) NOT complete ($($verification.uncheckedCount) criteria remaining)" -ForegroundColor Yellow
        $state.consecutiveFailures++
        $state.failedTasks += @{
            taskId = $currentTask.id
            iteration = $i
            timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        $state.lastError = "Task criteria not complete ($($verification.uncheckedCount) remaining)"
    }
    
    Save-State $state
    
    # Check for completion promise
    if ($result -match "<promise>COMPLETE</promise>") {
        $finalCheck = Get-CurrentTask
        if ($null -eq $finalCheck) {
            Write-Host ""
            Write-Host "=======================================================================" -ForegroundColor Green
            Write-Host "  ALL TASKS COMPLETE!                                                 " -ForegroundColor Green
            Write-Host "=======================================================================" -ForegroundColor Green

            if ($GenerateDocs) {
                Write-Host "Generating documentation..." -ForegroundColor Cyan
                $docsPrompt = "Generate documentation for the completed project. Read PRD.md, progress.txt, and AGENTS.md. Create docs folder with README.md, TECHNICAL.md, CLIENT-PITCH.md, TROUBLESHOOTING.md, SETUP.md."
                & claude --dangerously-skip-permissions -p $docsPrompt 2>&1 | Out-String | Write-Host
            }

            # Trigger analytics unless skipped
            if (-not $SkipAnalytics) {
                $buildPath = Get-Location | Select-Object -ExpandProperty Path
                $resolvedProjectName = if ($ProjectName) { $ProjectName } else { Split-Path $buildPath -Leaf }
                $resolvedClientName = if ($ClientName) { $ClientName } else { "Internal" }
                Invoke-AnalyticsTrigger -buildPath $buildPath -projectName $resolvedProjectName -clientName $resolvedClientName -webhookUrl $AnalyticsWebhook
            }

            exit 0
        }
    }
    
    Start-Sleep -Seconds $SleepSeconds
}

# Max iterations reached
Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Yellow
Write-Host "  MAX ITERATIONS REACHED                                              " -ForegroundColor Yellow
Write-Host "=======================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Iterations: $MaxIterations"
Write-Host "  Completed: $($state.completedTasks.Count)"
Write-Host "  Skipped: $($state.skippedTasks.Count)"
Write-Host "  Failed attempts: $($state.failedTasks.Count)"
Write-Host ""
Write-Host "  State saved to $StateFile - run again to resume."

exit 1
