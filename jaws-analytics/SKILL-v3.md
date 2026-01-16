---
name: prd
description: "Generate a Product Requirements Document (PRD) for autonomous AI implementation via RALPH-JAWS v3. Combines Cole Medin's agent harness concepts with Rasmus Widing's PRP validation system. Optimized for n8n workflows, Supabase backends, and Lovable apps. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out, ralph this, build me."
---

# PRD Generator for RALPH-JAWS v3

**The Ultimate Agent Harness PRD System**

Combines:
- **Cole Medin's Harness Concepts:** Checkpoints, rabbit hole detection, human-in-the-loop
- **Rasmus Widing's PRP System:** Multi-level validation, CRITICAL markers, ai_docs context
- **JAWS Documentation:** Automatic client deliverables

---

## The Job

1. Receive a feature/project description from the user
2. Ask 3-5 essential clarifying questions (with lettered options)
3. Generate a structured PRD based on answers
4. Save to `PRD.md`
5. Create initialized `progress.txt`
6. Create `AGENTS.md` with CRITICAL markers section
7. Create `validation-commands.md` with multi-level validation
8. Create `ai_docs/` structure if integrations are involved

**Important:** Do NOT start implementing. Just create the PRD and supporting files.

---

## Step 1: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous.

### Format Questions Like This:

```
1. What type of project is this?
   A. n8n workflow system (automation)
   B. Lovable/React app with Supabase backend
   C. API/backend service only
   D. Full-stack application (custom)
   E. Other: [please specify]

2. What is the primary trigger/entry point?
   A. Webhook (receives external data)
   B. Schedule/Cron (time-based)
   C. Manual trigger (user-initiated)
   D. Database change (Supabase realtime)
   E. Multiple triggers

3. What integrations are needed?
   A. Supabase only
   B. Supabase + Claude API
   C. Supabase + external APIs (Slack, email, etc.)
   D. Multiple third-party services
   E. [List specific services]

4. Who is the end client?
   A. Construction company
   B. Digital agency
   C. Content creator/influencer
   D. Internal use
   E. Other: [please specify]

5. What is the scope?
   A. MVP - minimal viable version
   B. Full-featured implementation
   C. Proof of concept for client pitch
   D. Production-ready with error handling
```

This lets users respond with "1A, 2A, 3C, 4A, 5D" for quick iteration.

---

## Step 2: Story Sizing (THE NUMBER ONE RULE)

**Each story must be completable in ONE context window (~10 min of AI work).**

RALPH spawns a fresh Claude instance per iteration. If a story is too big, the AI runs out of context before finishing.

### Right-sized stories:

**For n8n workflows:**
- Create a single webhook trigger node with validation
- Build one data transformation/mapping node
- Add a single Supabase operation (insert/update/query)
- Create one error handling branch
- Add a single Claude API call with prompt

**For Supabase:**
- Add one table with columns and RLS
- Create a single database function
- Add one edge function endpoint
- Set up RLS policies for one table

**For Lovable/React apps:**
- Add a single UI component
- Create one form with validation
- Add a single data fetching hook
- Implement one user action

### Too big (MUST split):

| Too Big | Split Into |
|---------|-----------|
| "Build the n8n workflow" | Trigger, validation, processing, Supabase ops, error handling |
| "Create the dashboard" | Schema, queries, individual components, filters |
| "Add AI classification" | Claude API setup, prompt engineering, response parsing, storage |

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Step 3: Story Ordering with Checkpoint Gates

Stories execute in priority order. Earlier stories MUST NOT depend on later ones.

### Correct Order with Checkpoint Gates:

```
═══════════════════════════════════════════════════════════════════════════════
PHASE 1: Foundation                                    [CHECKPOINT: FOUNDATION]
═══════════════════════════════════════════════════════════════════════════════
  US-001: Supabase schema (tables, columns, types)
  US-002: RLS policies
  US-003: Environment variables / credentials
  
  ⏸️ CHECKPOINT: Run Level 1 validation. Verify schema before building on it.
  
  VALIDATION GATE:
  - [ ] All tables created
  - [ ] RLS policies active
  - [ ] Credentials configured

═══════════════════════════════════════════════════════════════════════════════
PHASE 2: Backend Logic                                    [CHECKPOINT: BACKEND]
═══════════════════════════════════════════════════════════════════════════════
  US-004: n8n webhook/trigger setup
  US-005: Data validation nodes
  US-006: Core processing logic
  US-007: Supabase operation nodes
  
  ⏸️ CHECKPOINT: Run Level 2 validation. Test backend manually before AI layer.
  
  VALIDATION GATE:
  - [ ] Webhook responds to test payload
  - [ ] Data flows to Supabase
  - [ ] Error handling works

═══════════════════════════════════════════════════════════════════════════════
PHASE 3: AI Integration (if applicable)                       [CHECKPOINT: AI]
═══════════════════════════════════════════════════════════════════════════════
  US-008: Claude API connection
  US-009: Prompt templates
  US-010: Response parsing
  
  ⏸️ CHECKPOINT: Verify AI responses before wiring notifications.
  
  VALIDATION GATE:
  - [ ] Claude API responds
  - [ ] Classification/output is correct
  - [ ] Error handling for API failures

═══════════════════════════════════════════════════════════════════════════════
PHASE 4: Notifications & Error Handling              [CHECKPOINT: NOTIFICATIONS]
═══════════════════════════════════════════════════════════════════════════════
  US-011: Notification dispatch (email, Slack)
  US-012: Error logging
  US-013: Retry logic
  
  ⏸️ CHECKPOINT: Run Level 3 integration tests.
  
  VALIDATION GATE:
  - [ ] Notifications send correctly
  - [ ] Errors are logged
  - [ ] Full flow works end-to-end

═══════════════════════════════════════════════════════════════════════════════
PHASE 5: Frontend (if applicable)                              [CHECKPOINT: UI]
═══════════════════════════════════════════════════════════════════════════════
  US-014: UI components
  US-015: Data display
  US-016: User interactions
  
  ⏸️ CHECKPOINT: Verify UI before documentation.

═══════════════════════════════════════════════════════════════════════════════
PHASE 6: Documentation & Polish                              [CHECKPOINT: DONE]
═══════════════════════════════════════════════════════════════════════════════
  US-017: Generate documentation
  US-018: Final testing
```

---

## Step 4: Acceptance Criteria with Multi-Level Validation

Each criterion must be verifiable. Include validation commands for each level.

### Story Template with Validation:

```markdown
### US-004: Create Webhook Receiver Workflow
**Phase:** 2 - Backend Logic
**Estimated Iterations:** 1-2

**Description:** As the system, I need to receive incoming RFIs so they can be processed.

**Acceptance Criteria:**
- [ ] Webhook node at /webhook/rfi
- [ ] Accepts POST with JSON body
- [ ] Validates required fields: title, description, source
- [ ] Returns 400 for invalid payloads
- [ ] Returns 200 with rfi_id for valid payloads
- [ ] Passes payload to processing sub-workflow

**Validation Commands:**

Level 1 - Syntax:
```bash
# Verify workflow JSON is valid
cat workflows/webhook-receiver.json | jq .
```

Level 2 - Unit:
```bash
# Test with valid payload
curl -X POST http://localhost:5678/webhook/rfi \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Test desc","source":"manual"}'
# Expected: 200 with rfi_id

# Test with invalid payload
curl -X POST http://localhost:5678/webhook/rfi \
  -H "Content-Type: application/json" \
  -d '{"title":"Test"}'
# Expected: 400 error
```

Level 3 - Integration:
```bash
# Full flow test (after US-005, US-006, US-007 complete)
# Verify record appears in Supabase after webhook call
```

**Context for Future Iterations:**
- Depends on: US-002 (credentials), US-001 (schema)
- Pattern: Use n8n's built-in validation nodes
- Known gotcha: Webhook URL changes in production mode

**If This Fails (Recovery Hints):**
- If 404: Check webhook path matches exactly
- If 500: Check Supabase credentials are configured
- If timeout: Check n8n is running and accessible
- # CRITICAL: If stuck 3+ times, task may need splitting

**Rabbit Hole Warning:** 🐰
If validation fails 3+ times, STOP and request human review.
```

---

## Step 5: CRITICAL Markers System (Rasmus's Pattern)

