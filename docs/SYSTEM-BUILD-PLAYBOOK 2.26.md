# The System Build Playbook
## From Idea to Finished Product — A Definitive Guide

**Author:** Janice | **Version:** 2.0 | **Date:** February 2026

> **This is your reference document.** Every time you sit down to build something, start here. It maps your entire toolkit — JAWS, GSD, Claude Sub-agents, Claude Agent Teams, Manual Auto-Claude, n8n templates, and everything else — to a clear, repeatable process.

> **v2.0 Changes:** Integrated Cole Medin's contract-first agent team protocol, cross-cutting concerns checklist, lead-as-relay pattern, agent-level validation, and battle-tested integration anti-patterns.

---

## The Big Picture

Every complex system build follows this lifecycle:

```
+-------------------------------------------------------------------------+
|                    THE BUILD LIFECYCLE                                   |
|                                                                         |
|  PHASE 1        PHASE 2        PHASE 3         PHASE 4       PHASE 5   |
|  --------       --------       --------        --------      --------   |
|  DISCOVER       PLAN           BUILD           VERIFY        DELIVER    |
|                                                                         |
|  Idea ->        Architecture -> Code ->         Test ->       Deploy -> |
|  Research ->    PRD ->          Integrate ->     QA ->         Handoff   |
|  Validate       Contracts      Connect          Fix                     |
|                                                                         |
|  +------+      +------+      +--------------+ +------+     +------+    |
|  |Claude|      |Claude|      |Claude Code   | |JAWS  |     |Manual|    |
|  |Chat  |      |Chat +|      |Agent Teams + | |Test  |     |Review|    |
|  |+ Web |      |Sub-  |      |JAWS v6 +     | |Module|     |+     |    |
|  |Search|      |agents|      |GSD           | |      |     |Deploy|    |
|  +------+      +------+      +--------------+ +------+     +------+    |
|                                                                         |
|  TIME:          TIME:          TIME:           TIME:         TIME:      |
|  2-4 hours      4-8 hours      1-3 days        2-4 hours    2-4 hours  |
+-------------------------------------------------------------------------+
```

---

## Your Toolkit — When to Use What

Before diving into the phases, here's the decision matrix:

| Tool | What It Does | When to Use It | When NOT to Use It |
|------|-------------|----------------|-------------------|
| **Claude Chat (this interface)** | Research, planning, document creation, strategy | Idea validation, PRD writing, architecture decisions, competitive research | Actual code execution |
| **Claude Code (single agent)** | Code one thing at a time, sequential building | Simple features, bug fixes, single-file changes, learning new patterns | Complex multi-layer systems |
| **Claude Code Sub-agents** | Research within a codebase, analyze code, summarize | Pre-build codebase analysis, dependency mapping, code review | Building new code (use agent teams instead) |
| **Claude Code Agent Teams** | Parallel multi-agent code building via tmux | Multi-layer builds (DB + API + Frontend), complex features with clear contracts | Simple 1-2 file changes, exploratory work |
| **Agent Team Skill** | Structured agent team orchestration with contract-first protocol | Any agent team build — install in `~/.claude/skills/` | Solo Claude Code work, JAWS builds |
| **JAWS v5 (ralph-jaws-v5.ps1)** | Sequential PRD-driven automated building | Client projects, teaching demos, transparent builds, n8n workflow generation | When you need parallelism |
| **JAWS v6 (ralph-jaws-v6.ps1)** | Orchestrated parallel PRD-driven building | Your personal complex builds, multi-worker coordination | Client-facing work (too opaque), simple builds |
| **GSD / Manual Auto-Claude** | Structured multi-phase build with human checkpoints | When you want full control over each phase, learning a new architecture | When speed matters more than control |
| **n8n Template Library** | Pre-tested workflow patterns | Every n8n workflow build — always start from templates | Non-n8n work |
| **JAWS Testing Module** | Automated smoke/functional/edge testing | Before any production deployment | Quick prototypes |

### Subagents vs Agent Teams — Quick Decision

| | Subagents | Agent Teams |
|---|-----------|-------------|
| **Context** | Runs within main session | Each agent has its own session |
| **Communication** | Reports back to main agent only | Agents message each other directly |
| **Coordination** | Main agent manages all work | Shared task list, self-coordination via lead |
| **Visibility** | Results summarized to main context | Each agent visible in tmux pane |
| **Best for** | Quick, focused tasks (research, exploration) | Complex builds requiring collaboration |
| **Token cost** | Lower (results summarized) | Higher (2-4x, each agent is a separate instance) |

**Use subagents when:** task is quick and isolated, you only need the result, or you're cost-sensitive.

**Use agent teams when:** multiple components need to integrate, agents need to agree on interfaces, or you want to see parallel progress in real-time.

### The Decision Tree

```
"I have an idea for a system"
    |
    +-- Is it simple? (1-3 tasks, single layer)
    |   +-- YES -> Claude Code single agent + JAWS v5
    |
    +-- Is it moderate? (4-8 tasks, 2 layers)
    |   +-- YES -> Claude Code Agent Teams + JAWS v5
    |
    +-- Is it complex? (8+ tasks, 3+ layers, multiple integrations)
        +-- YES -> Full Playbook (all 5 phases below)
```

---

## PHASE 1: DISCOVER (2-4 hours)

**Goal:** Go from vague idea to validated concept with clear requirements.

**Tools:** Claude Chat, Web Search, possibly Claude Code Sub-agents for codebase analysis.

### Step 1.1: Articulate the Idea (30 min)

Start in Claude Chat with this prompt structure:

```
I want to build [SYSTEM NAME] for [WHO].

The core problem: [What pain point does this solve?]

What it needs to do (high level):
- [Capability 1]
- [Capability 2]
- [Capability 3]

Who will use it: [End users]
How they'll access it: [Web app / mobile / API / workflow]

My tech stack: Supabase (database), n8n (workflows), 
Next.js or React (frontend), Claude API (AI features)

Help me think through:
1. Is this a valuable thing to build? What's the market/need?
2. What are the major components this system needs?
3. What are the risks or gotchas I should know about?
4. What's the simplest version I could build first (MVP)?
```

**Example for Empire Mortgage:**
```
I want to build a mortgage tools platform for Empire Mortgage.

The core problem: Loan officers waste time on manual calculations, 
paper forms, and disconnected systems.

What it needs to do:
- Mortgage calculators (payment, qualification, refinance)
- Digital intake forms for loan applications
- Secure document upload and storage
- Automated workflows for lead nurturing
- Dashboard for loan officers to track pipeline

Who: Individual loan officers at Empire Mortgage
Access: Web app with secure login

Help me think through the viability, components, risks, and MVP.
```

