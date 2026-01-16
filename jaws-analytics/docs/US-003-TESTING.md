# US-003 Testing Guide: Build Artifact Reader Workflow

## Overview
This document provides step-by-step instructions for testing the Build Artifact Reader workflow.

## Prerequisites

1. **n8n Running:** Ensure n8n is running and accessible
   - Local: `http://localhost:5678`
   - Docker: Ensure container is running
   - Cloud: Use your n8n cloud URL

2. **Workflow Imported:** The `build-artifact-reader.json` workflow must be imported and activated in n8n

3. **Test Project Available:** You need a completed RALPH-JAWS project to test with. This project itself can be used as test data.

## Level 1: Syntax Validation

**Goal:** Verify the workflow JSON is valid and can be imported to n8n.

### Test 1.1: JSON Syntax
```bash
# Using Node.js (cross-platform)
node -e "JSON.parse(require('fs').readFileSync('workflows/build-artifact-reader.json', 'utf8')); console.log('✅ Valid JSON');"
```

**Expected Output:**
```
✅ Valid JSON
```

**If Failed:**
- Check for syntax errors in build-artifact-reader.json
- Verify file encoding is UTF-8
- Ensure no trailing commas or missing brackets

---

## Level 2: Unit Testing

**Goal:** Test the workflow with real data and verify it returns expected results.

### Test 2.1: Success Case - This Project as Test Data

**Setup:**
1. Import workflow to n8n
2. Activate the workflow
3. Get the webhook URL from n8n (should be `http://localhost:5678/webhook/analyze-build`)

**Test Command (Windows PowerShell):**
```powershell
$body = @{
    build_path = $PWD.Path
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5678/webhook/analyze-build" -Method POST -Body $body -ContentType "application/json" | ConvertTo-Json -Depth 10
```

**Test Command (Linux/Mac Bash):**
```bash
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d "{\"build_path\": \"$(pwd)\"}" \
  | jq .
```

**Expected Response:**
```json
{
  "status": 200,
  "message": "Build artifacts successfully read",
  "data": {
    "build_path": "/path/to/jaws-analytics",
    "project_name": null,
    "client_name": null,
    "artifacts": {
      "prd": {
        "found": true,
        "content": "# PRD: JAWS Analytics Dashboard System..."
      },
      "progress": {
        "found": true,
        "content": "# Progress Log..."
      },
      "state": {
        "found": true,
        "content": {
          "currentIteration": 3,
          "completedTasks": ["US-001", "US-002", "US-003"],
          ...
        }
      },
      "agents": {
        "found": true,
        "content": "# Agent Knowledge Base..."
      },
      "workflows": {
        "found": true,
        "count": 1,
        "files": [
          {
            "filename": "build-artifact-reader.json",
            "content": { ... }
          }
        ]
      }
    }
  }
}
```

**Validation Checklist:**
- [ ] HTTP status code is 200
- [ ] `status` field equals 200
- [ ] `message` includes "successfully"
- [ ] `prd.found` is true
- [ ] `prd.content` includes "JAWS Analytics"
- [ ] `progress.found` is true
- [ ] `state.found` is true
- [ ] `state.content` is a JSON object (not string)
- [ ] `agents.found` is true
- [ ] `workflows.found` is true
- [ ] `workflows.count` >= 1
- [ ] `workflows.files` is an array

---

### Test 2.2: Error Case - Missing Required Files

**Test Command (PowerShell):**
```powershell
$body = @{
    build_path = "C:\NonExistent\Path"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5678/webhook/analyze-build" -Method POST -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue
```

**Test Command (Bash):**
```bash
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d '{"build_path": "/non/existent/path"}' \
  | jq .
```

**Expected Response:**
```json
{
  "status": 400,
  "error": "Required files missing",
  "message": "The following required files were not found: PRD.md, progress.txt, ralph-state.json",
  "missing_files": ["PRD.md", "progress.txt", "ralph-state.json"],
  "build_path": "/non/existent/path"
}
```

**Validation Checklist:**
- [ ] HTTP status code is 400
- [ ] `status` field equals 400
- [ ] `error` field includes "missing"
- [ ] `missing_files` is an array
- [ ] `missing_files` includes "PRD.md", "progress.txt", "ralph-state.json"
- [ ] `build_path` matches the input

---

### Test 2.3: Error Case - Missing build_path

**Test Command (PowerShell):**
```powershell
$body = @{
    something_else = "value"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5678/webhook/analyze-build" -Method POST -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue
```

**Test Command (Bash):**
```bash
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d '{"something_else": "value"}' \
  | jq .
```

**Expected Response:**
```json
{
  "status": 400,
  "error": "Missing required field: build_path",
  "message": "POST body must include { \"build_path\": \"/path/to/project\" }"
}
```