Use CRITICAL markers for must-not-forget information.

### In Acceptance Criteria:
```markdown
- [ ] # CRITICAL: Use service role key, not anon key
- [ ] # CRITICAL: RLS must be enabled before inserting data
- [ ] # CRITICAL: Claude API responses need JSON parsing
```

### In Known Gotchas:
```markdown
**Known Gotchas:**
# CRITICAL: n8n webhook URLs change between test and production mode
# CRITICAL: Supabase RLS blocks service role if not configured correctly
# CRITICAL: Claude API has rate limits - add retry logic
- Webhook nodes need "Respond to Webhook" node for custom responses
- Set nodes don't auto-parse JSON - use JSON.parse() in expressions
```

### In AGENTS.md:
```markdown
## Common Gotchas
# CRITICAL: Always use upsert for idempotent operations
# CRITICAL: Check RLS policies before debugging "no data" issues
# CRITICAL: n8n expressions use $json not just json
```

---

## Step 6: AI Docs Context (Rasmus's Pattern)

For projects with integrations, create an `ai_docs/` folder with relevant documentation.

### Structure:
```
ai_docs/
├── README.md              # What docs are available
├── n8n-nodes.md           # n8n node documentation
├── n8n-expressions.md     # Expression syntax reference
├── supabase-js.md         # Supabase client docs
├── supabase-rls.md        # RLS patterns
├── claude-api.md          # Claude API reference
└── [integration]-api.md   # Specific API docs
```

### ai_docs/README.md Template:
```markdown
# AI Documentation Context

This folder contains documentation for Claude to reference during implementation.

## Available Docs

| File | Purpose | When to Use |
|------|---------|-------------|
| n8n-nodes.md | Node configuration | Any n8n workflow task |
| supabase-rls.md | RLS policy patterns | Database security tasks |
| claude-api.md | Claude API reference | AI integration tasks |

## How to Add Docs

1. Find official documentation for your integration
2. Extract the most relevant sections (keep it focused)
3. Save as markdown in this folder
4. Claude will automatically use it for context
```

---

## Step 7: PRD Structure (Complete Template)

