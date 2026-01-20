# RLM Reconnaissance Prompts

**Use these immediately - no code changes needed. Just copy-paste into Claude Code.**

---

## The Core Principle

> "Long prompts should NOT be fed into the neural network, but should be treated as part of the ENVIRONMENT the LLM can interact with."

**Translation:** Don't dump files into context. Query what you need with commands.

---

## Standard Task Prompt (With Recon)

Copy this and replace `[TASK_ID]` and `[TASK_NAME]`:

```
## Your Task: [TASK_ID] - [TASK_NAME]

## CRITICAL: Reconnaissance First

Before writing ANY code, explore your environment with commands:

### Step 1: Project Structure
```bash
find . -type f \( -name "*.js" -o -name "*.ts" -o -name "*.json" \) | head -30
```

### Step 2: Find Your Task in PRD
```bash
sed -n '/### [TASK_ID]/,/### US-/p' PRD.md | head -50
```

### Step 3: Find Related Code
```bash
grep -r "KEYWORD" . --include="*.js" --include="*.ts" -l | head -10
```

### Step 4: Check Existing Patterns
```bash
head -50 src/[relevant-file].js
```

## Rules

1. **Query, don't load** - Use grep/find, don't open entire files
2. **Read only what you'll change** - Skip unrelated code
3. **One file at a time** - Don't open multiple large files
4. **Verify before marking done** - Run the VERIFY check

## Anti-Patterns (DO NOT)

❌ Don't "read the entire codebase to understand it"
❌ Don't open PRD.md and read the whole thing
❌ Don't load files you won't modify
❌ Don't dump large documents then ask questions

## Start Reconnaissance Now

Run the commands above, then implement based on what you find.
```

---

## Quick Recon Prompt (Minimal)

For simpler tasks:

```
Before implementing [TASK_ID]:

1. Run: grep -r "[keyword]" . --include="*.js" -l
2. Run: sed -n '/### [TASK_ID]/,/### US-/p' PRD.md
3. Check only the files you'll modify
4. Implement
5. Verify

Don't load entire files. Query what you need.
```

---

## Complex Task Prompt (Sub-Agent Style)

For tasks with 5+ acceptance criteria:

```
## Task: [TASK_ID] - [TASK_NAME]

This task has multiple criteria. Handle them ONE AT A TIME.

## Process for Each Criterion

### Criterion 1: [Text]

1. Reconnaissance:
   ```bash
   grep -r "[relevant keyword]" . --include="*.js" -l
   ```

2. Read ONLY the relevant function/file section

3. Implement this ONE criterion

4. Verify it works

5. THEN move to Criterion 2

### Criterion 2: [Text]
[Repeat process]

## Rules

- Complete and verify each criterion before starting the next
- Don't try to implement everything at once
- Query files as needed, don't preload

Start with Criterion 1 reconnaissance now.
```

---

## N8n Workflow Task Prompt

For JAWS workflow building:

```
## Task: [TASK_ID] - [WORKFLOW_NAME]

## Reconnaissance First

### Check Existing Workflows
```bash
find . -name "*.json" -path "*/workflows/*" | head -10
```

### Find Related Patterns
```bash
grep -r "webhook\|trigger\|HTTP" . --include="*.json" -l
```

### Read PRD Task Section Only
```bash
sed -n '/### [TASK_ID]/,/### US-/p' PRD.md
```

## Implementation Rules

1. Don't load example workflows unless you'll copy from them
2. Build incrementally - test each node connection
3. Query AGENTS.md for patterns only if stuck
4. Verify webhook responds before marking done

## Verify

Run: [VERIFY command from PRD]

If passes → Mark criteria complete
If fails → Debug before proceeding

Start reconnaissance now.
```

---

## Session Start Prompt (Fresh Context)

Use at the beginning of any session:

```
I'm starting work on [PROJECT_NAME].

Before loading any files, help me understand the environment:

1. What's the project structure?
   ```bash
   find . -type f -name "*.js" -o -name "*.json" | head -30
   ```

2. What task should I work on?
   ```bash
   grep -n "\[ \]" PRD.md | head -10
   ```

3. What patterns exist?
   ```bash
   head -30 AGENTS.md
   ```

Don't read entire files. Just give me the lay of the land, then we'll query specifics as needed.
```

---

## The Key Commands

| Purpose | Command |
|---------|---------|
| Project structure | `find . -type f -name "*.js" \| head -30` |
| Find keyword | `grep -r "keyword" . --include="*.js" -l` |
| Extract PRD task | `sed -n '/### US-XXX/,/### US-/p' PRD.md` |
| Check file start | `head -50 filename.js` |
| Find functions | `grep -n "function\|const.*=" file.js` |
| Incomplete tasks | `grep -n "\[ \]" PRD.md` |

---

## Why This Works

**Before (Context Rot):**
```
Load PRD.md (5000 tokens)
Load AGENTS.md (2000 tokens)  
Load src/index.js (3000 tokens)
Load src/utils.js (2000 tokens)
... context filling up ...
... quality degrading ...
```

**After (RLM Style):**
```
Query: "What tasks are incomplete?"
→ grep returns 5 lines (50 tokens)

Query: "What's in task US-302?"
→ sed returns task section (200 tokens)

Query: "Where is auth implemented?"
→ grep returns 3 filenames (30 tokens)

Query: "Show me the auth function"
→ head returns relevant code (300 tokens)

... context stays lean ...
... quality stays high ...
```

---

## Quick Reference

| Situation | Do This |
|-----------|---------|
| Starting a task | Run recon commands first |
| Need to understand code | `grep` for keywords, don't open files |
| Need PRD details | `sed` to extract your task only |
| Complex task | Handle one criterion at a time |
| Context getting long | Start fresh session, run recon again |

---

*Based on MIT RLM paper principles - treat documents as environment, not context.*
