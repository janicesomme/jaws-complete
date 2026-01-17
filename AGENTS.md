# AGENTS.md - Project Patterns & Learnings

> This file captures patterns discovered during builds. RALPH updates this automatically after each task.

## Project Info

**Project:** Owner's Manual Generator
**Started:** 2026-01-16
**Stack:** Node.js, Claude API, Markdown generation

---

## CRITICAL Rules

```
CRITICAL: All output must be in PLAIN ENGLISH - no jargon
CRITICAL: A non-technical person must understand every sentence
CRITICAL: Never assume the reader knows what a "webhook" or "node" is
CRITICAL: Use analogies to explain technical concepts
CRITICAL: Target 400-500 words for "5-minute read" documentation
```

---

## Patterns Discovered

### Pattern: AI-Powered Plain English Generator
**Task:** US-301
**Problem:** Need to convert technical PRDs into documentation that business owners can understand in 5 minutes
**Solution:** Create comprehensive prompt template with rules, examples, and analogies. Use Claude API to transform technical content. Structure output with clear sections: one-sentence summary, component list with friendly names, ASCII diagram, business value bullets.
**Reuse:** Use this pattern whenever generating client-facing documentation from technical artifacts. Key elements:
- Prompt template with translation rules and analogy examples
- Word count target (~500 words = 5 min read)
- ASCII diagram showing flow not complexity
- Emphasize business value over technical features

```javascript
// Script pattern for AI-powered doc generation
const fs = require('fs');
const https = require('https');

// 1. Read source document (PRD)
const prdContent = fs.readFileSync(prdPath, 'utf8');

// 2. Read prompt template
const promptContent = fs.readFileSync(promptPath, 'utf8');

// 3. Call Claude API with combined prompt + source
const apiRequest = {
  model: 'claude-sonnet-4-20250514',
  max_tokens: 2000,
  messages: [{
    role: 'user',
    content: `${promptContent}\n\n---\n\n# INPUT PRD\n\n${prdContent}`
  }]
};

// 4. Save generated output to owner-manual/ directory
fs.writeFileSync(outputPath, response.content[0].text, 'utf8');
```

### Pattern: Technical-to-Plain-English Translation Map
**Task:** US-301
**Problem:** Developers use jargon that confuses non-technical users
**Solution:** Create a translation table with effective analogies:

| Technical Term | Plain English Translation |
|----------------|---------------------------|
| n8n workflow with webhook | Automation that starts when it receives a signal |
| Supabase PostgreSQL with RLS | Secure storage system that keeps data organized |
| Claude API for NLG | AI assistant that writes summaries in plain English |
| React dashboard with Recharts | Interactive web page with visual charts |
| API calls | Making phone calls to other services to get information |
| Database | Filing cabinet that organizes and stores information |
| Webhook | Doorbell - when pressed, something happens automatically |

**Reuse:** Reference this table when writing any client-facing documentation. Add new translations as you encounter new technical concepts.

---

### Pattern: When/Then Flow Documentation
**Task:** US-302
**Problem:** Technical system flows are hard for non-technical owners to follow mentally. They can't trace what happens when a transaction enters their system.
**Solution:** Structure flow documentation using consistent "When/Then/Why This Matters" format:
- **When:** What triggers this step (in plain English)
- **Then:** What happens as a result
- **Why This Matters:** Business value of this step

Number each step sequentially (Step 1, Step 2, etc.) to show clear progression. Explicitly call out decision points with "If/Then/Otherwise" format. Include a "Big Picture" summary at the start and optional "For the Technically Curious" details at the end for layered depth.

**Reuse:** Use this pattern whenever documenting system flows, automation sequences, or data pipelines. Key elements:
- Every step must have When/Then/Why structure
- Decision points get special callout sections
- Start with high-level journey, end with technical details
- Target 500-700 words for main flow (50-70 words per step)
- Include realistic timeline expectations

Example structure:
```markdown
## The Big Picture
[2-3 sentence summary with analogy]

## The Journey of [Transaction/Process Name]

**Step 1: [Name]**
**When:** [Trigger]
**Then:** [Result]
**Why This Matters:** [Business value]

[Repeat for each step]

