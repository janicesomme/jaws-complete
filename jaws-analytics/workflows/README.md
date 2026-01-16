# n8n Workflows

This directory contains n8n workflow JSON files for the JAWS Analytics Dashboard System.

## Workflows

### 1. build-artifact-reader.json
**Purpose:** Reads and parses all build artifacts from a completed RALPH-JAWS project.

**Trigger:** Webhook at `/webhook/analyze-build`

**Input:**
```json
{
  "build_path": "/path/to/completed/project",
  "project_name": "Optional Project Name",
  "client_name": "Optional Client Name"
}
```

**Output (Success - 200):**
```json
{
  "status": 200,
  "message": "Build artifacts successfully read",
  "data": {
    "build_path": "/path/to/project",
    "project_name": "Project Name",
    "client_name": "Client Name",
    "artifacts": {
      "prd": {
        "found": true,
        "content": "... PRD.md content as string ..."
      },
      "progress": {
        "found": true,
        "content": "... progress.txt content as string ..."
      },
      "state": {
        "found": true,
        "content": { ... parsed ralph-state.json object ... }
      },
      "agents": {
        "found": true,
        "content": "... AGENTS.md content as string ..."
      },
      "workflows": {
        "found": true,
        "count": 3,
        "files": [
          {
            "filename": "workflow1.json",
            "content": { ... parsed workflow JSON ... }
          }
        ]
      }
    }
  }
}
```

**Output (Error - 400):**
```json
{
  "status": 400,
  "error": "Required files missing",
  "message": "The following required files were not found: PRD.md, progress.txt",
  "missing_files": ["PRD.md", "progress.txt"],
  "build_path": "/path/to/project"
}
```

**Required Files:**
- `PRD.md` - Project Requirements Document
- `progress.txt` - Build progress log
- `ralph-state.json` - RALPH execution state

**Optional Files:**
- `AGENTS.md` - Agent learnings and patterns
- `workflows/*.json` - n8n workflow files (for n8n projects)

