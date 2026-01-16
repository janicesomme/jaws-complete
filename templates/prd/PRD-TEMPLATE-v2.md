# PRD Template v2 - JAWS Format with Verify/Done Fields

## How to Use This Template

This PRD format is optimized for RALPH-JAWS v4. Each task includes:
- **FILES:** What files will be created/modified
- **VERIFY:** A specific test RALPH can run to confirm completion
- **DONE:** The acceptance criteria in one line

Copy this template and fill in your project details.

---

# [PROJECT NAME] PRD

## Project Overview

**What:** [One sentence describing what this system does]

**Who:** [Who will use it]

**Why:** [Business problem being solved]

**Success Metric:** [How we know it worked]

---

## Technical Context

**Stack:**
- Frontend: [e.g., React, Lovable, None]
- Backend: [e.g., n8n, Supabase Edge Functions]
- Database: [e.g., Supabase]
- Deployment: [e.g., Vercel, n8n Cloud]

**Integrations:**
- [List external services: Gmail, Slack, etc.]

**Constraints:**
- [Budget limits, timeline, etc.]

---

## CRITICAL Rules

<!-- RALPH reads these and treats them as non-negotiable -->

```
CRITICAL: [Rule 1 - e.g., Never store plain text passwords]
CRITICAL: [Rule 2 - e.g., All API calls must have error handling]
CRITICAL: [Rule 3 - e.g., Use jose for JWT, not jsonwebtoken]
```

---

## User Stories

### US-001: [Task Title]

**FILES:** `[path/to/file1.ts]`, `[path/to/file2.ts]`

**ACTION:** 
[2-4 sentences describing what needs to be built]

**VERIFY:** [Specific test command or check, e.g., "Run `curl localhost:3000/api/health` → returns 200"]

**DONE:** [One-line acceptance criteria, e.g., "Endpoint responds with {status: 'ok'} in <100ms"]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

---

### US-002: [Task Title]

**FILES:** `[paths]`

**ACTION:** 
[What needs to be built]

**VERIFY:** [How to test it]

**DONE:** [When is it done]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

---

### US-003: [Task Title]

**FILES:** `[paths]`

**ACTION:** 
[What needs to be built]

**VERIFY:** [How to test it]

**DONE:** [When is it done]

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

---

## Dependencies Between Tasks

```
US-001 → US-002 (US-002 needs US-001's database tables)
US-002 → US-003 (US-003 uses US-002's API)
```

---

## Out of Scope (v1)

- [Feature we're NOT building now]
- [Another feature for later]

---

## Post-Build Checklist

- [ ] All acceptance criteria marked [x]
- [ ] VERIFY checks pass for all tasks
- [ ] AGENTS.md updated with patterns learned
- [ ] progress.txt has final summary
- [ ] Documentation generated (if -GenerateDocs)

---

# Example: Filled-In PRD

Below is an example of a completed PRD using this format:

---

# Lead Capture System PRD

## Project Overview

**What:** Capture leads from website form, score them, route to team members

**Who:** Sales team at ABC Company

**Why:** Currently losing leads that sit unassigned for days

**Success Metric:** 100% of leads assigned within 5 minutes

---

## Technical Context

**Stack:**
- Frontend: Webflow (existing)
- Backend: n8n
- Database: Supabase
- Deployment: n8n Cloud

**Integrations:**
- Webflow forms (webhook)
- Gmail (notifications)
- Slack (alerts)

**Constraints:**
- $50/month budget for tools
- Must work with existing Webflow site

---

## CRITICAL Rules

```
CRITICAL: All leads must be logged to Supabase before any other action
CRITICAL: Lead scoring must happen before routing
CRITICAL: Failed webhook calls must retry 3 times with exponential backoff
```

---

## User Stories

### US-001: Create Supabase Lead Table

**FILES:** `supabase/migrations/001_create_leads.sql`

**ACTION:** 
Create a Supabase table to store all incoming leads with fields for name, email, phone, company, score, assigned_to, status, and timestamps.

**VERIFY:** Run `SELECT * FROM leads LIMIT 1` in Supabase SQL editor → returns empty result with correct columns

**DONE:** Table exists with all fields, RLS enabled, insert policy for service role

**Acceptance Criteria:**
- [ ] Table `leads` created with all required fields
- [ ] RLS enabled on table
- [ ] Service role can insert records
- [ ] Created_at defaults to now()

---

### US-002: Create n8n Webhook Receiver

**FILES:** `n8n/workflows/lead-capture.json`

**ACTION:** 
Build n8n workflow that receives Webflow form submissions via webhook, validates required fields, and inserts into Supabase leads table.

**VERIFY:** POST test data to webhook URL → record appears in Supabase leads table within 5 seconds

**DONE:** Webhook receives form data, validates email exists, inserts to Supabase, returns 200

**Acceptance Criteria:**
- [ ] Webhook node configured and active
- [ ] Email validation (reject if missing)
- [ ] Supabase insert works
- [ ] Error handling for failed inserts

---

### US-003: Add Lead Scoring Logic

**FILES:** `n8n/workflows/lead-capture.json` (update)

**ACTION:** 
Add lead scoring node after webhook receive. Score based on: company email domain (+20), phone provided (+10), company name length > 3 (+5).

**VERIFY:** Submit test lead with company email and phone → score = 30 in Supabase record

**DONE:** All leads receive score 0-100, score saved before routing

**Acceptance Criteria:**
- [ ] Scoring logic implemented
- [ ] Score saved to leads table
- [ ] Score happens before routing step

---

### US-004: Add Team Routing Logic

**FILES:** `n8n/workflows/lead-capture.json` (update)

**ACTION:** 
Route leads based on score: >70 to Sarah (senior), 40-70 to Mike (mid), <40 to queue. Send Gmail notification to assigned person.

**VERIFY:** Submit high-score lead (company email + phone) → Sarah receives email notification within 1 minute

**DONE:** Leads routed correctly, assignee notified via email, assigned_to updated in Supabase

**Acceptance Criteria:**
- [ ] Routing logic by score threshold
- [ ] Email notification sent
- [ ] Supabase record updated with assigned_to
- [ ] Low-score leads go to queue (assigned_to = null)

---

### US-005: Add Slack Alert for High-Value Leads

**FILES:** `n8n/workflows/lead-capture.json` (update)

**ACTION:** 
For leads scoring >70, also send Slack message to #sales channel with lead details.

**VERIFY:** Submit high-score lead → Slack message appears in #sales within 30 seconds

**DONE:** High-value leads trigger Slack alert with name, email, company, score

**Acceptance Criteria:**
- [ ] Slack integration configured
- [ ] Message includes lead details
- [ ] Only triggers for score > 70

---

## Dependencies Between Tasks

```
US-001 → US-002 (need table before inserting)
US-002 → US-003 (need webhook before scoring)
US-003 → US-004 (need score before routing)
US-004 → US-005 (Slack is parallel to email but needs routing done)
```

---

## Out of Scope (v1)

- Lead deduplication
- CRM integration (Hubspot)
- Lead nurturing sequences
- Dashboard for viewing leads

---

*Template Version: 2.0*
*Compatible with: RALPH-JAWS v4*
