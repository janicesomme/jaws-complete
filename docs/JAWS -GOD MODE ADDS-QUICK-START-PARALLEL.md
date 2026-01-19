# JAWS Parallel Enhancement - Quick Start

**Get started in 5 minutes.**

---

## Step 1: Add Files to Your JAWS Repo

Copy these files to your `jaws-complete` repository:

```
jaws-complete/
├── templates/
│   ├── PRD-TEMPLATE-v2.md      ← New PRD template with dependencies
│   ├── DECISIONS-TEMPLATE.md   ← Track architectural decisions
│   └── PLAN-GUARDIAN-PROMPTS.md ← Copy-paste verification prompts
├── jaws-parallel-module.ps1    ← PowerShell functions (optional)
└── JAWS-PARALLEL-ENHANCEMENT.md ← Full documentation
```

---

## Step 2: Start Using Today (No Code Changes)

### A. After ANY phase completes, verify with Plan Guardian

Open a **fresh** Claude Code terminal (not the one you've been working in) and paste:

```
Read PRD.md. [Phase/Task] just completed in another session.

Verify:
1. Are all acceptance criteria actually working?
2. Do the VERIFY checks pass?
3. Any gaps or half-finished work?
4. Anything missing for the next phase?

Be thorough. Check actual code, not just checkboxes.
```

### B. Add dependency markers to your PRDs

In each task, add these fields:

```markdown
### US-302: Build Dashboard

**DEPENDS ON:** US-301 (auth must be complete)
**PARALLEL WITH:** US-303, US-304
**BLOCKS:** US-305

**FILES:** src/dashboard/
**VERIFY:** npm run test:dashboard
**DONE:** Dashboard shows user data

- [ ] Criterion 1
- [ ] Criterion 2
```

### C. Create DECISIONS.md when you deviate

```markdown
### 2025-01-19 - US-301: Auth Choice

**Decision:** Used Supabase Auth instead of custom JWT

**Reasoning:** Client already has Supabase, reduces complexity

**Impact:** All auth uses Supabase client
```

---

## Step 3: Parallel Worktrees (When Ready)

After your foundation is complete:

```powershell
# Import the module
. .\jaws-parallel-module.ps1

# See what's ready for parallel work
Show-DependencyMap -CompletedTasks @("US-301")

# Create parallel worktrees
Initialize-ParallelWorktrees -TaskIds @("US-302", "US-303", "US-304") -CompletedTasks @("US-301")

# Follow the prompts it generates for each terminal
```

After parallel work completes:

```powershell
# Merge all back to main
Merge-ParallelWorktrees -Worktrees $worktrees -Cleanup
```

---

## The Key Insight

> **The Plan Guardian has fresh context.**
> 
> Your implementation session gets "polluted" by code details and auto-compacting.
> A fresh session sees the big picture clearly.

Use it after every phase. It catches things you'll miss.

---

## Cheat Sheet

| Situation | What to Do |
|-----------|------------|
| Phase complete | Run Plan Guardian in fresh terminal |
| Starting parallel work | Use `Initialize-ParallelWorktrees` |
| Made architectural choice | Add to DECISIONS.md |
| Not sure what's ready | Run `Show-DependencyMap` |
| Merging parallel branches | Use `Merge-ParallelWorktrees` |

---

## Common Patterns

### Pattern 1: Foundation → Parallel → Integration

```
Phase 1: Foundation (sequential)
    US-301: Database + Auth
    ↓ [Guardian Check]
    
Phase 2: Features (parallel)
    US-302 ←→ US-303 ←→ US-304
    ↓ [Guardian Check]
    
Phase 3: Integration (sequential)
    US-305: Connect everything
    ↓ [Guardian Check]
    
Phase 4: Polish
    US-306: Testing + Docs
```

### Pattern 2: Quick Guardian Check

After any task:
```
Read PRD.md. Is US-XXX actually complete? 
Run the VERIFY check. Report any issues.
```

### Pattern 3: Start of Session

```
Read PRD.md and DECISIONS.md.
What's the current state? What should I work on next?
```

---

## Files Reference

| File | When to Use |
|------|-------------|
| `PRD-TEMPLATE-v2.md` | Starting new projects |
| `DECISIONS-TEMPLATE.md` | First architectural decision |
| `PLAN-GUARDIAN-PROMPTS.md` | After phases complete |
| `jaws-parallel-module.ps1` | Parallel worktree management |
| `JAWS-PARALLEL-ENHANCEMENT.md` | Full documentation |

---

## That's It

1. **Use Plan Guardian** after every phase (biggest win)
2. **Add dependency markers** to PRD tasks
3. **Track decisions** in DECISIONS.md
4. **Use parallel worktrees** when tasks are independent

Questions? The full documentation is in `JAWS-PARALLEL-ENHANCEMENT.md`.
