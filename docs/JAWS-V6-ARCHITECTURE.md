# JAWS v6 Architecture

**Your Personal Power Tool - Not for Distribution**

---

## Overview

JAWS v6 is an orchestrated multi-agent build system that automatically parallelizes PRD tasks across multiple Claude instances, coordinates their work, and merges results.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        JAWS v6 ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐  │
│   │                     ORCHESTRATOR PROCESS                         │  │
│   │  - Parses PRD                                                    │  │
│   │  - Builds dependency graph                                       │  │
│   │  - Creates parallelization plan                                  │  │
│   │  - Spawns workers                                                │  │
│   │  - Monitors progress                                             │  │
│   │  - Coordinates merges                                            │  │
│   └─────────────────────────────────────────────────────────────────┘  │
│                              │                                          │
│         ┌────────────────────┼────────────────────┐                    │
│         ▼                    ▼                    ▼                    │
│   ┌───────────┐        ┌───────────┐        ┌───────────┐             │
│   │  WORKER 0 │        │  WORKER 1 │        │  WORKER 2 │             │
│   │           │        │           │        │           │             │
│   │ Worktree: │        │ Worktree: │        │ Worktree: │             │
│   │ jaws-v6-  │        │ jaws-v6-  │        │ jaws-v6-  │             │
│   │ worker-0  │        │ worker-1  │        │ worker-2  │             │
│   │           │        │           │        │           │             │
│   │ Tasks:    │        │ Tasks:    │        │ Tasks:    │             │
│   │ US-001    │        │ US-002    │        │ US-006    │             │
│   │           │        │ US-003    │        │ US-008    │             │
│   │           │        │ US-004    │        │           │             │
│   └───────────┘        └───────────┘        └───────────┘             │
│         │                    │                    │                    │
│         └────────────────────┼────────────────────┘                    │
│                              ▼                                          │
│                     ┌───────────────┐                                  │
│                     │    MERGER     │                                  │
│                     │  (Sequential) │                                  │
│                     └───────────────┘                                  │
│                              │                                          │
│                              ▼                                          │
│                     ┌───────────────┐                                  │
│                     │ PLAN GUARDIAN │                                  │
│                     │ (Fresh QA)    │                                  │
│                     └───────────────┘                                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Key Components

### 1. Orchestrator Process

The main PowerShell process that coordinates everything.

**Responsibilities:**
- Parse PRD to extract tasks
- Analyze task types (database, workflow, frontend, backend, integration)
- Build dependency graph (which tasks block others)
- Create optimal parallelization plan
- Spawn worker processes
- Monitor worker progress via state files
- Signal task completions to unblock dependent tasks
- Orchestrate sequential merge
- Run Plan Guardian verification

**State File:** `jaws-orchestrator-state.json`

```json
{
  "status": "running",
  "startTime": "2026-01-30 18:00:00",
  "workers": {
    "worker-0": {
      "status": "working",
      "tasks": ["US-001"],
      "worktree": { "path": "...", "branch": "..." }
    }
  },
  "signals": {
    "US-001-complete": true,
    "US-002-complete": false
  },
  "completedTasks": ["US-001"],
  "failedTasks": []
}
```

### 2. Worker Processes

Independent PowerShell processes, each running Claude in its own git worktree.

**Responsibilities:**
- Execute assigned tasks sequentially
- Wait for dependency signals before starting blocked tasks
- Update local worker state file
- Commit changes to worker branch
- Signal completion to orchestrator

**State File:** `worker-state.json` (in each worktree)

```json
{
  "workerId": "worker-1",
  "status": "working",
  "tasks": ["US-002", "US-003", "US-004"],
  "currentTask": "US-002",
  "completedTasks": [],
  "failedTasks": [],
  "startTime": "2026-01-30 18:00:05"
}
```

### 3. Dependency Graph

Automatically inferred from PRD content:

```
Task Type Detection:
- "supabase|database|schema|table" → database
- "n8n|workflow|webhook|node" → workflow
- "react|component|dashboard|frontend" → frontend
- "email|notification|slack" → integration
- "API|endpoint|route" → backend

Inference Rules:
- Database tasks block workflows/backend that reference DB
- Tasks modifying same file are sequential
- Explicit DEPENDS: field in PRD
- Everything else can parallelize
```

### 4. Plan Guardian

Fresh-context verification agent that knows NOTHING about how code was built.

**Input:**
- Original PRD (what should exist)
- Git diff (what does exist)

**Output:**
- Verification report (PASS/FAIL/WARNING)
- Evidence for each verified task
- Concerns and blockers

**Why Fresh Context?**
Same-context QA has bias - the agent that built it assumes it works. Plan Guardian starts fresh and must find evidence in the actual code.

---

## Execution Phases

### Phase 1: Analysis
```
1. Parse PRD.md for all pending tasks
2. Extract task metadata (type, files, verify, done, depends)
3. Build dependency graph
4. Create parallelization plan
5. Assign tasks to workers (group by type)
```

### Phase 2: Setup
```
1. Create git worktree for each worker
2. Copy essential files (PRD, AGENTS.md, etc.)
3. Create worker state files
4. Generate worker scripts
```

### Phase 3: Orchestration
```
1. Spawn worker processes (PowerShell background jobs)
2. Monitor worker state files every 10 seconds
3. Update orchestrator signals as tasks complete
4. Wait for all workers to finish
5. Collect worker outputs
```

### Phase 4: Merge
```
1. Return to main branch
2. Merge each worker branch sequentially
3. If conflicts and -AImergeResolution: auto-resolve
4. If conflicts without flag: stop for manual resolution
```

### Phase 5: Verification
```
1. Run Plan Guardian (if -PlanGuardian)
2. Generate changelog (if -GenerateChangelog)
3. Cleanup worktrees
4. Report final status
```

---

## Inter-Process Communication

### Signal System

Workers signal task completion through the orchestrator state file:

```powershell
# Worker completes US-001
$orchState = Read-StateAtomic $orchestratorState
$orchState.signals["US-001-complete"] = $true
Save-StateAtomic $orchState $orchestratorState

# Worker-2 waiting for US-001
while (-not $orchState.signals["US-001-complete"]) {
    Start-Sleep -Seconds 5
    $orchState = Read-StateAtomic $orchestratorState
}
# Now can proceed with US-002
```

### File Locking

Atomic operations with simple file locking:

```powershell
function Save-StateAtomic {
    # 1. Check for lock file
    # 2. Create lock
    # 3. Write to .tmp file
    # 4. Backup existing
    # 5. Atomic rename
    # 6. Release lock
}
```

---

## Smart Task Assignment

### Type Grouping

Workers are assigned tasks of similar types to reduce context switching:

```
Worker-0 (database):  US-001 (schema)
Worker-1 (workflow):  US-002 → US-003 → US-004 → US-005
Worker-2 (frontend):  US-006 → US-008
```

### Wave Detection

Tasks grouped into execution waves based on dependencies:

```
Wave 1: US-001, US-006 (no dependencies)
Wave 2: US-002, US-008 (after US-001 or independent)
Wave 3: US-003 (after US-002)
Wave 4: US-004, US-005 (after US-003)
```

---

## PRD Format for v6

v6 works best with these PRD fields:

```markdown
### US-001: Create Database Schema

**FILES:** supabase/schema.sql
**DEPENDS:** (none)
**VERIFY:** SELECT * FROM leads LIMIT 1 returns correct columns
**DONE:** Tables exist with RLS enabled

**Acceptance Criteria:**
- [ ] Table leads created
- [ ] RLS policies added
- [ ] Service role can insert
```

The `**DEPENDS:**` field explicitly declares dependencies.
The `**FILES:**` field helps detect implicit dependencies (same file = sequential).

---

## Command Line Reference

### Basic Usage

