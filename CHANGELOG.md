# Changelog

All notable changes to JAWS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [4.0.0] - 2026-01-16

### Added

#### RALPH Harness v4
- **Git Worktrees** (`-UseWorktree`) - Isolate builds in separate git branches, main branch never touched until merge
- **Atomic Commits** (`-AtomicCommits`) - Commit after each task with conventional commit format `feat(US-001): description`
- **Context Reset Protocol** (`-FreshContextMode`) - Automatically prompt for restart after N tasks to prevent quality degradation
- **Model Selection** (`-Model opus/sonnet/haiku`) - Choose Claude model per build for cost optimization
- **Changelog Generation** (`-GenerateChangelog`) - Auto-generate build summary markdown file
- **VERIFY/DONE field support** - Read and display verification commands from PRD

#### PRD Template v2
- New task format with explicit **FILES**, **ACTION**, **VERIFY**, **DONE** fields
- Example PRD included (lead capture system)
- Dependency mapping section
- CRITICAL rules section

#### Repository Structure
- Complete folder organization for templates, prompts, scripts, docs
- Template library structure for pre-built PRDs
- Owner's Manual template structure
- AGENTS.md pattern capture template
- progress.txt tracking template

#### Documentation
- README with full usage guide
- INSTALLATION.md with prerequisites and setup
- QUICK-REFERENCE.md cheat sheet
- Status check script (`ralph-status.ps1`)

#### Meta-Build
- JAWS-V3-MASTER-PRD.md - 38 tasks across 7 phases to build complete JAWS system using JAWS

### Changed
- Upgraded from v3 to v4 with GSD-inspired improvements
- Task verification now uses explicit VERIFY commands instead of just checkbox counting
- Prompt includes FILES and DONE fields for clearer agent guidance

### Inherited from v3
- Checkpoint system (human review gates)
- Rabbit hole detection (consecutive failure tracking)
- State persistence and resume capability
- Multi-level validation
- AutoPilot mode
- Documentation generation (`-GenerateDocs`)

---

## [3.0.0] - 2026-01-15

### Added
- Cole Medin harness concepts (checkpoints, rabbit hole detection)
- Rasmus Widing PRP system (multi-level validation, CRITICAL markers, git memory)
- State tracking with JSON persistence
- Resume capability from interrupted builds
- ai_docs context injection
- Token estimation

### Features
- Checkpoint system with human review
- Rabbit hole detection after N consecutive failures
- State file for resume
- AGENTS.md pattern capture
- progress.txt tracking
- Documentation generation

---

## [2.0.0] - 2026-01-10

### Added
- PRD-based task structure
- Autonomous loop execution
- Basic task verification (checkbox counting)

---

## [1.0.0] - 2026-01-05

### Added
- Initial RALPH concept
- Simple prompt-response loop
- Basic n8n workflow building

---

## Roadmap

### [4.1.0] - Planned
- [ ] Owner's Manual auto-generation (Phase 3 of Master PRD)
- [ ] PRD Generator from plain English (Phase 2)
- [ ] RALPH status web dashboard

### [4.2.0] - Planned  
- [ ] Analytics Dashboard (Phase 4)
- [ ] Knowledge Vault with embeddings (Phase 5)

### [5.0.0] - Planned
- [ ] MCP direct integration (Phase 6)
- [ ] ProjectHub UI (Phase 7)

---

*For full feature details, see the Master PRD: `JAWS-V3-MASTER-PRD.md`*
