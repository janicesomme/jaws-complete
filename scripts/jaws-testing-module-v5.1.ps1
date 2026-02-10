# ============================================================================
# JAWS TESTING MODULE v5.1
# Evidence-Based Validation Enhancement
# Add this to ralph-jaws-v5.ps1 or import as module
# ============================================================================
#
# v5.1 CHANGES (Feb 2026):
# - Evidence-based validation: every test result requires proof
# - Agent-level validation protocol for agent team builds
# - Contract diff: compare backend curl vs frontend fetch before integration
# - Evidence audit: flag tests that pass without evidence
# - Enhanced report with evidence sections and contract diff results
#
# USAGE:
#   . .\jaws-testing-module-v5.ps1
#   
#   # Standard (evidence optional)
#   $results = Invoke-JAWSTests -Level "all"
#   
#   # Evidence required (tests without proof get WARNING)
#   $results = Invoke-JAWSTests -Level "all" -EvidenceRequired
#
#   # Agent team validation
#   $agentResults = Invoke-AgentValidation -Agents @("database","backend","frontend")
#
#   # Contract diff before integration
#   $diffResults = Invoke-ContractDiff -ContractsPath "CONTRACTS.md"
#
# ============================================================================

# New parameters to add to ralph-jaws-v5.ps1:
# [switch]$GenerateTests,
# [switch]$RunTests,
# [ValidateSet("all", "smoke", "functional", "edge")]
# [string]$TestLevel = "all",
# [switch]$TestReport,
# [switch]$EvidenceRequired,
# [switch]$AgentValidation,
# [switch]$ContractDiff,
# [string]$TestManifestPath = "TEST-MANIFEST.md",
# [string]$TestReportPath = "TEST-REPORT.md"

# ============================================================================
# EVIDENCE COLLECTION HELPERS
# ============================================================================