```powershell
# Analyze PRD and show plan (no execution)
.\ralph-jaws-v6.ps1 -PRDPath PRD.md -DryRun

# Run with 3 workers
.\ralph-jaws-v6.ps1 -PRDPath PRD.md -MaxWorkers 3

# Full featured
.\ralph-jaws-v6.ps1 `
    -PRDPath PRD.md `
    -MaxWorkers 3 `
    -AutoOrchestrate `
    -PlanGuardian `
    -AImergeResolution `
    -GenerateChangelog
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-PRDPath` | string | PRD.md | Path to PRD file |
| `-MaxWorkers` | int | 3 | Maximum parallel workers (1-5) |
| `-AutoOrchestrate` | switch | false | Enable automatic orchestration |
| `-DryRun` | switch | false | Show plan without executing |
| `-PlanGuardian` | switch | false | Run fresh-context verification |
| `-AImergeResolution` | switch | false | Auto-resolve merge conflicts |
| `-GenerateChangelog` | switch | false | Generate build changelog |
| `-EnableLearnings` | switch | false | Use PROJECT-LEARNINGS.json |
| `-UseWorktree` | switch | implied | Always uses worktrees |
| `-AtomicCommits` | switch | false | Atomic commits per task |
| `-Verbose` | switch | false | Detailed output |

---

## Comparison: v5 vs v6

| Aspect | v5 | v6 |
|--------|----|----|
| **Execution** | Single agent, sequential | Multi-agent, parallel |
| **Parallelization** | Manual (MANUAL-AUTO-CLAUDE.md) | Automatic |
| **Task Assignment** | You decide | Orchestrator decides |
| **Dependency Handling** | Manual | Automatic graph analysis |
| **Merge** | Manual or AI-assisted | Orchestrated sequential |
| **QA** | Same-context | Fresh-context Plan Guardian |
| **Your Involvement** | Monitor + coordinate | Start command, review results |
| **Complexity** | Low | Higher |
| **Best For** | Teaching, simple builds | Your personal complex builds |

---

## Error Handling

### Worker Failure

If a worker fails:
1. Worker state file shows `failedTasks`
2. Orchestrator continues with other workers
3. Final summary shows failed tasks
4. You can re-run with just failed tasks

### Merge Conflict

If merge conflicts occur:
1. With `-AImergeResolution`: Claude attempts to resolve
2. Without flag: Build pauses for manual resolution
3. After resolution: Run `git merge --continue`

### Dependency Timeout

If a task waits too long for dependencies (5 min default):
1. Warning logged
2. Build continues (may fail downstream)
3. Review orchestrator state for stuck signals

---

## File Structure

During a v6 build:

```
your-project/
├── PRD.md
├── jaws-orchestrator-state.json     ← Main state file
├── CHANGELOG-v6-*.md                ← Generated changelogs
└── ../.worktrees/
    ├── jaws-v6-worker-0-20260130/
    │   ├── (copy of project)
    │   ├── worker-state.json        ← Worker state
    │   └── worker-script.ps1        ← Worker script
    ├── jaws-v6-worker-1-20260130/
    └── jaws-v6-worker-2-20260130/
```

After successful build, worktrees are cleaned up.

---

## Tips for Best Results

1. **Clear Dependencies:** Use `**DEPENDS:** US-001, US-002` in PRD
2. **Task Granularity:** Keep tasks focused (15-30 min each)
3. **Type Grouping:** Similar tasks parallelize better
4. **Files Field:** Always specify `**FILES:**` for conflict prevention
5. **Start with DryRun:** Check the plan before executing

---

## Limitations

1. **Max 5 Workers:** More workers = more merge complexity
2. **Same Machine:** All workers run locally (no distributed)
3. **Sequential Merge:** Branches merge one at a time
4. **Signal Latency:** 10-second polling interval

---

## Future Enhancements (Ideas)

- [ ] Proactive conflict prevention (alert before file collision)
- [ ] Dynamic worker scaling (add workers mid-build)
- [ ] Remote worker support (distributed builds)
- [ ] Visual progress dashboard
- [ ] Cost tracking per worker

---

*JAWS v6 - Your Personal Power Tool*
