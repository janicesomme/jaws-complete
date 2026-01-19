# ============================================================================
# JAWS PARALLEL ENHANCEMENT MODULE
# Add this to ralph-jaws-v4.ps1 or import as module
# ============================================================================

# New parameters to add to ralph-jaws-v4.ps1 param block:
# [switch]$UseParallelWorktrees,
# [string[]]$ParallelTasks,
# [switch]$UseGuardian,
# [int]$GuardianAfterTasks = 3,

# ============================================================================
# DEPENDENCY MANAGEMENT
# ============================================================================

function Get-TaskDependencies {
    <#
    .SYNOPSIS
    Extracts dependency markers from a task in the PRD.
    
    .DESCRIPTION
    Parses DEPENDS ON, PARALLEL WITH, and BLOCKS fields from task definition.
    
    .PARAMETER TaskId
    The task ID (e.g., "US-302")
    
    .PARAMETER PRDPath
    Path to the PRD file (default: PRD.md)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        [string]$PRDPath = "PRD.md"
    )
    
    if (-not (Test-Path $PRDPath)) {
        Write-Host "  [WARNING] PRD not found: $PRDPath" -ForegroundColor Yellow
        return @{ dependsOn = @(); parallelWith = @(); blocks = @() }
    }
    
    $prd = Get-Content $PRDPath -Raw
    $escapedId = [regex]::Escape($TaskId)
    
    # Find task section
    $sections = $prd -split "###\s+$escapedId"
    if ($sections.Count -lt 2) {
        Write-Host "  [WARNING] Task $TaskId not found in PRD" -ForegroundColor Yellow
        return @{ dependsOn = @(); parallelWith = @(); blocks = @() }
    }
    
    $taskSection = $sections[1]
    $nextTaskSplit = $taskSection -split "###\s+US-"
    $taskSection = $nextTaskSplit[0]
    
    # Extract dependencies
    $dependsOn = @()
    $parallelWith = @()
    $blocks = @()
    
    if ($taskSection -match '\*\*DEPENDS ON:\*\*\s*(.+?)(?=\r?\n)') {
        $raw = $Matches[1]
        if ($raw -notmatch 'None') {
            $dependsOn = $raw -split ',\s*' | ForEach-Object { 
                if ($_ -match '(US-\d+)') { $Matches[1] }
            } | Where-Object { $_ }
        }
    }
    
    if ($taskSection -match '\*\*PARALLEL WITH:\*\*\s*(.+?)(?=\r?\n)') {
        $raw = $Matches[1]
        if ($raw -notmatch 'None') {
            $parallelWith = $raw -split ',\s*' | ForEach-Object { 
                if ($_ -match '(US-\d+)') { $Matches[1] }
            } | Where-Object { $_ }
        }
    }
    
    if ($taskSection -match '\*\*BLOCKS:\*\*\s*(.+?)(?=\r?\n)') {
        $raw = $Matches[1]
        if ($raw -notmatch 'None') {
            $blocks = $raw -split ',\s*' | ForEach-Object { 
                if ($_ -match '(US-\d+)') { $Matches[1] }
            } | Where-Object { $_ }
        }
    }
    
    return @{
        taskId = $TaskId
        dependsOn = $dependsOn
        parallelWith = $parallelWith
        blocks = $blocks
    }
}

function Test-TaskReady {
    <#
    .SYNOPSIS
    Checks if a task is ready to start based on its dependencies.
    
    .PARAMETER TaskId
    The task ID to check
    
    .PARAMETER CompletedTasks
    Array of completed task IDs
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        [string[]]$CompletedTasks = @()
    )
    
    $deps = Get-TaskDependencies -TaskId $TaskId
    
    $missingDeps = @()
    foreach ($dep in $deps.dependsOn) {
        if ($dep -notin $CompletedTasks) {
            $missingDeps += $dep
        }
    }
    
    if ($missingDeps.Count -gt 0) {
        return @{
            ready = $false
            taskId = $TaskId
            blockedBy = $missingDeps
            reason = "Waiting for: $($missingDeps -join ', ')"
        }
    }
    
    return @{
        ready = $true
        taskId = $TaskId
        parallelWith = $deps.parallelWith
    }
}