### Step 1.2: Competitive and Market Research (1-2 hours)

Use Claude Chat with web search to validate:

```
Search for and analyze:
1. Existing mortgage calculator tools - what features do they have?
2. Loan officer productivity tools - what's already out there?
3. Compliance requirements for mortgage data handling
4. What loan officers actually complain about (forums, Reddit, reviews)

Give me a competitive landscape summary with:
- Top 3 competitors and their strengths/weaknesses
- Features that are table stakes vs. differentiators
- Compliance requirements I MUST handle
- Gaps in the market my system could fill
```

### Step 1.3: Define the MVP Scope (30 min)

Based on research, narrow to what you'll actually build first:

```
Based on our research, help me define an MVP scope.

Rules for MVP:
- Must be buildable in 1-2 weeks
- Must deliver immediate value to loan officers
- Must handle security/compliance basics
- Should demonstrate the platform's potential

Give me:
1. The 3-5 features in the MVP (not the full vision)
2. What we're explicitly LEAVING OUT for now
3. The user journey for the MVP
4. Success criteria - how we know it works
```

**OUTPUT FROM PHASE 1:** A clear, validated concept with defined MVP scope. Save this as `DISCOVERY.md` in your project folder.

---

## PHASE 2: PLAN (4-8 hours)

**Goal:** Turn the validated concept into a buildable architecture with a detailed PRD.

**Tools:** Claude Chat for architecture + PRD, Claude Code Sub-agents for codebase analysis (if extending existing code).

### Step 2.1: System Architecture (1-2 hours)

This is where you make the big decisions. Use Claude Chat:

```
I'm ready to architect [SYSTEM NAME]. Here's my validated concept:
[Paste DISCOVERY.md]

My tech stack:
- Database: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- Workflows: n8n (automation, integrations, webhook handling)
- Frontend: [Next.js / React / whatever you're using]
- AI: Claude API via n8n or direct
- Hosting: [Vercel / your preference]

Design the architecture:

1. DATABASE LAYER
   - What tables do I need? (with columns, types, relationships)
   - What RLS policies? (who can see what)
   - What indexes for performance?

2. API / BACKEND LAYER  
   - What Edge Functions or API routes?
   - What webhook endpoints?
   - Authentication flow?

3. WORKFLOW LAYER (n8n)
   - What workflows do I need?
   - What triggers each one?
   - What external services do they connect to?

4. FRONTEND LAYER
   - What pages/screens?
   - What components?
   - What state management approach?

5. SECURITY LAYER
   - Auth method (Supabase Auth, OAuth, etc.)
   - Data encryption needs
   - HIPAA/compliance requirements (if applicable)

Output this as a structured architecture document with a 
Mermaid diagram showing how the layers connect.
```

**Example architecture output for Empire Mortgage:**
```
Database: Supabase
  tables: users, loan_officers, leads, applications, 
          documents, calculations, audit_log
  RLS: loan officers see only their leads/applications
  Storage: document bucket with RLS
  Auth: email/password + MFA for loan officers

Workflows: n8n  
  lead-intake: webhook -> validate -> save to DB -> notify LO
  document-processor: upload trigger -> classify -> store -> notify
  nurture-sequence: schedule -> check leads -> send emails
  calculator-logger: webhook -> log calculation -> analytics

Frontend: Next.js on Vercel
  /login - authentication
  /dashboard - pipeline overview
  /calculators - mortgage tools
  /leads - lead management
  /applications - loan applications
  /documents - secure document portal

Security:
  Supabase Auth with MFA
  RLS on all tables
  Encrypted document storage
  Audit logging on sensitive operations
```

### Step 2.2: Create the PRD (2-4 hours)

This is the most critical document. Use Claude Chat:

```
Now create a detailed PRD for this system. 

CRITICAL FORMAT - each task MUST have:

### US-XXX: Task Name

**TYPE:** [database / workflow / frontend / backend / integration]
**FILES:** [specific files to create/modify]
**DEPENDS:** [US-XXX or empty if independent]
**VERIFY:** [specific test to prove it works]
**DONE:** [definition of done]

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
- [ ] Acceptance criterion 3

RULES FOR TASK ORDERING:
1. Database/schema tasks FIRST (everything depends on data)
2. API/backend tasks SECOND (frontend needs endpoints)
3. Workflow tasks can parallel with frontend
4. Frontend tasks THIRD (consumes APIs)
5. Integration/polish tasks LAST

RULES FOR TASK SIZING:
- Each task should take 1-3 Claude iterations to complete
- If a task has more than 5 acceptance criteria, split it
- Each task should produce a testable output

RULES FOR DEPENDENCIES:
- Mark explicit dependencies with DEPENDS field
- Database tasks have no dependencies (they go first)
- Be conservative — if unsure, add the dependency

Create the PRD with [X] tasks covering the full MVP.
```

### Step 2.3: Define Contracts Between Layers (1 hour)

**This is the #1 factor in whether agent teams succeed or fail.** Contracts are not optional documentation — they are the enforcement mechanism that prevents integration failures. Agents that build in parallel WILL diverge on interfaces (endpoint URLs, response shapes, trailing slashes, data storage semantics) unless they agree on contracts FIRST.

```
For each boundary between layers, define the contract:

1. DATABASE -> API CONTRACT
   - Table schemas (exact column names and types)
   - RLS policy behavior
   - Expected query patterns
   - Function signatures for all CRUD operations

2. API -> FRONTEND CONTRACT
   - Exact endpoint URLs WITH trailing slash notation
     (e.g., POST /api/sessions/ vs GET /api/sessions/{id})
   - Exact request body JSON shapes
   - Exact response JSON shapes (including envelope wrappers)
   - Auth header requirements
   - Error response format with specific status codes
   - SSE/streaming event types with exact JSON per type (if applicable)

3. WORKFLOW -> DATABASE CONTRACT
   - What data workflows read/write
   - Webhook payload formats
   - Expected Supabase operations

4. WORKFLOW -> EXTERNAL CONTRACT
   - External API endpoints and auth
   - Webhook payload formats in/out
   - Rate limits and retry policies

Output these as a CONTRACTS.md file I can give to each 
build agent so they build compatible interfaces.
```

**Contract Verification Checklist — use this EVERY time before approving a contract:**