## Decision Points
**Decision Point: [What's Being Checked]**
- **If** [condition], **then** [action]
- **Otherwise**, **then** [alternative]
```

### Pattern: Operational Checklist Documentation
**Task:** US-303
**Problem:** Business owners don't know what routine maintenance their system needs or how to recognize when something is wrong. Without operational checklists, they either over-monitor (wasting time) or under-monitor (missing issues).
**Solution:** Create time-boxed checklists (daily/weekly/monthly) where every item includes three components:
1. **Time estimate** - Realistic duration (daily: 15-60s each, weekly: 2-5m each, monthly: 5-15m each)
2. **What normal looks like** - Specific baseline indicators so owner knows healthy state
3. **Warning signs** - Clear escalation levels (🚨 immediate vs ⚠️ within 24 hours)

Structure as:
- Daily: 3-5 quick checks totaling 2 minutes
- Weekly: 3-5 deeper checks totaling 10 minutes
- Monthly: 2-4 comprehensive checks totaling 30 minutes

Include reference sections:
- "What Normal Looks Like" - consolidated baseline indicators
- "Warning Signs" - escalation guidelines with urgency levels

**Reuse:** Use this pattern whenever creating operational documentation for business owners. Key elements:
- Every checklist item must be concrete action, not vague ("Check dashboard loads" not "Verify system health")
- Customize by system type (analytics: data freshness, automation: execution rates, customer apps: user experience)
- Time estimates help owners budget their maintenance activities
- Baseline indicators prevent false alarms and missed issues
- Clear escalation paths (reference WHEN-THINGS-BREAK.md for problems)
- Target ~15 minutes per week total across all checklists

Example template:
```markdown
## Daily Checklist (2 minutes total)

**⏱️ Every morning before you start work:**

- [ ] **[Specific action]** (X seconds)
  - What normal looks like: [Concrete indicator]
  - Warning sign: [Clear symptom]
```

### Pattern: Symptom-Based Troubleshooting Documentation
**Task:** US-304
**Problem:** Business owners struggle to diagnose and fix system issues because technical error messages don't map to what they see on screen. They waste time trying to fix wrong problems or call for help on simple issues they could resolve themselves.
**Solution:** Structure troubleshooting guides using symptom-first diagnosis:
1. **"What This Looks Like"** - Describe exact visual symptoms (blank screen, old data, error message text)
2. **"What This Usually Means"** - Translate technical cause into plain English with analogy
3. **"How to Fix It Yourself"** - Numbered 3-step self-service checklist with exact locations
4. **"Still Not Working?"** - Clear escalation criteria to prevent wasted troubleshooting time

Front-load critical scenarios at top ("When to Call for Help Immediately"). Group issues by system type (dashboard systems, automation systems, data processing systems). Each fix step must include:
- Where to look (exact URL or location like "Top right corner of dashboard")
- What you should see (baseline normal state)
- What to do (specific action in plain English)
- Expected result (how you know if it worked)

Include time estimates ("This usually takes 2 minutes") and reassuring language ("This is common and easy to fix"). Add prevention tips and error message decoder sections.

**Reuse:** Use this pattern whenever creating troubleshooting guides for non-technical system owners. Key elements:
- Organize by what user SEES, not by technical root cause
- 5 most common issues per system type
- 3 self-service steps per issue with exact locations
- Clear escalation criteria ("Call if you tried X and Y")
- Time estimates help users know if they're in normal range
- "What You Will Not Break" section reduces fear and empowers self-service
- Target 800-1000 words covering 5 issues

Example structure:
```markdown
## When to Call for Help Immediately
[Critical symptoms with ❌ emoji]

## Issue 1: [What You See]

**What This Looks Like:**
[Specific visual symptoms]

**What This Usually Means:**
[Plain English cause]

**How to Fix It Yourself:**
1. **First, check [X]:**
   - Where to look: [Exact location]
   - What you should see: [Normal state]
   - What to do: [Action]

2. [Steps 2 and 3]

**Still Not Working?**
→ **Call for help if:** [Clear criteria]

**Estimated Fix Time:** [X minutes]
```

### Pattern: Change Management Documentation
**Task:** US-305
**Problem:** Business owners don't know which system changes they can safely make themselves vs which require technical expertise. Without clear guidance, they either avoid making any changes (blocking productivity) or make risky changes that break functionality.
**Solution:** Create two-category change guide structure:

**Safe Changes (You Can Do These):**
- Each change includes 5 components:
  1. **Why you might need this:** Business context
  2. **Where to do this:** Exact URLs, button names, tab locations
  3. **Step-by-step:** Numbered instructions with what you'll see at each step
  4. **How to verify it worked:** Specific test they can perform
  5. **How to undo if needed:** Exact reversal steps
- Use ✅ emoji indicator for safe changes
- Include time estimates for each change
- Examples: notification emails, dashboard date ranges, color themes, display names

**Risky Changes (Get Help With These):**
- Each change includes 3 components:
  1. **Why this needs expert help:** Plain English explanation of complexity
  2. **What could go wrong:** Specific risks (data loss, broken functionality, performance issues)
  3. **How to request this change:** 4-step process (Document → Gather examples → Contact support → Testing together)
- Use ⚠️ emoji indicator for risky changes
- Include response time expectations
- Examples: new data sources, calculation changes, workflow modifications, API integrations

**Additional sections:**
- **Common Scenarios: Quick Reference** - Table showing safe vs risky at a glance
- **How to Request Changes Safely** - 4-step process with documentation template
- **What You Will NOT Break** - Reassurance section listing protected elements

**Reuse:** Use this pattern whenever creating change management documentation for non-technical system owners. Key elements:
- Clear boundaries between safe and risky changes
- Every safe change must be reversible by the owner
- Every risky change must include specific risks and request process
- Use exact locations (not "go to settings" but "click the gear icon in top right corner")
- Include time estimates for both self-service and support-assisted changes
- Build confidence with "What You Will NOT Break" section
- Customize safe/risky categories by system type:
  - Analytics systems: safe = filters/date ranges, risky = calculations/data sources
  - Automation systems: safe = notification recipients/schedule times, risky = workflow logic/API configs
  - Customer apps: safe = display text/colors, risky = validation rules/authentication
- Target 1000-1500 words covering 5-8 safe changes and 5-8 risky changes

Example structure:
```markdown
## Safe Changes (You Can Do These)

### ✅ Change 1: [What They're Changing]

**Why you might need this:**
[Business reason]

**Where to do this:**
1. Go to [exact URL]
2. Click [specific button]
3. Find [exact field name]

**Step-by-step:**
1. [Action with expected result]
2. [Action with expected result]
3. Save and verify

**How to verify it worked:**
[Specific test]

**How to undo if needed:**
[Exact reversal steps]

**Estimated time:** [X minutes]

## Risky Changes (Get Help With These)

### ⚠️ Change 1: [What They Might Want]

**Why this needs expert help:**
[Plain English explanation]

**What could go wrong:**
- [Specific risk 1]
- [Specific risk 2]

**How to request this change:**
[4-step process with contact info and response times]
```

### Pattern: Cost Transparency Documentation
**Task:** US-306
**Problem:** Business owners don't understand their monthly operating costs or how to control them. Without clear cost documentation, they either overspend unknowingly or waste time asking support about normal billing fluctuations. They can't distinguish between normal cost variation (5-15% monthly) and concerning spikes (50%+ increases).
**Solution:** Create four-layer cost documentation structure:

**Layer 1: Cost Table** - Clear table showing each service with plain English description, monthly cost range, and billing type. Include context for ranges: "$20-50 (based on X executions/day)" not just "$20-50". Add total estimated monthly cost with usage assumptions clearly stated.

**Layer 2: Cost Drivers** - Per-service explanation of what causes costs to increase:
- Specific metrics that drive costs (execution count, storage GB, API tokens)
- Real examples showing volume impact ("100 orders/day vs 50 = double executions")
- How to check if approaching limits (exact billing URLs, specific metrics to look for)
- Warning thresholds (80% of limit triggers concern)
- What overages cost (specific pricing for exceeding limits)

**Layer 3: Monitoring Instructions** - Step-by-step guide to check current costs:
- Where to go (exact URLs for each service billing page)
- What credentials to use
- Which specific numbers to record
- Simple tracking template (Month, Service 1, Service 2, Total, Notes)
- Time estimate (5 minutes monthly check)

**Layer 4: Billing Alerts** - Complete setup instructions for automatic warnings:
- Step-by-step for each service's alert configuration
- Recommended thresholds (80% of usage limits, 120% of typical spending)
- What the email notifications will look like
- Backup calendar reminder in case alerts fail

**Additional sections:**
- **Normal vs. Concerning patterns** - Calibrate expectations with specific percentages
  - ✅ Normal: 5-15% monthly fluctuation, 10-20% annual growth, 20-40% spike after major changes
  - ⚠️ Concerning: 50%+ sudden increase, 20%+ every month for 3+ months, mystery charges, repeated overages
- **Cost investigation procedure** - 5-step process for troubleshooting spikes
  1. Identify which service increased (compare month-over-month)
  2. Check usage metrics for that service (what metric spiked?)
  3. Look for business explanation (new customers, campaigns, features?)
  4. Look for technical explanation (workflow stuck in loop, data archival failed?)
  5. Document findings and decide (contact support vs. accept new normal)
- **Cost optimizations** - Safe (owner can do) vs. Risky (needs expert help) following MAKING-CHANGES.md pattern

**Reuse:** Use this pattern whenever creating cost/billing documentation for business owners using subscription SaaS services. Key elements:
- Always include all four layers: table, drivers, monitoring, alerts
- Provide exact billing URLs (not "check your billing page" but "go to app.supabase.com → Settings → Billing")
- Use specific percentages for normal vs. concerning thresholds
- Include time estimates for monitoring tasks (5-minute monthly check)
- Explain costs in context of business actions ("more customers = more data = higher storage costs")
- Customize by system type:
  - Analytics systems: focus on query volume, storage growth, report generation
  - Automation systems: focus on execution counts, API call volumes, workflow complexity
  - Customer apps: focus on user count, file storage, authentication volume
- Target 2000-3000 words covering all services comprehensively
- Tone: transparent, educational, empowering (not fear-based)

Example structure:
```markdown
## Your Monthly Operating Costs
[Table with Service, Description, Cost Range, Billing Type]

## What Makes Your Costs Increase
[Per-service breakdown of usage drivers]

## How to Check Your Current Costs
[Step-by-step monitoring guide]

## How to Set Up Billing Alerts
[Setup instructions per service]

## What's Normal vs. What's Concerning
[Pattern recognition with specific thresholds]

## How to Investigate Cost Increases
[5-step troubleshooting procedure]

## How to Keep Costs Under Control (Optional)
[Safe and risky optimizations]
```

### Pattern: Project Handover Checklist Documentation
**Task:** US-307
**Problem:** Project handovers are often incomplete - forgotten credentials, missing documentation, inadequate training, or no follow-up plan. Both developers and clients need a systematic approach to ensure nothing is forgotten and the client feels confident operating their new system.
**Solution:** Create three-phase handover checklist structure:

**Phase 1: Pre-Handover Preparation** (48-72 hours before meeting)
- System verification (all features working, production stable, no critical bugs)
- Access & credentials preparation (accounts created, credentials documented, billing configured)
- Documentation package ready (Owner's Manual generated with all 7 sections)

**Phase 2: Handover Meeting** (90-120 minute structured session)
- Part 1: Access Transfer (20-30 min) - Client logs into all accounts, resets passwords, confirms access
- Part 2: System Walkthrough (30-40 min) - Interactive demo of WHAT-YOU-HAVE and HOW-IT-WORKS docs with live system
- Part 3: Operations Training (20-30 min) - Walk through DAILY-OPERATIONS, WHEN-THINGS-BREAK, MAKING-CHANGES, COSTS together
- Part 4: Support & Next Steps (10-15 min) - Contact info, support coverage explanation, schedule first check-in

**Phase 3: Post-Handover Follow-Up** (Critical for success)
- Immediate (24 hours): Send summary email, verify access, monitor for issues
- First week (7 days): Check-in call to answer questions that came up
- First month (30 days): Review performance, costs, and any needed documentation updates

**Key components:**
- Every checklist item must have clear completion criteria and client confirmation statements
- Include time estimates for all activities so clients can budget their time
- Access transfer must happen first before any training begins
- Documentation walkthrough should be interactive (demonstrate then let client try)
- Formal sign-off certification provides accountability for both parties
- "What's Next" section sets clear ongoing responsibilities

**Reuse:** Use this pattern whenever delivering any system to a client (n8n workflows, Supabase apps, custom dashboards, full-stack applications). Key elements:
- Customize account list per system (n8n, Supabase, Vercel, AWS, etc.)
- Adjust meeting time estimates based on system complexity (simple automation: 60 min, complex dashboard: 120 min)
- Adapt training section to available documentation (if using Owner's Manual generator, reference all 6 sections)
- Customize by system type:
  - Analytics systems: emphasize dashboard navigation, metric interpretation, report generation
  - Automation systems: emphasize workflow monitoring, execution history, manual triggers, notification recipients
  - Customer apps: emphasize user management, customer support responsibilities, safe content changes
- Post-handover follow-up schedule is non-negotiable - first week determines handover success
- Target 1500-2000 words covering all phases comprehensively

Example structure:
```markdown
# Handover Checklist: [Project Name]

## Introduction
[Welcome message explaining comprehensive handover process]

## Pre-Handover Preparation
[Developer checklist to complete before meeting]

## Handover Meeting Checklist
### Part 1: Access Transfer (20-30 minutes)
[Account transfer with login verification]

### Part 2: System Walkthrough (30-40 minutes)
[Interactive demonstration with documentation]

### Part 3: Operations Training (20-30 minutes)
[Training on all operational docs]

### Part 4: Support & Next Steps (10-15 minutes)
[Contact info, support coverage, scheduling]

## Post-Handover Follow-Up
[24hr, 7-day, 30-day check-ins]

## Handover Completion Certification
[Client and developer sign-off with confidence assessment]

## What's Next?
[Responsibilities, reminders, emergency contacts]
```

### Pattern: Multi-Generator Orchestration with DOCX Compilation
**Task:** US-308
**Problem:** After creating 7 individual documentation generators, need a single command to run all generators and compile output into one professional DOCX file. Manual execution of each generator is error-prone and clients expect a single deliverable document, not 7 separate markdown files.
**Solution:** Create orchestration script that:
1. Validates environment and inputs upfront
2. Runs all 7 generators sequentially with error handling
3. Reads generated markdown files
4. Converts markdown to DOCX using docx library
5. Compiles into single document with professional elements

**Key Implementation Details:**
```javascript
// Define generator sequence
const generators = [
  { name: 'WHAT-YOU-HAVE', script: 'generate-what-you-have.js', output: 'WHAT-YOU-HAVE.md' },
  { name: 'HOW-IT-WORKS', script: 'generate-how-it-works.js', output: 'HOW-IT-WORKS.md' },
  // ... 5 more generators
];

// Run generators sequentially
for (const generator of generators) {
  await execAsync(`node "${scriptPath}" "${prdPath}"`);
  // Verify output was created
}

// Convert markdown to DOCX paragraphs
function markdownToDOCX(markdown) {
  // Handle: H1-H3 headings, bullet lists, numbered lists,
  // checkboxes, bold text, regular paragraphs
}

// Create professional DOCX structure
const doc = new Document({
  sections: [{
    properties: { page: { pageNumbers: { start: 1 } } },
    footers: { default: new Footer({ children: [/* footer content */] }) },
    children: [
      /* Cover page */,
      /* Table of contents */,
      /* Section 1 with page break */,
      /* Section 2 with page break */,
      // ...
    ]
  }]
});
```

**Professional DOCX Elements:**
1. **Cover Page:** Project name, "Owner's Manual" title, generation date, centered alignment
2. **Table of Contents:** Numbered list of all 7 sections with page breaks after
3. **Section Structure:** Each section starts with H1 title, includes all content, ends with page break
4. **Footer:** Project name and "Owner's Manual" text in footer (across all pages)
5. **Formatting:** Proper heading levels (H1/H2/H3), spacing (before/after), bullet/numbered lists

**Markdown-to-DOCX Conversion Support:**
- Headings: `# H1`, `## H2`, `### H3` → HeadingLevel.HEADING_1/2/3
- Bullet lists: `- item` or `* item` → bullet paragraphs
- Numbered lists: `1. item` → numbering reference
- Checkboxes: `- [ ]` → ☐, `- [x]` → ☑
- Bold text: `**bold**` → TextRun with bold: true
- Regular text → standard paragraphs with spacing

**Error Handling & Testing:**
- Validate environment variables before generation (ANTHROPIC_API_KEY)
- Provide `--compile-only` flag to skip generation (useful for testing or when markdown files already exist)
- Show file status check before compilation (existing vs missing files)
- Verify each generator output was created before moving to next
- Gracefully handle missing markdown files (skip and warn user)
- Install docx library automatically if not present

**Reuse:** Use this pattern whenever you need to orchestrate multiple generation scripts and compile outputs into single deliverable. Key elements:
- Sequential execution with error handling between steps
- File existence verification before and after generation
- Professional document structure (cover, TOC, sections, footers)
- Markdown-to-DOCX conversion supporting common formatting
- Command-line flags for flexible usage (--compile-only, --skip-generation)
- Automatic dependency management (install required libraries)
- Clear progress logging with visual separators
- Output filename generation from project metadata
- Target: Single command execution for complete deliverable

Example usage:
```bash
# Full generation and compilation
node scripts/compile-owner-manual.js path/to/PRD.md

# Compile existing files only (for testing)
node scripts/compile-owner-manual.js --compile-only path/to/PRD.md
```

---

## Things That Didn't Work

### Failed Approach: [Name]
**Task:** US-XXX
**What I Tried:** [Description]
**Why It Failed:** [Reason]
**Better Approach:** [What worked instead]

---

## Library/Tool Notes

### n8n
- [Specific n8n learnings for this project]

### Supabase
- [Specific Supabase learnings]

### Other
- [Other tool learnings]

---

## Questions for Human Review

- [ ] [Question 1]
- [ ] [Question 2]

---

*Last updated: 2026-01-16*
*Updated by: RALPH-JAWS v4*
*Tasks completed this session: US-301, US-302, US-303, US-304, US-305, US-306, US-307, US-308*