function Get-ParallelReadyTasks {
    <#
    .SYNOPSIS
    Returns all tasks that can run in parallel right now.
    
    .PARAMETER CompletedTasks
    Array of completed task IDs
    
    .PARAMETER PRDPath
    Path to the PRD file
    #>
    param(
        [string[]]$CompletedTasks = @(),
        [string]$PRDPath = "PRD.md"
    )
    
    if (-not (Test-Path $PRDPath)) {
        return @()
    }
    
    $prd = Get-Content $PRDPath -Raw
    
    # Find all task IDs
    $taskPattern = '###\s+(US-\d+):'
    $taskMatches = [regex]::Matches($prd, $taskPattern)
    
    $parallelReady = @()
    
    foreach ($match in $taskMatches) {
        $taskId = $match.Groups[1].Value
        
        # Skip completed tasks
        if ($taskId -in $CompletedTasks) { continue }
        
        # Skip skipped tasks
        if ($prd -match "\[SKIPPED\]\s*###\s+$taskId") { continue }
        
        $readiness = Test-TaskReady -TaskId $taskId -CompletedTasks $CompletedTasks
        
        if ($readiness.ready -and $readiness.parallelWith.Count -gt 0) {
            $parallelReady += @{
                taskId = $taskId
                parallelWith = $readiness.parallelWith
            }
        }
    }
    
    return $parallelReady
}

# ============================================================================
# PARALLEL WORKTREE MANAGEMENT
# ============================================================================

