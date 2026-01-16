# JAWS v3 COMPLETE SYSTEM - Master PRD

## Meta-Build: Using JAWS to Build JAWS

**What:** Build the complete JAWS v3 system with all brain dump features

**Who:** You (Janice) as the operator, business clients as end users

**Why:** Create a complete business automation system builder that delivers working systems + Owner's Manual + Knowledge Vault + Analytics Dashboard

**Success Metric:** Build a full client system in <2 hours with 100% documentation auto-generated

---

## Technical Context

**Stack:**
- Core: PowerShell (RALPH), Claude Code CLI
- Backend: n8n, Supabase
- Frontend: Lovable → Vercel
- MCP: n8n-mcp, Supabase MCP, Vercel MCP, GitHub MCP
- Documentation: Markdown → DOCX (via docx-js)

**Project Structure:**
```
jaws-v3/
├── ralph-jaws-v4.ps1          # Core harness (done)
├── PRD-TEMPLATE-v2.md         # Task format (done)
├── SKILL.md                   # Claude Code skill
├── prompts/                   # Agent prompts
│   ├── PRD-GENERATOR.md
│   ├── OWNER-MANUAL-GENERATOR.md
│   └── KNOWLEDGE-VAULT-GENERATOR.md
├── templates/                 # Output templates
│   ├── owner-manual/
│   ├── analytics/
│   └── client-presentation/
├── n8n-workflows/            # Supporting workflows
│   ├── analytics-tracker.json
│   └── changelog-generator.json
└── docs/                     # System documentation
```

---

## CRITICAL Rules

```
CRITICAL: All generated documentation must be in PLAIN ENGLISH - no jargon
CRITICAL: Every feature must work for NON-TECHNICAL business owners
CRITICAL: Client systems must be independently operable without JAWS creator
CRITICAL: All file paths must be relative, not absolute
CRITICAL: Test every workflow in n8n before marking complete
```

---

# PHASE 1: RALPH HARDENING

*Foundation improvements to make builds more reliable*

---

### US-101: Ralph Status Script

**FILES:** `ralph-status.ps1`

**ACTION:** 
Create a quick-check script that reads ralph-state.json and displays current build status in a human-readable format. Show: current task, % complete, time elapsed, completed tasks, skipped tasks.

**VERIFY:** Run `./ralph-status.ps1` in a project folder → displays formatted status table

**DONE:** One-command status check shows exactly where build is at

**Acceptance Criteria:**
- [ ] Reads ralph-state.json
- [ ] Shows current task and progress
- [ ] Shows completed/skipped counts
- [ ] Shows elapsed time
- [ ] Handles missing state file gracefully

---

### US-102: AGENTS.md Auto-Update

**FILES:** Update `ralph-jaws-v4.ps1`

**ACTION:** 
After each completed task, have RALPH automatically append a learning entry to AGENTS.md with: task ID, what was done, any patterns discovered, timestamp.

**VERIFY:** Complete a task → AGENTS.md has new entry with structured format

**DONE:** AGENTS.md grows automatically with learnings, searchable by task ID

**Acceptance Criteria:**
- [ ] Auto-append after task completion
- [ ] Structured format (task, pattern, timestamp)
- [ ] Doesn't duplicate entries
- [ ] Creates AGENTS.md if doesn't exist

---

### US-103: Progress Dashboard (Terminal)

**FILES:** `ralph-jaws-v4.ps1` (update)

**ACTION:** 
Add a visual progress bar to the iteration header. Show: [████████░░] 80% (8/10 criteria). Use ANSI colors for terminal display.

**VERIFY:** Run RALPH → iteration header shows visual progress bar

**DONE:** Each iteration displays visual progress indicator

**Acceptance Criteria:**
- [ ] Progress bar renders correctly
- [ ] Updates each iteration
- [ ] Shows fraction and percentage
- [ ] Uses colors (green for progress, gray for remaining)

