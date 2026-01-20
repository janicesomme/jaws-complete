# RALPH v4.1 - RLM Enhancement
# Add this reconnaissance-enhanced prompt to ralph-jaws-v4.ps1

# ============================================================================
# RLM-INSPIRED RECONNAISSANCE PROMPT
# ============================================================================
# 
# Key insight from MIT RLM paper:
# "Long prompts should NOT be fed into the neural network, but should be 
# treated as part of the ENVIRONMENT the LLM can interact with."
#
# Translation: Don't dump context. Query what you need.
# ============================================================================

function Get-ReconnaissancePrompt {
    param(
        [hashtable]$CurrentTask,
        [hashtable]$State
    )
    
    $taskId = $CurrentTask.id
    $taskName = $CurrentTask.name
    $verify = $CurrentTask.verify
    $done = $CurrentTask.done
    $files = $CurrentTask.files
    
    $prompt = @"
You are RALPH, an autonomous coding agent using RLM principles.

## CRITICAL: Reconnaissance First

You have access to a large codebase and PRD. DO NOT load everything into your context.
Instead, treat documents as your ENVIRONMENT - query what you need, when you need it.

## Phase 1: Reconnaissance (DO THIS FIRST)

Before writing ANY code, run these commands to understand your environment:

### 1. Project Structure
``````bash
# See what you're working with
find . -type f -name "*.js" -o -name "*.ts" -o -name "*.json" -o -name "*.py" | head -30
``````

### 2. Find Related Code
``````bash
# Search for patterns related to your task
grep -r "KEYWORD_FROM_TASK" . --include="*.js" --include="*.ts" -l
``````

### 3. Read ONLY Your Task from PRD
``````bash
# Extract just your task section, not the whole PRD
sed -n '/### $taskId/,/### US-/p' PRD.md | head -50
``````

### 4. Check Existing Patterns
``````bash
# Find similar implementations to follow
grep -r "function\|export\|const.*=" . --include="*.js" | head -20
``````

## Phase 2: Your Assignment

**Task:** $taskId - $taskName

**Files to create/modify:** $files

**VERIFY by:** $verify

**DONE when:** $done

## Phase 3: Implementation Rules

1. **Query, don't load** - Read specific functions, not entire files
2. **One file at a time** - Don't open multiple large files simultaneously  
3. **Check before writing** - Verify file doesn't already exist with similar code
4. **Small commits** - Implement incrementally, verify each step

## Phase 4: Completion

After implementation:
1. Run the VERIFY check: $verify
2. If VERIFY passes, mark criteria complete in PRD.md
3. Update progress.txt with:
   - What you built
   - Files created/modified
   - Any patterns discovered for AGENTS.md

## Anti-Patterns (DO NOT DO)

❌ Don't read entire PRD.md into context
❌ Don't open all project files to "understand the codebase"
❌ Don't dump large documents then ask questions about them
❌ Don't load files you won't modify

## Pro-Patterns (DO THIS)

✅ Use grep/find to locate relevant code
✅ Read only the functions you'll modify
✅ Query PRD for specific task section only
✅ Check file existence before creating

Start with Phase 1 reconnaissance now.
"@

    return $prompt
}

# ============================================================================
# UPDATED Get-CompressedContext FUNCTION
# ============================================================================

function Get-CompressedContext-RLM {
    param(
        [hashtable]$State,
        [hashtable]$CurrentTask
    )
    
    # Minimal context - just pointers, not content
    $context = @"
## Quick Pointers (Query for details, don't load)

**Current Task:** $($CurrentTask.id) - $($CurrentTask.name)
**Task Location:** Search PRD.md for "### $($CurrentTask.id)"
**Files Hint:** $($CurrentTask.files)
**Verify Command:** $($CurrentTask.verify)

**Completed:** $($State.completedTasks -join ', ')
**Attempts on this task:** $(Get-TaskFailureCount $State $CurrentTask.id)

DO NOT read entire PRD. Query only your task section.
"@

    return $context
}

# ============================================================================
# SUB-AGENT SPAWNING FOR COMPLEX TASKS
# ============================================================================

function Test-TaskComplexity {
    param(
        [hashtable]$Task
    )
    
    # Count acceptance criteria
    $criteriaCount = $Task.criteriaTotal
    
    # Estimate complexity
    if ($criteriaCount -ge 5) {
        return @{
            level = "complex"
            suggestion = "Consider splitting into sub-tasks"
            subAgentCount = [math]::Ceiling($criteriaCount / 2)
        }
    }
    elseif ($criteriaCount -ge 3) {
        return @{
            level = "medium"
            suggestion = "Standard single-agent approach"
            subAgentCount = 1
        }
    }
    else {
        return @{
            level = "simple"
            suggestion = "Quick implementation"
            subAgentCount = 1
        }
    }
}