function Initialize-ParallelWorktrees {
    <#
    .SYNOPSIS
    Creates isolated git worktrees for parallel task execution.
    
    .PARAMETER TaskIds
    Array of task IDs to create worktrees for
    
    .PARAMETER BasePath
    Base directory for worktrees (default: ../.worktrees)
    
    .PARAMETER CompletedTasks
    Array of already completed tasks (for dependency check)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$TaskIds,
        [string]$BasePath = "../.worktrees",
        [string[]]$CompletedTasks = @()
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  INITIALIZING PARALLEL WORKTREES                                     " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Verify all tasks are ready
    $allReady = $true
    $taskDetails = @()
    
    foreach ($taskId in $TaskIds) {
        $readiness = Test-TaskReady -TaskId $taskId -CompletedTasks $CompletedTasks
        
        if (-not $readiness.ready) {
            Write-Host "  [BLOCKED] $taskId - $($readiness.reason)" -ForegroundColor Red
            $allReady = $false
        } else {
            Write-Host "  [READY] $taskId (parallel with: $($readiness.parallelWith -join ', '))" -ForegroundColor Green
            $taskDetails += $readiness
        }
    }
    
    if (-not $allReady) {
        Write-Host ""
        Write-Host "  Cannot create parallel worktrees. Resolve blockers first." -ForegroundColor Yellow
        return $null
    }
    
    # Create worktrees
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $createdWorktrees = @()
    
    # Ensure base path exists
    if (-not (Test-Path $BasePath)) {
        New-Item -ItemType Directory -Path $BasePath -Force | Out-Null
    }
    
    foreach ($taskId in $TaskIds) {
        $branchName = "jaws-$taskId-$timestamp"
        $worktreeDir = Join-Path $BasePath $taskId
        
        Write-Host ""
        Write-Host "  Creating worktree for $taskId..." -ForegroundColor Cyan
        
        try {
            # Remove existing worktree if present
            if (Test-Path $worktreeDir) {
                git worktree remove $worktreeDir --force 2>&1 | Out-Null
            }
            
            # Create new worktree
            git worktree add $worktreeDir -b $branchName 2>&1 | Out-Null
            
            # Copy context files
            @("PRD.md", "AGENTS.md", "DECISIONS.md", "progress.txt", "ai_docs") | ForEach-Object {
                if (Test-Path $_) {
                    if (Test-Path $_ -PathType Container) {
                        Copy-Item $_ -Destination $worktreeDir -Recurse -Force
                    } else {
                        Copy-Item $_ -Destination $worktreeDir -Force
                    }
                }
            }
            
            $createdWorktrees += @{
                taskId = $taskId
                branch = $branchName
                path = $worktreeDir
            }
            
            Write-Host "  [OK] $worktreeDir" -ForegroundColor Green
            Write-Host "       Branch: $branchName" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "  [ERROR] Failed to create worktree: $_" -ForegroundColor Red
        }
    }
    
    # Generate session prompts
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Yellow
    Write-Host "  PARALLEL SESSION PROMPTS                                            " -ForegroundColor Yellow
    Write-Host "=======================================================================" -ForegroundColor Yellow
    
    foreach ($wt in $createdWorktrees) {
        $prompt = Get-ParallelSessionPrompt -TaskId $wt.taskId -ParallelTasks $TaskIds
        
        Write-Host ""
        Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
        Write-Host "  TERMINAL FOR $($wt.taskId)" -ForegroundColor Cyan
        Write-Host "  ═══════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host "  cd $($wt.path)" -ForegroundColor White
        Write-Host "  claude" -ForegroundColor White
        Write-Host ""
        Write-Host "  Then paste:" -ForegroundColor DarkGray
        Write-Host "  ───────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host $prompt -ForegroundColor Gray
        Write-Host "  ───────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    }
    
    return $createdWorktrees
}

function Get-ParallelSessionPrompt {
    <#
    .SYNOPSIS
    Generates a prompt for a parallel session.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        [string[]]$ParallelTasks = @(),
        [string]$PRDPath = "PRD.md"
    )
    
    $otherTasks = ($ParallelTasks | Where-Object { $_ -ne $TaskId }) -join ', '
    
    # Get task details
    $deps = Get-TaskDependencies -TaskId $TaskId -PRDPath $PRDPath
    
    $prompt = @"
You are working on task $TaskId in a PARALLEL worktree.

## Critical Rules
- Other sessions are simultaneously building: $otherTasks
- DO NOT modify files outside your task scope
- DO NOT change database schema, auth system, or shared config
- Focus ONLY on your assigned task

## Your Assignment
Read PRD.md and find task $TaskId.
Implement it according to its acceptance criteria.

## When Done
1. Mark all acceptance criteria [x] in PRD.md
2. Run the VERIFY check specified in the task
3. Update progress.txt with what you built
4. Commit with: git commit -m "feat($TaskId): [description]"

Start by reading PRD.md to understand your task.
"@
    
    return $prompt
}

