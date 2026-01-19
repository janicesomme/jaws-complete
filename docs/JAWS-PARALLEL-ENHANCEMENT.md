# JAWS Parallel Enhancement

**Version:** 1.0  
**Date:** 2025-01-19  
**Purpose:** Integrate Plan Guardian pattern and dependency awareness into JAWS

---

## Overview

This enhancement adds three capabilities to JAWS inspired by the "Parallel Terminals Playbook":

1. **Plan Guardian** - A verification session with virgin context
2. **Dependency Markers** - Explicit task dependencies in PRD
3. **Decisions Log** - Tracking deviations from the plan

These additions improve JAWS for:
- Multi-worktree parallel builds
- Complex sequential builds
- Quality verification without context pollution

---

## Enhancement 1: Plan Guardian

### What It Is

A **Plan Guardian** is a Claude Code session that:
- Has never touched implementation code
- Only reads the PRD and codebase
- Verifies work completed by other sessions
- Catches gaps that implementation sessions miss

### Why It Works

Implementation sessions get "polluted" by:
- Auto-compacting losing nuance
- Focus on specific tasks losing big picture
- Context window filling with code details

The Plan Guardian has:
- 100% fresh context
- Full understanding of the plan
- No implementation bias

### How to Use

**After each phase completes, open a FRESH terminal:**

```
Read PRD.md. Phase [N]: [Phase Name] just completed in another session.

Check the codebase against the PRD and tell me:
1. Are all Phase [N] tasks actually complete?
2. Are there any gaps, missing pieces, or half-done work?
3. Is anything missing that Phase [N+1] will need?
4. Do any acceptance criteria remain unchecked that should be checked?

Be thorough. This is a quality gate before we proceed.
```

**For JAWS specifically (n8n workflows):**

```
Read PRD.md. We just completed [US-XXX] through [US-XXX].

Verify against the PRD:
1. Do all workflows exist that should exist?
2. Are all webhook endpoints responding?
3. Do the VERIFY checks in each task actually pass?
4. Are there any acceptance criteria marked complete that aren't actually working?

Run any verification commands needed to confirm.
```

---

## Enhancement 2: Dependency Markers

### New PRD Fields

Add these fields to each task in PRD.md:

```markdown
### US-302: Build User Dashboard

**DEPENDS ON:** US-301 (auth system must be complete)
**PARALLEL WITH:** US-303, US-304 (can run simultaneously with these)
**BLOCKS:** US-305, US-306 (these cannot start until this completes)

**FILES:** src/dashboard.js, src/components/Dashboard.jsx
**VERIFY:** `npm run test:dashboard` passes
**DONE:** Dashboard renders with user data from authenticated session

**Acceptance Criteria:**
- [ ] Shows logged-in user's name
- [ ] Displays list of user's projects
- [ ] Logout button works
```

### Dependency Types

| Marker | Meaning | Example |
|--------|---------|---------|
| **DEPENDS ON** | Must wait for these to complete | Auth before Dashboard |
| **PARALLEL WITH** | Can run simultaneously | Dashboard, Admin Panel, Settings |
| **BLOCKS** | These tasks wait for this one | Analytics waits for all features |

### Visual Dependency Map

Include this in your PRD for complex projects:

```
## Dependency Map

US-301 (Auth)
    │
    ├──► US-302 (Dashboard) ──┐
    │                         │
    ├──► US-303 (Admin) ──────┼──► US-306 (Analytics)
    │                         │
    └──► US-304 (Settings) ───┘
         │
         └──► US-305 (Notifications)
```

### RALPH Integration

Add this function to `ralph-jaws-v4.ps1`:

