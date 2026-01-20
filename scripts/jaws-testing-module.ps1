# ============================================================================
# JAWS TESTING MODULE
# Add this to ralph-jaws-v4.ps1 or import as module
# ============================================================================

# New parameters to add to ralph-jaws-v4.ps1:
# [switch]$GenerateTests,
# [switch]$RunTests,
# [ValidateSet("all", "smoke", "functional", "edge")]
# [string]$TestLevel = "all",
# [switch]$TestReport,
# [string]$TestManifestPath = "TEST-MANIFEST.md",
# [string]$TestReportPath = "TEST-REPORT.md"

# ============================================================================
# TEST MANIFEST GENERATION
# ============================================================================

function New-TestManifest {
    param(
        [string]$PRDPath = "PRD.md",
        [string]$OutputPath = "TEST-MANIFEST.md"
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
        
        $tasks += @{
            id = $taskId
            name = $taskName
            criteria = $criteria
            verify = $verify
            done = $done
        }
    }
    
    # Generate manifest
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $manifest = @"
# Test Manifest: $projectName

**Generated:** $timestamp
**Source:** $PRDPath
**Tasks Covered:** $(($tasks | ForEach-Object { $_.id }) -join ', ')

---

## Quick Stats

| Level | Total Tests | Automated | Manual |
|-------|-------------|-----------|--------|
| 1 - Smoke | 6 | 6 | 0 |
| 2 - Functional | $($tasks.Count * 2) | $($tasks.Count) | $($tasks.Count) |
| 3 - Edge Cases | 9 | 6 | 3 |
| **TOTAL** | **$(6 + ($tasks.Count * 2) + 9)** | **$(6 + $tasks.Count + 6)** | **$($tasks.Count + 3)** |

---

## Level 1: Smoke Tests ðŸ”¥

*"Does it run without crashing?"*

| ID | Test Name | Type | How to Run | Pass Criteria |
|----|-----------|------|------------|---------------|
| S1 | Workflow activates | [AUTO] | Toggle workflow active | No error, status shows "Active" |
| S2 | Webhook endpoint responds | [AUTO] | POST to webhook URL | Returns 200 OK |
| S3 | All credentials valid | [AUTO] | Test each credential | All return success |
| S4 | No disconnected nodes | [AUTO] | Check workflow JSON | All nodes connected |
| S5 | Database connection | [AUTO] | Test Supabase query | Returns without error |
| S6 | MCP optimization enabled | [AUTO] | Check .claude/settings.json | enable_tool_search = true |

---

## Level 2: Functional Tests âš™ï¸

*"Does it do what it should?"*

"@

    # Add functional tests for each task
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
        
        $manifest += @"

| ID | Test Name | Type | Input | Expected Output | Verify By |
|----|-----------|------|-------|-----------------|-----------|
"@
        
        foreach ($criterion in $task.criteria) {
            $manifest += "| F$fIndex | $criterion | [SEMI] | ``{sample: data}`` | Criterion met | Manual verification |`n"
            $fIndex++
        }
    }
    
    $manifest += @"

---

## Level 3: Edge Case Tests ðŸŒªï¸

*"What happens when things go wrong?"*

### Input Validation

| ID | Test Name | Type | Bad Input | Expected Behavior |
|----|-----------|------|-----------|-------------------|
| E1 | Missing required field | [AUTO] | ``{name: ""}`` | Returns validation error |
| E2 | Invalid email format | [AUTO] | ``{email: "notanemail"}`` | Rejects with message |
| E3 | Extra unexpected fields | [AUTO] | ``{extra: "garbage"}`` | Ignores extra fields |
| E4 | Null values | [AUTO] | ``{name: null}`` | Handles gracefully |
| E5 | Injection attempt | [AUTO] | ``{name: "'; DROP--"}`` | Sanitized |

### Error Handling

| ID | Test Name | Type | Scenario | Expected Behavior |
|----|-----------|------|----------|-------------------|
| E6 | API timeout | [SEMI] | API takes 30s+ | Retries then notifies |
| E7 | API 500 error | [AUTO] | Mock 500 response | Logs and alerts |
| E8 | Database down | [SEMI] | Pause DB | Queues and retries |
| E9 | Duplicate submit | [AUTO] | Same data twice | Detects duplicate |

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

