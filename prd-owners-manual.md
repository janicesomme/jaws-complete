# PRD: Owner's Manual Generator

## Project Overview

**What:** Auto-generate plain English documentation for any JAWS-built system

**Who:** Business owners who receive systems from Janice

**Why:** Clients can understand and maintain their own systems without calling for help

**Success Metric:** Non-technical person understands their system in under 10 minutes

---

## Technical Context

**Stack:**
- Input: Completed PRD.md, progress.txt, AGENTS.md, workflows/*.json
- Processing: Claude API for plain English generation
- Output: 7 markdown files + compiled DOCX

**Integrations:**
- Claude API (claude-sonnet-4-20250514)
- docx-js (for DOCX compilation)

---

## CRITICAL Rules
```
CRITICAL: All output must be in PLAIN ENGLISH - no jargon
CRITICAL: A non-technical person must understand every sentence
CRITICAL: Never assume the reader knows what a "webhook" or "node" is
CRITICAL: Use analogies to explain technical concepts
```

---

## User Stories

### US-301: Create WHAT-YOU-HAVE.md Generator

**FILES:** `prompts/owner-manual/what-you-have-prompt.md`, `scripts/generate-what-you-have.js`

**ACTION:** 
Create a prompt and script that reads a completed PRD and generates a plain-English explanation of what was built. Include a simple ASCII diagram showing the main components and how they connect.

**VERIFY:** Run on jaws-analytics PRD → outputs 1-page doc a business owner can understand

**DONE:** Non-technical person can read and understand their system in 5 minutes

**Acceptance Criteria:**
- [x] Reads PRD.md and extracts system description
- [x] Generates plain English summary (no jargon)
- [x] Includes simple ASCII or text diagram
- [x] Lists components with friendly names (not technical names)
- [x] One-sentence purpose for each component
- [x] Output saved to `owner-manual/WHAT-YOU-HAVE.md`

---

### US-302: Create HOW-IT-WORKS.md Generator

**FILES:** `prompts/owner-manual/how-it-works-prompt.md`, `scripts/generate-how-it-works.js`

**ACTION:** 
Generate step-by-step explanation of system flow using "When X happens, then Y" language. Walk through a typical transaction from start to finish.

**VERIFY:** Generate for jaws-analytics → explains full flow from webhook trigger to dashboard display

**DONE:** Owner can trace any transaction through their system mentally

**Acceptance Criteria:**
- [x] Uses "When/Then" language throughout
- [x] Numbered walkthrough of typical transaction
- [x] Explains each step in plain English
- [x] Mentions what happens at decision points
- [x] No technical jargon (or explains it with analogy)
- [x] Output saved to `owner-manual/HOW-IT-WORKS.md`

---

### US-303: Create DAILY-OPERATIONS.md Generator

**FILES:** `prompts/owner-manual/daily-operations-prompt.md`, `scripts/generate-daily-operations.js`

**ACTION:** 
Generate daily/weekly/monthly checklists for system operation. Include what "normal" looks like so owner knows when something is wrong.

**VERIFY:** Generate for any project → includes concrete checklist items with time estimates

**DONE:** Owner has actionable checklist to keep system healthy

**Acceptance Criteria:**
- [x] Daily checklist (2-minute tasks)
- [x] Weekly checklist (10-minute tasks)
- [x] Monthly checklist (30-minute tasks)
- [x] "What normal looks like" section
- [x] "Warning signs" section
- [x] Output saved to `owner-manual/DAILY-OPERATIONS.md`

---

### US-304: Create WHEN-THINGS-BREAK.md Generator

**FILES:** `prompts/owner-manual/when-things-break-prompt.md`, `scripts/generate-troubleshooting.js`

**ACTION:** 
Generate troubleshooting guide with common issues and self-service fixes. Include clear "when to call for help" criteria.

**VERIFY:** Generate for jaws-analytics → includes "Dashboard not loading" with 3 self-service checks

**DONE:** Owner can resolve 80% of issues without calling for help

**Acceptance Criteria:**
- [x] Top 5 common issues for this system type
- [x] Symptom-based diagnosis (what you see → what it means)
- [x] Step-by-step self-service fixes
- [x] Clear "call for help if..." criteria
- [x] Emergency contact info placeholder
- [x] Output saved to `owner-manual/WHEN-THINGS-BREAK.md`

---

### US-305: Create MAKING-CHANGES.md Generator

**FILES:** `prompts/owner-manual/making-changes-prompt.md`, `scripts/generate-making-changes.js`

**ACTION:** 
Generate guide for safe self-service changes. Two categories: things owner CAN change safely vs things that need help.

**VERIFY:** Generate for any project → shows how to change notification email (safe) vs add new routing rule (needs help)

**DONE:** Owner knows what they can touch and what requires support

**Acceptance Criteria:**
- [x] "Safe changes" list with step-by-step instructions
- [x] "Risky changes" list with warnings
- [x] Specific examples for each category
- [x] Screenshots/location descriptions for where to make changes
- [x] "How to request changes" process
- [x] Output saved to `owner-manual/MAKING-CHANGES.md`

---

### US-306: Create COSTS.md Generator

**FILES:** `prompts/owner-manual/costs-prompt.md`, `scripts/generate-costs.js`

**ACTION:** 
Generate cost breakdown showing monthly operating costs per service and what affects costs.

**VERIFY:** Generate for jaws-analytics → shows n8n: $X, Supabase: $Y, total: $Z

**DONE:** Owner understands and can monitor their operating costs

**Acceptance Criteria:**
- [x] Cost table by service (n8n, Supabase, etc.)
- [x] Estimated monthly total
- [x] What drives costs up (usage triggers)
- [x] How to check current usage
- [x] How to set up billing alerts
- [x] Output saved to `owner-manual/COSTS.md`

---

### US-307: Create HANDOVER-CHECKLIST.md Generator

**FILES:** `prompts/owner-manual/handover-prompt.md`, `scripts/generate-handover.js`

**ACTION:** 
Generate comprehensive handover checklist ensuring nothing is forgotten when delivering to client.

**VERIFY:** Generate for any project → checklist covers credentials, access, docs, training

**DONE:** Every handover is complete with nothing forgotten

**Acceptance Criteria:**
- [x] Access credentials checklist
- [x] Account ownership verification
- [x] Documentation delivered checklist
- [x] Training completed checklist
- [x] Support contacts section
- [x] "What's next" section
- [x] Output saved to `owner-manual/HANDOVER-CHECKLIST.md`

---

### US-308: Create Owner's Manual Compiler

**FILES:** `scripts/compile-owner-manual.js`

**ACTION:** 
Create script that runs all generators and compiles output into single professional DOCX file with table of contents.

**VERIFY:** Run compiler → outputs `OwnerManual-[ProjectName].docx` with all 7 sections

**DONE:** One command generates complete, professional Owner's Manual

**Acceptance Criteria:**
- [x] Runs all 7 generators in sequence
- [x] Compiles to single DOCX file
- [x] Includes table of contents
- [x] Professional formatting (headers, spacing)
- [x] Client name/project name on cover
- [x] Page numbers in footer
- [x] Output: `owner-manual/OwnerManual-[ProjectName].docx`

---

## Dependencies
```
US-301 through US-307 can be built in parallel
US-308 depends on all previous tasks
```

---

## Out of Scope (v1)

- PDF output (DOCX only for now)
- Custom branding/logo injection
- Multiple language support
- Version tracking of manuals

---

## Test Strategy

**Test Project:** Use jaws-analytics as test input

**Validation:**
1. Generate each doc individually
2. Have non-technical person read and rate clarity (1-10)
3. Target: 8+ clarity rating on all docs
4. Compile full manual
5. Verify DOCX opens correctly in Word/Google Docs