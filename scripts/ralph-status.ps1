param(
    [string]$StateFile = "ralph-state.json",
    [string]$PRDPath = "PRD.md"
)

# RALPH Status Check
# Quick view of current build state

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  RALPH-JAWS Status Check                                      " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check for state file
if (-not (Test-Path $StateFile)) {
    Write-Host "  No build in progress." -ForegroundColor Yellow
    Write-Host "  State file not found: $StateFile" -ForegroundColor DarkGray
    Write-Host ""
    exit 0
}

# Load state
$state = Get-Content $StateFile -Raw | ConvertFrom-Json

# Calculate duration
$duration = "Unknown"
if ($state.startedAt) {
    try {
        $start = [DateTime]::Parse($state.startedAt)
        $elapsed = (Get-Date) - $start
        $duration = "$($elapsed.Days)d $($elapsed.Hours)h $($elapsed.Minutes)m"
    } catch {}
}

# Count tasks in PRD
$totalTasks = 0
$completedInPRD = 0
if (Test-Path $PRDPath) {
    $prd = Get-Content $PRDPath -Raw
    $totalTasks = ([regex]::Matches($prd, '###\s+US-\d+')).Count
    $completedInPRD = ([regex]::Matches($prd, '\[x\]')).Count
    $remainingCriteria = ([regex]::Matches($prd, '\[\s\]')).Count
}

# Display status
Write-Host "  Project:     $($state.projectName)" -ForegroundColor White
Write-Host "  Started:     $($state.startedAt)" -ForegroundColor DarkGray
Write-Host "  Duration:    $duration" -ForegroundColor DarkGray
Write-Host ""

Write-Host "  ┌─────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
Write-Host "  │  PROGRESS                                               │" -ForegroundColor DarkGray
Write-Host "  ├─────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray

# Current task
if ($state.currentTaskId) {
    Write-Host "  │  Current Task:  $($state.currentTaskId)" -ForegroundColor Cyan
} else {
    Write-Host "  │  Current Task:  None" -ForegroundColor DarkGray
}

Write-Host "  │  Iteration:     $($state.currentIteration)" -ForegroundColor White
Write-Host "  │" -ForegroundColor DarkGray

# Progress bar
$completedCount = $state.completedTasks.Count
$progress = if ($totalTasks -gt 0) { [math]::Round(($completedCount / $totalTasks) * 100) } else { 0 }
$barLength = 30
$filledLength = [math]::Round($barLength * $progress / 100)
$emptyLength = $barLength - $filledLength
$progressBar = ("█" * $filledLength) + ("░" * $emptyLength)

Write-Host "  │  [$progressBar] $progress%" -ForegroundColor Green
Write-Host "  │" -ForegroundColor DarkGray

# Task counts
Write-Host "  │  Completed:     $completedCount" -ForegroundColor Green
Write-Host "  │  Skipped:       $($state.skippedTasks.Count)" -ForegroundColor Yellow
Write-Host "  │  Failed:        $($state.failedTasks.Count)" -ForegroundColor Red
Write-Host "  │  Remaining:     $($totalTasks - $completedCount - $state.skippedTasks.Count)" -ForegroundColor DarkGray
Write-Host "  │" -ForegroundColor DarkGray

# Consecutive failures warning
if ($state.consecutiveFailures -gt 0) {
    Write-Host "  │  ⚠️  Consecutive Failures: $($state.consecutiveFailures)" -ForegroundColor Red
    if ($state.lastError) {
        Write-Host "  │     Last Error: $($state.lastError.Substring(0, [Math]::Min(40, $state.lastError.Length)))..." -ForegroundColor Red
    }
    Write-Host "  │" -ForegroundColor DarkGray
}

Write-Host "  └─────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
Write-Host ""

# Completed tasks list
if ($state.completedTasks.Count -gt 0) {
    Write-Host "  Completed Tasks:" -ForegroundColor Green
    foreach ($task in $state.completedTasks) {
        Write-Host "    ✓ $task" -ForegroundColor Green
    }
    Write-Host ""
}

# Skipped tasks list
if ($state.skippedTasks.Count -gt 0) {
    Write-Host "  Skipped Tasks:" -ForegroundColor Yellow
    foreach ($task in $state.skippedTasks) {
        Write-Host "    ⏭ $task" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Resume command
Write-Host "  To resume: ./ralph-jaws-v4.ps1 -PRDPath `"$PRDPath`"" -ForegroundColor DarkGray
Write-Host ""
