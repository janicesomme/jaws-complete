# JAWS Installation Guide

## Prerequisites

### Required

| Tool | Version | Check Command | Install |
|------|---------|---------------|---------|
| PowerShell | 7.0+ | `$PSVersionTable.PSVersion` | [Install](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |
| Git | 2.30+ | `git --version` | [Install](https://git-scm.com/downloads) |
| Claude Code CLI | Latest | `claude --version` | `npm install -g @anthropic-ai/claude-code` |
| Node.js | 18+ | `node --version` | [Install](https://nodejs.org/) |

### Optional (for full features)

| Tool | Purpose | Install |
|------|---------|---------|
| n8n | Workflow automation | `npm install -g n8n` |
| Supabase CLI | Database management | `npm install -g supabase` |
| Vercel CLI | Frontend deployment | `npm install -g vercel` |

---

## Installation Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/jaws-complete.git
cd jaws-complete
```

### Step 2: Verify Prerequisites

```powershell
# Run this to check all prerequisites
./scripts/check-prerequisites.ps1

# Or manually check:
$PSVersionTable.PSVersion  # Should be 7.0+
git --version              # Should be 2.30+
claude --version           # Should show version
node --version             # Should be 18+
```

### Step 3: Configure Claude Code

```bash
# Login to Claude Code (if not already)
claude login

# Verify it works
claude --help
```

### Step 4: Test Installation

```powershell
# Run a simple test build
./ralph-jaws-v4.ps1 -PRDPath "examples/simple-test.md" -MaxIterations 3

# You should see:
# - Banner with configuration
# - Iteration progress
# - Task completion messages
```

---

## Project Setup

When starting a NEW project with JAWS:

### Step 1: Create Project Folder

```powershell
mkdir my-project
cd my-project
git init
```

### Step 2: Copy JAWS Files

```powershell
# Copy the essentials
cp /path/to/jaws-complete/ralph-jaws-v4.ps1 .
cp /path/to/jaws-complete/templates/prd/PRD-TEMPLATE-v2.md ./PRD.md
cp /path/to/jaws-complete/AGENTS.md .
cp /path/to/jaws-complete/progress.txt .
```

### Step 3: Edit Your PRD

Open `PRD.md` and fill in:
1. Project overview
2. Technical context
3. CRITICAL rules
4. User stories with VERIFY/DONE

### Step 4: Initial Commit

```powershell
git add -A
git commit -m "Initial project setup"
```

### Step 5: Run RALPH

```powershell
./ralph-jaws-v4.ps1 -PRDPath "PRD.md" -UseWorktree -AtomicCommits
```

---

## Configuration Options

### Environment Variables (Optional)

```powershell
# Set default model
$env:JAWS_DEFAULT_MODEL = "sonnet"

# Set default checkpoint interval
$env:JAWS_CHECKPOINT_EVERY = 5
```

### RALPH Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-PRDPath` | "PRD.md" | Path to PRD file |
| `-MaxIterations` | 10 | Max build loops |
| `-CheckpointEvery` | 3 | Human review interval |
| `-MaxConsecutiveFailures` | 3 | Rabbit hole threshold |
| `-SleepSeconds` | 2 | Delay between iterations |
| `-UseWorktree` | false | Isolate in git worktree |
| `-AtomicCommits` | false | Commit after each task |
| `-FreshContextMode` | false | Restart after N tasks |
| `-MaxTasksPerSession` | 5 | Tasks before context reset |
| `-Model` | "sonnet" | opus/sonnet/haiku |
| `-GenerateDocs` | false | Auto-generate docs |
| `-GenerateChangelog` | false | Create build summary |
| `-AutoPilot` | false | Skip all checkpoints |
| `-Verbose` | false | Extra logging |
| `-StateFile` | "ralph-state.json" | State persistence file |

---

## Troubleshooting Installation

### "claude: command not found"

```bash
# Make sure npm global bin is in PATH
npm config get prefix
# Add that path + /bin to your PATH

# Or reinstall:
npm install -g @anthropic-ai/claude-code
```

### "PowerShell version too old"

```powershell
# Windows: Install PowerShell 7
winget install Microsoft.PowerShell

# Mac:
brew install powershell

# Linux:
# See https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux
```

### "Git worktree fails"

```bash
# Make sure you have at least one commit
git add -A
git commit -m "Initial commit"

# Then worktree will work
```

### "Permission denied on .ps1"

```powershell
# Windows: Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Mac/Linux: Make executable
chmod +x ralph-jaws-v4.ps1
```

---

## Updating JAWS

```bash
cd /path/to/jaws-complete
git pull origin main

# Copy updated files to your projects as needed
```

---

## Next Steps

1. Read [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for the cheat sheet
2. Try the example in `examples/`
3. Create your first PRD
4. Run your first build!

---

*Need help? Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or open a GitHub issue.*