**Validation Checklist:**
- [ ] HTTP status code is 400
- [ ] `status` field equals 400
- [ ] `error` includes "build_path"
- [ ] `message` includes example format

---

### Test 2.4: Partial Success - Optional Files Missing

**Setup:** Create a test directory with only required files

**PowerShell:**
```powershell
# Create test directory
New-Item -ItemType Directory -Path ".\test-minimal" -Force

# Copy only required files
Copy-Item "PRD.md" ".\test-minimal\"
Copy-Item "progress.txt" ".\test-minimal\"
Copy-Item "ralph-state.json" ".\test-minimal\"

# Test
$body = @{
    build_path = (Resolve-Path ".\test-minimal").Path
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5678/webhook/analyze-build" -Method POST -Body $body -ContentType "application/json" | ConvertTo-Json -Depth 10

# Cleanup
Remove-Item ".\test-minimal" -Recurse -Force
```

**Bash:**
```bash
# Create test directory
mkdir -p ./test-minimal

# Copy only required files
cp PRD.md ./test-minimal/
cp progress.txt ./test-minimal/
cp ralph-state.json ./test-minimal/

# Test
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d "{\"build_path\": \"$(pwd)/test-minimal\"}" \
  | jq .

# Cleanup
rm -rf ./test-minimal
```

**Expected Behavior:**
- [ ] HTTP status code is 200 (not 400!)
- [ ] `prd.found` is true
- [ ] `progress.found` is true
- [ ] `state.found` is true
- [ ] `agents.found` is false (optional file)
- [ ] `workflows.found` is false (optional directory)
- [ ] No error about missing AGENTS.md or workflows/

---

## Troubleshooting

### Problem: "Cannot find module 'fs'"
**Cause:** n8n environment doesn't support Node.js built-in modules.

**Solution:**
- Ensure using n8n Code node (not Function node)
- Check n8n version (fs support added in recent versions)
- For cloud n8n, use HTTP endpoints or git repos instead of local files

---

### Problem: "ENOENT: no such file or directory"
**Cause:** File path is incorrect or n8n doesn't have access.

**Solution:**
- Use absolute paths (not relative)
- Check case sensitivity (Linux/Mac are case-sensitive)
- For Docker n8n, ensure volumes are mounted:
  ```yaml
  volumes:
    - /host/path:/container/path:ro
  ```

---

### Problem: Workflow returns empty response
**Cause:** Workflow not activated or wrong URL.

**Solution:**
- Check workflow is activated (toggle in n8n UI)
- Verify webhook URL in n8n matches test command
- Check n8n logs for errors: Settings → Log Streaming

---

### Problem: JSON.parse error for ralph-state.json
**Cause:** ralph-state.json is malformed or not valid JSON.

**Solution:**
- Validate ralph-state.json:
  ```bash
  node -e "JSON.parse(require('fs').readFileSync('ralph-state.json', 'utf8'))"
  ```
- Fix JSON syntax errors
- Ensure UTF-8 encoding

---

## Test Data Recommendations

For comprehensive testing, use a completed RALPH-JAWS project that has:

1. ✅ **Complete PRD.md** - Multiple user stories, phases, checkpoints
2. ✅ **Detailed progress.txt** - Multiple iterations logged
3. ✅ **Valid ralph-state.json** - Realistic iteration counts, tasks, failures
4. ✅ **Optional AGENTS.md** - Some learnings documented
5. ✅ **Optional workflows/** - One or more n8n workflow JSON files

**This project (jaws-analytics) is ideal test data** because it contains all required files and demonstrates the expected structure.

---

## Success Criteria for US-003

All 10 acceptance criteria must be verified:

- [x] Webhook trigger at `/webhook/analyze-build` → Test 2.1 passed
- [x] Accepts POST with `{ "build_path": "/path/to/project" }` → Test 2.1 passed
- [x] Reads and parses PRD.md → Test 2.1 shows prd.found=true
- [x] Reads and parses progress.txt → Test 2.1 shows progress.found=true
- [x] Reads and parses ralph-state.json → Test 2.1 shows state as parsed JSON object
- [x] Reads and parses AGENTS.md → Test 2.1 shows agents.found=true
- [x] Finds and reads all workflows/*.json files → Test 2.1 shows workflows array
- [x] Returns 400 if required files missing → Test 2.2 passed
- [x] Returns 200 with parsed artifacts object → Test 2.1 passed
- [x] Handle missing optional files gracefully → Test 2.4 passed

---

## Next Steps After Testing

Once all tests pass:

1. ✅ Mark US-003 as complete in PRD.md
2. ✅ Update progress.txt with learnings
3. ✅ Update AGENTS.md with reusable patterns
4. 📝 Move to US-004: Create PRD Analyzer Sub-Workflow

---