function Merge-ParallelWorktrees {
    <#
    .SYNOPSIS
    Merges completed parallel worktrees back to main.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [array]$Worktrees,
        [switch]$Cleanup
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  MERGING PARALLEL WORKTREES                                          " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $originalPath = Get-Location
    $mergeResults = @()
    
    foreach ($wt in $Worktrees) {
        Write-Host "  Merging $($wt.taskId) from $($wt.branch)..." -ForegroundColor Cyan
        
        try {
            git merge $wt.branch --no-ff -m "feat($($wt.taskId)): Merge parallel worktree" 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [OK] $($wt.taskId) merged successfully" -ForegroundColor Green
                $mergeResults += @{ taskId = $wt.taskId; status = "merged" }
            } else {
                Write-Host "  [CONFLICT] $($wt.taskId) has merge conflicts" -ForegroundColor Yellow
                Write-Host "             Resolve manually, then continue" -ForegroundColor Yellow
                $mergeResults += @{ taskId = $wt.taskId; status = "conflict" }
            }
        }
        catch {
            Write-Host "  [ERROR] Failed to merge $($wt.taskId): $_" -ForegroundColor Red
            $mergeResults += @{ taskId = $wt.taskId; status = "error"; error = $_.ToString() }
        }
    }
    
    # Cleanup if requested and all merges succeeded
    if ($Cleanup) {
        $allMerged = ($mergeResults | Where-Object { $_.status -eq "merged" }).Count -eq $Worktrees.Count
        
        if ($allMerged) {
            Write-Host ""
            Write-Host "  Cleaning up worktrees..." -ForegroundColor Cyan
            
            foreach ($wt in $Worktrees) {
                try {
                    git worktree remove $wt.path --force 2>&1 | Out-Null
                    git branch -d $wt.branch 2>&1 | Out-Null
                    Write-Host "  [OK] Removed $($wt.taskId) worktree" -ForegroundColor Green
                }
                catch {
                    Write-Host "  [WARNING] Could not clean $($wt.taskId): $_" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host ""
            Write-Host "  Skipping cleanup - not all worktrees merged cleanly" -ForegroundColor Yellow
        }
    }
    
    Set-Location $originalPath
    return $mergeResults
}

# ============================================================================
# PLAN GUARDIAN
# ============================================================================

function Request-GuardianVerification {
    <#
    .SYNOPSIS
    Prompts for Plan Guardian verification after a phase or milestone.
    #>
    param(
        [string]$PhaseCompleted = "Phase",
        [string[]]$TasksCompleted = @(),
        [switch]$AutoPilot
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "  PLAN GUARDIAN CHECKPOINT                                            " -ForegroundColor Magenta
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Completed: $PhaseCompleted"
    Write-Host "  Tasks: $($TasksCompleted -join ', ')"
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Open a FRESH Claude Code terminal and paste:" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    $guardianPrompt = @"
Read PRD.md. $PhaseCompleted just completed.
Tasks: $($TasksCompleted -join ', ')

Verify against the PRD:
1. Are ALL acceptance criteria actually complete?
2. Do the VERIFY checks pass when you run them?
3. Are there any gaps or half-finished work?
4. Is anything missing that the next phase will need?

Be thorough. Check actual code/workflows, not just checkboxes.
"@
    
    Write-Host $guardianPrompt -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    if (-not $AutoPilot) {
        Write-Host "  After running the Guardian check:" -ForegroundColor White
        Write-Host "    [C] Continue - Guardian confirmed all good"
        Write-Host "    [I] Issues found - Stop and review"
        Write-Host "    [S] Skip - Continue without guardian check"
        Write-Host ""
        
        $choice = Read-Host "  Your choice"
        
        switch ($choice.ToUpper()) {
            'C' { return @{ verified = $true; action = 'continue' } }
            'I' { return @{ verified = $false; action = 'review' } }
            'S' { return @{ verified = $true; action = 'skip'; skipped = $true } }
            default { return @{ verified = $true; action = 'continue' } }
        }
    }
    
    return @{ verified = $true; action = 'auto'; skipped = $true }
}

# ============================================================================
# DECISIONS LOG MANAGEMENT
# ============================================================================

function Add-Decision {
    <#
    .SYNOPSIS
    Adds a decision entry to DECISIONS.md
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$true)]
        [string]$Decision,
        [string[]]$Alternatives = @(),
        [string]$Reasoning = "",
        [string]$Impact = "",
        [string]$DecisionsPath = "DECISIONS.md"
    )
    
    $date = Get-Date -Format "yyyy-MM-dd"
    
    $entry = @"

### $date - $TaskId`: $Title

**Decision:** $Decision

"@
    
    if ($Alternatives.Count -gt 0) {
        $entry += "**Alternatives Considered:**`n"
        foreach ($alt in $Alternatives) {
            $entry += "- $alt`n"
        }
        $entry += "`n"
    }
    
    if ($Reasoning) {
        $entry += "**Reasoning:** $Reasoning`n`n"
    }
    
    if ($Impact) {
        $entry += "**Impact:** $Impact`n`n"
    }
    
    $entry += "---`n"
    
    # Append to file
    if (Test-Path $DecisionsPath) {
        Add-Content -Path $DecisionsPath -Value $entry
    } else {
        # Create file with header
        $header = @"
# Decisions Log

**Project:** [Project Name]
**Started:** $date

---

## Decisions
$entry
"@
        $header | Out-File -FilePath $DecisionsPath -Encoding utf8
    }
    
    Write-Host "  [OK] Decision logged: $Title" -ForegroundColor Green
}

