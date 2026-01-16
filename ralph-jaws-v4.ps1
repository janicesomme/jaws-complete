param(
    [int]$MaxIterations = 10,
    [int]$SleepSeconds = 2,
    [switch]$GenerateDocs,
    [switch]$Verbose,
    [switch]$AutoPilot,
    [int]$CheckpointEvery = 3,
    [int]$MaxConsecutiveFailures = 3,
    [string]$StateFile = "ralph-state.json",
    
    # === NEW v4 FEATURES (GSD-inspired) ===
    [switch]$UseWorktree,
    [string]$WorktreePath = "../.worktrees",
    [int]$MaxTasksPerSession = 5,
    [switch]$FreshContextMode,
    [ValidateSet("opus", "sonnet", "haiku")]
    [string]$Model = "sonnet",
    [switch]$AtomicCommits,
    [switch]$GenerateChangelog,
    [string]$PRDPath = "PRD.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# BANNER
# ============================================================================

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RALPH-JAWS v4 - Ultimate Agent Harness                              " -ForegroundColor Cyan
Write-Host "  Now with: Git Worktrees | Atomic Commits | Context Reset | Models   " -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Configuration:"
Write-Host "  - Max Iterations:        $MaxIterations"
Write-Host "  - Checkpoint Every:      $CheckpointEvery iterations"
Write-Host "  - Max Consecutive Fails: $MaxConsecutiveFailures (rabbit hole detection)"
Write-Host "  - AutoPilot Mode:        $AutoPilot"
Write-Host "  - Generate Docs:         $GenerateDocs"
Write-Host ""
Write-Host "  v4 Features:" -ForegroundColor Yellow
Write-Host "  - Use Worktree:          $UseWorktree"
Write-Host "  - Fresh Context Mode:    $FreshContextMode (max $MaxTasksPerSession tasks/session)"
Write-Host "  - Model:                 $Model"
Write-Host "  - Atomic Commits:        $AtomicCommits"
Write-Host "  - Generate Changelog:    $GenerateChangelog"
Write-Host ""

# ============================================================================
# GIT WORKTREE MANAGEMENT (NEW - from Manual Auto-Claude)
# ============================================================================

$WorktreeBranch = $null
$WorktreeCreated = $false
$OriginalPath = Get-Location

function Initialize-Worktree {
    if (-not $UseWorktree) { return }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $script:WorktreeBranch = "jaws-build-$timestamp"
    $worktreeDir = Join-Path $WorktreePath $WorktreeBranch
    
    Write-Host "  Creating isolated worktree: $worktreeDir" -ForegroundColor Cyan
    Write-Host "  Branch: $WorktreeBranch" -ForegroundColor Cyan
    
    # Ensure worktree directory exists
    if (-not (Test-Path $WorktreePath)) {
        New-Item -ItemType Directory -Path $WorktreePath -Force | Out-Null
    }
    
    try {
        # Create worktree with new branch
        git worktree add $worktreeDir -b $WorktreeBranch 2>&1 | Out-Null
        
        # Copy PRD to worktree if it exists
        if (Test-Path $PRDPath) {
            Copy-Item $PRDPath -Destination $worktreeDir -Force
        }
        
        # Copy any other necessary files (AGENTS.md, progress.txt)
        @("AGENTS.md", "progress.txt", "ai_docs") | ForEach-Object {
            if (Test-Path $_) {
                Copy-Item $_ -Destination $worktreeDir -Recurse -Force
            }
        }
        
        # Change to worktree
        Set-Location $worktreeDir
        $script:WorktreeCreated = $true
        
        Write-Host "  [OK] Worktree created. Main branch is SAFE." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "  [ERROR] Failed to create worktree: $_" -ForegroundColor Red
        Write-Host "  Continuing in current directory..." -ForegroundColor Yellow
    }
}

function Complete-Worktree {
    param([bool]$Success = $true)
    
    if (-not $WorktreeCreated) { return }
    
    $worktreeDir = Get-Location
    Set-Location $OriginalPath
    
    if ($Success) {
        Write-Host ""
        Write-Host "  Build successful. Merging worktree to main..." -ForegroundColor Cyan
        
        try {
            git merge $WorktreeBranch --no-ff -m "JAWS Build: $WorktreeBranch completed" 2>&1 | Out-Null
            Write-Host "  [OK] Merged to main branch" -ForegroundColor Green
        }
        catch {
            Write-Host "  [WARNING] Merge had conflicts. Resolve manually." -ForegroundColor Yellow
            Write-Host "  Branch $WorktreeBranch preserved for review." -ForegroundColor Yellow
            return
        }
    }
    else {
        Write-Host ""
        Write-Host "  Build incomplete. Worktree preserved for review." -ForegroundColor Yellow
        Write-Host "  Branch: $WorktreeBranch" -ForegroundColor Yellow
        Write-Host "  Path: $worktreeDir" -ForegroundColor Yellow
        return
    }
    
    # Cleanup
    try {
        git worktree remove $worktreeDir --force 2>&1 | Out-Null
        git branch -d $WorktreeBranch 2>&1 | Out-Null
        Write-Host "  [OK] Worktree cleaned up" -ForegroundColor Green
    }
    catch {
        Write-Host "  [WARNING] Cleanup failed. Run manually:" -ForegroundColor Yellow
        Write-Host "    git worktree remove $worktreeDir" -ForegroundColor Yellow
        Write-Host "    git branch -d $WorktreeBranch" -ForegroundColor Yellow
    }
}

# ============================================================================
# ATOMIC COMMITS (NEW - from GSD)
# ============================================================================

function New-AtomicCommit {
    param(
        [string]$TaskId,
        [string]$Summary
    )
    
    if (-not $AtomicCommits) { return }
    
    try {
        # Stage all changes
        git add -A 2>&1 | Out-Null
        
        # Check if there are changes to commit
        $status = git status --porcelain 2>&1
        if (-not $status) {
            Write-Host "  [COMMIT] No changes to commit for $TaskId" -ForegroundColor DarkGray
            return
        }
        
        # Create commit with conventional commit format
        $commitMsg = "feat($TaskId): $Summary"
        git commit -m $commitMsg 2>&1 | Out-Null
        
        Write-Host "  [COMMIT] $commitMsg" -ForegroundColor Green
    }
    catch {
        Write-Host "  [COMMIT] Failed: $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# CONTEXT RESET PROTOCOL (NEW - from GSD)
# ============================================================================

function Test-ContextReset {
    param($state)
    
    if (-not $FreshContextMode) { return $false }
    
    $tasksThisSession = $state.completedTasks.Count
    
    if ($tasksThisSession -gt 0 -and $tasksThisSession % $MaxTasksPerSession -eq 0) {
        Write-Host ""
        Write-Host "=======================================================================" -ForegroundColor Magenta
        Write-Host "  CONTEXT RESET RECOMMENDED                                           " -ForegroundColor Magenta
        Write-Host "=======================================================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  Completed $tasksThisSession tasks this session."
        Write-Host "  Fresh context improves quality for remaining tasks."
        Write-Host ""
        Write-Host "  State saved to $StateFile"
        Write-Host "  Run RALPH again to continue with fresh context."
        Write-Host ""
        
        if (-not $AutoPilot) {
            Write-Host "  Options:" -ForegroundColor Cyan
            Write-Host "    [R] Restart now (recommended)"
            Write-Host "    [C] Continue anyway"
            Write-Host ""
            
            $choice = Read-Host "  Your choice"
            
            if ($choice.ToUpper() -eq 'C') {
                return $false
            }
        }
        
        return $true
    }
    
    return $false
}

# ============================================================================
# CHANGELOG GENERATION (NEW - from brain dump)
# ============================================================================

function New-Changelog {
    param($state)
    
    if (-not $GenerateChangelog) { return }
    
    $changelogPath = "CHANGELOG-$(Get-Date -Format 'yyyy-MM-dd-HHmm').md"
    
    $duration = if ($state.startedAt) {
        $start = [DateTime]::Parse($state.startedAt)
        $elapsed = (Get-Date) - $start
        "$($elapsed.Hours)h $($elapsed.Minutes)m"
    } else { "Unknown" }
    
    $content = @"
# Build Changelog

**Project:** $($state.projectName)
**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm")
**Duration:** $duration
**Iterations:** $($state.currentIteration)

---

## What Was Built

$($state.completedTasks | ForEach-Object { "- [x] $_" } | Out-String)

## Skipped Tasks

$($state.skippedTasks | ForEach-Object { "- [ ] $_ (skipped)" } | Out-String)

## Failed Attempts

| Task | Iteration | Time |
|------|-----------|------|
$($state.failedTasks | ForEach-Object { "| $($_.taskId) | $($_.iteration) | $($_.timestamp) |" } | Out-String)

## Learnings Captured

$($state.learnings | ForEach-Object { "- $_" } | Out-String)

## Checkpoint History

| Iteration | Reason | Choice | Time |
|-----------|--------|--------|------|
$($state.checkpointHistory | ForEach-Object { "| $($_.iteration) | $($_.reason) | $($_.choice) | $($_.timestamp) |" } | Out-String)

---

*Generated by RALPH-JAWS v4*
"@
    
    $content | Out-File -FilePath $changelogPath -Encoding utf8
    Write-Host "  [CHANGELOG] Generated: $changelogPath" -ForegroundColor Green
}

# ============================================================================
# MODEL SELECTION (NEW - from brain dump)
# ============================================================================

function Get-ClaudeCommand {
    # Map model names to Claude CLI parameters
    # Note: Actual model selection depends on Claude CLI support
    # This is a placeholder for when/if model selection is added
    
    $modelMap = @{
        "opus" = "claude"      # Would be: claude --model opus
        "sonnet" = "claude"    # Default
        "haiku" = "claude"     # Would be: claude --model haiku
    }
    
    return $modelMap[$Model]
}

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
        sessionNumber = 1
        totalTasksAllSessions = 0
    }
    return $newState
}

function Save-State {
    param($state)
    $state | ConvertTo-Json -Depth 10 | Out-File -FilePath $StateFile -Encoding utf8
}

# ============================================================================
# TASK MANAGEMENT (UPDATED - now reads VERIFY/DONE fields)
# ============================================================================

function Get-CurrentTask {
    if (-not (Test-Path $PRDPath)) {
        return $null
    }
    
    $prd = Get-Content $PRDPath -Raw
    
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
        
        # Find this task's section
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
            
            # NEW: Extract VERIFY and DONE fields
            $verifyMatch = [regex]::Match($taskSection, '\*\*VERIFY:\*\*\s*(.+?)(?=\r?\n)')
            $doneMatch = [regex]::Match($taskSection, '\*\*DONE:\*\*\s*(.+?)(?=\r?\n)')
            $filesMatch = [regex]::Match($taskSection, '\*\*FILES:\*\*\s*(.+?)(?=\r?\n)')
            
            return @{
                id = $taskId
                name = $taskName
                hasIncomplete = $true
                criteriaTotal = $total
                criteriaComplete = $complete
                progress = if ($total -gt 0) { [math]::Round(($complete / $total) * 100) } else { 0 }
                verify = if ($verifyMatch.Success) { $verifyMatch.Groups[1].Value.Trim() } else { "" }
                done = if ($doneMatch.Success) { $doneMatch.Groups[1].Value.Trim() } else { "" }
                files = if ($filesMatch.Success) { $filesMatch.Groups[1].Value.Trim() } else { "" }
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

function Test-TaskCompletion {
    param($taskId)
    
    if (-not (Test-Path $PRDPath)) {
        return @{ isComplete = $false; uncheckedCount = 0 }
    }
    
    $prd = Get-Content $PRDPath -Raw
    $escapedId = [regex]::Escape($taskId)
    
    # Find task section
    $sections = $prd -split "###\s+$escapedId"
    if ($sections.Count -lt 2) {
        return @{ isComplete = $false; uncheckedCount = 0 }
    }
    
    $taskSection = $sections[1]
    $nextTaskSplit = $taskSection -split "###\s+US-"
    $taskSection = $nextTaskSplit[0]
    
    $unchecked = [regex]::Matches($taskSection, '\[\s\]')
    
    return @{
        isComplete = ($unchecked.Count -eq 0)
        uncheckedCount = $unchecked.Count
    }
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
# CONTEXT BUILDING (UPDATED - includes VERIFY/DONE)
# ============================================================================

function Get-CompressedContext {
    param($state, $currentTask)
    
    $verifySection = if ($currentTask.verify) { "`nVERIFY BY: $($currentTask.verify)" } else { "" }
    $doneSection = if ($currentTask.done) { "`nDONE WHEN: $($currentTask.done)" } else { "" }
    $filesSection = if ($currentTask.files) { "`nFILES TO CREATE/MODIFY: $($currentTask.files)" } else { "" }
    
    $context = @"
## Quick Context

Current Task: $($currentTask.id) - $($currentTask.name)
Progress: $($currentTask.criteriaComplete)/$($currentTask.criteriaTotal) criteria ($($currentTask.progress)%)
Attempts on this task: $(Get-TaskFailureCount $state $currentTask.id)
$filesSection
$verifySection
$doneSection

Completed this session: $($state.completedTasks -join ', ')
Skipped: $($state.skippedTasks -join ', ')
"@
    
    return $context
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Initialize
$state = Initialize-State

# Initialize worktree if requested
Initialize-Worktree

Write-Host "  Starting build loop..."
Write-Host ""

$humanGuidance = $null
$claudeCmd = Get-ClaudeCommand

# Main Loop
for ($i = ($state.currentIteration + 1); $i -le $MaxIterations; $i++) {
    $state.currentIteration = $i
    Save-State $state
    
    # Check for context reset
    if (Test-ContextReset $state) {
        Save-State $state
        Complete-Worktree -Success $false
        exit 0
    }
    
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
        
        # Generate changelog
        New-Changelog $state
        
        if ($GenerateDocs) {
            Write-Host "Generating documentation..." -ForegroundColor Cyan
            $docsPrompt = "Generate documentation for the completed project. Read PRD.md, progress.txt, and AGENTS.md. Create: docs/README.md (plain English), docs/TECHNICAL.md (technical breakdown), docs/CLIENT-PITCH.md (client presentation), docs/TROUBLESHOOTING.md (common issues), docs/SETUP.md (setup guide)."
            & $claudeCmd --dangerously-skip-permissions -p $docsPrompt 2>&1 | Out-String | Write-Host
        }
        
        # Complete worktree (merge to main)
        Complete-Worktree -Success $true
        
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
                Complete-Worktree -Success $false
                exit 1 
            }
            'skip' {
                Write-Host "Skipping task $($currentTask.id)" -ForegroundColor Yellow
                $prd = Get-Content $PRDPath -Raw
                $prd = $prd -replace "(###\s+$($currentTask.id):)", "[SKIPPED] `$1"
                $prd | Out-File $PRDPath -Encoding utf8
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
            Complete-Worktree -Success $false
            exit 1
        }
        if ($checkpoint.action -eq 'skip') {
            $prd = Get-Content $PRDPath -Raw
            $prd = $prd -replace "(###\s+$($currentTask.id):)", "[SKIPPED] `$1"
            $prd | Out-File $PRDPath -Encoding utf8
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
    if ($currentTask.verify) {
        Write-Host "  Verify: $($currentTask.verify)" -ForegroundColor DarkYellow
    }
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
4. Run the VERIFY check: $($currentTask.verify)
5. Confirm DONE criteria: $($currentTask.done)

## Rules

- ONLY mark complete if VERIFY check passes
- Mark complete in PRD.md - change [ ] to [x] for criteria you verified
- One task only
- Be specific about what files you created/modified

## After Completion

Update progress.txt with what you did and learned.
Update AGENTS.md if you found a reusable pattern.

If ALL tasks in PRD are complete, output: <promise>COMPLETE</promise>
"@

    # Execute Claude
    $startTime = Get-Date
    
    if ($Verbose) {
        Write-Host "  Sending prompt to Claude ($Model)..." -ForegroundColor DarkGray
    }
    
    $result = ""
    try {
        $result = (& $claudeCmd --dangerously-skip-permissions -p $prompt 2>&1 | Out-String)
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
        $state.totalTasksAllSessions++
        
        # Atomic commit for this task
        New-AtomicCommit -TaskId $currentTask.id -Summary $currentTask.name
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
            
            New-Changelog $state
            
            if ($GenerateDocs) {
                Write-Host "Generating documentation..." -ForegroundColor Cyan
                $docsPrompt = "Generate documentation for the completed project. Read PRD.md, progress.txt, and AGENTS.md. Create docs folder with README.md, TECHNICAL.md, CLIENT-PITCH.md, TROUBLESHOOTING.md, SETUP.md."
                & $claudeCmd --dangerously-skip-permissions -p $docsPrompt 2>&1 | Out-String | Write-Host
            }
            
            Complete-Worktree -Success $true
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

New-Changelog $state
Complete-Worktree -Success $false

exit 1
