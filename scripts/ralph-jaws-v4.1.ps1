param(
    [int]$MaxIterations = 10,
    [int]$SleepSeconds = 2,
    [switch]$GenerateDocs,
    [switch]$Verbose,
    [switch]$AutoPilot,
    [int]$CheckpointEvery = 3,
    [int]$MaxConsecutiveFailures = 3,
    [string]$StateFile = "ralph-state.json",
    
    # === v4 FEATURES (GSD-inspired) ===
    [switch]$UseWorktree,
    [string]$WorktreePath = "../.worktrees",
    [int]$MaxTasksPerSession = 5,
    [switch]$FreshContextMode,
    [ValidateSet("opus", "sonnet", "haiku")]
    [string]$Model = "sonnet",
    [switch]$AtomicCommits,
    [switch]$GenerateChangelog,
    [string]$PRDPath = "PRD.md",
    
    # === v4.1 FEATURES (Auto-Claude v2.7.4) ===
    [int]$MaxClaudeRetries = 3,
    [switch]$UseExponentialBackoff,
    [switch]$SkipMergeChecks,
    [string]$PreferredClaudeVersion = $null
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# BANNER
# ============================================================================

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  RALPH-JAWS v4.1 - Ultimate Agent Harness                            " -ForegroundColor Cyan
Write-Host "  Now with: Retry Logic | Merge Checks | Version Management           " -ForegroundColor Cyan
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
Write-Host "  v4.1 Features (Auto-Claude v2.7.4):" -ForegroundColor Green
Write-Host "  - Claude Retry Logic:    $MaxClaudeRetries retries"
Write-Host "  - Exponential Backoff:   $UseExponentialBackoff"
Write-Host "  - Merge Readiness Checks: $(if ($SkipMergeChecks) { 'Disabled' } else { 'Enabled' })"
Write-Host ""

# ============================================================================
# v4.1: CLAUDE RETRY LOGIC (from Auto-Claude v2.7.4)
# ============================================================================

$script:RetryConfig = @{
    DefaultRetryDelaySeconds = 5
    MaxRetryDelaySeconds = 60
    ExponentialBackoffMultiplier = 2
}

function Invoke-ClaudeWithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        [string]$ClaudeCommand = "claude",
        [int]$MaxRetries = $MaxClaudeRetries,
        [int]$RetryDelaySeconds = 5
    )
    
    $currentDelay = $RetryDelaySeconds
    $lastError = $null
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        $startTime = Get-Date
        
        try {
            $result = (& $ClaudeCommand --dangerously-skip-permissions -p $Prompt 2>&1 | Out-String)
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0 -and $result -and $result.Trim().Length -gt 0) {
                if ($attempt -gt 1) {
                    Write-Host "  [RETRY] Succeeded on attempt $attempt" -ForegroundColor Green
                }
                return @{
                    Success = $true
                    Result = $result
                    Attempts = $attempt
                    Duration = ((Get-Date) - $startTime).TotalSeconds
                }
            }
            
            $lastError = "Exit code: $exitCode"
            Write-Host "  [RETRY] Attempt $attempt/$MaxRetries failed ($lastError)" -ForegroundColor Yellow
        }
        catch {
            $lastError = $_.Exception.Message
            Write-Host "  [RETRY] Attempt $attempt/$MaxRetries exception: $lastError" -ForegroundColor Red
        }
        
        if ($attempt -lt $MaxRetries) {
            Write-Host "  [RETRY] Waiting ${currentDelay}s..." -ForegroundColor DarkGray
            Start-Sleep -Seconds $currentDelay
            
            if ($UseExponentialBackoff) {
                $currentDelay = [Math]::Min(
                    $currentDelay * $script:RetryConfig.ExponentialBackoffMultiplier,
                    $script:RetryConfig.MaxRetryDelaySeconds
                )
            }
        }
    }
    
    return @{
        Success = $false
        Result = $null
        Attempts = $MaxRetries
        Error = $lastError
    }
}

function Test-ClaudeAvailability {
    param([string]$ClaudeCommand = "claude")
    
    try {
        $version = & $ClaudeCommand --version 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0 -and $version) {
            return @{
                Available = $true
                Version = $version.Trim()
            }
        }
    }
    catch { }
    
    return @{
        Available = $false
        Version = $null
    }
}