**Workflow Nodes:**
1. **Webhook Trigger** - Accepts POST requests
2. **Validate Input** - Checks for required build_path field
3. **Check Validation** - Routes to error or processing
4. **Read PRD.md** - Reads PRD file
5. **Read progress.txt** - Reads progress log
6. **Read ralph-state.json** - Reads and parses state JSON
7. **Read AGENTS.md** - Reads agent learnings (optional)
8. **Read Workflows** - Finds and reads all workflow/*.json files
9. **Check Required Files** - Validates all required files were found
10. **Build Success Response** - Constructs success payload
11. **Success Response** - Returns 200 with artifacts
12. **Missing Files Error** - Constructs error payload
13. **Missing Files Response** - Returns 400 with error details

**Error Handling:**
- Missing `build_path` → 400 error immediately
- Missing required files (PRD, progress, state) → 400 error with list
- Missing optional files (AGENTS, workflows) → Success with found=false
- File read errors → Captured in error field, treated as missing

## Installation

### Method 1: Import via n8n CLI (Recommended)

```bash
# Import all workflows
n8n import:workflow --input=workflows/prd-analyzer.json
n8n import:workflow --input=workflows/prd-analyzer-test.json
n8n import:workflow --input=workflows/build-artifact-reader.json

# List imported workflows to get their IDs
n8n list:workflow

# Activate the test wrapper workflow (use the ID from list command)
n8n update:workflow --id=<workflow-id> --active=true

# Note: If n8n is already running, you'll need to restart it for activation to take effect
# Stop n8n (Ctrl+C) and restart: n8n start
```

### Method 2: Import via n8n UI

1. Open n8n UI at `http://localhost:5678`
2. Go to **Workflows** → **Add Workflow**
3. Click **Import from File**
4. Select the workflow JSON file (e.g., `prd-analyzer-test.json`)
5. Click **Save**
6. **Toggle the workflow to Active** (switch in top-right corner)
7. Repeat for all workflows

**IMPORTANT:** For webhook workflows (like `prd-analyzer-test.json`), you MUST activate the workflow for the webhook endpoint to be available.

### Configuration

**File System Access:**
This workflow uses Node.js `fs` module to read files. Ensure:

- **Local n8n:** No additional configuration needed
- **Docker n8n:** Mount project directories as volumes:
  ```yaml
  volumes:
    - /path/to/projects:/data/projects:ro
  ```
- **Cloud n8n:** File system access may be restricted. Consider using HTTP endpoints or git repos instead.

### Testing

**Level 1 - Syntax Validation:**
```bash
# Verify JSON is valid
node -e "JSON.parse(require('fs').readFileSync('workflows/build-artifact-reader.json', 'utf8')); console.log('Valid');"
```

**Level 2 - Unit Test:**
```bash
# Test with this project as test data
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d "{\"build_path\": \"$(pwd)\"}"
```

**Expected Result:**
- Status: 200
- All required files found: true
- PRD content includes "JAWS Analytics Dashboard"
- State content includes currentIteration field
- Workflows array is empty (no workflows in this project yet)

**Level 2 - Error Test:**
```bash
# Test with non-existent path
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d '{"build_path": "/non/existent/path"}'
```

**Expected Result:**
- Status: 400
- Error: "Required files missing"
- missing_files array includes PRD.md, progress.txt, ralph-state.json

## Troubleshooting

### Error: "ENOENT: no such file or directory"
**Cause:** File path is incorrect or file doesn't exist.
**Fix:**
- Verify the build_path is absolute (not relative)
- Check file names are exact (case-sensitive on Linux)
- Ensure n8n has read permissions

### Error: "Cannot find module 'fs'"
**Cause:** n8n environment doesn't support Node.js fs module.
**Fix:** Use n8n's "Read Binary File" node instead of Code node with fs.

### Error: "JSON.parse failed"
**Cause:** ralph-state.json or workflow JSON files are malformed.
**Fix:** Validate JSON syntax in those files before running workflow.

### Webhook returns nothing
**Cause:** Workflow not active or wrong URL.
**Fix:**
- Ensure workflow is activated in n8n UI
- Check webhook URL matches: `http://localhost:5678/webhook/analyze-build`
- Check n8n logs for errors

---

### 2. prd-analyzer.json
**Purpose:** Extracts structured metrics from PRD.md content.

**Trigger:** Execute Workflow Trigger (called by other workflows)

**Input:**
```json
{
  "prd_content": "... full PRD.md markdown content as string ..."
}
```

**Output:**
```json
{
  "project_name": "Project Name",
  "client_name": "Client Name or null",
  "total_user_stories": 10,
  "user_story_ids": ["US-001", "US-002", "..."],
  "tasks_completed": 25,
  "tasks_incomplete": 15,
  "tasks_skipped": 2,
  "tasks_total": 42,
  "completion_rate": 59.5,
  "phases": [
    {
      "number": 1,
      "name": "Foundation",
      "checkpoint": "FOUNDATION"
    }
  ],
  "goals": [
    "Goal 1 text",
    "Goal 2 text"
  ],
  "tech_stack": [
    "Analytics Engine: n8n workflow",
    "Database: Supabase PostgreSQL"
  ]
}
```

**What it extracts:**
- Project name from `# PRD: Name` title
- Client name from `**Client:**` field
- User story count from `### US-XXX:` patterns
- Task counts from checkbox patterns: `[x]`, `[ ]`, `[SKIPPED]`
- Phase information from `PHASE X: Name [CHECKPOINT: NAME]` patterns
- Goals from bullet points in `## Goals` section
- Tech stack from `**Category:** Technology` in `## Technical Stack` section

**Usage:**
This is a sub-workflow called by the main orchestrator. It does NOT have a webhook endpoint.

---

### 3. prd-analyzer-test.json
**Purpose:** Test wrapper for PRD Analyzer sub-workflow with webhook endpoint.

**Trigger:** Webhook at `/webhook-test/analyze-prd`

**Input:**
```json
{
  "prd_content": "# PRD: Test\n\n### US-001: Task\n- [x] Done"
}
```

**Output:** Same as prd-analyzer.json (passes through the result)

**Usage:**
This workflow provides a testable HTTP endpoint for the PRD Analyzer sub-workflow. Use it for validation and testing:

```bash
# Test with sample PRD content
curl -X POST http://localhost:5678/webhook-test/analyze-prd \
  -H "Content-Type: application/json" \
  -d '{"prd_content": "# PRD: Test Project\n\n### US-001: Test\n- [x] Done\n- [ ] Not done"}'
```

**Workflow Nodes:**
1. **Webhook Trigger** - Accepts POST requests
2. **Extract Input** - Extracts prd_content from body
3. **Execute PRD Analyzer** - Calls the PRD Analyzer sub-workflow
4. **Respond to Webhook** - Returns the analysis result

**Why two workflows?**
- `prd-analyzer.json` is the pure sub-workflow (no webhook, called internally)
- `prd-analyzer-test.json` is the test wrapper (webhook endpoint for validation)
- This pattern allows testing sub-workflows independently before integration

---

## Next Steps

After US-004 is complete, the following sub-workflows will be created:
- **workflow-analyzer.json** (US-005) - Analyzes n8n workflow files
- **token-estimator.json** (US-006) - Estimates Claude API token usage
- **state-analyzer.json** (US-007) - Extracts metrics from ralph-state.json
- **ai-summary-generator.json** (US-008) - Generates summaries with Claude
- **architecture-diagram-generator.json** (US-009) - Generates Mermaid diagrams
- **dashboard-spec-generator.json** (US-010) - Compiles dashboard spec
- **supabase-storage.json** (US-011) - Stores data in Supabase
- **main-analytics-orchestrator.json** (US-012) - Coordinates all sub-workflows