```
[ ] Are URLs exact, including trailing slashes?
    (e.g., POST /api/sessions/ vs POST /api/sessions)
[ ] Are request/response JSON shapes explicit with field names and types?
    (e.g., {"session": {...}, "messages": [...]} NOT "returns session with messages")
[ ] Are all status codes specified for success AND error cases?
    (200, 201, 204, 400, 404, 422, 500 — what does each return?)
[ ] Are SSE/streaming event types documented with exact JSON per type?
[ ] Are error response bodies specified? (404 body shape, 422 body shape, etc.)
[ ] Are envelope wrappers documented?
    (Flat object vs nested like {"data": {...}} — both sides MUST agree)
[ ] Is data accumulation vs per-item storage clarified?
    (e.g., stream chunks stored as one DB row or many?)
```

**EXAMPLE — What a precise API contract looks like:**

```
| Method | Endpoint (exact)          | Request Body                    | Response             |
|--------|---------------------------|---------------------------------|----------------------|
| POST   | /api/sessions/            | {"title":"...","model?":"..."}  | SessionResponse(200) |
| GET    | /api/sessions/            | -                               | SessionResponse[](200)|
| GET    | /api/sessions/{id}        | -                               | {"session": SessionResponse, "messages": MessageResponse[]} (200) or 404 |
| POST   | /api/sessions/{id}/chat   | {"message": "..."}              | SSE stream           |
| DELETE | /api/sessions/{id}        | -                               | 204 No Content       |

Note: POST and GET list endpoints use trailing slash.
GET by ID, DELETE, and chat do NOT use trailing slash.
```

### Step 2.3b: Identify Cross-Cutting Concerns (30 min)

**This step prevents the #1 cause of integration failures.** Cross-cutting concerns are behaviors that span multiple layers but get assigned to nobody unless you explicitly call them out. They WILL fall through the cracks.

```
Review the architecture and identify cross-cutting concerns.

For each concern, assign ONE owner and specify who they 
must coordinate with:
```

**Common Cross-Cutting Concerns Checklist:**

| Concern | Typical Owner | Coordinates With | Why It Matters |
|---------|--------------|-----------------|----------------|
| Streaming data storage | Backend | Frontend | If backend stores each chunk as a separate DB row, frontend renders N bubbles on page reload. Accumulate into one row. |
| URL conventions (trailing slashes) | Backend | Frontend | /api/sessions/ vs /api/sessions — one character causes 404s |
| Response envelopes (flat vs nested) | Backend | Frontend | `{id, title}` vs `{"session": {id, title}}` — frontend destructuring breaks |
| Error shapes and status codes | Backend | Frontend | Frontend needs to know exact error body format to show messages |
| Auth token handling | Backend | Frontend | Where token lives, how it refreshes, what header name |
| SSE/WebSocket event format | Backend | Frontend | Exact event type names and JSON per event |
| File upload size limits | Backend + Workflow | Frontend | Frontend validation must match server limits |
| Timezone handling | Database | All layers | UTC in DB, local in UI — who converts? |
| Pagination format | Backend | Frontend | Cursor vs offset, response shape for paginated lists |
| Rate limiting behavior | Backend | Frontend | What status code, what retry-after header |
| Hidden UI elements | Frontend | Testing | CSS `opacity-0` on interactive elements breaks automation. Add aria-labels. |

**Add the cross-cutting concern assignments to CONTRACTS.md.**

### Step 2.4: Set Up the Project Infrastructure (30 min)

Before building, get the foundation in place:

```bash
# 1. Create project directory
mkdir empire-mortgage && cd empire-mortgage
git init

# 2. Create project structure
mkdir -p supabase/migrations
mkdir -p workflows
mkdir -p src/components src/pages src/lib
mkdir -p docs
mkdir -p specs

# 3. Save your planning documents
# Copy DISCOVERY.md, PRD.md, CONTRACTS.md, ARCHITECTURE.md to docs/

# 4. Create CLAUDE.md (copy from your JAWS project, customize)
# This tells Claude Code how to build n8n workflows correctly

# 5. Create AGENTS.md (project patterns file)
echo "# Project Patterns\n\n## Discovered patterns go here" > AGENTS.md

# 6. Create progress.txt
echo "# Build Progress\n" > progress.txt

# 7. Initial commit
git add -A && git commit -m "Initial project setup with architecture and PRD"
```

**OUTPUT FROM PHASE 2:** 
- `PRD.md` — detailed, numbered tasks with dependencies
- `CONTRACTS.md` — interface definitions between layers + cross-cutting concern assignments
- `ARCHITECTURE.md` — system design with diagrams
- `CLAUDE.md` — build instructions for Claude Code agents
- Project directory structure ready to go

---

## PHASE 3: BUILD (1-3 days)

**Goal:** Execute the PRD and produce working code.

**This is where you choose your build strategy based on complexity.**

### Build Strategy Decision

```
How many tasks in your PRD?
    |
    +-- 1-5 tasks -> STRATEGY A: Sequential (JAWS v5 or Claude Code solo)
    |
    +-- 6-12 tasks -> STRATEGY B: Orchestrated (JAWS v6 or Agent Teams)  
    |
    +-- 13+ tasks -> STRATEGY C: Phased Parallel (combine everything)
```

---

### STRATEGY A: Sequential Build (Simple Systems)

**When:** 1-5 tasks, single developer, straightforward.

**Tool:** JAWS v5 or Claude Code with your PRD.

```powershell
# Option 1: JAWS v5 (automated, PRD-driven)
.\ralph-jaws-v5.ps1 `
  -PRDPath "PRD.md" `
  -MaxIterations 15 `
  -CheckpointEvery 3 `
  -EnableLearnings `
  -AtomicCommits `
  -GenerateChangelog

# Option 2: Claude Code manual (more control)
cd empire-mortgage
claude
# Then paste your task: "Read PRD.md, complete US-001"
```

**Your role:** Monitor, intervene at checkpoints, review output.

---

### STRATEGY B: Orchestrated Parallel Build (Medium Systems)

**When:** 6-12 tasks, clear layer separation, you want speed.

**Tool:** JAWS v6 OR Claude Code Agent Teams.

#### Option B1: JAWS v6

```powershell
# First, see the plan without executing
.\ralph-jaws-v6.ps1 -DryRun -MaxWorkers 3

# If the plan looks right, execute
.\ralph-jaws-v6.ps1 `
  -PRDPath "PRD.md" `
  -MaxWorkers 3 `
  -UseWorktree `
  -PlanGuardian `
  -AImergeResolution `
  -EnableLearnings `
  -EvidenceBasedQA `
  -AtomicCommits `
  -GenerateChangelog
