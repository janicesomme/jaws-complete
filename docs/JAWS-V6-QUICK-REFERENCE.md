# JAWS v6 Quick Reference

**Your Power Tool - Start Here**

---

## 30-Second Start

```powershell
# See the plan (no execution)
.\ralph-jaws-v6.ps1 -DryRun

# Run it
.\ralph-jaws-v6.ps1 -MaxWorkers 3 -PlanGuardian -AImergeResolution -GenerateChangelog
```

---

## What v6 Does

1. **Reads** your PRD.md
2. **Analyzes** task dependencies
3. **Spawns** multiple Claude workers
4. **Coordinates** parallel execution
5. **Merges** all branches
6. **Verifies** with fresh-context QA
7. **Reports** results

---

## Key Flags

| Flag | What It Does |
|------|--------------|
| `-DryRun` | Show plan, don't execute |
| `-MaxWorkers 3` | Use 3 parallel Claudes |
| `-PlanGuardian` | Fresh-context verification |
| `-AImergeResolution` | Auto-fix merge conflicts |
| `-GenerateChangelog` | Create build changelog |

---

## PRD Format for v6

Add these fields for best results:

```markdown
### US-001: Task Name

**FILES:** path/to/files.ext
**DEPENDS:** US-000 (or leave empty)
**VERIFY:** How to verify it works
**DONE:** Definition of done

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```

---

## Typical Build

**8-Task Build (like Lead Management System):**

| Version | Time | Your Work |
|---------|------|-----------|
| v5 Sequential | 3.5 hours | Monitor |
| v5 Manual Parallel | 2 hours | 45 min coordination |
| **v6 Orchestrated** | **1.5 hours** | **Start + Review** |

---

## When Things Go Wrong

**Worker failed?**
- Check `jaws-orchestrator-state.json` for which tasks failed
- Re-run with just those tasks

**Merge conflict?**
- If you used `-AImergeResolution`, it tried to fix it
- If not, resolve manually then continue

**Task stuck waiting?**
- Check if dependency actually completed
- Look in worker-state.json in the worktree

---

## Files Created

| File | Purpose |
|------|---------|
| `jaws-orchestrator-state.json` | Main state tracking |
| `CHANGELOG-v6-*.md` | Build summary |
| `.worktrees/jaws-v6-worker-*/` | Temporary worktrees (cleaned up) |

---

## v5 vs v6

| Use v5 When | Use v6 When |
|-------------|-------------|
| Teaching others | Your personal builds |
| Simple 1-3 task builds | Complex 5+ task builds |
| Need transparency | Need speed |
| Client watching | Working alone |

---

## Full Command

```powershell
.\ralph-jaws-v6.ps1 `
    -PRDPath PRD.md `
    -MaxWorkers 3 `
    -AutoOrchestrate `
    -PlanGuardian `
    -AImergeResolution `
    -EnableLearnings `
    -GenerateChangelog `
    -Verbose
```

---

*v6 = Your power tool. v5 = Your product.*