---

# PHASE 2: PRD GENERATION SYSTEM

*Auto-generate PRDs from plain English input*

---

### US-201: Plain English → PRD Generator Prompt

**FILES:** `prompts/PRD-GENERATOR.md`

**ACTION:** 
Create a Claude Code prompt that takes a plain English business description and outputs a complete PRD in v2 format. Include: task breakdown, VERIFY/DONE fields, dependency mapping, CRITICAL rules extraction.

**VERIFY:** Feed "I need a system that captures leads from my website and sends them to my team" → outputs complete PRD with 4-6 tasks

**DONE:** Any plain English description produces a structured, actionable PRD

**Acceptance Criteria:**
- [ ] Accepts plain English input
- [ ] Outputs valid PRD v2 format
- [ ] Includes VERIFY and DONE for each task
- [ ] Maps dependencies correctly
- [ ] Extracts reasonable CRITICAL rules

---

### US-202: PRD Complexity Estimator

**FILES:** `prompts/PRD-GENERATOR.md` (update), `complexity-estimator.ps1`

**ACTION:** 
Add complexity estimation to PRD generator. Calculate: number of tasks, estimated hours, token budget, recommended model (haiku/sonnet/opus). Output as header in PRD.

**VERIFY:** Generate PRD → header includes "Estimated: 5 tasks, ~3 hours, sonnet recommended"

**DONE:** Every generated PRD includes complexity estimate

**Acceptance Criteria:**
- [ ] Counts tasks automatically
- [ ] Estimates hours based on task type
- [ ] Recommends model based on complexity
- [ ] Includes in PRD header

---

### US-203: Template Library - Lead Capture

**FILES:** `templates/prd/lead-capture.md`

**ACTION:** 
Create a pre-built PRD template for the common "lead capture" use case. Include: webhook receiver, Supabase storage, scoring logic, team routing, notifications. All VERIFY/DONE fields pre-filled.

**VERIFY:** Copy template → customize 3 fields → run RALPH → working lead system

**DONE:** Lead capture template reduces setup time to <5 minutes

**Acceptance Criteria:**
- [ ] Complete PRD with all tasks
- [ ] Clear customization points marked
- [ ] Works with RALPH out of the box
- [ ] Includes all VERIFY commands

---

### US-204: Template Library - Appointment Booking

**FILES:** `templates/prd/appointment-booking.md`

**ACTION:** 
Create pre-built PRD for appointment booking system. Include: calendar integration, availability check, confirmation emails, reminder sequence, rescheduling flow.

**VERIFY:** Copy template → customize → run RALPH → working booking system

**DONE:** Appointment booking template is production-ready

**Acceptance Criteria:**
- [ ] Complete PRD with all tasks
- [ ] Calendar integration documented
- [ ] Reminder sequence included
- [ ] Customization points marked

---

### US-205: Template Library - Support Ticket

**FILES:** `templates/prd/support-ticket.md`

**ACTION:** 
Create pre-built PRD for support ticket system. Include: intake form, categorization, priority scoring, assignment, status tracking, resolution workflow.

**VERIFY:** Copy template → customize → run RALPH → working ticket system

**DONE:** Support ticket template is production-ready

**Acceptance Criteria:**
- [ ] Complete PRD with all tasks
- [ ] Category system flexible
- [ ] Priority scoring included
- [ ] Status flow documented

---

# PHASE 3: OWNER'S MANUAL GENERATION

*Auto-generate business-friendly documentation*

---

### US-301: WHAT-YOU-HAVE.md Generator

**FILES:** `prompts/OWNER-MANUAL-GENERATOR.md`, `templates/owner-manual/WHAT-YOU-HAVE.md`

**ACTION:** 
Create prompt that reads completed PRD and generates plain-English explanation of what was built. Include: visual diagram (ASCII), component list with friendly names, one-sentence explanations.