```

**What JAWS v6 does automatically:**
1. Reads your PRD
2. Builds a dependency graph
3. Groups tasks into execution waves
4. Spawns workers in isolated git worktrees
5. Coordinates execution order
6. Merges all branches
7. Runs Plan Guardian verification

#### Option B2: Claude Code Agent Teams (Contract-First Protocol)

**This is the battle-tested approach from Cole Medin's agent team methodology.** The critical insight: agents that build in parallel WILL diverge on interfaces unless the lead enforces a contract-first, build-second protocol.

**Prerequisites:**
```bash
# 1. Install tmux (required for agent teams)
brew install tmux          # macOS
sudo apt install tmux      # Linux

# 2. Enable agent teams (experimental feature)
# Add to ~/.claude/settings.json:
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}

# 3. Install the agent team skill (optional but recommended)
cp -r build-with-agent-team ~/.claude/skills/
```

**If using the skill:**
```bash
/build-with-agent-team ./docs/PRD.md 3
```

**If prompting manually, follow this exact protocol:**

**STEP 1: Map the Contract Chain**

Before spawning any agents, identify the dependency chain:

```
Database -> publishes function signatures -> Backend
Backend -> publishes API contract -> Frontend
```

Agents UPSTREAM must publish their contract BEFORE downstream agents start building. Spawning is STAGGERED, not fully parallel.

**STEP 2: Spawn Upstream Agents First**

Enter Delegate Mode (Shift+Tab) — you coordinate, you do NOT code.

Spawn the database agent first:

```
You are the DATABASE agent for this build.

## Your Ownership
- You own: supabase/migrations/, src/lib/database.ts
- Do NOT touch: src/components/, src/pages/, workflows/

## What You're Building
[Paste database tasks from PRD]

## Mandatory Communication (REQUIRED)
Your FIRST deliverable is your schema and function signatures.
Send them to the lead via SendMessage BEFORE writing implementation.
Include: exact table schemas, exact function signatures, data types.
Wait for the lead to confirm before proceeding.

## Cross-Cutting Concerns You Own
[List from CONTRACTS.md cross-cutting section]

## Validation Before Reporting Done
1. Schema creates without errors
2. CRUD operations work (create, read, update, delete)
3. Foreign keys and cascades behave correctly
4. Indexes exist for common queries
Do NOT report done until all validations pass.
```

**STEP 3: Receive, Verify, and Forward Contracts (Lead as Active Relay)**

**CRITICAL: Do NOT just tell agents "share your contract with the other agent."** This fails because the upstream agent may finish and share too late, or the downstream agent may already be building with wrong assumptions.

Instead, YOU (the lead) must:

1. **Receive** the contract from the producing agent
2. **Verify** it against the contract verification checklist:
   - Are URLs exact, including trailing slashes?
   - Are JSON response shapes explicit (not "returns session with messages")?
   - Are all status codes specified?
   - Are SSE event types documented with exact JSON?
   - Are error responses specified?
   - Are envelope wrappers clarified?
3. **Forward** the verified contract to consuming agents with: "Build to this contract exactly. Do not deviate."

**STEP 4: Spawn Downstream Agents with Verified Contracts**

Only after receiving and verifying the database contract, spawn the backend agent:

```
You are the BACKEND agent for this build.

## Your Ownership
- You own: src/api/, backend/
- Do NOT touch: src/components/, supabase/migrations/

## The Contract You Must Conform To (from Database Agent)
[Paste the VERIFIED database contract here]

## What You're Building
[Paste backend tasks from PRD]

## Mandatory Communication (REQUIRED)
Your FIRST deliverable is your complete API contract.
Send it to the lead via SendMessage BEFORE writing implementation.
Include: exact URLs (with trailing slashes), exact request/response 
JSON shapes, status codes, SSE event formats.
Wait for the lead to confirm before proceeding.

## Cross-Cutting Concerns You Own
- Text chunk accumulation: accumulate streamed chunks into ONE DB row
- URL trailing slashes: document which endpoints use them
- Response envelope format: document flat vs nested shapes
[Others from CONTRACTS.md]

## Validation Before Reporting Done
1. Server starts without errors
2. All API endpoints respond correctly (provide curl commands)
3. Request/response formats match the verified contract
4. Error cases return proper status codes
5. SSE streaming works (if applicable)
Do NOT report done until all validations pass.
```

Then, after receiving and verifying the backend API contract, spawn the frontend agent with the verified API contract included in the prompt.

**STEP 5: Pre-Completion Contract Diff**

Before any agent reports "done," run a contract diff:

```
"Backend: what exact curl commands test each endpoint?"
"Frontend: what exact fetch URLs are you calling with what request bodies?"
```

Compare them. Flag mismatches BEFORE integration testing.

**STEP 6: Cross-Review**

After all agents complete:
- Frontend reviews Backend API usability
- Backend reviews Database query patterns
- Database reviews Frontend data access patterns

**Agent Team Anti-Patterns (Avoid These):**

| Anti-Pattern | What Happens | Do This Instead |
|-------------|-------------|----------------|
| Fully parallel spawn | All agents start simultaneously, build to own assumptions, integration fails | Spawn upstream first, get contracts, then spawn downstream |
| Late contract sharing | Backend finishes, sends contract, frontend already built with wrong URLs | Contract-first: publish contract BEFORE implementation |
| "Tell them to talk" | Lead tells backend "share your contract with frontend" — they won't reliably | Lead as active relay: receive, verify, forward |
| Vague contracts | "The API returns sessions" — ambiguous | Require exact JSON shapes, URLs with trailing slashes, status codes |
| Per-chunk storage | Backend stores each streamed text chunk as a separate DB row | Frontend renders N bubbles on reload. Accumulate chunks into single rows |
| Orphaned cross-cutting concerns | Nobody owns streaming storage, URL conventions, error shapes | Explicitly assign each concern to ONE agent |
| Hidden UI elements | CSS `opacity-0` on interactive elements | Invisible to automation. Add aria-labels, ensure keyboard/focus visibility |
| Lead over-implementing | You start coding instead of coordinating | Stay in Delegate Mode (Shift+Tab) |

**Your role:** You are the LEAD. You receive contracts, verify them, forward them, track blockers, and run end-to-end validation. You do NOT write code.

---

### STRATEGY C: Phased Parallel Build (Complex Systems)

**When:** 13+ tasks, multiple integration points, like Empire Mortgage.

**This is the full orchestration approach.** You break the build into phases, using different tools for each phase. The contract-first protocol from Strategy B2 applies at every phase boundary.

#### Phase 3a: Foundation (Database + Auth)

**Tool:** Claude Code single agent or JAWS v5. This MUST be sequential and correct — everything depends on it.

```
TASK: Complete all database tasks from the PRD.