```markdown
# PRD: [Project Name]

## Introduction

[2-3 sentences: What we're building, who it's for, why it matters]

**Client:** [Name, Company]
**Business Value:** [Specific outcome with numbers if possible]

## Goals

- [Measurable outcome 1]
- [Measurable outcome 2]
- [Measurable outcome 3]

## Technical Stack

- **Orchestration:** n8n (self-hosted/cloud)
- **Database:** Supabase (PostgreSQL + RLS)
- **AI:** Claude API (claude-sonnet-4-20250514)
- **Notifications:** [Email service, Slack, etc.]
- **Frontend:** [Lovable, React, etc.]

## User Stories

[Organized by Phase with Checkpoint Gates]

### Phase 1: Foundation [CHECKPOINT: FOUNDATION]

#### US-001: Create Supabase Schema
**Estimated Iterations:** 1

**Description:** As a developer, I need the database schema...

**Acceptance Criteria:**
- [ ] Table `[name]` with columns: [list]
- [ ] # CRITICAL: RLS enabled on all tables
- [ ] Schema documented in AGENTS.md

**Validation Commands:**
```sql
-- Level 1: Verify tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';
```

**If This Fails:**
- Check Supabase project URL is correct
- Verify service role key has permissions

---

[Continue for each story...]

## Validation Strategy (Multi-Level)

### Level 1: Syntax & Style
```bash
# For n8n workflows
cat workflows/*.json | jq . > /dev/null && echo "Valid JSON"

# For code projects
npm run lint
# or
ruff check src/
```

### Level 2: Unit Tests
```bash
# Webhook tests
curl -X POST http://localhost:5678/webhook/[endpoint] \
  -H "Content-Type: application/json" \
  -d '[test payload]'

# Database tests
# Test queries against Supabase
```

### Level 3: Integration Tests
```bash
# Full flow test
[Complete end-to-end test command]

# Expected outcome:
# 1. [Step 1 result]
# 2. [Step 2 result]
# 3. [Final result]
```

## Non-Goals

- [What this does NOT do]
- [Out of scope for this phase]
- [Future enhancements]

## Documentation Requirements

- [ ] Plain English explanation (README.md)
- [ ] Technical breakdown (TECHNICAL.md)
- [ ] Client pitch (CLIENT-PITCH.md)
- [ ] Troubleshooting guide (TROUBLESHOOTING.md)
- [ ] Environment setup (SETUP.md)

## Testing Strategy

**Sample Webhook Payload:**
```json
{
  "field1": "value1",
  "field2": "value2"
}
```

**Test Scenarios:**
1. Valid payload → Expected: [outcome]
2. Invalid payload → Expected: [error]
3. Edge case → Expected: [handling]
```

---

## Output Files

### 1. PRD.md
The complete PRD following the structure above.

### 2. progress.txt
```markdown
# Progress Log

## Project Info
- **Created:** [DATE]
- **Project:** [PROJECT NAME]
- **Type:** [n8n workflow / Lovable app / etc.]
- **Harness:** RALPH-JAWS v3

## Learnings
(Patterns discovered during implementation - RALPH will update this)

## Validation Results
(RALPH will track validation pass/fail here)

## Iteration Log

---
```

### 3. AGENTS.md
```markdown
# Agent Knowledge Base

## Project Patterns

### Technology Stack
- [List stack components]

### Naming Conventions
- Workflows: "[Project] - [Purpose]"
- Tables: snake_case
- Functions: camelCase

## Common Gotchas

# CRITICAL: [Most important warning]
# CRITICAL: [Second most important warning]

- [Other gotchas discovered during implementation]

## Reusable Patterns

### Pattern: [Name]
```
[Code or configuration snippet]
```
When to use: [Description]

---
*Updated by RALPH as patterns emerge.*
```

### 4. validation-commands.md
```markdown
# Validation Commands

Run these commands to verify each component works.

## Level 1: Syntax & Style

```bash
# JSON validation for n8n workflows
for f in workflows/*.json; do
  echo "Checking $f..."
  cat "$f" | jq . > /dev/null || echo "INVALID: $f"
done

# Code linting (if applicable)
# npm run lint
# ruff check src/
```

## Level 2: Unit Tests

```bash
# Webhook endpoint tests
echo "Testing webhook..."
curl -s -o /dev/null -w "%{http_code}" \
  -X POST http://localhost:5678/webhook/[endpoint] \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
# Expected: 200

# Database query tests
# [Add Supabase test queries]
```

## Level 3: Integration Tests

```bash
# Full end-to-end flow
echo "Running integration test..."

# Step 1: Send test data
RESPONSE=$(curl -s -X POST http://localhost:5678/webhook/[endpoint] \
  -H "Content-Type: application/json" \
  -d '[full test payload]')

echo "Response: $RESPONSE"

# Step 2: Verify database
# [Query to check data was stored]

# Step 3: Verify notification
# [Check email/Slack was sent]
```

## Quick Validation Script

```bash
#!/bin/bash
# Run all validation levels

echo "=== Level 1: Syntax ==="
[syntax commands]

echo "=== Level 2: Unit ==="
[unit commands]

echo "=== Level 3: Integration ==="
[integration commands]

echo "=== DONE ==="
```

---
*Update this file with project-specific validation commands*
```

### 5. ai_docs/ folder (if integrations exist)

Create relevant documentation files based on the integrations in the project.

---

## Checklist Before Saving

### PRD Quality
- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user's answers
- [ ] User stories use US-001 format
- [ ] Each story completable in ONE iteration
- [ ] Stories ordered by dependency
- [ ] Checkpoint gates defined between phases

### Validation Quality
- [ ] All criteria are verifiable (not vague)
- [ ] Validation commands included for each level
- [ ] CRITICAL markers on must-not-forget items
- [ ] Recovery hints for complex tasks
- [ ] Rabbit hole warnings on high-risk tasks

### Context Quality
- [ ] Context hints for dependencies
- [ ] ai_docs folder created (if integrations exist)
- [ ] Testing strategy with sample payloads

### Files Created
- [ ] PRD.md
- [ ] progress.txt
- [ ] AGENTS.md (with CRITICAL section)
- [ ] validation-commands.md (with 3 levels)
- [ ] ai_docs/ (if applicable)