**VERIFY:** Run on completed lead capture → outputs 1-page doc a business owner can understand

**DONE:** Non-technical person can read and understand their system in 5 minutes

**Acceptance Criteria:**
- [ ] Plain English only (no jargon)
- [ ] Includes visual diagram
- [ ] Component table with friendly names
- [ ] One-sentence purpose for each component

---

### US-302: HOW-IT-WORKS.md Generator

**FILES:** `prompts/OWNER-MANUAL-GENERATOR.md` (update), `templates/owner-manual/HOW-IT-WORKS.md`

**ACTION:** 
Generate step-by-step explanation of system flow. Write as "When X happens, then Y, then Z." Include numbered walkthrough of a typical transaction.

**VERIFY:** Generate for lead capture → explains full flow from form submit to team notification

**DONE:** Owner can trace a transaction through their system mentally

**Acceptance Criteria:**
- [ ] Step-by-step numbered flow
- [ ] "When/Then" language
- [ ] Covers happy path completely
- [ ] Mentions key decision points

---

### US-303: DAILY-OPERATIONS.md Generator

**FILES:** `prompts/OWNER-MANUAL-GENERATOR.md` (update), `templates/owner-manual/DAILY-OPERATIONS.md`

**ACTION:** 
Generate daily/weekly/monthly checklists for system operation. Include: what "normal" looks like, what to check, how often.

**VERIFY:** Generate for lead capture → includes "Check leads were assigned today" in daily checklist

**DONE:** Owner has concrete checklist to keep system healthy

**Acceptance Criteria:**
- [ ] Daily checklist (2-minute tasks)
- [ ] Weekly checklist (10-minute tasks)
- [ ] Monthly checklist (30-minute tasks)
- [ ] "What normal looks like" section

---

### US-304: WHEN-THINGS-BREAK.md Generator

**FILES:** `prompts/OWNER-MANUAL-GENERATOR.md` (update), `templates/owner-manual/WHEN-THINGS-BREAK.md`

**ACTION:** 
Generate troubleshooting guide with common issues and self-service fixes. Include: symptom → diagnosis → fix flowchart. Clear "when to call for help" criteria.

**VERIFY:** Generate for lead capture → includes "Emails not sending" with 3 checks before escalating

**DONE:** Owner can resolve 80% of issues without calling for help

**Acceptance Criteria:**
- [ ] Top 5 common issues covered
- [ ] Symptom-based diagnosis
- [ ] Self-service fix steps
- [ ] Clear escalation criteria

---

### US-305: MAKING-CHANGES.md Generator

**FILES:** `prompts/OWNER-MANUAL-GENERATOR.md` (update), `templates/owner-manual/MAKING-CHANGES.md`

**ACTION:** 
Generate guide for safe self-service changes. Two categories: "Changes You Can Make Yourself" (with steps) and "Changes That Need Help." Include specific examples.

**VERIFY:** Generate for lead capture → shows how to change notification email address (safe) vs add new routing rule (needs help)

**DONE:** Owner knows what they can touch and what requires support

**Acceptance Criteria:**
- [ ] Safe changes list with steps
- [ ] Risky changes list with warnings
- [ ] Specific examples for each category
- [ ] Request process for help

---

### US-306: COSTS.md Generator

**FILES:** `prompts/OWNER-MANUAL-GENERATOR.md` (update), `templates/owner-manual/COSTS.md`

**ACTION:** 
Generate cost breakdown and monitoring guide. Include: monthly cost estimate per service, what affects costs, how to set up billing alerts.

**VERIFY:** Generate for lead capture → shows n8n: $X, Supabase: $Y, total: $Z with alert instructions

**DONE:** Owner understands and can monitor their operating costs

**Acceptance Criteria:**
- [ ] Cost table by service
- [ ] Estimated monthly total
- [ ] Cost drivers explained
- [ ] Alert setup instructions

---

### US-307: HANDOVER-CHECKLIST.md Generator