Read PRD.md and complete ONLY the database/schema tasks 
(US-001 through US-00X).

For each task:
1. Create the Supabase migration SQL
2. Include RLS policies
3. Include indexes
4. Verify the migration is valid SQL

After ALL database tasks are complete:
- Create a DATABASE-CONTRACTS.md documenting:
  * All tables with exact column names and types
  * All relationships and foreign keys
  * All function signatures for CRUD operations
  * All RLS policy behaviors
- This becomes the source of truth for all other agents

VALIDATION before proceeding:
- Schema creates without errors
- CRUD operations work
- Foreign keys and cascades behave correctly
- Indexes exist for common queries
```

**Verify before proceeding:** Connect to Supabase, run the migrations, confirm tables exist.

#### Phase 3b: Middle Layer (API + Workflows in parallel)

**Tool:** Claude Code Agent Teams OR two JAWS v5 instances in separate worktrees.

**Follow the contract-first protocol:** The API agent must publish its API contract (exact URLs, response shapes, status codes, SSE event formats) to the lead BEFORE the frontend agent starts. The lead verifies it against the checklist and forwards it.

```bash
# Option 1: Two JAWS worktrees
git worktree add .worktrees/api -b build/api-layer
git worktree add .worktrees/workflows -b build/workflow-layer

# Terminal 1: API tasks
cd .worktrees/api
# Run JAWS v5 with only API tasks

# Terminal 2: Workflow tasks  
cd .worktrees/workflows
# Run JAWS v5 with only workflow tasks
```

```
# Option 2: Claude Code Agent Teams
Build the middle layer using agent teams:

- Agent 1 (API): Complete US-004 through US-006 (API routes, 
  Edge Functions). Reference DATABASE-CONTRACTS.md for schemas.
  FIRST TASK: Publish complete API contract to lead.
  
- Agent 2 (Workflows): Complete US-007 through US-009 (n8n workflows).
  Follow CLAUDE.md patterns exactly. Reference DATABASE-CONTRACTS.md
  for Supabase operations.

These agents can work in parallel because they don't touch 
the same files. APIs go in src/api/, workflows go in workflows/.

BEFORE starting frontend: Lead verifies API contract against 
the contract verification checklist and forwards to frontend agent.
```

**Verify before proceeding:** Test each API endpoint with curl, import and test each n8n workflow.

#### Phase 3c: Frontend

**Tool:** Claude Code Agent Teams (one agent per major feature area) or single agent if frontend is straightforward.

```
Build the frontend layer.

Reference:
- CONTRACTS.md for the VERIFIED API contract (exact URLs, response shapes)
- DATABASE-CONTRACTS.md for data shapes
- PRD.md tasks US-010 through US-015

CRITICAL: Build to the verified API contract exactly. 
Do NOT guess endpoint URLs or response shapes.

Build order:
1. Auth pages (login, register, MFA)
2. Layout and navigation
3. Dashboard
4. Feature pages (calculators, leads, etc.)
5. Document upload/management

VALIDATION before reporting done:
1. TypeScript compiles (tsc --noEmit)
2. Build succeeds (npm run build)
3. Dev server starts
4. Components render without console errors
```

#### Phase 3d: Integration and Polish

**Tool:** Claude Code single agent. This is surgical work.

**Run a contract diff FIRST:**
```
Before integration, compare:
- Backend's actual curl commands for each endpoint
- Frontend's actual fetch URLs and request bodies
Flag any mismatches and fix them before connecting layers.
```

```
All layers are built. Now integrate and polish:

1. Connect frontend to real API endpoints (replace mocks)
2. Connect n8n workflows to real Supabase instance
3. Test the full user journey end-to-end
4. Fix any interface mismatches between layers
5. Add error handling for edge cases
6. Add loading states and user feedback
```

### Build Phase Best Practices

Regardless of which strategy you use:

**Before each build session:**
```
1. Read PROJECT-STATE.json or progress.txt (where did I leave off?)
2. Read AGENTS.md (what patterns have I discovered?)
3. Check git status (am I on the right branch?)
4. Set a clear goal: "This session I will complete US-004 and US-005"
```

**During building:**
```
1. Build incrementally — don't try to build 10 things at once
2. Test each component before moving to the next
3. Commit after each completed task (atomic commits)
4. Update progress.txt with what you did and learned
5. Update AGENTS.md when you discover reusable patterns
```

**After each build session:**
```
1. Commit all changes
2. Update PROJECT-STATE.json / progress.txt
3. Note any blockers or decisions for next session
4. Verify the build still works (no regressions)
```

**For n8n workflows specifically:**
```
1. ALWAYS start from n8n template library templates
2. NEVER let Claude invent node structures from scratch
3. Validate JSON before importing
4. Test webhook endpoints with curl before marking done
5. Verify every expression starts with = 
6. Confirm all IF branches connect to appropriate outputs
```

---

## PHASE 4: VERIFY (2-4 hours)

**Goal:** Prove the system works before delivery.

**Tools:** Agent-level validation, contract diff, JAWS Testing Module, Plan Guardian, manual testing.

### Step 4.0: Agent-Level Validation (If Agent Teams Were Used)

**Before proceeding to system-level testing, each agent must validate their own domain.** This catches 80% of bugs before integration.

```
AGENT VALIDATION PROTOCOL

Each agent validates before reporting "done":

DATABASE AGENT:
  [ ] Schema creates without errors
  [ ] CRUD operations work (create, read, update, delete)
  [ ] Foreign keys and cascades behave correctly
  [ ] Indexes exist for common queries
  [ ] Provide validation commands that prove it works

BACKEND AGENT:
  [ ] Server starts without errors
  [ ] All API endpoints respond correctly
  [ ] Request/response formats match the verified contract
  [ ] Error cases return proper status codes
  [ ] SSE streaming works (if applicable)
  [ ] Provide exact curl commands that test each endpoint

FRONTEND AGENT:
  [ ] TypeScript compiles (tsc --noEmit)
  [ ] Build succeeds (npm run build)
  [ ] Dev server starts
  [ ] Components render without console errors
  [ ] Responsive layout works at different widths