function Get-DecisionsContext {
    <#
    .SYNOPSIS
    Extracts decisions for context injection into prompts.
    #>
    param(
        [string]$DecisionsPath = "DECISIONS.md",
        [int]$MaxDecisions = 5
    )
    
    if (-not (Test-Path $DecisionsPath)) {
        return ""
    }
    
    $content = Get-Content $DecisionsPath -Raw
    
    # Extract just the decisions section
    if ($content -match '## Decisions(.+)$') {
        $decisions = $Matches[1].Trim()
        
        # Get last N decisions
        $decisionBlocks = $decisions -split '###\s+\d{4}-\d{2}-\d{2}'
        $recent = $decisionBlocks | Select-Object -Last $MaxDecisions
        
        if ($recent) {
            return "`n## Recent Decisions`n$($recent -join "`n")"
        }
    }
    
    return ""
}

# ============================================================================
# INTEGRATION HELPERS
# ============================================================================

function Show-DependencyMap {
    <#
    .SYNOPSIS
    Displays a visual dependency map of all tasks.
    #>
    param(
        [string]$PRDPath = "PRD.md",
        [string[]]$CompletedTasks = @()
    )
    
    if (-not (Test-Path $PRDPath)) {
        Write-Host "  PRD not found: $PRDPath" -ForegroundColor Yellow
        return
    }
    
    $prd = Get-Content $PRDPath -Raw
    
    # Find all tasks
    $taskPattern = '###\s+(US-\d+):\s+(.+?)(?=\r?\n)'
    $taskMatches = [regex]::Matches($prd, $taskPattern)
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  DEPENDENCY MAP                                                      " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($match in $taskMatches) {
        $taskId = $match.Groups[1].Value
        $taskName = $match.Groups[2].Value.Trim()
        
        $deps = Get-TaskDependencies -TaskId $taskId -PRDPath $PRDPath
        $readiness = Test-TaskReady -TaskId $taskId -CompletedTasks $CompletedTasks
        
        # Determine status
        $status = if ($taskId -in $CompletedTasks) {
            "[DONE]"
            $color = "Green"
        } elseif ($prd -match "\[SKIPPED\]\s*###\s+$taskId") {
            "[SKIP]"
            $color = "DarkGray"
        } elseif ($readiness.ready) {
            "[READY]"
            $color = "Yellow"
        } else {
            "[WAIT]"
            $color = "Red"
        }
        
        Write-Host "  $status $taskId: $taskName" -ForegroundColor $color
        
        if ($deps.dependsOn.Count -gt 0) {
            Write-Host "         └─ Depends on: $($deps.dependsOn -join ', ')" -ForegroundColor DarkGray
        }
        if ($deps.parallelWith.Count -gt 0) {
            Write-Host "         └─ Parallel with: $($deps.parallelWith -join ', ')" -ForegroundColor DarkGray
        }
    }
    
    Write-Host ""
}

# ============================================================================
# MODULE EXPORT
# ============================================================================

Write-Host ""
Write-Host "JAWS Parallel Enhancement Module loaded." -ForegroundColor Green
Write-Host ""
Write-Host "Commands available:" -ForegroundColor Cyan
Write-Host "  Get-TaskDependencies      - Parse task dependencies from PRD"
Write-Host "  Test-TaskReady            - Check if task can start"
Write-Host "  Get-ParallelReadyTasks    - Find tasks ready for parallel work"
Write-Host "  Initialize-ParallelWorktrees - Set up parallel worktrees"
Write-Host "  Merge-ParallelWorktrees   - Merge completed worktrees"
Write-Host "  Request-GuardianVerification - Plan Guardian checkpoint"
Write-Host "  Add-Decision              - Log an architectural decision"
Write-Host "  Show-DependencyMap        - Visual task dependency map"
Write-Host ""