# ============================================================================
# v4.1: MERGE READINESS CHECKS (from Auto-Claude v2.7.4)
# ============================================================================

function Test-MergeReadiness {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BranchName,
        [string]$TargetBranch = "main"
    )
    
    if ($SkipMergeChecks) {
        return @{ CanMerge = $true; Skipped = $true }
    }
    
    $result = @{
        CanMerge = $true
        Errors = @()
        Warnings = @()
    }
    
    Write-Host "  [MERGE CHECK] Validating branch state..." -ForegroundColor Cyan
    
    # Check 1: Uncommitted changes
    $status = git status --porcelain 2>&1
    $uncommitted = @($status | Where-Object { $_ -match "^[MADRCU]" })
    
    if ($uncommitted.Count -gt 0) {
        $result.Errors += "Found $($uncommitted.Count) uncommitted changes"
        $result.CanMerge = $false
        Write-Host "  [MERGE CHECK] ❌ Uncommitted changes: $($uncommitted.Count)" -ForegroundColor Red
    }
    else {
        Write-Host "  [MERGE CHECK] ✓ Working tree clean" -ForegroundColor Green
    }
    
    # Check 2: Branch exists
    $branchExists = git rev-parse --verify $BranchName 2>&1
    if ($LASTEXITCODE -ne 0) {
        $result.Errors += "Branch '$BranchName' not found"
        $result.CanMerge = $false
        Write-Host "  [MERGE CHECK] ❌ Branch not found: $BranchName" -ForegroundColor Red
    }
    else {
        Write-Host "  [MERGE CHECK] ✓ Branch exists: $BranchName" -ForegroundColor Green
    }
    
    # Check 3: Commits ahead/behind
    try {
        $aheadBehind = git rev-list --left-right --count "$TargetBranch...$BranchName" 2>&1
        if ($LASTEXITCODE -eq 0 -and $aheadBehind -match "(\d+)\s+(\d+)") {
            $behind = [int]$Matches[1]
            $ahead = [int]$Matches[2]
            
            Write-Host "  [MERGE CHECK] ✓ $ahead commits ahead, $behind behind $TargetBranch" -ForegroundColor Green
            
            if ($ahead -eq 0) {
                $result.Warnings += "No new commits to merge"
                Write-Host "  [MERGE CHECK] ⚠ No new commits" -ForegroundColor Yellow
            }
        }
    }
    catch { }
    
    # Check 4: Merge conflicts
    try {
        $mergeBase = git merge-base $TargetBranch $BranchName 2>&1
        if ($LASTEXITCODE -eq 0) {
            $mergeTest = git merge-tree $mergeBase $TargetBranch $BranchName 2>&1
            if ($mergeTest -match "CONFLICT") {
                $result.Errors += "Merge conflicts detected"
                $result.CanMerge = $false
                Write-Host "  [MERGE CHECK] ❌ Merge conflicts detected!" -ForegroundColor Red
            }
            else {
                Write-Host "  [MERGE CHECK] ✓ No merge conflicts" -ForegroundColor Green
            }
        }
    }
    catch { }
    
    # Summary
    Write-Host ""
    if ($result.CanMerge) {
        Write-Host "  [MERGE CHECK] ✓ READY TO MERGE" -ForegroundColor Green
    }
    else {
        Write-Host "  [MERGE CHECK] ❌ NOT READY" -ForegroundColor Red
        $result.Errors | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkRed }
    }
    Write-Host ""
    
    return $result
}

# ============================================================================
# v4.1: CLAUDE VERSION MANAGEMENT (from Auto-Claude v2.7.4)
# ============================================================================

function Get-ClaudeVersions {
    $versions = @()
    
    # Check standard locations
    $locations = @("claude", "$env:APPDATA\npm\claude.cmd", "$env:LOCALAPPDATA\npm\claude.cmd")
    
    foreach ($loc in $locations) {
        try {
            if ($loc -match "\.cmd$" -and -not (Test-Path $loc)) { continue }
            
            $ver = & $loc --version 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -and $ver) {
                $existing = $versions | Where-Object { $_.Version -eq $ver.Trim() }
                if (-not $existing) {
                    $versions += @{
                        Path = $loc
                        Version = $ver.Trim()
                    }
                }
            }
        }
        catch { }
    }
    
    return $versions
}