**FILES:** `prompts/OWNER-MANUAL-GENERATOR.md` (update), `templates/owner-manual/HANDOVER-CHECKLIST.md`

**ACTION:** 
Generate comprehensive handover checklist. Include: access credentials needed, documentation delivered, support contacts, next steps.

**VERIFY:** Generate for any project → complete checklist ensures nothing missed at handover

**DONE:** Every handover is complete with nothing forgotten

**Acceptance Criteria:**
- [ ] Access checklist
- [ ] Credentials checklist
- [ ] Documentation checklist
- [ ] Support contacts section
- [ ] Next steps section

---

### US-308: Owner's Manual Compiler

**FILES:** `compile-owner-manual.ps1`

**ACTION:** 
Create script that runs all Owner's Manual generators and compiles into single DOCX file with table of contents, consistent formatting, client branding placeholder.

**VERIFY:** Run script → outputs `OwnerManual-[ProjectName].docx` with all 7 sections

**DONE:** One command generates complete, professional Owner's Manual

**Acceptance Criteria:**
- [ ] Runs all 7 generators
- [ ] Compiles to single DOCX
- [ ] Includes table of contents
- [ ] Has branding placeholder
- [ ] Professional formatting

---

# PHASE 4: ANALYTICS DASHBOARD

*Visual proof of what was built*

---

### US-401: Analytics Supabase Schema

**FILES:** `supabase/migrations/analytics_schema.sql`

**ACTION:** 
Create Supabase tables for analytics: builds (project_name, started_at, completed_at, tasks_count, etc.), tasks (build_id, task_id, status, duration, etc.), events (build_id, event_type, timestamp, data).

**VERIFY:** Run migration → tables exist with correct columns and RLS

**DONE:** Analytics data model ready for population

**Acceptance Criteria:**
- [ ] builds table created
- [ ] tasks table created
- [ ] events table created
- [ ] RLS enabled
- [ ] Indexes on common queries

---

### US-402: RALPH Analytics Integration

**FILES:** `ralph-jaws-v4.ps1` (update)

**ACTION:** 
Add analytics logging to RALPH. On build start: log to builds table. On task complete/skip/fail: log to tasks table. On checkpoint: log to events table.

**VERIFY:** Run RALPH build → Supabase tables have records for all events

**DONE:** Every RALPH action is tracked in analytics database

**Acceptance Criteria:**
- [ ] Build start logged
- [ ] Task completions logged
- [ ] Task failures logged
- [ ] Checkpoints logged
- [ ] Timestamps accurate

---

### US-403: n8n Analytics Trigger Workflow

**FILES:** `n8n-workflows/analytics-logger.json`

**ACTION:** 
Create n8n workflow that can receive analytics events via webhook and insert to Supabase. Backup method if direct Supabase MCP isn't available.

**VERIFY:** POST event to webhook → record appears in Supabase

**DONE:** Analytics can be logged via n8n as fallback

**Acceptance Criteria:**
- [ ] Webhook receives events
- [ ] Validates required fields
- [ ] Inserts to correct table
- [ ] Returns success/error

---

### US-404: Dashboard Frontend - Build Status View

**FILES:** `dashboard/src/pages/BuildStatus.tsx` (Lovable)

**ACTION:** 
Create dashboard page showing current/recent build status. Include: current task, progress bar, time elapsed, completed/failed/skipped counts.

**VERIFY:** View during active build → shows real-time progress

**DONE:** Can watch build progress visually

**Acceptance Criteria:**
- [ ] Shows current task
- [ ] Visual progress bar
- [ ] Task counts by status
- [ ] Auto-refreshes

---

### US-405: Dashboard Frontend - Project Overview

**FILES:** `dashboard/src/pages/ProjectOverview.tsx` (Lovable)

**ACTION:** 
Create dashboard page showing what was built for a project. Include: system diagram, component list, health status (green/red), recent activity.