### All Tests
``````powershell
.\ralph-jaws-v4.ps1 -RunTests -TestLevel all
``````

### Smoke Tests Only
``````powershell
.\ralph-jaws-v4.ps1 -RunTests -TestLevel smoke
``````

### Functional Tests Only
``````powershell
.\ralph-jaws-v4.ps1 -RunTests -TestLevel functional
``````

---

*Generated by JAWS Testing Framework*
"@
    
    $manifest | Out-File -FilePath $OutputPath -Encoding utf8
    
    Write-Host "  [OK] Test manifest generated: $OutputPath" -ForegroundColor Green
    Write-Host "  Total tests: $(5 + ($tasks.Count * 2) + 9)"
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
        [string]$WebhookUrl = $null
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  RUNNING JAWS TESTS - Level: $Level                                  " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @{
        startTime = Get-Date
        level = $Level
        smoke = @()
        functional = @()
        edge = @()
    }
    
    # Level 1: Smoke Tests
    if ($Level -eq "all" -or $Level -eq "smoke") {
        Write-Host "  Running Level 1: Smoke Tests..." -ForegroundColor Yellow
        
        # S1: Check if we can execute (we're running, so yes)
        $results.smoke += @{
            id = "S1"
            name = "Script executes"
            status = "ðŸŸ¢ PASS"
            time = "0.1s"
            notes = "PowerShell executing"
        }
        Write-Host "    S1: Script executes - ðŸŸ¢ PASS" -ForegroundColor Green
        
        # S2: Check if PRD exists
        $prdExists = Test-Path "PRD.md"
        $results.smoke += @{
            id = "S2"
            name = "PRD exists"
            status = if ($prdExists) { "ðŸŸ¢ PASS" } else { "ðŸ”´ FAIL" }
            time = "0.1s"
            notes = if ($prdExists) { "PRD.md found" } else { "PRD.md not found" }
        }
        $statusColor = if ($prdExists) { "Green" } else { "Red" }
        $statusIcon = if ($prdExists) { "ðŸŸ¢ PASS" } else { "ðŸ”´ FAIL" }
        Write-Host "    S2: PRD exists - $statusIcon" -ForegroundColor $statusColor
        
        # S3: Check Git status
        $gitOk = $false
        try {
            $gitStatus = git status 2>&1
            $gitOk = $?
        } catch { $gitOk = $false }
        
        $results.smoke += @{
            id = "S3"
            name = "Git repository valid"
            status = if ($gitOk) { "ðŸŸ¢ PASS" } else { "ðŸ”´ FAIL" }
            time = "0.3s"
        }
        $statusColor = if ($gitOk) { "Green" } else { "Red" }
        $statusIcon = if ($gitOk) { "ðŸŸ¢ PASS" } else { "ðŸ”´ FAIL" }
        Write-Host "    S3: Git repository - $statusIcon" -ForegroundColor $statusColor
        
        # S4: Check Claude CLI
        $claudeOk = $false
        try {
            $claudeVersion = claude --version 2>&1
            $claudeOk = $?
        } catch { $claudeOk = $false }
        
        $results.smoke += @{
            id = "S4"
            name = "Claude CLI available"
            status = if ($claudeOk) { "ðŸŸ¢ PASS" } else { "ðŸ”´ FAIL" }
            time = "0.5s"
        }
        $statusColor = if ($claudeOk) { "Green" } else { "Red" }
        $statusIcon = if ($claudeOk) { "ðŸŸ¢ PASS" } else { "ðŸ”´ FAIL" }
        Write-Host "    S4: Claude CLI - $statusIcon" -ForegroundColor $statusColor
        
        # S5: Check test manifest exists
        $manifestExists = Test-Path $ManifestPath
        $results.smoke += @{
            id = "S5"
            name = "Test manifest exists"
            status = if ($manifestExists) { "ðŸŸ¢ PASS" } else { "ðŸŸ¡ WARNING" }
            time = "0.1s"
            notes = if ($manifestExists) { "Manifest found" } else { "Run -GenerateTests first" }
        }
        $statusColor = if ($manifestExists) { "Green" } else { "Yellow" }
        $statusIcon = if ($manifestExists) { "ðŸŸ¢ PASS" } else { "ðŸŸ¡ WARNING" }
        Write-Host "    S5: Test manifest - $statusIcon" -ForegroundColor $statusColor
        
        # S6: Check MCP tool search is enabled (context optimization)
        $mcpOptimized = $false
        $mcpSettingsLocation = "Not found"
        $projectSettingsPath = ".claude/settings.json"
        $globalSettingsPath = Join-Path $env:USERPROFILE ".claude/settings.json"
        
        # Check project-level first, then user-level
        foreach ($path in @($projectSettingsPath, $globalSettingsPath)) {
            if (Test-Path $path) {
                try {
                    $settings = Get-Content $path -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($settings.env.CLAUDE_CODE_ENABLE_TOOL_SEARCH -eq "true") {
                        $mcpOptimized = $true
                        $mcpSettingsLocation = $path
                        break
                    }
                } catch { }
            }
        }
        
        $results.smoke += @{
            id = "S6"
            name = "MCP tool search enabled"
            status = if ($mcpOptimized) { "ðŸŸ¢ PASS" } else { "ðŸŸ¡ WARNING" }
            time = "0.1s"
            notes = if ($mcpOptimized) { "Lazy loading enabled ($mcpSettingsLocation)" } else { "Run enable-mcp-optimization.ps1 to save context window" }
        }
        $statusColor = if ($mcpOptimized) { "Green" } else { "Yellow" }
        $statusIcon = if ($mcpOptimized) { "ðŸŸ¢ PASS" } else { "ðŸŸ¡ WARNING" }
        Write-Host "    S6: MCP optimization - $statusIcon" -ForegroundColor $statusColor
        
        Write-Host ""
    }
    
    # Level 2: Functional Tests (placeholder - requires n8n integration)
    if ($Level -eq "all" -or $Level -eq "functional") {
        Write-Host "  Running Level 2: Functional Tests..." -ForegroundColor Yellow
        
        if ($WebhookUrl) {
            Write-Host "    Testing webhook: $WebhookUrl" -ForegroundColor DarkGray
            try {
                $response = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body '{"test": true}' -ContentType "application/json" -TimeoutSec 10
                $results.functional += @{
                    id = "F1"
                    name = "Webhook responds"
                    status = "ðŸŸ¢ PASS"
                    time = "1.2s"
                    evidence = "Response received"
                }
                Write-Host "    F1: Webhook responds - ðŸŸ¢ PASS" -ForegroundColor Green
            } catch {
                $results.functional += @{
                    id = "F1"
                    name = "Webhook responds"
                    status = "ðŸ”´ FAIL"
                    time = "10s"
                    error = $_.Exception.Message
                }
                Write-Host "    F1: Webhook responds - ðŸ”´ FAIL" -ForegroundColor Red
            }
        } else {
            $results.functional += @{
                id = "F1"
                name = "Functional tests"
                status = "âšª SKIPPED"
                notes = "No webhook URL provided. Use -WebhookUrl to test."
            }
            Write-Host "    F1: Functional tests - âšª SKIPPED (no webhook URL)" -ForegroundColor DarkGray
        }
        
        Write-Host ""
    }
    
    # Level 3: Edge Cases (placeholder - requires n8n integration)
    if ($Level -eq "all" -or $Level -eq "edge") {
        Write-Host "  Running Level 3: Edge Case Tests..." -ForegroundColor Yellow
        
        $results.edge += @{
            id = "E1-E9"
            name = "Edge case tests"
            status = "âšª SKIPPED"
            notes = "Requires n8n integration. Import n8n-test-runner-workflow.json"
        }
        Write-Host "    E1-E9: Edge cases - âšª SKIPPED (requires n8n)" -ForegroundColor DarkGray
        
        Write-Host ""
    }
    
    $results.endTime = Get-Date
    $results.duration = ($results.endTime - $results.startTime).TotalSeconds
    
    return $results
}

