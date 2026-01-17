# How It Works: JAWS Analytics Dashboard System

## The Big Picture

Your system works like an automatic report generator with a memory. When you finish building a client project, the system reads all your files, counts what was created, asks an AI to write summaries, and displays everything on a professional dashboard. Think of it as having an assistant who documents your work, calculates costs, and creates client-ready reports while you sleep.

## The Journey of a Project Analysis

**Step 1: The Starting Signal**

**When:** You finish a client project and send a signal to your analytics system (by calling a special web address)

**Then:** Your automation immediately wakes up and starts reading files from your project folder

**Why This Matters:** The moment you're done building, your documentation process begins automatically - no manual report creation needed

---

**Step 2: File Collection**

**When:** The automation receives your project folder location

**Then:** It opens the folder and reads four types of files:
- Your project plan (PRD.md) - what you promised to build
- Your progress notes (progress.txt) - what you actually completed
- Your system state file (ralph-state.json) - how long it took and what challenges you faced
- Your workflow files (workflows/*.json) - the automations you created

**Why This Matters:** The system needs to see all the pieces to understand the complete picture of your work

---

**Step 3: Counting and Extracting**

**When:** All files are collected

**Then:** The system counts everything important:
- How many features (user stories) were in the plan
- How many you completed versus skipped
- How many automations (workflows) you built
- How many database tables you created
- How long the project took in iterations

**Why This Matters:** These numbers prove the scope of work and help justify your pricing to clients

---

**Step 4: Workflow Deep-Dive**

**When:** The system finds automation files (workflows)

**Then:** It analyzes each automation to understand:
- What triggers it (a signal from outside, a schedule, or manual activation)
- How many steps it contains
- Whether it uses AI (Claude nodes)
- Whether it saves data (Supabase nodes)
- How many AI tokens it will use per run

**Why This Matters:** You can show clients exactly what each automation does and estimate monthly operating costs

---

**Step 5: Cost Calculation**

**When:** The system knows how many AI calls each automation makes

**Then:** It estimates monthly costs by:
- Counting tokens in prompts (roughly 4 characters = 1 token)
- Applying Claude's pricing ($3 per million input tokens, $15 per million output tokens)
- Multiplying by expected monthly usage

**Why This Matters:** Clients want to know "what will this cost me to run?" - now you have an answer

---

**Step 6: AI Summary Writing**

**When:** All the numbers are counted and organized

**Then:** The system asks an AI assistant (Claude) to read your technical files and write three things:
- An executive summary (for business owners who want the big picture)
- A technical summary (for developers who want implementation details)
- A value proposition (talking points about ROI and benefits)

**Why This Matters:** Technical documentation gets translated into language your clients actually understand

---

**Step 7: Architecture Diagram Creation**

**When:** The AI understands how your workflows connect

**Then:** It generates a flowchart diagram showing:
- Your main orchestrator workflow at the top
- Connected sub-workflows below it
- Arrows showing which workflows call which others
- Labels explaining what triggers each one

**Why This Matters:** A visual diagram helps clients understand the system architecture without reading code

---

**Step 8: Dashboard Specification Building**

**When:** All summaries, counts, and diagrams are ready

**Then:** The system compiles everything into a structured "dashboard spec" containing:
- Header information (project name, client name, date, duration)
- Stats cards (workflows created, tables created, token estimates, completion rate)
- Workflow breakdown tables
- Token usage charts
- Build timeline
- Architecture diagram
- Plain English summaries

**Why This Matters:** This spec becomes the blueprint for what displays on your dashboard

---

**Step 9: Saving to the Database**

**When:** The dashboard spec is complete

**Then:** Everything gets saved into your secure database (Supabase) in three organized tables:
- Build overview (jaws_builds table) - high-level project info
- Individual workflows (jaws_workflows table) - details about each automation
- Database tables (jaws_tables table) - what data structures were created

**Why This Matters:** All your project history is preserved forever, letting you track your entire consulting portfolio

---

**Step 10: Dashboard Display**

**When:** You open your analytics dashboard website

**Then:** The dashboard loads data from your database and displays:
- A list of all your projects
- Stats and metrics for each
- Interactive charts showing token usage
- The architecture diagram
- Summaries you can copy-paste into client emails

**Why This Matters:** You have a professional portfolio of all your work at your fingertips

---

**Step 11: PDF Export**

**When:** You click "Export PDF" on a project

**Then:** The system generates a professional PDF document with:
- Cover page with client name and project name
- Executive summary
- Architecture diagram
- Stats and metrics
- Workflow breakdown
- Cost projections

**Why This Matters:** You hand clients a polished deliverable document without spending hours in PowerPoint

## Decision Points in the Flow

**Decision Point: Does This Project Have Workflows?**

- **If** the project folder contains a "workflows/" directory with JSON files, **then** the system performs detailed workflow analysis and includes automation metrics
- **Otherwise**, **then** the system skips workflow analysis and focuses on other project components (like database structure or documentation)

**Decision Point: Did the Build Have Failures?**

- **If** the state file shows failed tasks or rabbit holes detected, **then** the dashboard highlights these issues in the technical view
- **Otherwise**, **then** the dashboard emphasizes the smooth completion and efficiency

**Decision Point: Which View is Selected?**

- **If** you toggle to "Client View", **then** the dashboard shows simplified summaries and high-level stats
- **If** you toggle to "Technical View", **then** the dashboard reveals detailed breakdowns, node counts, and iteration history

## What You'll Notice When It's Working

When everything is running correctly, you'll observe:

- Analysis completes in 30-60 seconds after triggering
- Your dashboard updates automatically with the new project
- All charts and diagrams render properly
- PDF exports include all sections with correct formatting
- Token estimates are reasonable (not wildly high or zero)
- AI summaries make sense and match your project

## Common Flow Triggers

Your analytics system can start in three ways:

1. **Manual Trigger**: You send a web request with your project folder path
2. **Automatic Trigger**: Your RALPH automation calls the analytics webhook when a build finishes
3. **Re-Analysis**: You trigger analysis again on an existing project (it updates the existing record instead of creating a duplicate)

## The End Result

From start to finish, here's what you get:

**Input:** A folder containing your project files (PRD, progress notes, workflows, state files)

**Process:** Automatic reading, counting, AI summarization, diagram generation, and database storage

**Output:** A professional dashboard with metrics, charts, diagrams, and exportable PDFs - all generated without manual work

## For the Technically Curious

While this flow is happening, the system is also:

- Validating JSON syntax in workflow files (skipping malformed files gracefully)
- Handling missing optional files (like workflows/) without crashing
- Creating timestamps for audit trails
- Using "upsert" operations so re-analyzing a project updates the existing record
- Applying security rules (Row Level Security) to protect your data
- Logging errors for troubleshooting if something fails

## Typical Timeline

- **Step 1-2** (File Collection): 2-5 seconds
- **Step 3-5** (Counting and Analysis): 5-10 seconds
- **Step 6-7** (AI Summaries and Diagrams): 15-30 seconds (AI calls take time)
- **Step 8-9** (Spec Building and Database Save): 3-5 seconds
- **Step 10-11** (Dashboard Display and PDF Export): Instant (on-demand)

**Total time from trigger to dashboard display: 30-60 seconds**