```powershell
function Get-TaskDependencies {
    param([string]$TaskId)
    
    if (-not (Test-Path $PRDPath)) {
        return @{ dependsOn = @(); parallelWith = @(); blocks = @() }
    }
    
    $prd = Get-Content $PRDPath -Raw
    $escapedId = [regex]::Escape($TaskId)
    
    # Find task section
    $sections = $prd -split "###\s+$escapedId"
    if ($sections.Count -lt 2) {
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
        $dependsOn = $Matches[1] -split ',\s*' | ForEach-Object { ($_ -split '\s+')[0].Trim() }
    }
    
    if ($taskSection -match '\*\*PARALLEL WITH:\*\*\s*(.+?)(?=\r?\n)') {
        $parallelWith = $Matches[1] -split ',\s*' | ForEach-Object { ($_ -split '\s+')[0].Trim() }
    }
    
    if ($taskSection -match '\*\*BLOCKS:\*\*\s*(.+?)(?=\r?\n)') {
        $blocks = $Matches[1] -split ',\s*' | ForEach-Object { ($_ -split '\s+')[0].Trim() }
    }
    
    return @{
        dependsOn = $dependsOn
        parallelWith = $parallelWith
        blocks = $blocks
    }
}

function Test-TaskReady {
    param(
        [string]$TaskId,
        [hashtable]$State
    )
    
    $deps = Get-TaskDependencies $TaskId
    
    foreach ($dep in $deps.dependsOn) {
        if ($dep -notin $State.completedTasks) {
            return @{
                ready = $false
                blockedBy = $dep
                reason = "Depends on $dep which is not complete"
            }
        }
    }
    
    return @{
        ready = $true
        parallelWith = $deps.parallelWith
    }
}
```

---

## Enhancement 3: Decisions Log

### What It Is

A `DECISIONS.md` file that tracks:
- Deviations from the original plan
- Architectural choices made during implementation
- Rationale for future sessions to understand

### Template: DECISIONS.md

```markdown
# Decisions Log

**Project:** [Project Name]
**Started:** [Date]

---

## How to Use This File

When you deviate from the PRD or make a significant architectural choice:
1. Add an entry below
2. Include the date, task, decision, and reasoning
3. Future sessions will read this for context

---

## Decisions

### [Date] - [Task ID]: [Brief Title]

**Decision:** [What you decided]

**Alternatives Considered:**
- [Alternative 1]
- [Alternative 2]

**Reasoning:** [Why this choice]

**Impact:** [What this affects]

---

### 2025-01-19 - US-301: Auth Implementation

**Decision:** Used Supabase Auth instead of custom JWT

**Alternatives Considered:**
- Custom JWT with refresh tokens
- Auth0 integration
- Firebase Auth

**Reasoning:** 
- Client already has Supabase for database
- Reduces complexity and maintenance
- Built-in email verification

**Impact:** 
- All auth-related tasks now use Supabase client
- No need for separate token management
- Password reset handled by Supabase

---
```

### Integration with RALPH

Add to session context building:

```powershell
function Get-DecisionsContext {
    $decisionsPath = "DECISIONS.md"
    
    if (-not (Test-Path $decisionsPath)) {
        return ""
    }
    
    $decisions = Get-Content $decisionsPath -Raw
    
    # Extract just the decisions (skip template instructions)
    if ($decisions -match '## Decisions(.+)$') {
        return "`n## Previous Decisions`n$($Matches[1].Trim())"
    }
    
    return ""
}
```

---

## Enhancement 4: Parallel Worktree Orchestration

### When to Use Parallel Worktrees

Use JAWS parallel worktrees when:

| Condition | Parallel? |
|-----------|-----------|
| Tasks have `PARALLEL WITH` markers | ✅ Yes |
| Foundation phase is complete | ✅ Yes |
| Tasks share no file dependencies | ✅ Yes |
| Tasks modify same files | ❌ No |
| Tasks have `DEPENDS ON` incomplete tasks | ❌ No |

### Parallel Worktree Setup Script

Add to `ralph-jaws-v4.ps1` or use standalone:

```powershell
function Initialize-ParallelWorktrees {
    param(
        [string[]]$TaskIds,
        [string]$BasePath = "../.worktrees"
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  INITIALIZING PARALLEL WORKTREES                                     " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    
    # Verify all tasks are ready
    $state = Initialize-State
    $allReady = $true
    
    foreach ($taskId in $TaskIds) {
        $readiness = Test-TaskReady -TaskId $taskId -State $state
        
        if (-not $readiness.ready) {
            Write-Host "  [BLOCKED] $taskId - $($readiness.reason)" -ForegroundColor Red
            $allReady = $false
        } else {
            Write-Host "  [READY] $taskId" -ForegroundColor Green
        }
    }
    
    if (-not $allReady) {
        Write-Host ""
        Write-Host "  Cannot create parallel worktrees. Resolve blockers first." -ForegroundColor Yellow
        return $false
    }
    
    # Create worktrees
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    foreach ($taskId in $TaskIds) {
        $branchName = "jaws-$taskId-$timestamp"
        $worktreeDir = Join-Path $BasePath $taskId
        
        Write-Host ""
        Write-Host "  Creating worktree for $taskId..." -ForegroundColor Cyan
        
        try {
            git worktree add $worktreeDir -b $branchName 2>&1 | Out-Null
            
            # Copy context files
            @("PRD.md", "AGENTS.md", "DECISIONS.md", "progress.txt") | ForEach-Object {
                if (Test-Path $_) {
                    Copy-Item $_ -Destination $worktreeDir -Force
                }
            }
            
            Write-Host "  [OK] $worktreeDir ($branchName)" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERROR] Failed to create worktree: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "  Parallel worktrees ready. Open separate terminals and run:" -ForegroundColor Yellow
    
    foreach ($taskId in $TaskIds) {
        $worktreeDir = Join-Path $BasePath $taskId
        Write-Host ""
        Write-Host "  Terminal for $taskId:" -ForegroundColor Cyan
        Write-Host "    cd $worktreeDir"
        Write-Host "    claude"
        Write-Host "    # Then paste the prompt for $taskId"
    }
    
    return $true
}
```

### Parallel Session Prompts

Generate prompts for each parallel session:

```powershell
function Get-ParallelSessionPrompt {
    param(
        [string]$TaskId,
        [string[]]$ParallelTasks
    )
    
    $task = Get-CurrentTask  # Modified to accept TaskId parameter
    $decisions = Get-DecisionsContext
    
    $otherTasks = ($ParallelTasks | Where-Object { $_ -ne $TaskId }) -join ', '
    
    $prompt = @"
You are working on task $TaskId in a PARALLEL worktree.

## Your Task
$($task.id): $($task.name)

## Important Context
- Other sessions are simultaneously building: $otherTasks
- DO NOT modify files outside your task scope
- DO NOT change database schema or auth system
- Focus ONLY on your assigned task

## Files You Own
$($task.files)

## Verification
VERIFY: $($task.verify)
DONE: $($task.done)
$decisions

## Instructions
1. Read PRD.md - find your task and its acceptance criteria
2. Read DECISIONS.md - understand architectural context
3. Implement ONLY your task
4. Mark criteria complete as you verify them
5. Update progress.txt with what you built

When complete, commit your changes with: feat($TaskId): [description]
"@
    
    return $prompt
}
```

---

## Enhancement 5: Plan Guardian Checkpoint

### Add to RALPH Main Loop

After a phase completes or at designated checkpoints:

```powershell
function Request-GuardianVerification {
    param(
        [string]$PhaseCompleted,
        [string[]]$TasksCompleted
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "  PLAN GUARDIAN CHECKPOINT                                            " -ForegroundColor Magenta
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  Phase completed: $PhaseCompleted"
    Write-Host "  Tasks: $($TasksCompleted -join ', ')"
    Write-Host ""
    Write-Host "  Open a FRESH Claude Code terminal and run this prompt:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    $guardianPrompt = @"
Read PRD.md. Phase "$PhaseCompleted" just completed.
Tasks completed: $($TasksCompleted -join ', ')

Verify against the PRD:
1. Are ALL acceptance criteria for these tasks actually complete?
2. Do the VERIFY checks pass when you run them?
3. Are there any gaps or half-finished work?
4. Is anything missing that the next phase will need?

Be thorough. Check the actual code/workflows, not just the checkboxes.
Report any issues found.
"@
    
    Write-Host $guardianPrompt -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    
    if (-not $AutoPilot) {
        Write-Host "  After running the Guardian check:" -ForegroundColor White
        Write-Host "    [C] Continue - Guardian confirmed all good"
        Write-Host "    [I] Issues found - Stop and review"
        Write-Host "    [S] Skip - Continue without guardian check"
        Write-Host ""
        
        $choice = Read-Host "  Your choice"
        
        switch ($choice.ToUpper()) {
            'C' { return @{ verified = $true } }
            'I' { return @{ verified = $false; action = 'review' } }
            'S' { return @{ verified = $true; skipped = $true } }
            default { return @{ verified = $true } }
        }
    }
    
    return @{ verified = $true; skipped = $true }
}
```

---

## Updated PRD Template

### PRD-TEMPLATE-v2.md

```markdown
# [Project Name] - Product Requirements Document

**Version:** 1.0
**Created:** [Date]
**Last Updated:** [Date]

---

## Dependency Map

```
[US-301] Foundation
    │
    ├──► [US-302] Feature A ──┐
    │                         │
    ├──► [US-303] Feature B ──┼──► [US-305] Integration
    │                         │
    └──► [US-304] Feature C ──┘
```

---

## Phase 1: Foundation

### US-301: [Foundation Task]

**DEPENDS ON:** None (this is the foundation)
**PARALLEL WITH:** None
**BLOCKS:** US-302, US-303, US-304

**FILES:** [files to create/modify]
**VERIFY:** [command or check to verify]
**DONE:** [clear completion criteria]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

## Phase 2: Core Features (Parallel-Ready)

### US-302: [Feature A]

**DEPENDS ON:** US-301
**PARALLEL WITH:** US-303, US-304
**BLOCKS:** US-305

**FILES:** [files to create/modify]
**VERIFY:** [command or check to verify]
**DONE:** [clear completion criteria]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

### US-303: [Feature B]

**DEPENDS ON:** US-301
**PARALLEL WITH:** US-302, US-304
**BLOCKS:** US-305

**FILES:** [files to create/modify]
**VERIFY:** [command or check to verify]
**DONE:** [clear completion criteria]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

### US-304: [Feature C]

**DEPENDS ON:** US-301
**PARALLEL WITH:** US-302, US-303
**BLOCKS:** US-305

**FILES:** [files to create/modify]
**VERIFY:** [command or check to verify]
**DONE:** [clear completion criteria]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

---

## Phase 3: Integration

### US-305: [Integration Task]

**DEPENDS ON:** US-302, US-303, US-304
**PARALLEL WITH:** None
**BLOCKS:** None (final task)

**FILES:** [files to create/modify]
**VERIFY:** [command or check to verify]
**DONE:** [clear completion criteria]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2

---

## Guardian Checkpoints

- [ ] **After Phase 1:** Verify foundation before parallel work
- [ ] **After Phase 2:** Verify all parallel features before integration
- [ ] **After Phase 3:** Final verification before deployment
```

---

## Quick Reference

### New RALPH Parameters

```powershell
# Parallel worktree management
[switch]$UseParallelWorktrees,
[string[]]$ParallelTasks,

# Plan Guardian
[switch]$UseGuardian,
[int]$GuardianAfterPhase = 1,
```

### New Commands

```powershell
# Check if a task is ready to start
Test-TaskReady -TaskId "US-302" -State $state

# Get task dependencies
Get-TaskDependencies -TaskId "US-302"

# Set up parallel worktrees
Initialize-ParallelWorktrees -TaskIds @("US-302", "US-303", "US-304")

# Generate parallel session prompt
Get-ParallelSessionPrompt -TaskId "US-302" -ParallelTasks @("US-302", "US-303", "US-304")

# Request guardian verification
Request-GuardianVerification -PhaseCompleted "Phase 2" -TasksCompleted @("US-302", "US-303", "US-304")
```

### Files to Create

| File | Purpose |
|------|---------|
| `DECISIONS.md` | Track architectural decisions |
| `PRD.md` | Updated with dependency markers |
| `.worktrees/` | Parallel worktree directory |

---

## Migration Checklist

To upgrade existing JAWS projects:

1. [ ] Add dependency markers to existing PRD tasks
2. [ ] Create DECISIONS.md from PROJECT-STATE.md learnings
3. [ ] Add dependency map to PRD header
4. [ ] Update RALPH with new functions (or use standalone)
5. [ ] Add Guardian checkpoint prompts to workflow

---

## Summary

| Enhancement | What It Does | When to Use |
|-------------|--------------|-------------|
| **Plan Guardian** | Fresh-context verification | After each phase |
| **Dependency Markers** | Explicit task dependencies | All PRD tasks |
| **Decisions Log** | Track deviations | During implementation |
| **Parallel Worktrees** | Multiple simultaneous builds | Independent features |
| **Guardian Checkpoints** | Quality gates | Before phase transitions |

These enhancements make JAWS more robust for:
- Complex multi-phase projects
- Parallel feature development
- Maintaining quality across long builds
- Capturing institutional knowledge