WORKFLOW AGENT (n8n):
  [ ] Workflows import without errors
  [ ] Webhook endpoints respond to curl tests
  [ ] Expressions evaluate correctly
  [ ] All branches connect to appropriate outputs
```

### Step 4.0b: Pre-Integration Contract Diff (If Agent Teams Were Used)

**Before running integration tests, verify that what was built matches what was contracted:**

```
LEAD runs contract diff:

1. "Backend: what exact curl commands test each endpoint?"
2. "Frontend: what exact fetch URLs are you calling with what request bodies?"
3. Compare backend's actual implementation vs frontend's actual calls
4. Flag mismatches — fix BEFORE integration testing

Common mismatches to catch:
- Trailing slashes: backend uses /api/sessions/ but frontend calls /api/sessions
- Response envelopes: backend returns {session:{...}} but frontend expects flat {id, title}
- Status codes: backend returns 204 but frontend checks for 200
- SSE event names: backend sends "text_delta" but frontend listens for "text"
```

### Step 4.1: Generate Test Manifest

```powershell
# Auto-generate tests from your PRD
.\jaws-testing-module-v5.ps1
New-TestManifest -PRDPath "PRD.md" -OutputPath "TEST-MANIFEST.md"
```

This creates a test manifest with:
- Level 1: Smoke tests (does it run?)
- Level 2: Functional tests (does it work?)
- Level 3: Edge case tests (does it handle problems?)

### Step 4.2: Run Automated Tests

```powershell
# Run all levels
Invoke-JAWSTests -Level "all"

# Or just smoke tests for a quick check
Invoke-JAWSTests -Level "smoke"
```

### Step 4.3: Run Plan Guardian (Fresh-Context QA)

This is your secret weapon. A fresh Claude instance reviews what was built against what was requested — with zero knowledge of how it was built:

```powershell
# If using JAWS v6
.\ralph-jaws-v6.ps1 -PlanGuardian

# Or manually in Claude Code
claude -p "You are the Plan Guardian. You have NO knowledge of how 
this was built. Read PRD.md and compare against the actual code. 
For each task marked complete, find evidence in the code that it 
was actually implemented. Output a verification report."
```

### Step 4.4: End-to-End Validation (Lead-Level)

**After all agents report done AND contract diffs are clean, the lead runs full E2E:**

```
END-TO-END VALIDATION CHECKLIST

1. Can the system START?
   [ ] Start all services (database, backend, frontend)
   [ ] No startup errors in any terminal

2. Does the HAPPY PATH work?
   [ ] Walk through the primary user flow
   [ ] Each step produces expected results

3. Do INTEGRATIONS connect?
   [ ] Frontend successfully calls backend
   [ ] Backend successfully queries database
   [ ] Workflows trigger and complete correctly
   [ ] Data flows correctly through all layers

4. Are EDGE CASES handled?
   [ ] Empty states render correctly
   [ ] Error states display user-friendly messages
   [ ] Loading states appear during async operations
   [ ] Invalid inputs are rejected gracefully

If validation fails:
- Identify which agent's domain contains the bug
- Re-spawn that agent with the specific issue
- Re-run validation after fix
```

### Step 4.5: Manual Testing Checklist

For a system like Empire Mortgage:

```
SECURITY
[ ] Can't access pages without login
[ ] Loan officers can only see their own data
[ ] Document uploads are encrypted
[ ] MFA works correctly
[ ] Session timeout works

CALCULATORS
[ ] Payment calculator produces correct results
[ ] Qualification calculator handles edge cases
[ ] Refinance calculator matches industry formulas
[ ] All inputs validate properly

WORKFLOWS
[ ] Lead intake creates record in database
[ ] Email notifications fire correctly
[ ] Document upload triggers classification
[ ] Nurture sequences send on schedule

FRONTEND
[ ] Responsive on mobile, tablet, desktop
[ ] Forms validate before submission
[ ] Error messages are clear and helpful
[ ] Loading states appear during API calls
[ ] Navigation works correctly
```

### Step 4.6: Generate Test Report

```powershell
$results = Invoke-JAWSTests -Level "all"
New-TestReport -Results $results -OutputPath "TEST-REPORT.md"
```

The report uses the traffic light system:
- GREEN: READY FOR PRODUCTION
- YELLOW: READY WITH CAVEATS  
- RED: NOT READY

**OUTPUT FROM PHASE 4:** `TEST-REPORT.md` with pass/fail for every criterion.

---

## PHASE 5: DELIVER (2-4 hours)

**Goal:** Deploy, document, and hand off.

### Step 5.1: Deploy

```bash
# Frontend: Deploy to Vercel
vercel --prod

# Database: Apply migrations to production Supabase
supabase db push

# Workflows: Import to production n8n
# Use n8n API or manual import

# Environment variables: Set in each platform
# Supabase URL, keys, API secrets, etc.
```

### Step 5.2: Documentation

Generate client-ready documentation:

```
Read the entire codebase and create documentation:

1. docs/README.md - Plain English overview of the system
2. docs/SETUP.md - How to set up and configure
3. docs/USER-GUIDE.md - How end users operate the system
4. docs/TECHNICAL.md - Technical architecture for developers
5. docs/TROUBLESHOOTING.md - Common issues and fixes
6. docs/API-REFERENCE.md - All endpoints and their usage
```

### Step 5.3: Client Handoff Package

```
Create a client handoff package:

1. System overview (what was built, what it does)
2. Login credentials and access instructions
3. User training outline (how to use each feature)
4. Support procedures (what to do if something breaks)
5. Future roadmap (what could be added next)
6. Test report (proof it works)
```

---

## Empire Mortgage — The Full Example

Here's exactly how you'd build James's system using this playbook:

### Day 0: Discover (Evening, 3 hours)

| Time | Activity | Tool |
|------|----------|------|
| 0:00 | Articulate the idea, define user personas | Claude Chat |
| 0:30 | Research mortgage compliance requirements | Claude Chat + Web Search |
| 1:00 | Analyze competitor tools (LoanPro, Blend, etc.) | Claude Chat + Web Search |
| 1:30 | Define MVP scope with James | Claude Chat |
| 2:00 | Write DISCOVERY.md | Claude Chat |
| 2:30 | James reviews and approves scope | Meeting/Email |

### Day 1: Plan (Full Day, 6 hours)

| Time | Activity | Tool |
|------|----------|------|
| 0:00 | Design database schema | Claude Chat |
| 1:00 | Design API layer + auth flow | Claude Chat |
| 1:30 | Design n8n workflows | Claude Chat |
| 2:00 | Design frontend pages | Claude Chat |
| 2:30 | Write CONTRACTS.md with exact shapes + cross-cutting concerns | Claude Chat |
| 3:00 | Write full PRD.md (15-20 tasks) | Claude Chat |
| 4:30 | Review PRD, run contract verification checklist | Claude Chat |
| 5:00 | Set up project infrastructure | Terminal |
| 5:30 | Copy CLAUDE.md, install agent team skill | Terminal |

### Day 2-3: Build Foundation + Middle Layer (2 days)

| Time | Activity | Tool |
|------|----------|------|
| Day 2 AM | Build database layer (US-001 to US-003) | Claude Code single agent |
| Day 2 AM | Database agent validates + publishes contracts | Agent validation |
| Day 2 AM | Lead verifies database contracts against checklist | Contract checklist |
| Day 2 PM | Spawn API + Workflow agents with verified DB contracts | Agent Teams |
| Day 2 PM | API agent publishes API contract -> Lead verifies | Contract-first |
| Day 2 PM | Lead forwards verified API contract to frontend | Lead relay |
| Day 2 End | Run contract diff: curl vs fetch URLs | Pre-integration check |
| Day 3 AM | Build frontend with verified contracts | Agent Teams |
| Day 3 PM | Integration: connect all layers | Claude Code single agent |
| Day 3 PM | Fix any contract diff mismatches | Claude Code single agent |

### Day 4: Verify + Deliver (1 day)

| Time | Activity | Tool |
|------|----------|------|
| AM | Agent-level validation (each domain) | Agent validation protocol |
| AM | Pre-integration contract diff | Lead verification |
| AM | Generate test manifest + run automated tests | JAWS Testing Module |
| AM | Run Plan Guardian | JAWS v6 or Manual |
| AM | End-to-end validation (start all services, test flow) | Manual + curl |
| PM | Fix any failures from testing | Claude Code |
| PM | Generate test report | JAWS Testing Module |
| PM | Deploy to production | Vercel + Supabase |
| PM | Generate documentation | Claude Code |
| PM | Create client handoff package | Claude Chat |

**Total: ~4 working days from idea to delivered system.**

---

## Prompting Best Practices

### How to Get the Best Results from Claude at Each Phase

**PHASE 1 (Discovery) Prompts — Be broad, exploratory:**
```
"Help me think through..."
"What are the risks of..."  
"What would a competitor analysis show for..."
"What's the simplest version that delivers value?"
```

**PHASE 2 (Planning) Prompts — Be precise, structured:**
```
"Design the exact database schema with column names and types"
"Write the PRD in this exact format: [show format]"
"Define the API contract between [layer A] and [layer B] with exact URLs, 
 trailing slashes, response shapes, and status codes"
"Identify cross-cutting concerns and assign owners"
```

**PHASE 3 (Building) Prompts — Be atomic, verifiable:**
```
"Read PRD.md, complete ONLY task US-004"
"Follow the n8n patterns in CLAUDE.md exactly"
"Your FIRST deliverable is your API contract. Send it before coding."
"Build to this contract exactly. Do not deviate."
```

**PHASE 4 (Verification) Prompts — Be adversarial, thorough:**
```
"You have NO context on how this was built. Verify against the PRD."
"What exact curl commands test each of your endpoints?"
"What exact fetch URLs is the frontend calling? Compare against backend."
"Try to break this by sending invalid data"
```

**PHASE 5 (Delivery) Prompts — Be audience-aware:**
```
"Write this for a non-technical business owner"
"Create a troubleshooting guide that a loan officer could follow"
"Generate API documentation for a developer maintaining this system"
```

### Anti-Patterns to Avoid

| Don't Do This | Do This Instead |
|--------------|----------------|
| "Build me a mortgage system" | Break into 5 phases, start with DISCOVER |
| Give Claude the whole PRD and say "build it" | Assign one task at a time or use agent teams with contracts |
| Skip the planning phase | Spend 30% of your time planning, 70% building |
| Let Claude invent n8n node structures | Always start from template library patterns |
| Mark tasks complete without testing | Verify every criterion with evidence |
| Build the frontend first | Database -> API -> Workflows -> Frontend |
| Use agent teams for everything | Simple tasks = single agent, complex = teams |
| Forget to update AGENTS.md | Capture every pattern for future builds |
| Trust AI output without review | Plan Guardian + manual testing always |
| Spawn all agents simultaneously | Stagger: upstream first, get contracts, then downstream |
| Say "share your contract with the other agent" | Lead receives, verifies, and forwards contracts |
| Write vague contracts ("returns sessions") | Exact JSON shapes, URLs with trailing slashes, status codes |
| Let cross-cutting concerns go unassigned | Explicitly assign each to ONE agent |
| Store streaming chunks as separate DB rows | Accumulate chunks into one row per response |
| Skip the pre-completion contract diff | Compare curl commands vs fetch URLs BEFORE integration |

---

## Quick-Start Checklist

When you sit down to build something new:

```
[ ] PHASE 1: DISCOVER
  [ ] Articulate the idea clearly
  [ ] Research the market/competition
  [ ] Define MVP scope
  [ ] Save DISCOVERY.md

[ ] PHASE 2: PLAN
  [ ] Design architecture (all layers)
  [ ] Write PRD with proper format (DEPENDS, VERIFY, DONE)
  [ ] Define contracts with EXACT shapes (use verification checklist)
  [ ] Identify and assign cross-cutting concerns
  [ ] Set up project infrastructure
  [ ] Configure CLAUDE.md with n8n patterns
  [ ] Install agent team skill if using agent teams

[ ] PHASE 3: BUILD
  [ ] Choose strategy (A/B/C based on complexity)
  [ ] Build database layer FIRST
  [ ] If agent teams: stagger spawning, contract-first protocol
  [ ] Lead receives, verifies, forwards all contracts
  [ ] Build API + workflows (parallel if possible)
  [ ] Build frontend LAST (with verified API contract)
  [ ] Run contract diff before integration
  [ ] Integrate layers
  [ ] Commit atomically, update progress

[ ] PHASE 4: VERIFY
  [ ] Agent-level validation (each agent validates their domain)
  [ ] Pre-integration contract diff (curl vs fetch)
  [ ] Generate test manifest
  [ ] Run automated tests
  [ ] Run Plan Guardian
  [ ] End-to-end validation (start all services, test flow)
  [ ] Manual testing
  [ ] Generate test report