**VERIFY:** View completed project → shows full system map with all components

**DONE:** Business owner can see "what they have" visually

**Acceptance Criteria:**
- [ ] System diagram
- [ ] Component list with status
- [ ] Health indicators
- [ ] Recent activity feed

---

### US-406: Dashboard Frontend - Cost Tracking

**FILES:** `dashboard/src/pages/CostTracking.tsx` (Lovable)

**ACTION:** 
Create dashboard page showing estimated costs. Include: cost by service, monthly trend, budget vs actual, alerts for spikes.

**VERIFY:** View project → shows $X total with breakdown

**DONE:** Costs are visible and trackable

**Acceptance Criteria:**
- [ ] Cost by service breakdown
- [ ] Monthly total
- [ ] Trend chart
- [ ] Alert indicators

---

### US-407: Dashboard Deployment

**FILES:** `vercel.json`, deployment scripts

**ACTION:** 
Deploy dashboard to Vercel. Configure environment variables for Supabase connection. Enable authentication (Supabase Auth).

**VERIFY:** Visit dashboard URL → prompted to login → shows projects

**DONE:** Dashboard is live and protected

**Acceptance Criteria:**
- [ ] Deployed to Vercel
- [ ] Environment vars configured
- [ ] Authentication working
- [ ] SSL enabled

---

# PHASE 5: KNOWLEDGE VAULT

*Queryable documentation for client self-service*

---

### US-501: Knowledge Vault Schema

**FILES:** `supabase/migrations/knowledge_vault_schema.sql`

**ACTION:** 
Create Supabase tables for knowledge vault: documents (project_id, doc_type, content, last_updated), sections (document_id, heading, content, embedding), queries (project_id, question, answer, created_at).

**VERIFY:** Run migration → tables exist with vector extension enabled

**DONE:** Knowledge Vault data model ready

**Acceptance Criteria:**
- [ ] documents table created
- [ ] sections table with embedding column
- [ ] queries table for history
- [ ] pgvector extension enabled

---

### US-502: Document Chunker

**FILES:** `knowledge-vault/chunker.js`

**ACTION:** 
Create script that takes Owner's Manual sections and chunks them for embedding. Split by heading, maintain context, output structured JSON.

**VERIFY:** Feed WHAT-YOU-HAVE.md → outputs chunks with headings preserved

**DONE:** Documents can be chunked for embedding

**Acceptance Criteria:**
- [ ] Splits by heading
- [ ] Preserves hierarchy
- [ ] Outputs structured JSON
- [ ] Handles all manual sections

---

### US-503: Embedding Generator

**FILES:** `knowledge-vault/embedder.js`

**ACTION:** 
Create script that takes chunks and generates embeddings via Claude/OpenAI API. Store embeddings in Supabase sections table.

**VERIFY:** Run on chunks → Supabase sections table has embedding vectors

**DONE:** All documentation is embedded and searchable

**Acceptance Criteria:**
- [ ] Generates embeddings
- [ ] Stores in Supabase
- [ ] Handles rate limits
- [ ] Batch processing

---

### US-504: Query Interface

**FILES:** `knowledge-vault/query.js`, n8n workflow

**ACTION:** 
Create query system that takes natural language question, finds relevant chunks via vector similarity, generates answer using context.

**VERIFY:** Ask "How do I change the notification email?" → returns answer from MAKING-CHANGES.md

**DONE:** Clients can ask questions in plain English

**Acceptance Criteria:**
- [ ] Accepts natural language
- [ ] Finds relevant chunks
- [ ] Generates contextual answer
- [ ] Logs query for improvement

---

### US-505: Knowledge Vault Chat UI

**FILES:** `dashboard/src/pages/KnowledgeVault.tsx` (Lovable)

**ACTION:** 
Add chat interface to dashboard for Knowledge Vault. Include: question input, conversation history, source citations, "was this helpful?" feedback.

