# JAWS v4 Complete System

> **J**ust **A**nother **W**orkflow **S**ystem - The Business AI Automation Builder

Build production-ready business automation systems with AI. Walk away and come back to a working system with documentation.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         JAWS WORKFLOW                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   Plain English    →    PRD    →    RALPH    →    Working System   │
│   "I need..."           Tasks       Build         + Owner's Manual │
│                                                   + Analytics       │
│                                                   + Knowledge Vault │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## What Makes JAWS Different

| Other Tools | JAWS |
|-------------|------|
| Output: Code | Output: Complete business system |
| Docs: Technical | Docs: Plain English Owner's Manual |
| For: Developers | For: Business owners & consultants |
| Result: Dependency | Result: Independence |

## Quick Start

```powershell
# 1. Clone this repo
git clone https://github.com/YOUR-USERNAME/jaws-complete.git
cd jaws-complete

# 2. Copy to your project
cp ralph-jaws-v4.ps1 /path/to/your/project/
cp templates/prd/PRD-TEMPLATE-v2.md /path/to/your/project/PRD.md

# 3. Edit PRD.md with your tasks

# 4. Run RALPH
./ralph-jaws-v4.ps1 -PRDPath "PRD.md" -UseWorktree -AtomicCommits
```

## Repository Structure

```
jaws-complete/
├── README.md                    # You are here
├── CHANGELOG.md                 # Version history
├── ralph-jaws-v4.ps1           # 🔥 Main build harness
│
├── templates/
│   ├── prd/
│   │   ├── PRD-TEMPLATE-v2.md  # Task format with VERIFY/DONE
│   │   ├── lead-capture.md     # Pre-built: Lead capture system
│   │   ├── appointment.md      # Pre-built: Booking system
│   │   └── support-ticket.md   # Pre-built: Ticket system
│   │
│   └── owner-manual/           # Documentation templates
│       ├── WHAT-YOU-HAVE.md
│       ├── HOW-IT-WORKS.md
│       ├── DAILY-OPERATIONS.md
│       ├── WHEN-THINGS-BREAK.md
│       ├── MAKING-CHANGES.md
│       ├── COSTS.md
│       └── HANDOVER-CHECKLIST.md
│
├── prompts/                    # Agent prompts
│   ├── PRD-GENERATOR.md        # Plain English → PRD
│   ├── OWNER-MANUAL-GENERATOR.md
│   └── KNOWLEDGE-VAULT-GENERATOR.md
│
├── scripts/
│   ├── ralph-status.ps1        # Quick status check
│   ├── new-project.ps1         # Project scaffolding
│   └── compile-manual.ps1      # Owner's Manual compiler
│
├── n8n-workflows/              # Supporting workflows
│   ├── analytics-logger.json
│   └── changelog-generator.json
│
├── docs/
│   ├── INSTALLATION.md         # Setup guide
│   ├── QUICK-REFERENCE.md      # Cheat sheet
│   ├── OPERATIONS-GUIDE.md     # Session management
│   └── TROUBLESHOOTING.md      # Common issues
│
├── examples/
│   ├── lead-capture-complete/  # Finished example project
│   └── sample-owner-manual/    # Example documentation
│
├── ai_docs/                    # Context injection files
│   └── n8n-patterns.md         # Common n8n patterns
│
├── AGENTS.md                   # Project patterns (template)
├── progress.txt                # Progress tracking (template)
├── JAWS-V3-MASTER-PRD.md      # Meta-build: JAWS building JAWS
└── .gitignore
```

## Core Components

### 1. RALPH Harness (`ralph-jaws-v4.ps1`)

The autonomous build engine. Features:

| Feature | Flag | What It Does |
|---------|------|--------------|
| Git Worktrees | `-UseWorktree` | Isolates builds, main branch never touched |
| Atomic Commits | `-AtomicCommits` | Commits after each task completion |
| Context Reset | `-FreshContextMode` | Restarts after N tasks for quality |
| Model Selection | `-Model opus/sonnet/haiku` | Cost optimization |
| Checkpoints | `-CheckpointEvery N` | Human review gates |
| Rabbit Hole Detection | `-MaxConsecutiveFailures N` | Catches stuck loops |
| Auto Documentation | `-GenerateDocs` | Creates docs on completion |
| Changelog | `-GenerateChangelog` | Build summary |

### 2. PRD Template v2

Task format with explicit verification:

```markdown
### US-001: Task Name

**FILES:** `path/to/files`
**ACTION:** What to build
**VERIFY:** How to test it
**DONE:** When it's complete

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
```

### 3. Owner's Manual System

Auto-generated business documentation:

| Document | Purpose |
|----------|---------|
| WHAT-YOU-HAVE.md | System overview in plain English |
| HOW-IT-WORKS.md | Step-by-step flow explanation |
| DAILY-OPERATIONS.md | Checklists for daily/weekly/monthly |
| WHEN-THINGS-BREAK.md | Self-service troubleshooting |
| MAKING-CHANGES.md | Safe vs risky modifications |
| COSTS.md | Operating cost breakdown |
| HANDOVER-CHECKLIST.md | Complete handover verification |

## Usage Examples

### Basic Build
```powershell
./ralph-jaws-v4.ps1 -PRDPath "PRD.md"
```

### Full-Featured Build
```powershell
./ralph-jaws-v4.ps1 `
    -PRDPath "PRD.md" `
    -UseWorktree `
    -AtomicCommits `
    -GenerateChangelog `
    -CheckpointEvery 5 `
    -MaxIterations 30
```

### AutoPilot Mode (Walk Away)
```powershell
./ralph-jaws-v4.ps1 -PRDPath "PRD.md" -AutoPilot -UseWorktree
```

### Resume Interrupted Build
```powershell
./ralph-jaws-v4.ps1 -PRDPath "PRD.md"
# Automatically resumes from ralph-state.json
```

## Prerequisites

- **PowerShell 7+** (Windows/Mac/Linux)
- **Claude Code CLI** (`claude --version`)
- **Git** (for worktrees and commits)
- **Node.js 18+** (for n8n workflows)

## Installation

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for detailed setup.

Quick version:
```powershell
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Clone JAWS
git clone https://github.com/YOUR-USERNAME/jaws-complete.git

# Test
cd jaws-complete
./ralph-jaws-v4.ps1 -PRDPath "examples/simple-test.md" -MaxIterations 3
```

## Building JAWS with JAWS

This repo includes `JAWS-V3-MASTER-PRD.md` - a complete PRD for building all brain dump features using JAWS itself.

```powershell
# Meta-build: Use JAWS to extend JAWS
./ralph-jaws-v4.ps1 -PRDPath "JAWS-V3-MASTER-PRD.md" -UseWorktree -AtomicCommits
```

38 tasks across 7 phases:
1. RALPH Hardening
2. PRD Generation System
3. Owner's Manual Generation
4. Analytics Dashboard
5. Knowledge Vault
6. MCP Integration
7. ProjectHub

## Contributing

1. Fork this repo
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Use JAWS to build your feature (dogfooding!)
4. Push: `git push origin feature/amazing-feature`
5. Open PR

## Roadmap

- [x] RALPH v4 with GSD improvements
- [x] PRD Template v2 with VERIFY/DONE
- [ ] Owner's Manual auto-generation
- [ ] Analytics Dashboard
- [ ] Knowledge Vault
- [ ] MCP direct integration
- [ ] ProjectHub UI

## License

MIT - Use it, modify it, sell systems built with it.

## Credits

Built on the shoulders of:
- Cole Medin's harness concepts
- Rasmus Widing's PRP system
- GSD framework's context management
- Manual Auto-Claude's worktree patterns

---

**JAWS: Because business owners deserve working systems, not just code.**