[ ] PHASE 5: DELIVER
  [ ] Deploy to production
  [ ] Generate documentation
  [ ] Create client handoff
  [ ] Archive project learnings
```

---

## Appendix A: File Structure for Any JAWS Build

```
project-name/
  docs/
    DISCOVERY.md           <- Phase 1 output
    ARCHITECTURE.md        <- Phase 2 output  
    CONTRACTS.md           <- Layer interface definitions + cross-cutting concerns
    USER-GUIDE.md          <- Phase 5 output
  specs/
    001-mvp/
      PRD.md               <- Phase 2 output (the build plan)
      implementation-plan.md
      qa-report.md
  supabase/
    migrations/            <- Database migrations
  workflows/               <- n8n workflow JSON files
  src/                     <- Application code
  CLAUDE.md                <- Build instructions for Claude agents
  AGENTS.md                <- Discovered patterns
  progress.txt             <- Build log
  PROJECT-LEARNINGS.json   <- Cross-session memory
  TEST-MANIFEST.md         <- Phase 4 test plan
  TEST-REPORT.md           <- Phase 4 results
  CHANGELOG.md             <- What was built and when
```

## Appendix B: When Things Go Wrong

### General Build Problems

| Problem | Cause | Fix |
|---------|-------|-----|
| Claude builds wrong n8n structure | Using outdated knowledge | Point it to CLAUDE.md and template library |
| Build takes way longer than expected | Tasks too large | Split tasks so each has 2-3 criteria max |
| Agent goes down a rabbit hole | Vague acceptance criteria | Make VERIFY field more specific |
| System works in testing, breaks in production | Missing environment config | Add deployment checklist to PRD |
| Lost context between sessions | Didn't update progress.txt | Session start/end checklists from Operations Guide |

### Agent Team Integration Failures (Battle-Tested Fixes)

| Problem | Root Cause | Fix |
|---------|-----------|-----|
| Frontend calls wrong API endpoints | No contract document or vague contracts | Create CONTRACTS.md with exact URLs, trailing slashes, response shapes BEFORE building |
| Agent teams produce incompatible code | Fully parallel spawn — agents diverged | Stagger spawning: upstream first, get contracts, then downstream |
| Backend returns `{session:{...}}` but frontend expects `{id, title}` | Response envelope mismatch not specified in contract | Require exact JSON shapes in contract, including nesting |
| 404 errors on API calls that "should work" | Trailing slash mismatch (`/api/sessions/` vs `/api/sessions`) | Document trailing slash convention per endpoint in contract |
| Frontend renders N separate text bubbles on page reload | Backend stored each streaming chunk as a separate DB row | Accumulate chunks into single rows — assign as cross-cutting concern |
| Merge conflicts between worktrees | Overlapping file changes | Better task isolation, assign clear file ownership per agent |
| Automation/testing can't find UI elements | CSS `opacity-0` or hidden interactive elements | Add aria-labels, ensure keyboard/focus visibility — assign to frontend agent |
| Agents "talk" but still diverge | Told agents to share with each other instead of lead relay | Lead receives, verifies, and forwards all contracts |
| Integration tests fail despite all agents reporting "done" | No pre-completion contract diff | Compare backend's curl commands vs frontend's fetch URLs BEFORE integration |
| Late-discovered interface mismatch | Backend shared contract after frontend already built half the app | Contract-first: publish contract BEFORE writing implementation code |

## Appendix C: Token Cost Estimation

| Build Strategy | Typical Token Usage | Estimated Cost (Claude Max) |
|---------------|--------------------|-----------------------------|
| Single agent, 5 tasks | 200K-500K tokens | Included in subscription |
| JAWS v5, 10 tasks | 500K-1M tokens | Included in subscription |
| Agent teams, 12 tasks | 1M-3M tokens | Included in subscription |
| JAWS v6, 15+ tasks | 2M-5M tokens | May need API for parallel |

**Rule of thumb:** Agent teams use 2-4x the tokens of single agent work. Budget accordingly if using API instead of subscription.

## Appendix D: Agent Team Setup Reference

### One-Time Setup

```bash
# 1. Install tmux
brew install tmux                    # macOS
sudo apt update && sudo apt install tmux  # Linux (Ubuntu/Debian)
sudo dnf install tmux                # Linux (Fedora/RHEL)

# Windows: Requires WSL (Windows Subsystem for Linux)
# wsl --install (from PowerShell Admin), restart, then:
# sudo apt update && sudo apt install tmux

# 2. Enable agent teams
# Add to ~/.claude/settings.json:
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}

# Or export in shell profile (~/.bashrc or ~/.zshrc):
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# 3. Install agent team skill
# For personal use (all projects):
cp -r build-with-agent-team ~/.claude/skills/

# For project-level use:
cp -r build-with-agent-team .claude/skills/

# 4. Verify
tmux -V
```

### Agent Team Skill Usage

```bash
# Let the skill determine team size based on plan complexity
/build-with-agent-team ./docs/PRD.md

# Specify number of agents
/build-with-agent-team ./docs/PRD.md 3

# Build a feature in existing codebase
/build-with-agent-team ./docs/new-auth-feature.md 2
```

### Agent Team Sizing Guidelines

| Agents | When |
|--------|------|
| 2 | Simple projects with clear frontend/backend split |
| 3 | Full-stack apps (frontend, backend, database/infra) |
| 4 | Complex systems with additional concerns (testing, DevOps, docs) |
| 5+ | Large systems with many independent modules |

### Spawn Prompt Template

```
You are the [ROLE] agent for this build.

## Your Ownership
- You own: [directories/files]
- Do NOT touch: [other agents' files]

## What You're Building
[Relevant section from plan]

## Mandatory Communication (REQUIRED)

### Before You Build
- Your FIRST deliverable is your [API contract / schema / interface]
- Send it to the lead via SendMessage BEFORE writing implementation code
- Include: exact URLs (with trailing slashes if applicable), exact 
  request/response JSON shapes, status codes, SSE event formats
- Wait for the lead to confirm before proceeding

### The Contract You Must Conform To
[Include the upstream agent's verified contract here]

### Cross-Cutting Concerns You Own
[Explicitly list integration behaviors this agent is responsible for]

## Validation Before Reporting Done
[Specific validation commands and checks]
Do NOT report done until all validations pass.
```

---

*This playbook is a living document. Update it as you learn. Every build makes the next one faster.*