function Get-SubAgentPrompt {
    param(
        [string]$TaskId,
        [string]$CriterionText,
        [int]$CriterionIndex
    )
    
    $prompt = @"
You are a SUB-AGENT handling ONE criterion for task $TaskId.

## Your Single Focus

Criterion $CriterionIndex: $CriterionText

## Rules

1. Implement ONLY this criterion
2. Do reconnaissance first (grep, find)
3. Don't read unrelated files
4. When done, report back:
   - Files modified
   - How criterion was satisfied
   - Any issues encountered

## Start

Run reconnaissance to find where to implement this criterion.
"@

    return $prompt
}

# ============================================================================
# ENVIRONMENT-BASED DOCUMENT ACCESS
# ============================================================================

function Get-PRDSection {
    <#
    .SYNOPSIS
    Extracts only a specific task section from PRD without loading entire file.
    
    .DESCRIPTION
    Implements RLM principle: treat documents as environment, query what you need.
    #>
    param(
        [string]$TaskId,
        [string]$PRDPath = "PRD.md"
    )
    
    if (-not (Test-Path $PRDPath)) {
        return $null
    }
    
    $prd = Get-Content $PRDPath -Raw
    $escapedId = [regex]::Escape($TaskId)
    
    # Extract just this task's section
    if ($prd -match "(### $escapedId[\s\S]*?)(?=### US-|\z)") {
        return $Matches[1].Trim()
    }
    
    return $null
}

function Get-RelevantFiles {
    <#
    .SYNOPSIS
    Finds files relevant to a task without loading them.
    #>
    param(
        [string]$TaskId,
        [string]$Keywords
    )
    
    $results = @()
    
    # Search for keyword matches
    $keywords = $Keywords -split '\s*,\s*'
    
    foreach ($kw in $keywords) {
        $matches = git grep -l $kw 2>$null
        if ($matches) {
            $results += $matches
        }
    }
    
    return $results | Select-Object -Unique
}

# ============================================================================
# MAIN PROMPT BUILDER (UPDATED)
# ============================================================================

function Build-RLMPrompt {
    param(
        [hashtable]$State,
        [hashtable]$CurrentTask,
        [string]$HumanGuidance = ""
    )
    
    $complexity = Test-TaskComplexity -Task $CurrentTask
    $recon = Get-ReconnaissancePrompt -CurrentTask $CurrentTask -State $State
    
    # Add complexity note if needed
    $complexityNote = ""
    if ($complexity.level -eq "complex") {
        $complexityNote = @"

## ⚠️ Complex Task Detected

This task has $($CurrentTask.criteriaTotal) criteria.
Consider implementing ONE criterion at a time.
Verify each before moving to the next.
"@
    }
    
    # Add human guidance if provided
    $guidanceSection = ""
    if ($HumanGuidance) {
        $guidanceSection = @"

## 🎯 HUMAN GUIDANCE (Priority)

$HumanGuidance
"@
    }
    
    $fullPrompt = @"
$recon
$complexityNote
$guidanceSection

---

Remember: Query your environment, don't load it.
Start with reconnaissance commands now.
"@

    return $fullPrompt
}

# ============================================================================
# INTEGRATION INTO RALPH MAIN LOOP
# ============================================================================

<#
Replace the existing prompt building section in ralph-jaws-v4.ps1 with:

# Build RLM-enhanced prompt
$prompt = Build-RLMPrompt -State $state -CurrentTask $currentTask -HumanGuidance $humanGuidance

# Rest of execution remains the same
$result = (& $claudeCmd --dangerously-skip-permissions -p $prompt 2>&1 | Out-String)
#>

# ============================================================================
# EXPORT
# ============================================================================

Write-Host ""
Write-Host "RALPH RLM Enhancement loaded." -ForegroundColor Green
Write-Host ""
Write-Host "New functions:" -ForegroundColor Cyan
Write-Host "  Get-ReconnaissancePrompt  - RLM-style prompt with recon phase"
Write-Host "  Get-CompressedContext-RLM - Minimal context pointers"
Write-Host "  Test-TaskComplexity       - Detect if task needs sub-agents"
Write-Host "  Get-SubAgentPrompt        - Prompt for sub-agent spawning"
Write-Host "  Get-PRDSection            - Extract single task from PRD"
Write-Host "  Build-RLMPrompt           - Full RLM prompt builder"
Write-Host ""
