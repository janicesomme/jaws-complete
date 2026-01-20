# JAWS Enhancements from Auto-Claude v2.7.4

**Date:** January 19, 2026  
**Source:** [Auto-Claude v2.7.4 Release](https://github.com/AndyMik90/Auto-Claude/releases/tag/v2.7.4)

---

## What's Included

These modules bring key improvements from Auto-Claude v2.7.4 to your JAWS/RALPH system.

| Module | File | Priority | Description |
|--------|------|----------|-------------|
| **Terminal Retry** | `claude-retry-logic.ps1` | 🔴 HIGH | Resilient Claude CLI invocation with automatic retry |
| **Merge Checks** | `merge-readiness-checks.ps1` | 🟡 MEDIUM | Branch state validation before merge |
| **Version Management** | `claude-version-management.ps1` | 🟢 LOW | CLI version detection and rollback |

---

## Installation

### Option 1: Import as Modules (Recommended)

Add these lines to the top of `ralph-jaws-v4.ps1`:

```powershell
# Import JAWS enhancement modules
$enhancementsPath = Join-Path $PSScriptRoot "enhancements"

if (Test-Path (Join-Path $enhancementsPath "claude-retry-logic.ps1")) {
    . (Join-Path $enhancementsPath "claude-retry-logic.ps1")
}

if (Test-Path (Join-Path $enhancementsPath "merge-readiness-checks.ps1")) {
    . (Join-Path $enhancementsPath "merge-readiness-checks.ps1")
}

if (Test-Path (Join-Path $enhancementsPath "claude-version-management.ps1")) {
    . (Join-Path $enhancementsPath "claude-version-management.ps1")
}
```

### Option 2: Merge into RALPH

Each module has a `Get-*IntegrationCode` function that returns the code to merge directly:

```powershell
# Load module and get integration code
. .\claude-retry-logic.ps1
Get-RetryIntegrationCode | Out-File "integration-snippet.ps1"
```

---

## Module Details

### 1. Claude Retry Logic (`claude-retry-logic.ps1`)

**From Auto-Claude:** Enhanced terminal recreation logic with retry mechanism

**Functions:**
- `Invoke-ClaudeWithRetry` - Execute Claude with automatic retry on failure
- `Test-ClaudeAvailability` - Pre-flight health check

**Usage:**
```powershell
# Basic usage
$result = Invoke-ClaudeWithRetry -Prompt "Your prompt here"

# With exponential backoff
$result = Invoke-ClaudeWithRetry -Prompt $prompt -MaxRetries 5 -UseExponentialBackoff

# Health check before build
$health = Test-ClaudeAvailability
if (-not $health.Available) {
    Write-Host "Claude not available: $($health.Error)"
}
```

**Benefits:**
- Prevents lost work from transient CLI failures
- Integrates with rabbit hole detection
- Exponential backoff reduces API pressure

---

### 2. Merge Readiness Checks (`merge-readiness-checks.ps1`)

**From Auto-Claude:** Enhanced PR merge readiness checks with branch state validation

**Functions:**
- `Test-MergeReadiness` - Comprehensive pre-merge validation
- `Test-WorkingTreeClean` - Quick uncommitted check
- `Invoke-SafeMerge` - Merge only if checks pass

**Checks Performed:**
- ✅ Uncommitted changes detection
- ✅ Untracked files warning
- ✅ Branch sync status
- ✅ Merge conflict prediction
- ✅ Files changed summary

**Usage:**
```powershell
# Full readiness check
$ready = Test-MergeReadiness -BranchName "jaws-build-20260119"
if ($ready.CanMerge) {
    Invoke-SafeMerge -BranchName "jaws-build-20260119"
}

# Quick check
if (Test-WorkingTreeClean) {
    Write-Host "Ready to commit"
}
```

**Benefits:**
- Prevents broken merges
- Catches conflicts before they happen
- Clear error reporting

---

### 3. Claude Version Management (`claude-version-management.ps1`)

**From Auto-Claude:** Claude Code version rollback feature

**Functions:**
- `Get-ClaudeVersions` - Find all installed CLI versions
- `Get-BestClaudeVersion` - Auto-select recommended version
- `Set-ClaudeVersion` - Pin to specific version
- `Select-ClaudeVersion` - Interactive selector

**Usage:**
```powershell
# See what's installed
Get-ClaudeVersions

# Auto-select best version
$claude = Get-BestClaudeVersion
Write-Host "Using: $($claude.Version)"

# Pin to specific version (useful for rollback)
Set-ClaudeVersion -Version "1.0.3"

# Interactive selection
$selected = Select-ClaudeVersion
```

**Benefits:**
- Troubleshoot CLI issues by testing different versions
- Pin working version when updates break things
- Multi-version support for different projects

---

## Integration Examples

### RALPH Main Loop (Before)

```powershell
$result = (& $claudeCmd --dangerously-skip-permissions -p $prompt 2>&1 | Out-String)
```

### RALPH Main Loop (After)

```powershell
# With retry logic
try {
    $result = Invoke-ClaudeWithRetry `
        -Prompt $prompt `
        -MaxRetries 3 `
        -UseExponentialBackoff `
        -SkipPermissions
}
catch {
    $state.consecutiveFailures++
    $state.lastError = $_.Exception.Message
    Save-State $state
    continue
}
```

### Complete-Worktree (Before)

```powershell
git merge $WorktreeBranch --no-ff -m "JAWS Build: $WorktreeBranch"
```

### Complete-Worktree (After)

```powershell
$readiness = Test-MergeReadiness -BranchName $WorktreeBranch
if ($readiness.CanMerge) {
    $result = Invoke-SafeMerge -BranchName $WorktreeBranch
    if (-not $result.Success) {
        Write-Host "Merge failed: $($result.Reason)"
    }
}
```

---

## Changelog

### v1.0.0 (2026-01-19)
- Initial release
- Ported from Auto-Claude v2.7.4
- Added: Terminal retry logic
- Added: Merge readiness checks
- Added: CLI version management

---

## Credits

Based on improvements from [Auto-Claude](https://github.com/AndyMik90/Auto-Claude) by AndyMik90.

Adapted for JAWS/RALPH by Janice.