function Get-BestClaudeCommand {
    # Check for preferred version
    if ($PreferredClaudeVersion) {
        $versions = Get-ClaudeVersions
        $match = $versions | Where-Object { $_.Version -like "*$PreferredClaudeVersion*" }
        if ($match) {
            Write-Host "  Using preferred Claude version: $($match[0].Version)" -ForegroundColor Green
            return $match[0].Path
        }
    }
    
    # Default
    return "claude"
}

# ============================================================================
# GIT WORKTREE MANAGEMENT (UPDATED with merge checks)
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
    
    if (-not (Test-Path $WorktreePath)) {
        New-Item -ItemType Directory -Path $WorktreePath -Force | Out-Null
    }
    
    try {
        git worktree add $worktreeDir -b $WorktreeBranch 2>&1 | Out-Null
        
        if (Test-Path $PRDPath) {
            Copy-Item $PRDPath -Destination $worktreeDir -Force
        }
        
        @("AGENTS.md", "progress.txt", "ai_docs") | ForEach-Object {
            if (Test-Path $_) {
                Copy-Item $_ -Destination $worktreeDir -Recurse -Force
            }
        }
        
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
        Write-Host "  Build successful. Validating merge..." -ForegroundColor Cyan
        
        # v4.1: Run merge readiness checks
        $readiness = Test-MergeReadiness -BranchName $WorktreeBranch
        
        if (-not $readiness.CanMerge) {
            Write-Host "  [WARNING] Merge blocked by readiness checks" -ForegroundColor Yellow
            Write-Host "  Branch $WorktreeBranch preserved for manual review." -ForegroundColor Yellow
            Write-Host "  Path: $worktreeDir" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  To fix and merge manually:" -ForegroundColor Cyan
            Write-Host "    cd $worktreeDir" -ForegroundColor DarkCyan
            Write-Host "    # fix any issues" -ForegroundColor DarkCyan
            Write-Host "    git add -A && git commit -m 'fix: resolve issues'" -ForegroundColor DarkCyan
            Write-Host "    cd $OriginalPath" -ForegroundColor DarkCyan
            Write-Host "    git merge $WorktreeBranch --no-ff" -ForegroundColor DarkCyan
            return
        }
        
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
# ATOMIC COMMITS
# ============================================================================

function New-AtomicCommit {
    param(
        [string]$TaskId,
        [string]$Summary
    )
    
    if (-not $AtomicCommits) { return }
    
    try {
        git add -A 2>&1 | Out-Null
        
        $status = git status --porcelain 2>&1
        if (-not $status) {
            Write-Host "  [COMMIT] No changes to commit for $TaskId" -ForegroundColor DarkGray
            return
        }
        
        $commitMsg = "feat($TaskId): $Summary"
        git commit -m $commitMsg 2>&1 | Out-Null
        
        Write-Host "  [COMMIT] $commitMsg" -ForegroundColor Green
    }
    catch {
        Write-Host "  [COMMIT] Failed: $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# CONTEXT RESET PROTOCOL
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
# CHANGELOG GENERATION
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
**RALPH Version:** 4.1 (Auto-Claude v2.7.4 enhancements)

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

*Generated by RALPH-JAWS v4.1*
"@
    
    $content | Out-File -FilePath $changelogPath -Encoding utf8
    Write-Host "  [CHANGELOG] Generated: $changelogPath" -ForegroundColor Green
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
        claudeRetryCount = 0
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
    if (-not (Test-Path $PRDPath)) {
        return $null
    }
    
    $prd = Get-Content $PRDPath -Raw
    
    $pattern = '###\s+(US-\d+):\s+(.+?)(?=\r?\n)'
    $taskMatches = [regex]::Matches($prd, $pattern)
    
    foreach ($match in $taskMatches) {
        $taskId = $match.Groups[1].Value
        $taskName = $match.Groups[2].Value.Trim()
        
        if ($prd -match "\[SKIPPED\]\s*###\s+$taskId") {
            continue
        }
        
        $escapedTaskId = [regex]::Escape($taskId)
        $sections = $prd -split "###\s+$escapedTaskId"
        if ($sections.Count -lt 2) { continue }
        
        $taskSection = $sections[1]
        $nextTaskSplit = $taskSection -split "###\s+US-"
        $taskSection = $nextTaskSplit[0]
        
        if ($taskSection -match '\[\s\]') {
            $uncheckedMatches = [regex]::Matches($taskSection, '\[\s\]')
            $checkedMatches = [regex]::Matches($taskSection, '\[x\]')
            $total = $uncheckedMatches.Count + $checkedMatches.Count
            $complete = $checkedMatches.Count
            
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
# CONTEXT BUILDING
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

# v4.1: Pre-flight Claude availability check
Write-Host "  Checking Claude CLI..." -ForegroundColor DarkGray
$claudeHealth = Test-ClaudeAvailability
if (-not $claudeHealth.Available) {
    Write-Host "  [ERROR] Claude CLI not available!" -ForegroundColor Red
    Write-Host "  Install with: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Claude CLI: $($claudeHealth.Version)" -ForegroundColor Green
Write-Host ""

# Initialize
$state = Initialize-State

# Initialize worktree if requested
Initialize-Worktree

Write-Host "  Starting build loop..."
Write-Host ""

$humanGuidance = $null
$claudeCmd = Get-BestClaudeCommand

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
        
        New-Changelog $state
        
        if ($GenerateDocs) {
            Write-Host "Generating documentation..." -ForegroundColor Cyan
            $docsPrompt = "Generate documentation for the completed project. Read PRD.md, progress.txt, and AGENTS.md. Create: docs/README.md (plain English), docs/TECHNICAL.md (technical breakdown), docs/CLIENT-PITCH.md (client presentation), docs/TROUBLESHOOTING.md (common issues), docs/SETUP.md (setup guide)."
            & $claudeCmd --dangerously-skip-permissions -p $docsPrompt 2>&1 | Out-String | Write-Host
        }
        
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

    # v4.1: Execute Claude WITH RETRY LOGIC
    $startTime = Get-Date
    
    if ($Verbose) {
        Write-Host "  Sending prompt to Claude ($Model) with retry..." -ForegroundColor DarkGray
    }
    
    $claudeResult = Invoke-ClaudeWithRetry -Prompt $prompt -ClaudeCommand $claudeCmd
    
    if (-not $claudeResult.Success) {
        Write-Host "  [FATAL] Claude failed after $($claudeResult.Attempts) attempts" -ForegroundColor Red
        Write-Host "  Error: $($claudeResult.Error)" -ForegroundColor Red
        $state.consecutiveFailures++
        $state.lastError = "Claude CLI failed: $($claudeResult.Error)"
        $state.claudeRetryCount += $claudeResult.Attempts
        Save-State $state
        
        # Trigger checkpoint on Claude failures
        if ($state.consecutiveFailures -ge 2) {
            $checkpoint = Request-Checkpoint $state $i "Claude CLI repeated failures"
            if ($checkpoint.action -eq 'abort') {
                Complete-Worktree -Success $false
                exit 1
            }
        }
        continue
    }
    
    $result = $claudeResult.Result
    $duration = (Get-Date) - $startTime
    
    Write-Host $result
    Write-Host ""
    Write-Host "  Duration: $($duration.ToString('mm\:ss')) (attempts: $($claudeResult.Attempts))" -ForegroundColor DarkGray
    
    # Verify completion
    $verification = Test-TaskCompletion $currentTask.id
    
    if ($verification.isComplete) {
        Write-Host "  [OK] Task $($currentTask.id) verified complete" -ForegroundColor Green
        $state.completedTasks += $currentTask.id
        $state.consecutiveFailures = 0
        $state.lastError = ""
        $state.totalTasksAllSessions++
        
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
Write-Host "  Claude retries used: $($state.claudeRetryCount)"
Write-Host ""
Write-Host "  State saved to $StateFile - run again to resume."

New-Changelog $state
Complete-Worktree -Success $false

exit 1