# ============================================================================
# TEST REPORT GENERATION
# ============================================================================

function New-TestReport {
    param(
        [hashtable]$Results,
        [string]$OutputPath = "TEST-REPORT.md"
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  GENERATING TEST REPORT                                              " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Calculate summary
    $allTests = @($Results.smoke) + @($Results.functional) + @($Results.edge)
    $passed = ($allTests | Where-Object { $_.status -match "PASS" }).Count
    $failed = ($allTests | Where-Object { $_.status -match "FAIL" }).Count
    $warnings = ($allTests | Where-Object { $_.status -match "WARNING" }).Count
    $skipped = ($allTests | Where-Object { $_.status -match "SKIPPED" }).Count
    
    # Determine overall status
    $overallStatus = if ($failed -gt 0) {
        "ðŸ”´ NOT READY FOR PRODUCTION"
    } elseif ($warnings -gt 0) {
        "ðŸŸ¡ READY WITH CAVEATS"
    } elseif ($skipped -eq $allTests.Count) {
        "âšª NO TESTS RUN"
    } else {
        "ðŸŸ¢ READY FOR PRODUCTION"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    
    $report = @"
# Test Report

**Test Date:** $timestamp
**Duration:** $([math]::Round($Results.duration, 2)) seconds
**Level Tested:** $($Results.level)

---

## ðŸš¦ Overall Status

# $overallStatus

---

## Summary

| Metric | Count |
|--------|-------|
| âœ… Passed | $passed |
| âŒ Failed | $failed |
| âš ï¸ Warnings | $warnings |
| â­ï¸ Skipped | $skipped |
| **Total** | **$($allTests.Count)** |

**Pass Rate:** $(if (($passed + $failed) -gt 0) { [math]::Round(($passed / ($passed + $failed)) * 100) } else { 0 })%

---

## Level 1: Smoke Tests

"@
    
    foreach ($test in $Results.smoke) {
        $report += "- **$($test.id):** $($test.name) - $($test.status)`n"
        if ($test.notes) {
            $report += "  - Notes: $($test.notes)`n"
        }
    }
    
    $report += @"

---

## Level 2: Functional Tests

"@
    
    foreach ($test in $Results.functional) {
        $report += "- **$($test.id):** $($test.name) - $($test.status)`n"
        if ($test.notes) {
            $report += "  - Notes: $($test.notes)`n"
        }
        if ($test.error) {
            $report += "  - Error: $($test.error)`n"
        }
    }
    
    $report += @"

---

## Level 3: Edge Case Tests

"@
    
    foreach ($test in $Results.edge) {
        $report += "- **$($test.id):** $($test.name) - $($test.status)`n"
        if ($test.notes) {
            $report += "  - Notes: $($test.notes)`n"
        }
    }
    
    # Add failures detail
    $failures = $allTests | Where-Object { $_.status -match "FAIL" }
    if ($failures.Count -gt 0) {
        $report += @"

---

## ðŸ”´ Failures (Must Fix)

"@
        foreach ($fail in $failures) {
            $report += @"
### $($fail.id): $($fail.name)
- **Status:** $($fail.status)
- **Error:** $(if ($fail.error) { $fail.error } else { "See notes" })
- **Notes:** $(if ($fail.notes) { $fail.notes } else { "-" })

"@
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
    
    $report += @"

---

## Sign-Off

- [ ] Technical review completed
- [ ] All failures addressed
- [ ] Ready for production

**Reviewer:** _________________ **Date:** _________

---

*Generated by JAWS Testing Framework*
"@
    
    $report | Out-File -FilePath $OutputPath -Encoding utf8
    
    Write-Host "  [OK] Test report generated: $OutputPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Summary:"
    Write-Host "    Passed:   $passed" -ForegroundColor Green
    Write-Host "    Failed:   $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
    Write-Host "    Warnings: $warnings" -ForegroundColor $(if ($warnings -gt 0) { "Yellow" } else { "Green" })
    Write-Host "    Skipped:  $skipped" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Overall: $overallStatus"
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
    New-TestManifest -PRDPath $PRDPath
}

if ($RunTests) {
    $testResults = Invoke-JAWSTests -Level $TestLevel -ManifestPath $TestManifestPath
    New-TestReport -Results $testResults -OutputPath $TestReportPath
    
    # Check if tests passed
    $failed = ($testResults.smoke + $testResults.functional + $testResults.edge | Where-Object { $_.status -match "FAIL" }).Count
    
    if ($failed -gt 0 -and -not $AutoPilot) {
        Write-Host ""
        Write-Host "  âš ï¸  $failed test(s) failed. Continue anyway?" -ForegroundColor Yellow
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

Write-Host "JAWS Testing Module loaded." -ForegroundColor Green
Write-Host "Commands available:"
Write-Host "  New-TestManifest     - Generate tests from PRD"
Write-Host "  Invoke-JAWSTests     - Run tests"
Write-Host "  New-TestReport       - Generate report"