**VERIFY:** Type question in chat → get answer with source link

**DONE:** Clients have self-service Q&A for their system

**Acceptance Criteria:**
- [ ] Chat input
- [ ] Answer display
- [ ] Source citations
- [ ] Feedback buttons
- [ ] History visible

---

### US-506: Auto-Update on System Change

**FILES:** `knowledge-vault/auto-update.js`, n8n trigger

**ACTION:** 
Create trigger that re-embeds documentation when system changes. Detect changes via RALPH completion, regenerate relevant sections, update embeddings.

**VERIFY:** RALPH completes build → Knowledge Vault updates automatically

**DONE:** Knowledge Vault stays current without manual intervention

**Acceptance Criteria:**
- [ ] Triggers on RALPH complete
- [ ] Regenerates changed docs
- [ ] Updates embeddings
- [ ] Logs update history

---

# PHASE 6: MCP INTEGRATION

*Direct building without manual steps*

---

### US-601: n8n MCP Workflow Builder

**FILES:** `mcp/n8n-builder.js`, updated RALPH prompt

**ACTION:** 
Integrate n8n MCP so RALPH can create/update workflows directly without exporting JSON. Add workflow CRUD operations to RALPH's capability.

**VERIFY:** RALPH creates n8n workflow → workflow appears in n8n UI without manual import

**DONE:** n8n workflows are built directly, no copy-paste

**Acceptance Criteria:**
- [ ] Create workflow via MCP
- [ ] Update workflow via MCP
- [ ] Test workflow via MCP
- [ ] Delete workflow via MCP

---

### US-602: Supabase MCP Schema Builder

**FILES:** `mcp/supabase-builder.js`, updated RALPH prompt

**ACTION:** 
Integrate Supabase MCP so RALPH can create tables, RLS policies, and functions directly. Add database CRUD to RALPH's capability.

**VERIFY:** RALPH creates table → table appears in Supabase without manual SQL

**DONE:** Database is built directly, no SQL copy-paste

**Acceptance Criteria:**
- [ ] Create table via MCP
- [ ] Set RLS via MCP
- [ ] Create function via MCP
- [ ] Query data via MCP

---

### US-603: Vercel MCP Deployment

**FILES:** `mcp/vercel-deployer.js`, updated RALPH prompt

**ACTION:** 
Integrate Vercel MCP so RALPH can deploy frontends directly. Add deployment operations to RALPH's capability.

**VERIFY:** RALPH deploys dashboard → live URL returned without manual deployment

**DONE:** Frontends deploy automatically

**Acceptance Criteria:**
- [ ] Deploy via MCP
- [ ] Get deployment URL
- [ ] Set environment vars
- [ ] Check deployment status

---

### US-604: GitHub MCP Version Control

**FILES:** `mcp/github-manager.js`, updated RALPH prompt

**ACTION:** 
Integrate GitHub MCP so RALPH can commit, branch, and manage repos directly. Complements git worktree feature.

**VERIFY:** RALPH completes task → commit appears in GitHub without manual push

**DONE:** Version control is fully automated

**Acceptance Criteria:**
- [ ] Commit via MCP
- [ ] Create branch via MCP
- [ ] Create PR via MCP
- [ ] Check CI status

---

# PHASE 7: PROJECTHUB

*Visual project management for non-technical users*

---

### US-701: ProjectHub Database Schema

**FILES:** `supabase/migrations/projecthub_schema.sql`

**ACTION:** 
Create Supabase tables for ProjectHub: projects (name, description, status, client_id), milestones (project_id, name, deadline), tasks (milestone_id, prd_link, status), clients (name, email, org).

**VERIFY:** Run migration → tables exist for full project management

**DONE:** ProjectHub data model ready

**Acceptance Criteria:**
- [ ] projects table
- [ ] milestones table
- [ ] tasks table
- [ ] clients table
- [ ] Relationships correct

---

