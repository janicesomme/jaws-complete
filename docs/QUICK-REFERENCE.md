# JAWS Quick Reference

> Print this. Keep it handy.

---

## 🚀 Most Common Commands

```powershell
# Basic build
./ralph-jaws-v4.ps1 -PRDPath "PRD.md"

# Safe build (isolated worktree)
./ralph-jaws-v4.ps1 -PRDPath "PRD.md" -UseWorktree -AtomicCommits

# Walk-away build
./ralph-jaws-v4.ps1 -PRDPath "PRD.md" -AutoPilot -UseWorktree

# Resume interrupted build
./ralph-jaws-v4.ps1 -PRDPath "PRD.md"  # Auto-resumes from state file

# Check status
./scripts/ralph-status.ps1
```

---

## 📝 PRD Task Format

```markdown
### US-001: Task Name

**FILES:** `path/to/file.ts`
**ACTION:** What to build (2-4 sentences)
**VERIFY:** Test command → expected result
**DONE:** One-line acceptance criteria

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
```

---

## 🎛️ Key Parameters

| Flag | What It Does |
|------|--------------|
| `-UseWorktree` | Safe mode - isolates build |
| `-AtomicCommits` | Commits after each task |
| `-AutoPilot` | No human checkpoints |
| `-GenerateDocs` | Create docs on completion |
| `-GenerateChangelog` | Build summary |
| `-Model opus` | Use Opus for complex tasks |
| `-Model haiku` | Use Haiku for simple tasks |
| `-FreshContextMode` | Reset context every N tasks |
| `-MaxIterations 30` | Allow more iterations |
| `-CheckpointEvery 5` | Less frequent human reviews |

---

## 🔄 Checkpoint Options

When RALPH hits a checkpoint:

| Key | Action |
|-----|--------|
| `C` | Continue - proceed with build |
| `S` | Skip - mark task as skipped |
| `R` | Retry - provide guidance |
| `A` | Abort - stop build |
| `P` | AutoPilot - no more checkpoints |

---

## 📁 Project Files

| File | Purpose |
|------|---------|
| `PRD.md` | Your task list |
| `AGENTS.md` | Patterns & learnings |
| `progress.txt` | Build history |
| `ralph-state.json` | Resume state (auto-created) |

---

## 🔧 Git Worktree Commands

```bash
# List worktrees
git worktree list

# Manual cleanup if needed
git worktree remove .worktrees/branch-name --force
git branch -d branch-name

# See what branches exist
git branch -a
```

---

## 🚨 When Things Go Wrong

### Stuck in loop (rabbit hole)
- RALPH auto-detects after 3 failures
- Choose `S` to skip, or `R` to provide guidance

### Need to stop mid-build
- Press `Ctrl+C`
- State saved in `ralph-state.json`
- Run same command to resume

### Worktree won't merge
```bash
# Go back to main
cd /path/to/main/project
git status

# Manual merge
git merge branch-name

# If conflicts, resolve then:
git add -A
git commit -m "Merge resolved"
```

### Want to start fresh
```bash
# Delete state file
rm ralph-state.json

# Or delete and recreate PRD
```

---

## 📊 Complexity Guide

| Complexity | Tasks | Iterations | Time |
|------------|-------|------------|------|
| Simple | 1-3 | 5-10 | <1 hr |
| Medium | 4-7 | 15-25 | 2-4 hrs |
| Complex | 8-15 | 30-50 | 4-8 hrs |
| Large | 15+ | 50+ | Multiple sessions |

---

## 💡 Pro Tips

1. **Start small** - Test with 2-3 tasks first
2. **Good VERIFY = Good results** - Be specific about tests
3. **Use worktrees** - Never risk your main branch
4. **Commit often** - `-AtomicCommits` is your friend
5. **Fresh context** - For long builds, use `-FreshContextMode`
6. **Check AGENTS.md** - Patterns accumulate, reuse them
7. **Template first** - Use pre-built PRDs when possible

---

## 📚 Full Docs

- [INSTALLATION.md](INSTALLATION.md) - Setup guide
- [OPERATIONS-GUIDE.md](OPERATIONS-GUIDE.md) - Session management
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [README.md](../README.md) - Full documentation

---

*JAWS v4 - Quick Reference*