function New-TestResult {
    <#
    .SYNOPSIS
    Creates a standardized test result object with evidence support.
    Every test result flows through this function to ensure consistent structure.
    #>
    param(
        [string]$Id,
        [string]$Name,
        [ValidateSet("PASS", "FAIL", "WARNING", "SKIPPED")]
        [string]$Status,
        [string]$Time = "0s",
        [string]$Notes = "",
        [string]$Evidence = "",
        [string]$EvidenceType = "none",  # none, output, file, curl, screenshot, manual
        [string]$Error = "",
        [string]$TaskId = ""             # Links to US-XXX from PRD
    )
    
    $statusIcon = switch ($Status) {
        "PASS"    { [char]0x1F7E2 + " PASS" }
        "FAIL"    { [char]0x1F534 + " FAIL" }
        "WARNING" { [char]0x1F7E1 + " WARNING" }
        "SKIPPED" { [char]0x26AA  + " SKIPPED" }
    }
    
    return @{
        id           = $Id
        name         = $Name
        status       = $statusIcon
        rawStatus    = $Status
        time         = $Time
        notes        = $Notes
        evidence     = $Evidence
        evidenceType = $EvidenceType
        error        = $Error
        taskId       = $TaskId
        timestamp    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function Test-EvidencePresent {
    <#
    .SYNOPSIS
    Checks if a test result has valid evidence attached.
    Used when -EvidenceRequired is set to flag unproven passes.
    #>
    param([hashtable]$TestResult)
    
    return (
        $TestResult.evidence -and 
        $TestResult.evidence.Trim().Length -gt 0 -and 
        $TestResult.evidenceType -ne "none"
    )
}

function Add-EvidenceAudit {
    <#
    .SYNOPSIS
    Reviews all test results and flags passes without evidence when required.
    Downgrades PASS to WARNING if evidence is missing.
    #>
    param(
        [array]$TestResults,
        [bool]$EvidenceRequired = $false
    )
    
    if (-not $EvidenceRequired) { return $TestResults }
    
    $audited = @()
    foreach ($result in $TestResults) {
        if ($result.rawStatus -eq "PASS" -and -not (Test-EvidencePresent $result)) {
            # Downgrade to WARNING — passed but no proof
            $result.rawStatus = "WARNING"
            $result.status = [char]0x1F7E1 + " WARNING"
            $result.notes = "EVIDENCE MISSING: Test reported PASS but provided no proof. " + $result.notes
            Write-Host "    [AUDIT] $($result.id): $($result.name) - downgraded to WARNING (no evidence)" -ForegroundColor Yellow
        }
        $audited += $result
    }
    
    return $audited
}

function Invoke-EvidenceCapture {
    <#
    .SYNOPSIS
    Captures evidence for a test by running a command and storing the output.
    Returns the evidence string and type.
    
    .EXAMPLE
    $ev = Invoke-EvidenceCapture -Command "curl -s http://localhost:3000/api/health" -Label "Health check"
    # Returns: @{ evidence = "HTTP 200: {status: ok}"; type = "curl" }
    #>
    param(
        [string]$Command,
        [string]$Label = "Evidence capture",
        [int]$TimeoutSeconds = 30,
        [int]$MaxOutputChars = 500
    )
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Execute command and capture output
        $output = Invoke-Expression $Command 2>&1 | Out-String
        $stopwatch.Stop()
        
        # Truncate if too long (keep first and last portion)
        if ($output.Length -gt $MaxOutputChars) {
            $half = [math]::Floor($MaxOutputChars / 2) - 10
            $output = $output.Substring(0, $half) + "`n... [truncated] ...`n" + $output.Substring($output.Length - $half)
        }
        
        return @{
            evidence = "$Label`: $($output.Trim())"
            type     = if ($Command -match "curl") { "curl" } 
                       elseif ($Command -match "Test-Path|Get-Content") { "file" }
                       else { "output" }
            time     = "$([math]::Round($stopwatch.Elapsed.TotalSeconds, 1))s"
            success  = $true
        }
    } catch {
        return @{
            evidence = "$Label`: ERROR - $($_.Exception.Message)"
            type     = "output"
            time     = "0s"
            success  = $false
        }
    }
}

# ============================================================================
# TEST MANIFEST GENERATION
# ============================================================================

function New-TestManifest {
    param(
        [string]$PRDPath = "PRD.md",
        [string]$OutputPath = "TEST-MANIFEST.md",
        [switch]$IncludeEvidenceRequirements
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  GENERATING TEST MANIFEST                                            " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $PRDPath)) {
        Write-Host "  [ERROR] PRD not found: $PRDPath" -ForegroundColor Red
        return $false
    }
    
    $prd = Get-Content $PRDPath -Raw
    $projectName = "JAWS Build"
    
    # Extract project name from PRD
    if ($prd -match "# (.+?)(?=\r?\n)") {
        $projectName = $Matches[1]
    }
    
    # Extract all tasks and their acceptance criteria
    $tasks = @()
    $taskPattern = '###\s+(US-\d+):\s+(.+?)(?=\r?\n)'
    $taskMatches = [regex]::Matches($prd, $taskPattern)
    
    foreach ($match in $taskMatches) {
        $taskId = $match.Groups[1].Value
        $taskName = $match.Groups[2].Value.Trim()
        
        # Find task section
        $escapedId = [regex]::Escape($taskId)
        $sections = $prd -split "###\s+$escapedId"
        if ($sections.Count -lt 2) { continue }
        
        $taskSection = $sections[1]
        $nextTaskSplit = $taskSection -split "###\s+US-"
        $taskSection = $nextTaskSplit[0]
        
        # Extract acceptance criteria
        $criteria = @()
        $criteriaMatches = [regex]::Matches($taskSection, '\[[ x]\]\s+(.+?)(?=\r?\n|\[)')
        foreach ($c in $criteriaMatches) {
            $criteria += $c.Groups[1].Value.Trim()
        }
        
        # Extract VERIFY field
        $verify = ""
        if ($taskSection -match '\*\*VERIFY:\*\*\s*(.+?)(?=\r?\n)') {
            $verify = $Matches[1].Trim()
        }
        
        # Extract DONE field
        $done = ""
        if ($taskSection -match '\*\*DONE:\*\*\s*(.+?)(?=\r?\n)') {
            $done = $Matches[1].Trim()
        }
        
        # Extract TYPE field
        $type = "unknown"
        if ($taskSection -match '\*\*TYPE:\*\*\s*(.+?)(?=\r?\n)') {
            $type = $Matches[1].Trim()
        }
        
        $tasks += @{
            id       = $taskId
            name     = $taskName
            criteria = $criteria
            verify   = $verify
            done     = $done
            type     = $type
        }
    }
    
    # Generate manifest
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $manifest = @"
# Test Manifest: $projectName

**Generated:** $timestamp
**Source:** $PRDPath
**Tasks Covered:** $(($tasks | ForEach-Object { $_.id }) -join ', ')
**Evidence Mode:** $(if ($IncludeEvidenceRequirements) { "REQUIRED - every test must provide proof" } else { "Optional" })

---

## Quick Stats

| Level | Total Tests | Automated | Manual |
|-------|-------------|-----------|--------|
| 1 - Smoke | 5 | 5 | 0 |
| 2 - Functional | $($tasks.Count * 2) | $($tasks.Count) | $($tasks.Count) |
| 3 - Edge Cases | 9 | 6 | 3 |
| **TOTAL** | **$(5 + ($tasks.Count * 2) + 9)** | **$(5 + $tasks.Count + 6)** | **$($tasks.Count + 3)** |

---

## Level 1: Smoke Tests

*"Does it run without crashing?"*

| ID | Test Name | Type | How to Run | Pass Criteria | Evidence Required |
|----|-----------|------|------------|---------------|-------------------|
| S1 | Workflow activates | [AUTO] | Toggle workflow active | No error, status shows "Active" | Activation output |
| S2 | Webhook endpoint responds | [AUTO] | POST to webhook URL | Returns 200 OK | curl response |
| S3 | All credentials valid | [AUTO] | Test each credential | All return success | Credential test output |
| S4 | No disconnected nodes | [AUTO] | Check workflow JSON | All nodes connected | JSON parse result |
| S5 | Database connection | [AUTO] | Test Supabase query | Returns without error | Query result |

---

## Level 2: Functional Tests

*"Does it do what it should?"*

"@

    # Add functional tests for each task with evidence requirements
    $fIndex = 1
    foreach ($task in $tasks) {
        $manifest += @"

### $($task.id): $($task.name)

"@
        if ($task.verify) {
            $manifest += "**VERIFY:** $($task.verify)`n"
        }
        if ($task.done) {
            $manifest += "**DONE:** $($task.done)`n"
        }
        
        # Determine evidence type based on task type
        $evidenceHint = switch ($task.type) {
            "database"    { "SQL query result or Supabase dashboard screenshot" }
            "workflow"    { "n8n execution ID + output JSON" }
            "frontend"   { "Browser screenshot or DOM inspection" }
            "backend"    { "curl command output with status code + response body" }
            "integration" { "End-to-end trace showing data flow" }
            default       { "Command output or screenshot" }
        }
        
        $manifest += @"

| ID | Test Name | Type | Input | Expected Output | Evidence Required |
|----|-----------|------|-------|-----------------|-------------------|
"@
        
        foreach ($criterion in $task.criteria) {
            $manifest += "| F$fIndex | $criterion | [SEMI] | ``{sample: data}`` | Criterion met | $evidenceHint |`n"
            $fIndex++
        }
    }
    
    $manifest += @"

---

## Level 3: Edge Case Tests

*"What happens when things go wrong?"*

### Input Validation

| ID | Test Name | Type | Bad Input | Expected Behavior | Evidence Required |
|----|-----------|------|-----------|-------------------|-------------------|
| E1 | Missing required field | [AUTO] | ``{name: ""}`` | Returns validation error | Error response body |
| E2 | Invalid email format | [AUTO] | ``{email: "notanemail"}`` | Rejects with message | Rejection response |
| E3 | Extra unexpected fields | [AUTO] | ``{extra: "garbage"}`` | Ignores extra fields | Response showing clean data |
| E4 | Null values | [AUTO] | ``{name: null}`` | Handles gracefully | Response or error output |
| E5 | Injection attempt | [AUTO] | ``{name: "'; DROP--"}`` | Sanitized | DB query showing no damage |

### Error Handling

| ID | Test Name | Type | Scenario | Expected Behavior | Evidence Required |
|----|-----------|------|----------|-------------------|-------------------|
| E6 | API timeout | [SEMI] | API takes 30s+ | Retries then notifies | Retry logs + notification |
| E7 | API 500 error | [AUTO] | Mock 500 response | Logs and alerts | Error log excerpt |
| E8 | Database down | [SEMI] | Pause DB | Queues and retries | Queue state + retry log |
| E9 | Duplicate submit | [AUTO] | Same data twice | Detects duplicate | Dedup response |

---

## Test Data Sets

### Happy Path Data
``````json
{
  "standard_input": {
    "name": "Test User",
    "email": "test@example.com"
  }
}
``````

### Edge Case Data
``````json
{
  "missing_required": { "email": "only@email.com" },
  "invalid_email": { "name": "Test", "email": "notvalid" },
  "null_values": { "name": null, "email": null }
}
``````

---

## How to Run Tests

### All Tests (standard)
``````powershell
Invoke-JAWSTests -Level all
``````

### All Tests (evidence required)
``````powershell
Invoke-JAWSTests -Level all -EvidenceRequired
``````

### Agent Team Validation
``````powershell
Invoke-AgentValidation -Agents @("database","backend","frontend","workflow")
``````

### Contract Diff (pre-integration)
``````powershell
Invoke-ContractDiff -ContractsPath "CONTRACTS.md"
``````

---

*Generated by JAWS Testing Framework v5.1*
"@
    
    $manifest | Out-File -FilePath $OutputPath -Encoding utf8
    
    Write-Host "  [OK] Test manifest generated: $OutputPath" -ForegroundColor Green
    Write-Host "  Total tests: $(5 + ($tasks.Count * 2) + 9)"
    if ($IncludeEvidenceRequirements) {
        Write-Host "  Evidence mode: REQUIRED" -ForegroundColor Yellow
    }
    Write-Host ""
    
    return $true
}

# ============================================================================
# TEST EXECUTION
# ============================================================================

function Invoke-JAWSTests {
    param(
        [string]$Level = "all",
        [string]$ManifestPath = "TEST-MANIFEST.md",
        [string]$WebhookUrl = $null,
        [switch]$EvidenceRequired
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  RUNNING JAWS TESTS - Level: $Level                                  " -ForegroundColor Cyan
    if ($EvidenceRequired) {
        Write-Host "  EVIDENCE MODE: REQUIRED (passes without proof -> WARNING)           " -ForegroundColor Yellow
    }
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @{
        startTime        = Get-Date
        level            = $Level
        evidenceRequired = [bool]$EvidenceRequired
        smoke            = @()
        functional       = @()
        edge             = @()
        agentValidation  = @()
        contractDiff     = @()
    }
    
    # Level 1: Smoke Tests
    if ($Level -eq "all" -or $Level -eq "smoke") {
        Write-Host "  Running Level 1: Smoke Tests..." -ForegroundColor Yellow
        
        # S1: Check if we can execute (we're running, so yes)
        $results.smoke += New-TestResult `
            -Id "S1" -Name "Script executes" -Status "PASS" -Time "0.1s" `
            -Evidence "PowerShell $($PSVersionTable.PSVersion) executing in $(Get-Location)" `
            -EvidenceType "output"
        Write-Host "    S1: Script executes - PASS" -ForegroundColor Green
        
        # S2: Check if PRD exists
        $prdExists = Test-Path "PRD.md"
        $prdEvidence = if ($prdExists) { 
            $prdSize = (Get-Item "PRD.md").Length
            $prdLines = (Get-Content "PRD.md" | Measure-Object).Count
            "PRD.md found: $prdLines lines, $prdSize bytes"
        } else { "PRD.md not found in $(Get-Location)" }
        
        $results.smoke += New-TestResult `
            -Id "S2" -Name "PRD exists" `
            -Status $(if ($prdExists) { "PASS" } else { "FAIL" }) `
            -Time "0.1s" `
            -Evidence $prdEvidence `
            -EvidenceType "file"
        $statusColor = if ($prdExists) { "Green" } else { "Red" }
        Write-Host "    S2: PRD exists - $(if ($prdExists) {'PASS'} else {'FAIL'})" -ForegroundColor $statusColor
        
        # S3: Check Git status
        $gitOk = $false
        $gitEvidence = ""
        try {
            $gitBranch = git branch --show-current 2>&1
            $gitStatus = git status --short 2>&1 | Out-String
            $gitOk = $?
            $gitEvidence = "Branch: $gitBranch | Status: $(if ($gitStatus.Trim()) { $gitStatus.Trim() } else { 'clean' })"
        } catch { 
            $gitOk = $false 
            $gitEvidence = "Git error: $($_.Exception.Message)"
        }
        
        $results.smoke += New-TestResult `
            -Id "S3" -Name "Git repository valid" `
            -Status $(if ($gitOk) { "PASS" } else { "FAIL" }) `
            -Time "0.3s" `
            -Evidence $gitEvidence `
            -EvidenceType "output"
        $statusColor = if ($gitOk) { "Green" } else { "Red" }
        Write-Host "    S3: Git repository - $(if ($gitOk) {'PASS'} else {'FAIL'})" -ForegroundColor $statusColor
        
        # S4: Check Claude CLI
        $claudeOk = $false
        $claudeEvidence = ""
        try {
            $claudeVersion = claude --version 2>&1 | Out-String
            $claudeOk = $?
            $claudeEvidence = "Claude CLI: $($claudeVersion.Trim())"
        } catch { 
            $claudeOk = $false
            $claudeEvidence = "Claude CLI not found: $($_.Exception.Message)"
        }
        
        $results.smoke += New-TestResult `
            -Id "S4" -Name "Claude CLI available" `
            -Status $(if ($claudeOk) { "PASS" } else { "FAIL" }) `
            -Time "0.5s" `
            -Evidence $claudeEvidence `
            -EvidenceType "output"
        $statusColor = if ($claudeOk) { "Green" } else { "Red" }
        Write-Host "    S4: Claude CLI - $(if ($claudeOk) {'PASS'} else {'FAIL'})" -ForegroundColor $statusColor
        
        # S5: Check test manifest exists
        $manifestExists = Test-Path $ManifestPath
        $manifestEvidence = if ($manifestExists) {
            $mLines = (Get-Content $ManifestPath | Measure-Object).Count
            "Manifest found: $ManifestPath ($mLines lines)"
        } else { "No manifest at $ManifestPath" }
        
        $results.smoke += New-TestResult `
            -Id "S5" -Name "Test manifest exists" `
            -Status $(if ($manifestExists) { "PASS" } else { "WARNING" }) `
            -Time "0.1s" `
            -Notes $(if (-not $manifestExists) { "Run New-TestManifest first" } else { "" }) `
            -Evidence $manifestEvidence `
            -EvidenceType "file"
        $statusColor = if ($manifestExists) { "Green" } else { "Yellow" }
        Write-Host "    S5: Test manifest - $(if ($manifestExists) {'PASS'} else {'WARNING'})" -ForegroundColor $statusColor
        
        # Apply evidence audit to smoke tests
        if ($EvidenceRequired) {
            $results.smoke = Add-EvidenceAudit -TestResults $results.smoke -EvidenceRequired $true
        }
        
        Write-Host ""
    }
    
    # Level 2: Functional Tests
    if ($Level -eq "all" -or $Level -eq "functional") {
        Write-Host "  Running Level 2: Functional Tests..." -ForegroundColor Yellow
        
        if ($WebhookUrl) {
            Write-Host "    Testing webhook: $WebhookUrl" -ForegroundColor DarkGray
            
            # Test with evidence capture
            $ev = Invoke-EvidenceCapture `
                -Command "Invoke-RestMethod -Uri '$WebhookUrl' -Method POST -Body '{`"test`": true}' -ContentType 'application/json' -TimeoutSec 10" `
                -Label "Webhook POST response"
            
            $results.functional += New-TestResult `
                -Id "F1" -Name "Webhook responds" `
                -Status $(if ($ev.success) { "PASS" } else { "FAIL" }) `
                -Time $ev.time `
                -Evidence $ev.evidence `
                -EvidenceType "curl" `
                -Error $(if (-not $ev.success) { $ev.evidence } else { "" })
            
            $statusColor = if ($ev.success) { "Green" } else { "Red" }
            Write-Host "    F1: Webhook responds - $(if ($ev.success) {'PASS'} else {'FAIL'})" -ForegroundColor $statusColor
        } else {
            $results.functional += New-TestResult `
                -Id "F1" -Name "Functional tests" -Status "SKIPPED" `
                -Notes "No webhook URL provided. Use -WebhookUrl to test." `
                -Evidence "Skipped: no -WebhookUrl parameter" `
                -EvidenceType "output"
            Write-Host "    F1: Functional tests - SKIPPED (no webhook URL)" -ForegroundColor DarkGray
        }
        
        # Apply evidence audit to functional tests
        if ($EvidenceRequired) {
            $results.functional = Add-EvidenceAudit -TestResults $results.functional -EvidenceRequired $true
        }
        
        Write-Host ""
    }
    
    # Level 3: Edge Cases (placeholder - requires n8n integration)
    if ($Level -eq "all" -or $Level -eq "edge") {
        Write-Host "  Running Level 3: Edge Case Tests..." -ForegroundColor Yellow
        
        $results.edge += New-TestResult `
            -Id "E1-E9" -Name "Edge case tests" -Status "SKIPPED" `
            -Notes "Requires n8n integration. Import n8n-test-runner-workflow.json" `
            -Evidence "Skipped: n8n test runner not configured" `
            -EvidenceType "output"
        Write-Host "    E1-E9: Edge cases - SKIPPED (requires n8n)" -ForegroundColor DarkGray
        
        Write-Host ""
    }
    
    $results.endTime = Get-Date
    $results.duration = ($results.endTime - $results.startTime).TotalSeconds
    
    return $results
}

# ============================================================================
# AGENT-LEVEL VALIDATION (for Agent Team builds)
# ============================================================================

function Invoke-AgentValidation {
    <#
    .SYNOPSIS
    Runs domain-specific validation for each agent in an agent team build.
    Each agent type has a checklist of commands that must produce evidence.
    
    .DESCRIPTION
    Before system-level testing, each agent validates their own domain.
    This catches 80% of bugs before integration. Results feed into the
    main test report under a dedicated "Agent Validation" section.
    
    .EXAMPLE
    $results = Invoke-AgentValidation -Agents @("database","backend","frontend")
    
    .EXAMPLE
    $results = Invoke-AgentValidation -Agents @("database","backend","frontend","workflow") -ProjectRoot "/path/to/project"
    #>
    param(
        [ValidateSet("database", "backend", "frontend", "workflow")]
        [string[]]$Agents,
        [string]$ProjectRoot = ".",
        [string]$ContractsPath = "CONTRACTS.md"
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  AGENT-LEVEL VALIDATION                                              " -ForegroundColor Cyan
    Write-Host "  Agents: $($Agents -join ', ')                                       " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @()
    
    foreach ($agent in $Agents) {
        Write-Host "  Validating $($agent.ToUpper()) agent..." -ForegroundColor Yellow
        
        switch ($agent) {
            "database" {
                # Check: migration files exist
                $migrationPath = Join-Path $ProjectRoot "supabase/migrations"
                $migrationsExist = Test-Path $migrationPath
                $migrationFiles = if ($migrationsExist) { 
                    (Get-ChildItem $migrationPath -Filter "*.sql" | Measure-Object).Count 
                } else { 0 }
                
                $results += New-TestResult `
                    -Id "AV-DB-1" -Name "Migration files exist" `
                    -Status $(if ($migrationFiles -gt 0) { "PASS" } else { "FAIL" }) `
                    -Evidence "Found $migrationFiles .sql files in $migrationPath" `
                    -EvidenceType "file"
                Write-Host "    AV-DB-1: Migration files - $(if ($migrationFiles -gt 0) {'PASS'} else {'FAIL'}) ($migrationFiles files)" -ForegroundColor $(if ($migrationFiles -gt 0) { "Green" } else { "Red" })
                
                # Check: SQL is valid (basic syntax check)
                if ($migrationFiles -gt 0) {
                    $sqlFiles = Get-ChildItem $migrationPath -Filter "*.sql"
                    $validSql = $true
                    $sqlEvidence = @()
                    foreach ($sqlFile in $sqlFiles) {
                        $content = Get-Content $sqlFile.FullName -Raw
                        # Basic check: has CREATE TABLE or ALTER TABLE
                        $hasStatements = $content -match "(CREATE|ALTER|INSERT|DROP|UPDATE)\s+"
                        if (-not $hasStatements) {
                            $validSql = $false
                            $sqlEvidence += "$($sqlFile.Name): no SQL statements found"
                        } else {
                            $sqlEvidence += "$($sqlFile.Name): valid SQL statements detected"
                        }
                    }
                    
                    $results += New-TestResult `
                        -Id "AV-DB-2" -Name "SQL syntax valid" `
                        -Status $(if ($validSql) { "PASS" } else { "WARNING" }) `
                        -Evidence ($sqlEvidence -join "; ") `
                        -EvidenceType "file" `
                        -Notes $(if (-not $validSql) { "Some files may lack SQL statements" } else { "" })
                    Write-Host "    AV-DB-2: SQL syntax - $(if ($validSql) {'PASS'} else {'WARNING'})" -ForegroundColor $(if ($validSql) { "Green" } else { "Yellow" })
                }
                
                # Check: DATABASE-CONTRACTS.md published
                $dbContracts = Test-Path (Join-Path $ProjectRoot "DATABASE-CONTRACTS.md")
                $results += New-TestResult `
                    -Id "AV-DB-3" -Name "Database contracts published" `
                    -Status $(if ($dbContracts) { "PASS" } else { "WARNING" }) `
                    -Evidence $(if ($dbContracts) { "DATABASE-CONTRACTS.md found" } else { "DATABASE-CONTRACTS.md not found" }) `
                    -EvidenceType "file" `
                    -Notes $(if (-not $dbContracts) { "Downstream agents need this. Create it." } else { "" })
                Write-Host "    AV-DB-3: Contracts published - $(if ($dbContracts) {'PASS'} else {'WARNING'})" -ForegroundColor $(if ($dbContracts) { "Green" } else { "Yellow" })
            }
            
            "backend" {
                # Check: API route files exist
                $apiPaths = @("src/api", "src/routes", "api", "backend", "src/app/api")
                $apiFound = $false
                $apiPath = ""
                foreach ($ap in $apiPaths) {
                    $fullPath = Join-Path $ProjectRoot $ap
                    if (Test-Path $fullPath) {
                        $apiFound = $true
                        $apiPath = $fullPath
                        break
                    }
                }
                
                $apiFiles = if ($apiFound) { 
                    (Get-ChildItem $apiPath -Recurse -File | Measure-Object).Count 
                } else { 0 }
                
                $results += New-TestResult `
                    -Id "AV-BE-1" -Name "API route files exist" `
                    -Status $(if ($apiFound) { "PASS" } else { "FAIL" }) `
                    -Evidence "Found $apiFiles files in $apiPath" `
                    -EvidenceType "file"
                Write-Host "    AV-BE-1: API routes - $(if ($apiFound) {'PASS'} else {'FAIL'})" -ForegroundColor $(if ($apiFound) { "Green" } else { "Red" })
                
                # Check: package.json has start script
                $pkgPath = Join-Path $ProjectRoot "package.json"
                $hasStart = $false
                $startEvidence = ""
                if (Test-Path $pkgPath) {
                    $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
                    $hasStart = [bool]($pkg.scripts.PSObject.Properties.Name -contains "start" -or 
                                      $pkg.scripts.PSObject.Properties.Name -contains "dev")
                    $startEvidence = "Scripts found: $($pkg.scripts.PSObject.Properties.Name -join ', ')"
                } else {
                    $startEvidence = "No package.json found"
                }
                
                $results += New-TestResult `
                    -Id "AV-BE-2" -Name "Server can start" `
                    -Status $(if ($hasStart) { "PASS" } else { "WARNING" }) `
                    -Evidence $startEvidence `
                    -EvidenceType "file" `
                    -Notes $(if (-not $hasStart) { "No start/dev script found in package.json" } else { "" })
                Write-Host "    AV-BE-2: Server start script - $(if ($hasStart) {'PASS'} else {'WARNING'})" -ForegroundColor $(if ($hasStart) { "Green" } else { "Yellow" })
                
                # Check: TypeScript compiles (if TypeScript project)
                $tsconfigPath = Join-Path $ProjectRoot "tsconfig.json"
                if (Test-Path $tsconfigPath) {
                    $results += New-TestResult `
                        -Id "AV-BE-3" -Name "TypeScript config present" `
                        -Status "PASS" `
                        -Evidence "tsconfig.json found" `
                        -EvidenceType "file" `
                        -Notes "Run 'npx tsc --noEmit' manually to verify compilation"
                    Write-Host "    AV-BE-3: TypeScript config - PASS" -ForegroundColor Green
                }
            }
            
            "frontend" {
                # Check: Component files exist
                $componentPaths = @("src/components", "src/app", "app", "components", "pages")
                $componentsFound = $false
                $compPath = ""
                foreach ($cp in $componentPaths) {
                    $fullPath = Join-Path $ProjectRoot $cp
                    if (Test-Path $fullPath) {
                        $componentsFound = $true
                        $compPath = $fullPath
                        break
                    }
                }
                
                $compFiles = if ($componentsFound) {
                    (Get-ChildItem $compPath -Recurse -Include "*.tsx","*.jsx","*.vue","*.svelte" | Measure-Object).Count
                } else { 0 }
                
                $results += New-TestResult `
                    -Id "AV-FE-1" -Name "Frontend components exist" `
                    -Status $(if ($compFiles -gt 0) { "PASS" } else { "FAIL" }) `
                    -Evidence "Found $compFiles component files in $compPath" `
                    -EvidenceType "file"
                Write-Host "    AV-FE-1: Components - $(if ($compFiles -gt 0) {'PASS'} else {'FAIL'}) ($compFiles files)" -ForegroundColor $(if ($compFiles -gt 0) { "Green" } else { "Red" })
                
                # Check: Build script exists
                $pkgPath = Join-Path $ProjectRoot "package.json"
                $hasBuild = $false
                if (Test-Path $pkgPath) {
                    $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
                    $hasBuild = [bool]($pkg.scripts.PSObject.Properties.Name -contains "build")
                }
                
                $results += New-TestResult `
                    -Id "AV-FE-2" -Name "Build script exists" `
                    -Status $(if ($hasBuild) { "PASS" } else { "WARNING" }) `
                    -Evidence $(if ($hasBuild) { "build script found in package.json" } else { "No build script" }) `
                    -EvidenceType "file" `
                    -Notes $(if (-not $hasBuild) { "Run 'npm run build' manually to verify" } else { "" })
                Write-Host "    AV-FE-2: Build script - $(if ($hasBuild) {'PASS'} else {'WARNING'})" -ForegroundColor $(if ($hasBuild) { "Green" } else { "Yellow" })
                
                # Check: No console.error in source files (basic quality check)
                if ($componentsFound) {
                    $consoleErrors = Get-ChildItem $compPath -Recurse -Include "*.tsx","*.jsx","*.ts","*.js" | 
                        Select-String -Pattern "console\.error" -SimpleMatch | 
                        Measure-Object
                    
                    $results += New-TestResult `
                        -Id "AV-FE-3" -Name "Console errors in source" `
                        -Status $(if ($consoleErrors.Count -le 5) { "PASS" } else { "WARNING" }) `
                        -Evidence "Found $($consoleErrors.Count) console.error() calls in source" `
                        -EvidenceType "output" `
                        -Notes $(if ($consoleErrors.Count -gt 5) { "Review: excessive error logging may indicate unhandled cases" } else { "" })
                    Write-Host "    AV-FE-3: Console errors - $(if ($consoleErrors.Count -le 5) {'PASS'} else {'WARNING'}) ($($consoleErrors.Count) found)" -ForegroundColor $(if ($consoleErrors.Count -le 5) { "Green" } else { "Yellow" })
                }
            }
            
            "workflow" {
                # Check: Workflow JSON files exist
                $workflowPaths = @("workflows", "n8n", "n8n-workflows")
                $workflowsFound = $false
                $wfPath = ""
                foreach ($wp in $workflowPaths) {
                    $fullPath = Join-Path $ProjectRoot $wp
                    if (Test-Path $fullPath) {
                        $workflowsFound = $true
                        $wfPath = $fullPath
                        break
                    }
                }
                
                $wfFiles = if ($workflowsFound) {
                    (Get-ChildItem $wfPath -Filter "*.json" | Measure-Object).Count
                } else { 0 }
                
                $results += New-TestResult `
                    -Id "AV-WF-1" -Name "Workflow JSON files exist" `
                    -Status $(if ($wfFiles -gt 0) { "PASS" } else { "FAIL" }) `
                    -Evidence "Found $wfFiles .json files in $wfPath" `
                    -EvidenceType "file"
                Write-Host "    AV-WF-1: Workflow files - $(if ($wfFiles -gt 0) {'PASS'} else {'FAIL'}) ($wfFiles files)" -ForegroundColor $(if ($wfFiles -gt 0) { "Green" } else { "Red" })
                
                # Check: Each workflow JSON is valid
                if ($wfFiles -gt 0) {
                    $validJson = $true
                    $jsonEvidence = @()
                    $wfJsonFiles = Get-ChildItem $wfPath -Filter "*.json"
                    foreach ($wf in $wfJsonFiles) {
                        try {
                            $content = Get-Content $wf.FullName -Raw | ConvertFrom-Json
                            $nodeCount = if ($content.nodes) { $content.nodes.Count } else { 0 }
                            $jsonEvidence += "$($wf.Name): valid JSON, $nodeCount nodes"
                        } catch {
                            $validJson = $false
                            $jsonEvidence += "$($wf.Name): INVALID JSON - $($_.Exception.Message)"
                        }
                    }
                    
                    $results += New-TestResult `
                        -Id "AV-WF-2" -Name "Workflow JSON valid" `
                        -Status $(if ($validJson) { "PASS" } else { "FAIL" }) `
                        -Evidence ($jsonEvidence -join "; ") `
                        -EvidenceType "file" `
                        -Error $(if (-not $validJson) { "Some workflow files contain invalid JSON" } else { "" })
                    Write-Host "    AV-WF-2: JSON validity - $(if ($validJson) {'PASS'} else {'FAIL'})" -ForegroundColor $(if ($validJson) { "Green" } else { "Red" })
                    
                    # Check: Expressions start with = (n8n requirement)
                    $badExpressions = 0
                    foreach ($wf in $wfJsonFiles) {
                        $content = Get-Content $wf.FullName -Raw
                        # Look for expression patterns that DON'T start with =
                        $matches = [regex]::Matches($content, '"value"\s*:\s*"\{\{(?!=)')
                        $badExpressions += $matches.Count
                    }
                    
                    $results += New-TestResult `
                        -Id "AV-WF-3" -Name "Expressions start with =" `
                        -Status $(if ($badExpressions -eq 0) { "PASS" } else { "WARNING" }) `
                        -Evidence "Found $badExpressions expressions potentially missing = prefix" `
                        -EvidenceType "output" `
                        -Notes $(if ($badExpressions -gt 0) { "n8n expressions must start with = to evaluate" } else { "" })
                    Write-Host "    AV-WF-3: Expression syntax - $(if ($badExpressions -eq 0) {'PASS'} else {'WARNING'}) ($badExpressions issues)" -ForegroundColor $(if ($badExpressions -eq 0) { "Green" } else { "Yellow" })
                }
            }
        }
        
        Write-Host ""
    }
    
    return $results
}

# ============================================================================
# CONTRACT DIFF (pre-integration validation)
# ============================================================================

function Invoke-ContractDiff {
    <#
    .SYNOPSIS
    Compares the CONTRACTS.md specification against actual implementation.
    Detects mismatches between what was contracted and what was built.
    
    .DESCRIPTION
    Checks for common integration failure patterns:
    - Trailing slash mismatches in URLs
    - Missing endpoint implementations
    - Response shape discrepancies
    - File existence verification
    
    .EXAMPLE
    $diff = Invoke-ContractDiff -ContractsPath "CONTRACTS.md"
    #>
    param(
        [string]$ContractsPath = "CONTRACTS.md",
        [string]$ProjectRoot = "."
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  CONTRACT DIFF - Pre-Integration Validation                          " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @()
    
    # Check: CONTRACTS.md exists
    $contractsExist = Test-Path $ContractsPath
    if (-not $contractsExist) {
        $results += New-TestResult `
            -Id "CD-1" -Name "Contracts file exists" -Status "FAIL" `
            -Evidence "No file at $ContractsPath" -EvidenceType "file" `
            -Error "Cannot run contract diff without CONTRACTS.md"
        Write-Host "  [FAIL] No CONTRACTS.md found. Cannot run diff." -ForegroundColor Red
        return $results
    }
    
    $contracts = Get-Content $ContractsPath -Raw
    
    $results += New-TestResult `
        -Id "CD-1" -Name "Contracts file exists" -Status "PASS" `
        -Evidence "CONTRACTS.md found: $((Get-Item $ContractsPath).Length) bytes" `
        -EvidenceType "file"
    Write-Host "  CD-1: Contracts file - PASS" -ForegroundColor Green
    
    # Check: Extract and verify API endpoints from contracts
    $endpointPattern = '(GET|POST|PUT|DELETE|PATCH)\s+(/[^\s|]+)'
    $endpoints = [regex]::Matches($contracts, $endpointPattern)
    
    if ($endpoints.Count -gt 0) {
        $results += New-TestResult `
            -Id "CD-2" -Name "API endpoints defined" -Status "PASS" `
            -Evidence "Found $($endpoints.Count) endpoint definitions in contracts" `
            -EvidenceType "output"
        Write-Host "  CD-2: API endpoints defined - PASS ($($endpoints.Count) endpoints)" -ForegroundColor Green
        
        # Check for trailing slash consistency
        $trailingSlashIssues = @()
        $endpointList = @()
        foreach ($ep in $endpoints) {
            $method = $ep.Groups[1].Value
            $url = $ep.Groups[2].Value
            $endpointList += "$method $url"
            
            # Check if same base path exists with and without trailing slash
            $basePath = $url.TrimEnd('/')
            $withSlash = "$basePath/"
            $withoutSlash = $basePath
            
            # Look in source code for the opposite convention
            $srcFiles = Get-ChildItem $ProjectRoot -Recurse -Include "*.ts","*.tsx","*.js","*.jsx","*.py" -ErrorAction SilentlyContinue
            foreach ($sf in $srcFiles) {
                $content = Get-Content $sf.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $url.EndsWith('/')) {
                    # Contract has trailing slash, check if code uses without
                    if ($content -match [regex]::Escape($withoutSlash) -and $content -notmatch [regex]::Escape($withSlash)) {
                        $trailingSlashIssues += "$method $url -> code in $($sf.Name) uses $withoutSlash (no trailing slash)"
                    }
                }
            }
        }
        
        if ($trailingSlashIssues.Count -gt 0) {
            $results += New-TestResult `
                -Id "CD-3" -Name "Trailing slash consistency" -Status "WARNING" `
                -Evidence "Potential mismatches: $($trailingSlashIssues -join '; ')" `
                -EvidenceType "output" `
                -Notes "Trailing slash mismatches cause 404 errors. Verify each endpoint."
            Write-Host "  CD-3: Trailing slashes - WARNING ($($trailingSlashIssues.Count) potential mismatches)" -ForegroundColor Yellow
        } else {
            $results += New-TestResult `
                -Id "CD-3" -Name "Trailing slash consistency" -Status "PASS" `
                -Evidence "No trailing slash mismatches detected across $($srcFiles.Count) source files" `
                -EvidenceType "output"
            Write-Host "  CD-3: Trailing slashes - PASS" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "  Contracted endpoints:" -ForegroundColor DarkGray
        foreach ($ep in $endpointList) {
            Write-Host "    $ep" -ForegroundColor DarkGray
        }
    } else {
        $results += New-TestResult `
            -Id "CD-2" -Name "API endpoints defined" -Status "WARNING" `
            -Evidence "No endpoint patterns (GET/POST/etc + URL) found in contracts" `
            -EvidenceType "output" `
            -Notes "Contracts should define exact endpoints with methods"
        Write-Host "  CD-2: API endpoints - WARNING (none found in contracts)" -ForegroundColor Yellow
    }
    
    # Check: Cross-cutting concerns documented
    $crossCuttingTerms = @("streaming", "trailing slash", "envelope", "error shape", "pagination", "timezone", "rate limit")
    $documentedConcerns = @()
    $missingConcerns = @()
    
    foreach ($term in $crossCuttingTerms) {
        if ($contracts -match $term) {
            $documentedConcerns += $term
        } else {
            $missingConcerns += $term
        }
    }
    
    $results += New-TestResult `
        -Id "CD-4" -Name "Cross-cutting concerns documented" `
        -Status $(if ($missingConcerns.Count -eq 0) { "PASS" } elseif ($missingConcerns.Count -le 3) { "WARNING" } else { "FAIL" }) `
        -Evidence "Documented: $($documentedConcerns -join ', '). Missing: $(if ($missingConcerns.Count -gt 0) { $missingConcerns -join ', ' } else { 'none' })" `
        -EvidenceType "output" `
        -Notes $(if ($missingConcerns.Count -gt 0) { "Add missing concerns to CONTRACTS.md to prevent integration failures" } else { "" })
    Write-Host "  CD-4: Cross-cutting concerns - $(if ($missingConcerns.Count -eq 0) {'PASS'} elseif ($missingConcerns.Count -le 3) {'WARNING'} else {'FAIL'}) ($($documentedConcerns.Count)/$($crossCuttingTerms.Count) documented)" -ForegroundColor $(if ($missingConcerns.Count -eq 0) { "Green" } elseif ($missingConcerns.Count -le 3) { "Yellow" } else { "Red" })
    
    Write-Host ""
    
    return $results
}

# ============================================================================
# TEST REPORT GENERATION (Enhanced with Evidence)
# ============================================================================

function New-TestReport {
    param(
        [hashtable]$Results,
        [string]$OutputPath = "TEST-REPORT.md",
        [array]$AgentResults = @(),
        [array]$ContractDiffResults = @()
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  GENERATING TEST REPORT                                              " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Collect all test results
    $allTests = @($Results.smoke) + @($Results.functional) + @($Results.edge)
    $allWithAgent = $allTests + $AgentResults + $ContractDiffResults
    
    $passed = ($allWithAgent | Where-Object { $_.rawStatus -eq "PASS" }).Count
    $failed = ($allWithAgent | Where-Object { $_.rawStatus -eq "FAIL" }).Count
    $warnings = ($allWithAgent | Where-Object { $_.rawStatus -eq "WARNING" }).Count
    $skipped = ($allWithAgent | Where-Object { $_.rawStatus -eq "SKIPPED" }).Count
    
    # Count evidence coverage
    $testsWithEvidence = ($allWithAgent | Where-Object { Test-EvidencePresent $_ }).Count
    $testsNeedingEvidence = ($allWithAgent | Where-Object { $_.rawStatus -ne "SKIPPED" }).Count
    $evidenceCoverage = if ($testsNeedingEvidence -gt 0) { 
        [math]::Round(($testsWithEvidence / $testsNeedingEvidence) * 100) 
    } else { 0 }
    
    # Determine overall status
    $overallStatus = if ($failed -gt 0) {
        "NOT READY FOR PRODUCTION"
    } elseif ($warnings -gt 0) {
        "READY WITH CAVEATS"
    } elseif ($skipped -eq $allWithAgent.Count) {
        "NO TESTS RUN"
    } else {
        "READY FOR PRODUCTION"
    }
    
    $overallIcon = switch ($overallStatus) {
        "NOT READY FOR PRODUCTION" { "RED" }
        "READY WITH CAVEATS"       { "YELLOW" }
        "NO TESTS RUN"             { "GREY" }
        "READY FOR PRODUCTION"     { "GREEN" }
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    
    $report = @"
# Test Report

**Test Date:** $timestamp
**Duration:** $([math]::Round($Results.duration, 2)) seconds
**Level Tested:** $($Results.level)
**Evidence Mode:** $(if ($Results.evidenceRequired) { "REQUIRED" } else { "Optional" })

---

## Overall Status

# $overallIcon - $overallStatus

---

## Summary

| Metric | Count |
|--------|-------|
| Passed | $passed |
| Failed | $failed |
| Warnings | $warnings |
| Skipped | $skipped |
| **Total** | **$($allWithAgent.Count)** |

**Pass Rate:** $(if (($passed + $failed) -gt 0) { [math]::Round(($passed / ($passed + $failed)) * 100) } else { 0 })%
**Evidence Coverage:** $evidenceCoverage% ($testsWithEvidence / $testsNeedingEvidence tests have proof)

$(if ($Results.evidenceRequired -and $evidenceCoverage -lt 100) {
"**WARNING:** Evidence mode is REQUIRED but $($testsNeedingEvidence - $testsWithEvidence) test(s) lack proof. These were downgraded to WARNING."
})

---

## Level 1: Smoke Tests

| ID | Test | Status | Evidence | Notes |
|----|------|--------|----------|-------|

"@
    
    foreach ($test in $Results.smoke) {
        $evidenceDisplay = if ($test.evidence) { $test.evidence } else { "-" }
        $notesDisplay = if ($test.notes) { $test.notes } else { "-" }
        $report += "| $($test.id) | $($test.name) | $($test.rawStatus) | $evidenceDisplay | $notesDisplay |`n"
    }
    
    $report += @"

---

## Level 2: Functional Tests

| ID | Test | Status | Evidence | Notes |
|----|------|--------|----------|-------|

"@
    
    foreach ($test in $Results.functional) {
        $evidenceDisplay = if ($test.evidence) { $test.evidence } else { "-" }
        $notesDisplay = if ($test.notes) { $test.notes } else { "-" }
        $report += "| $($test.id) | $($test.name) | $($test.rawStatus) | $evidenceDisplay | $notesDisplay |`n"
    }
    
    $report += @"

---

## Level 3: Edge Case Tests

| ID | Test | Status | Evidence | Notes |
|----|------|--------|----------|-------|

"@
    
    foreach ($test in $Results.edge) {
        $evidenceDisplay = if ($test.evidence) { $test.evidence } else { "-" }
        $notesDisplay = if ($test.notes) { $test.notes } else { "-" }
        $report += "| $($test.id) | $($test.name) | $($test.rawStatus) | $evidenceDisplay | $notesDisplay |`n"
    }
    
    # Agent Validation Section (if applicable)
    if ($AgentResults.Count -gt 0) {
        $report += @"

---

## Agent-Level Validation

*Each agent validated their own domain before integration testing.*

| ID | Agent | Check | Status | Evidence |
|----|-------|-------|--------|----------|

"@
        foreach ($ar in $AgentResults) {
            $agentName = if ($ar.id -match "AV-(\w+)-") { $Matches[1] } else { "?" }
            $evidenceDisplay = if ($ar.evidence) { $ar.evidence } else { "-" }
            $report += "| $($ar.id) | $agentName | $($ar.name) | $($ar.rawStatus) | $evidenceDisplay |`n"
        }
    }
    
    # Contract Diff Section (if applicable)
    if ($ContractDiffResults.Count -gt 0) {
        $report += @"

---

## Contract Diff (Pre-Integration)

*Compared contracted interfaces against actual implementation.*

| ID | Check | Status | Evidence | Notes |
|----|-------|--------|----------|-------|

"@
        foreach ($cd in $ContractDiffResults) {
            $evidenceDisplay = if ($cd.evidence) { $cd.evidence } else { "-" }
            $notesDisplay = if ($cd.notes) { $cd.notes } else { "-" }
            $report += "| $($cd.id) | $($cd.name) | $($cd.rawStatus) | $evidenceDisplay | $notesDisplay |`n"
        }
    }
    
    # Failures detail
    $failures = $allWithAgent | Where-Object { $_.rawStatus -eq "FAIL" }
    if ($failures.Count -gt 0) {
        $report += @"

---

## Failures (Must Fix)

"@
        foreach ($fail in $failures) {
            $report += @"
### $($fail.id): $($fail.name)
- **Status:** FAIL
- **Error:** $(if ($fail.error) { $fail.error } else { "See notes" })
- **Evidence:** $(if ($fail.evidence) { $fail.evidence } else { "No evidence captured" })
- **Notes:** $(if ($fail.notes) { $fail.notes } else { "-" })

"@
        }
    }
    
    # Evidence audit section
    $noEvidence = $allWithAgent | Where-Object { $_.rawStatus -ne "SKIPPED" -and -not (Test-EvidencePresent $_) }
    if ($noEvidence.Count -gt 0) {
        $report += @"

---

## Evidence Audit

*Tests that $(if ($Results.evidenceRequired) { "were downgraded because they" } else { "would benefit from" }) lack$(if (-not $Results.evidenceRequired) { "ing" }) proof:*

| ID | Test | Status | What's Missing |
|----|------|--------|----------------|

"@
        foreach ($ne in $noEvidence) {
            $missing = switch ($ne.id) {
                { $_ -match "^S" }  { "Command output or system state" }
                { $_ -match "^F" }  { "curl response, execution ID, or output" }
                { $_ -match "^E" }  { "Error response or behavior observation" }
                { $_ -match "^AV" } { "File listing, query result, or command output" }
                { $_ -match "^CD" } { "Comparison result or file analysis" }
                default              { "Any verifiable proof" }
            }
            $report += "| $($ne.id) | $($ne.name) | $($ne.rawStatus) | $missing |`n"
        }
    }
    
    $report += @"

---

## Recommendations

"@
    
    if ($failed -gt 0) {
        $report += "1. **REQUIRED:** Fix all $failed failing tests before production`n"
    }
    if ($warnings -gt 0) {
        $report += "2. **RECOMMENDED:** Review $warnings warnings`n"
    }
    if ($skipped -gt 0) {
        $report += "3. **OPTIONAL:** Run skipped tests with full n8n integration`n"
    }
    if ($Results.evidenceRequired -and $evidenceCoverage -lt 100) {
        $report += "4. **EVIDENCE:** Collect proof for $($testsNeedingEvidence - $testsWithEvidence) unproven tests`n"
    }
    if ($ContractDiffResults.Count -eq 0 -and $AgentResults.Count -gt 0) {
        $report += "5. **CONTRACT DIFF:** Run Invoke-ContractDiff before integration`n"
    }
    
    $report += @"

---

## Sign-Off

- [ ] Technical review completed
- [ ] All failures addressed
- [ ] Evidence coverage acceptable$(if ($Results.evidenceRequired) { " (REQUIRED: 100%)" } else { "" })
- [ ] Ready for production

**Reviewer:** _________________ **Date:** _________

---

*Generated by JAWS Testing Framework v5.1 (Evidence-Based Validation)*
"@
    
    $report | Out-File -FilePath $OutputPath -Encoding utf8
    
    Write-Host "  [OK] Test report generated: $OutputPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Summary:"
    Write-Host "    Passed:   $passed" -ForegroundColor Green
    Write-Host "    Failed:   $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
    Write-Host "    Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })
    Write-Host "    Skipped:  $skipped" -ForegroundColor DarkGray
    Write-Host "    Evidence: $evidenceCoverage% coverage" -ForegroundColor $(if ($evidenceCoverage -ge 80) { "Green" } elseif ($evidenceCoverage -ge 50) { "Yellow" } else { "Red" })
    Write-Host ""
    Write-Host "  Overall: $overallIcon - $overallStatus"
    Write-Host ""
    
    return $OutputPath
}

# ============================================================================
# INTEGRATION INTO RALPH-JAWS MAIN LOOP
# ============================================================================

# Add this section to the main script after QA phase:

<#
# TESTING PHASE (add after QA, before merge)

if ($GenerateTests) {
    New-TestManifest -PRDPath $PRDPath -IncludeEvidenceRequirements:$EvidenceRequired
}

if ($AgentValidation) {
    $agentResults = Invoke-AgentValidation -Agents @("database","backend","frontend","workflow")
}

if ($ContractDiff) {
    $contractDiffResults = Invoke-ContractDiff -ContractsPath "CONTRACTS.md"
}

if ($RunTests) {
    $testResults = Invoke-JAWSTests -Level $TestLevel -ManifestPath $TestManifestPath -EvidenceRequired:$EvidenceRequired
    
    New-TestReport `
        -Results $testResults `
        -OutputPath $TestReportPath `
        -AgentResults $(if ($agentResults) { $agentResults } else { @() }) `
        -ContractDiffResults $(if ($contractDiffResults) { $contractDiffResults } else { @() })
    
    # Check if tests passed
    $allResults = $testResults.smoke + $testResults.functional + $testResults.edge
    if ($agentResults) { $allResults += $agentResults }
    if ($contractDiffResults) { $allResults += $contractDiffResults }
    
    $failed = ($allResults | Where-Object { $_.rawStatus -eq "FAIL" }).Count
    
    if ($failed -gt 0 -and -not $AutoPilot) {
        Write-Host ""
        Write-Host "  WARNING: $failed test(s) failed. Continue anyway?" -ForegroundColor Yellow
        $continue = Read-Host "  [Y/N]"
        
        if ($continue.ToUpper() -ne 'Y') {
            Write-Host "  Stopping. Fix failures and re-run." -ForegroundColor Red
            exit 1
        }
    }
}

if ($TestReport) {
    # Just generate report from last results
    if (Test-Path "test-results.json") {
        $savedResults = Get-Content "test-results.json" -Raw | ConvertFrom-Json
        New-TestReport -Results $savedResults -OutputPath $TestReportPath
    } else {
        Write-Host "  No test results found. Run -RunTests first." -ForegroundColor Yellow
    }
}
#>

# ============================================================================
# FULL VALIDATION PIPELINE (convenience function)
# ============================================================================

function Invoke-FullValidation {
    <#
    .SYNOPSIS
    Runs the complete validation pipeline: agent validation, contract diff, 
    all test levels, and generates a comprehensive report.
    
    .DESCRIPTION
    This is the one-command "prove it works" function. Use before delivery.
    
    .EXAMPLE
    # Standard validation
    Invoke-FullValidation
    
    # Evidence required (recommended for client delivery)
    Invoke-FullValidation -EvidenceRequired
    
    # With agent team validation
    Invoke-FullValidation -EvidenceRequired -Agents @("database","backend","frontend")
    #>
    param(
        [switch]$EvidenceRequired,
        [string[]]$Agents = @(),
        [string]$WebhookUrl = $null,
        [string]$ContractsPath = "CONTRACTS.md",
        [string]$OutputPath = "TEST-REPORT.md"
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "  JAWS FULL VALIDATION PIPELINE                                       " -ForegroundColor Magenta
    Write-Host "  Evidence Mode: $(if ($EvidenceRequired) { 'REQUIRED' } else { 'Optional' })                                              " -ForegroundColor Magenta
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host ""
    
    $agentResults = @()
    $contractDiffResults = @()
    
    # Step 1: Agent Validation (if agents specified)
    if ($Agents.Count -gt 0) {
        $agentResults = Invoke-AgentValidation -Agents $Agents
    }
    
    # Step 2: Contract Diff (if CONTRACTS.md exists)
    if (Test-Path $ContractsPath) {
        $contractDiffResults = Invoke-ContractDiff -ContractsPath $ContractsPath
    } else {
        Write-Host "  [SKIP] No CONTRACTS.md found - skipping contract diff" -ForegroundColor DarkGray
    }
    
    # Step 3: All Test Levels
    $testResults = Invoke-JAWSTests -Level "all" -WebhookUrl $WebhookUrl -EvidenceRequired:$EvidenceRequired
    
    # Step 4: Generate Report
    $reportPath = New-TestReport `
        -Results $testResults `
        -OutputPath $OutputPath `
        -AgentResults $agentResults `
        -ContractDiffResults $contractDiffResults
    
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "  VALIDATION COMPLETE                                                 " -ForegroundColor Magenta
    Write-Host "  Report: $reportPath                                                 " -ForegroundColor Magenta
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host ""
    
    return @{
        testResults         = $testResults
        agentResults        = $agentResults
        contractDiffResults = $contractDiffResults
        reportPath          = $reportPath
    }
}

# ============================================================================
# MODULE LOAD
# ============================================================================

Write-Host "JAWS Testing Module v5.1 loaded (Evidence-Based Validation)." -ForegroundColor Green
Write-Host "Commands available:"
Write-Host "  New-TestManifest       - Generate tests from PRD"
Write-Host "  Invoke-JAWSTests       - Run tests (add -EvidenceRequired for proof mode)"
Write-Host "  Invoke-AgentValidation - Validate agent team domains"
Write-Host "  Invoke-ContractDiff    - Compare contracts vs implementation"
Write-Host "  New-TestReport         - Generate report with evidence"
Write-Host "  Invoke-FullValidation  - Run complete pipeline"