### US-702: ProjectHub Dashboard - Project List

**FILES:** `projecthub/src/pages/Projects.tsx` (Lovable)

**ACTION:** 
Create dashboard showing all projects. Include: project cards with status, progress bar, last activity, client name.

**VERIFY:** View ProjectHub → see all projects with status at a glance

**DONE:** Bird's-eye view of all work

**Acceptance Criteria:**
- [ ] Project cards
- [ ] Status indicators
- [ ] Progress bars
- [ ] Filter/search

---

### US-703: ProjectHub Dashboard - Project Detail

**FILES:** `projecthub/src/pages/ProjectDetail.tsx` (Lovable)

**ACTION:** 
Create project detail page. Include: milestone timeline, task list with PRD links, build history, Owner's Manual link, Knowledge Vault link.

**VERIFY:** View project → see full breakdown with all links

**DONE:** Complete project view in one place

**Acceptance Criteria:**
- [ ] Milestone timeline
- [ ] Task list
- [ ] Build history
- [ ] Documentation links
- [ ] Client info

---

### US-704: ProjectHub - New Project Wizard

**FILES:** `projecthub/src/pages/NewProject.tsx` (Lovable)

**ACTION:** 
Create wizard for starting new projects. Steps: describe in plain English → review generated PRD → select template → configure → start build.

**VERIFY:** Walk through wizard → project created → RALPH can start

**DONE:** Non-technical users can initiate projects

**Acceptance Criteria:**
- [ ] Plain English input
- [ ] PRD preview
- [ ] Template selection
- [ ] Configuration step
- [ ] Build trigger

---

### US-705: ProjectHub - Client Portal

**FILES:** `projecthub/src/pages/ClientPortal.tsx` (Lovable)

**ACTION:** 
Create client-facing view. Show only: their projects, status, Owner's Manual, Knowledge Vault, support contact. Hide all technical details.

**VERIFY:** Client logs in → sees only their projects with friendly interface

**DONE:** Clients have their own dashboard

**Acceptance Criteria:**
- [ ] Client login
- [ ] Project list (theirs only)
- [ ] Documentation access
- [ ] Support contact
- [ ] No technical jargon

---

## Dependencies

```
PHASE 1 (RALPH) → All other phases

PHASE 2 (PRD Generator) → PHASE 3 (Owner's Manual needs PRD)

PHASE 3 (Owner's Manual) → PHASE 5 (Knowledge Vault embeds manual)

PHASE 4 (Analytics) → PHASE 7 (ProjectHub shows analytics)

PHASE 5 (Knowledge Vault) → PHASE 7 (ProjectHub links to vault)

PHASE 6 (MCP) → Independent, but improves all phases
```

---

## Build Order Recommendation

1. **Phase 1** (US-101 to US-103) - 3 tasks, ~2 hours
2. **Phase 2** (US-201 to US-205) - 5 tasks, ~4 hours
3. **Phase 3** (US-301 to US-308) - 8 tasks, ~6 hours
4. **Phase 4** (US-401 to US-407) - 7 tasks, ~8 hours
5. **Phase 5** (US-501 to US-506) - 6 tasks, ~6 hours
6. **Phase 6** (US-601 to US-604) - 4 tasks, ~4 hours
7. **Phase 7** (US-701 to US-705) - 5 tasks, ~8 hours

**Total: 38 tasks, ~38 hours estimated**

---

## How to Run This Build

```powershell
# Phase 1: RALPH Hardening
./ralph-jaws-v4.ps1 -PRDPath "jaws-master-prd.md" -MaxIterations 20 -AtomicCommits -UseWorktree

# Continue phases sequentially, or run parallel phases in separate worktrees
```

---

*This PRD uses JAWS to build JAWS. The meta-build that proves the system works.*

*Version: 1.0*
*Estimated Total Build Time: 38 hours over 2-3 weeks*
*Compatible with: RALPH-JAWS v4*
