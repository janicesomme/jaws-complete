param(
    # === CORE PARAMETERS ===
    [string]$PRDPath = "PRD.md",
    [string]$StateFile = "jaws-orchestrator-state.json",
    [int]$MaxIterationsPerWorker = 10,
    [int]$SleepSeconds = 2,
    
    # === ORCHESTRATION PARAMETERS ===
    [ValidateRange(1, 5)]
    [int]$MaxWorkers = 3,
    [switch]$AutoOrchestrate,
    [switch]$DryRun,
    
    # === INHERITED FROM v5 ===
    [switch]$UseWorktree,
    [string]$WorktreePath = "../.worktrees",
    [switch]$AtomicCommits,
    [switch]$GenerateChangelog,
    [switch]$EnableLearnings,
    [string]$LearningsFile = "PROJECT-LEARNINGS.json",
    [switch]$AImergeResolution,
    [switch]$EvidenceBasedQA,
    
    # === v6 SPECIFIC ===
    [switch]$PlanGuardian,
    [switch]$ProactiveConflictPrevention,
    [switch]$Verbose,
    [ValidateSet("opus", "sonnet", "haiku")]
    [string]$Model = "sonnet"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# BANNER
# ============================================================================

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Magenta
Write-Host "  RALPH-JAWS v6 - ORCHESTRATED MULTI-AGENT BUILD SYSTEM              " -ForegroundColor Magenta
Write-Host "  Personal Power Tool - Not for Distribution                          " -ForegroundColor Magenta
Write-Host "=======================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Orchestration Settings:" -ForegroundColor Cyan
Write-Host "  - Max Workers:              $MaxWorkers"
Write-Host "  - Auto Orchestrate:         $AutoOrchestrate"
Write-Host "  - Plan Guardian:            $PlanGuardian"
Write-Host "  - Proactive Conflict Prev:  $ProactiveConflictPrevention"
Write-Host "  - Dry Run:                  $DryRun"
Write-Host ""

# ============================================================================
# GLOBAL STATE
# ============================================================================

$script:OrchestratorState = $null
$script:WorkerProcesses = @{}
$script:OriginalPath = Get-Location
$script:StartTime = Get-Date

# ============================================================================
# ATOMIC FILE OPERATIONS (from v5)
# ============================================================================

function Save-StateAtomic {
    param($state, $filePath)
    
    $tempFile = "$filePath.tmp"
    $backupFile = "$filePath.bak"
    $lockFile = "$filePath.lock"
    
    # Simple file locking
    $lockAttempts = 0
    while ((Test-Path $lockFile) -and $lockAttempts -lt 10) {
        Start-Sleep -Milliseconds 100
        $lockAttempts++
    }
    
    try {
        # Create lock
        "locked" | Out-File $lockFile -Force
        
        # Write to temp
        $state | ConvertTo-Json -Depth 20 | Out-File -FilePath $tempFile -Encoding utf8
        
        # Backup existing
        if (Test-Path $filePath) {
            Copy-Item $filePath $backupFile -Force
        }
        
        # Atomic rename
        Move-Item $tempFile $filePath -Force
    }
    finally {
        # Release lock
        if (Test-Path $lockFile) {
            Remove-Item $lockFile -Force
        }
    }
}

function Read-StateAtomic {
    param($filePath)
    
    $lockFile = "$filePath.lock"
    
    # Wait for any write operation
    $lockAttempts = 0
    while ((Test-Path $lockFile) -and $lockAttempts -lt 10) {
        Start-Sleep -Milliseconds 100
        $lockAttempts++
    }
    
    if (Test-Path $filePath) {
        return Get-Content $filePath -Raw | ConvertFrom-Json
    }
    return $null
}

# ============================================================================
# PRD PARSING & DEPENDENCY ANALYSIS
# ============================================================================

function Get-AllTasks {
    param([string]$prdPath)
    
    if (-not (Test-Path $prdPath)) {
        Write-Host "  [ERROR] PRD not found: $prdPath" -ForegroundColor Red
        return @()
    }
    
    $prd = Get-Content $prdPath -Raw
    $tasks = @()
    
    # Match pattern: ### US-XXX: Title
    $taskPattern = '###\s+(US-\d+):\s+(.+?)(?=\r?\n)'
    $taskMatches = [regex]::Matches($prd, $taskPattern)
    
    foreach ($match in $taskMatches) {
        $taskId = $match.Groups[1].Value
        $taskName = $match.Groups[2].Value.Trim()
        
        # Skip if already marked SKIPPED or complete
        if ($prd -match "\[SKIPPED\]\s*###\s+$taskId") {
            continue
        }
        
        # Find task section
        $escapedId = [regex]::Escape($taskId)
        $sections = $prd -split "###\s+$escapedId"
        if ($sections.Count -lt 2) { continue }
        
        $taskSection = $sections[1]
        $nextTaskSplit = $taskSection -split "###\s+US-"
        $taskSection = $nextTaskSplit[0]
        
        # Check if complete
        $unchecked = [regex]::Matches($taskSection, '\[\s\]')
        $checked = [regex]::Matches($taskSection, '\[x\]')
        
        if ($unchecked.Count -eq 0 -and $checked.Count -gt 0) {
            continue  # Already complete
        }
        
        # Extract metadata
        $filesMatch = [regex]::Match($taskSection, '\*\*FILES:\*\*\s*(.+?)(?=\r?\n)')
        $verifyMatch = [regex]::Match($taskSection, '\*\*VERIFY:\*\*\s*(.+?)(?=\r?\n)')
        $doneMatch = [regex]::Match($taskSection, '\*\*DONE:\*\*\s*(.+?)(?=\r?\n)')
        $dependsMatch = [regex]::Match($taskSection, '\*\*DEPENDS:\*\*\s*(.+?)(?=\r?\n)')
        
        # Detect task type from content
        $taskType = "general"
        if ($taskSection -match "supabase|database|schema|table|RLS") {
            $taskType = "database"
        }
        elseif ($taskSection -match "n8n|workflow|webhook|node") {
            $taskType = "workflow"
        }
        elseif ($taskSection -match "react|component|dashboard|frontend|UI") {
            $taskType = "frontend"
        }
        elseif ($taskSection -match "email|notification|slack|alert") {
            $taskType = "integration"
        }
        elseif ($taskSection -match "API|endpoint|route") {
            $taskType = "backend"
        }
        
        $tasks += @{
            id = $taskId
            name = $taskName
            type = $taskType
            files = if ($filesMatch.Success) { $filesMatch.Groups[1].Value.Trim() } else { "" }
            verify = if ($verifyMatch.Success) { $verifyMatch.Groups[1].Value.Trim() } else { "" }
            done = if ($doneMatch.Success) { $doneMatch.Groups[1].Value.Trim() } else { "" }
            depends = if ($dependsMatch.Success) { 
                $dependsMatch.Groups[1].Value.Trim() -split ',\s*' 
            } else { @() }
            status = "pending"
            assignedWorker = $null
            section = $taskSection
        }
    }
    
    return $tasks
}

function Build-DependencyGraph {
    param($tasks)
    
    Write-Host ""
    Write-Host "  Building dependency graph..." -ForegroundColor Cyan
    
    # Auto-detect dependencies based on task types and files
    $graph = @{}
    
    foreach ($task in $tasks) {
        $graph[$task.id] = @{
            task = $task
            dependsOn = @($task.depends)
            blockedBy = @()
            blocks = @()
        }
    }
    
    # Infer dependencies from task types
    # Database tasks typically block everything else
    $dbTasks = $tasks | Where-Object { $_.type -eq "database" }
    $workflowTasks = $tasks | Where-Object { $_.type -eq "workflow" }
    $frontendTasks = $tasks | Where-Object { $_.type -eq "frontend" }
    $backendTasks = $tasks | Where-Object { $_.type -eq "backend" }
    
    # Database blocks workflows and backend that reference DB
    foreach ($dbTask in $dbTasks) {
        foreach ($wfTask in $workflowTasks) {
            if ($wfTask.section -match "supabase|database|insert|select|update") {
                if ($graph[$wfTask.id].dependsOn -notcontains $dbTask.id) {
                    $graph[$wfTask.id].dependsOn += $dbTask.id
                    $graph[$dbTask.id].blocks += $wfTask.id
                }
            }
        }
        foreach ($beTask in $backendTasks) {
            if ($beTask.section -match "supabase|database") {
                if ($graph[$beTask.id].dependsOn -notcontains $dbTask.id) {
                    $graph[$beTask.id].dependsOn += $dbTask.id
                    $graph[$dbTask.id].blocks += $beTask.id
                }
            }
        }
    }
    
    # Workflow tasks with sequence (US-002 → US-003 → US-004 if same workflow file)
    $workflowFiles = @{}
    foreach ($wfTask in $workflowTasks) {
        if ($wfTask.files) {
            if (-not $workflowFiles[$wfTask.files]) {
                $workflowFiles[$wfTask.files] = @()
            }
            $workflowFiles[$wfTask.files] += $wfTask
        }
    }
    
    foreach ($file in $workflowFiles.Keys) {
        $fileTasks = $workflowFiles[$file] | Sort-Object { [int]($_.id -replace 'US-', '') }
        for ($i = 1; $i -lt $fileTasks.Count; $i++) {
            $prev = $fileTasks[$i - 1]
            $curr = $fileTasks[$i]
            if ($graph[$curr.id].dependsOn -notcontains $prev.id) {
                $graph[$curr.id].dependsOn += $prev.id
                $graph[$prev.id].blocks += $curr.id
            }
        }
    }
    
    # Print graph
    Write-Host ""
    Write-Host "  Dependency Graph:" -ForegroundColor Yellow
    foreach ($taskId in ($graph.Keys | Sort-Object)) {
        $node = $graph[$taskId]
        $deps = if ($node.dependsOn.Count -gt 0) { " → depends on: $($node.dependsOn -join ', ')" } else { " (independent)" }
        $type = "[$($node.task.type)]"
        Write-Host "    $taskId $type$deps" -ForegroundColor DarkGray
    }
    Write-Host ""
    
    return $graph
}

function Get-ParallelizationPlan {
    param($graph, $maxWorkers)
    
    Write-Host "  Creating parallelization plan for $maxWorkers workers..." -ForegroundColor Cyan
    
    # Group tasks into execution waves
    $waves = @()
    $completed = @()
    $remaining = @($graph.Keys)
    
    while ($remaining.Count -gt 0) {
        # Find all tasks whose dependencies are satisfied
        $readyTasks = @()
        foreach ($taskId in $remaining) {
            $node = $graph[$taskId]
            $depsCompleted = $true
            foreach ($dep in $node.dependsOn) {
                if ($dep -and $completed -notcontains $dep) {
                    $depsCompleted = $false
                    break
                }
            }
            if ($depsCompleted) {
                $readyTasks += $taskId
            }
        }
        
        if ($readyTasks.Count -eq 0 -and $remaining.Count -gt 0) {
            Write-Host "  [WARNING] Circular dependency detected, forcing progress" -ForegroundColor Yellow
            $readyTasks = @($remaining[0])
        }
        
        $waves += ,@($readyTasks)
        $completed += $readyTasks
        $remaining = $remaining | Where-Object { $completed -notcontains $_ }
    }
    
    # Assign tasks to workers by wave
    $workerAssignments = @{}
    for ($w = 0; $w -lt $maxWorkers; $w++) {
        $workerAssignments["worker-$w"] = @{
            tasks = @()
            type = ""
        }
    }
    
    # Smart assignment: group similar task types on same worker
    $typeWorkerMap = @{}
    
    foreach ($wave in $waves) {
        foreach ($taskId in $wave) {
            $task = $graph[$taskId].task
            $assignedWorker = $null
            
            # Try to assign to worker already handling this type
            if ($typeWorkerMap[$task.type]) {
                $candidateWorker = $typeWorkerMap[$task.type]
                # Check if this worker can take it (not already in this wave)
                $workerWaveTasks = $workerAssignments[$candidateWorker].tasks | Where-Object { $wave -contains $_ }
                if ($workerWaveTasks.Count -lt 2) {  # Allow some overlap
                    $assignedWorker = $candidateWorker
                }
            }
            
            # Otherwise assign to least loaded worker
            if (-not $assignedWorker) {
                $leastLoaded = $workerAssignments.Keys | 
                    Sort-Object { $workerAssignments[$_].tasks.Count } | 
                    Select-Object -First 1
                $assignedWorker = $leastLoaded
                $typeWorkerMap[$task.type] = $assignedWorker
            }
            
            $workerAssignments[$assignedWorker].tasks += $taskId
            if (-not $workerAssignments[$assignedWorker].type) {
                $workerAssignments[$assignedWorker].type = $task.type
            }
        }
    }
    
    # Print plan
    Write-Host ""
    Write-Host "  Worker Assignments:" -ForegroundColor Yellow
    foreach ($worker in ($workerAssignments.Keys | Sort-Object)) {
        $assignment = $workerAssignments[$worker]
        if ($assignment.tasks.Count -gt 0) {
            Write-Host "    $worker [$($assignment.type)]: $($assignment.tasks -join ' → ')" -ForegroundColor White
        }
    }
    Write-Host ""
    
    Write-Host "  Execution Waves:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $waves.Count; $i++) {
        Write-Host "    Wave $($i + 1): $($waves[$i] -join ', ')" -ForegroundColor DarkGray
    }
    Write-Host ""
    
    return @{
        waves = $waves
        workerAssignments = $workerAssignments
        graph = $graph
    }
}

# ============================================================================
# WORKTREE MANAGEMENT
# ============================================================================

function Initialize-WorkerWorktrees {
    param($plan)
    
    Write-Host "  Setting up worker worktrees..." -ForegroundColor Cyan
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    # Ensure worktree base exists
    if (-not (Test-Path $WorktreePath)) {
        New-Item -ItemType Directory -Path $WorktreePath -Force | Out-Null
    }
    
    $worktrees = @{}
    
    foreach ($worker in $plan.workerAssignments.Keys) {
        $assignment = $plan.workerAssignments[$worker]
        if ($assignment.tasks.Count -eq 0) { continue }
        
        $branchName = "jaws-v6-$worker-$timestamp"
        $worktreeDir = Join-Path $WorktreePath $branchName
        
        try {
            Write-Host "    Creating worktree: $branchName" -ForegroundColor DarkGray
            git worktree add $worktreeDir -b $branchName 2>&1 | Out-Null
            
            # Copy essential files
            @("PRD.md", "AGENTS.md", "progress.txt", "PROJECT-LEARNINGS.json") | ForEach-Object {
                if (Test-Path $_) {
                    Copy-Item $_ -Destination $worktreeDir -Force
                }
            }
            
            $worktrees[$worker] = @{
                path = $worktreeDir
                branch = $branchName
                status = "ready"
            }
            
            Write-Host "    [OK] $worker → $branchName" -ForegroundColor Green
        }
        catch {
            Write-Host "    [ERROR] Failed to create worktree for $worker`: $_" -ForegroundColor Red
        }
    }
    
    return $worktrees
}

# ============================================================================
# WORKER PROCESS MANAGEMENT
# ============================================================================

function Start-WorkerProcess {
    param(
        $workerId,
        $worktreePath,
        $tasks,
        $graph
    )
    
    Write-Host "  Starting worker process: $workerId" -ForegroundColor Cyan
    
    # Create worker-specific state file
    $workerStateFile = Join-Path $worktreePath "worker-state.json"
    $workerState = @{
        workerId = $workerId
        status = "starting"
        tasks = $tasks
        currentTask = $null
        completedTasks = @()
        failedTasks = @()
        startTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    Save-StateAtomic $workerState $workerStateFile
    
    # Build worker prompt template
    $taskList = ($tasks | ForEach-Object { 
        $t = $graph[$_].task
        "- $($_): $($t.name) [$($t.type)]"
    }) -join "`n"
    
    $workerScript = @"
Set-Location '$worktreePath'

`$tasks = @($($tasks | ForEach-Object { "'$_'" } | Join-String -Separator ', '))
`$stateFile = 'worker-state.json'
`$orchestratorState = '$StateFile'

foreach (`$taskId in `$tasks) {
    # Update state
    `$state = Get-Content `$stateFile -Raw | ConvertFrom-Json
    `$state.currentTask = `$taskId
    `$state.status = "working"
    `$state | ConvertTo-Json -Depth 10 | Out-File `$stateFile -Encoding utf8
    
    # Check if blocked by dependency
    `$canProceed = `$true
    # Read orchestrator state for dependency signals
    if (Test-Path `$orchestratorState) {
        `$orchState = Get-Content `$orchestratorState -Raw | ConvertFrom-Json
        # Check signals for dependencies
    }
    
    # Build prompt
    `$prompt = @"
You are RALPH Worker $workerId, part of an orchestrated multi-agent build system.

YOUR ASSIGNMENT: Task `$taskId

Read PRD.md and complete ONLY this task:
`$taskId

RULES:
1. Complete ONLY the assigned task
2. Mark criteria complete in PRD.md as you verify them
3. Commit after completing the task
4. Update progress.txt with what you did

After completion, output: <worker-complete>`$taskId</worker-complete>
"@
    
    # Execute Claude
    try {
        `$result = claude --dangerously-skip-permissions -p `$prompt 2>&1 | Out-String
        
        if (`$result -match '<worker-complete>') {
            `$state.completedTasks += `$taskId
            Write-Host "[WORKER $workerId] Completed: `$taskId" -ForegroundColor Green
        }
        else {
            `$state.failedTasks += `$taskId
            Write-Host "[WORKER $workerId] Failed: `$taskId" -ForegroundColor Red
        }
    }
    catch {
        `$state.failedTasks += `$taskId
        Write-Host "[WORKER $workerId] Error: `$_" -ForegroundColor Red
    }
    
    `$state | ConvertTo-Json -Depth 10 | Out-File `$stateFile -Encoding utf8
}

# Mark worker complete
`$state = Get-Content `$stateFile -Raw | ConvertFrom-Json
`$state.status = "complete"
`$state.endTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
`$state | ConvertTo-Json -Depth 10 | Out-File `$stateFile -Encoding utf8

Write-Host "[WORKER $workerId] All tasks complete" -ForegroundColor Green
"@
    
    # Save worker script
    $workerScriptPath = Join-Path $worktreePath "worker-script.ps1"
    $workerScript | Out-File $workerScriptPath -Encoding utf8
    
    # Start as background job
    $job = Start-Job -ScriptBlock {
        param($scriptPath)
        pwsh -File $scriptPath
    } -ArgumentList $workerScriptPath
    
    return @{
        job = $job
        stateFile = $workerStateFile
        scriptPath = $workerScriptPath
    }
}

function Wait-ForDependency {
    param($taskId, $graph, $timeout = 300)
    
    $deps = $graph[$taskId].dependsOn
    if ($deps.Count -eq 0) { return $true }
    
    $startWait = Get-Date
    
    while (((Get-Date) - $startWait).TotalSeconds -lt $timeout) {
        $allComplete = $true
        
        # Check orchestrator state for completion signals
        $state = Read-StateAtomic $StateFile
        if ($state -and $state.signals) {
            foreach ($dep in $deps) {
                $signalKey = "$dep-complete"
                if (-not $state.signals.$signalKey) {
                    $allComplete = $false
                    break
                }
            }
        }
        else {
            $allComplete = $false
        }
        
        if ($allComplete) { return $true }
        
        Start-Sleep -Seconds 5
    }
    
    return $false
}

# ============================================================================
# ORCHESTRATION LOOP
# ============================================================================

function Start-Orchestration {
    param($plan, $worktrees)
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "  STARTING ORCHESTRATED BUILD                                         " -ForegroundColor Magenta
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Initialize orchestrator state
    $script:OrchestratorState = @{
        status = "running"
        startTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        workers = @{}
        signals = @{}
        completedTasks = @()
        failedTasks = @()
        currentWave = 0
    }
    
    foreach ($worker in $worktrees.Keys) {
        $script:OrchestratorState.workers[$worker] = @{
            status = "pending"
            worktree = $worktrees[$worker]
            tasks = $plan.workerAssignments[$worker].tasks
        }
    }
    
    Save-StateAtomic $script:OrchestratorState $StateFile
    
    # Start workers
    $workerJobs = @{}
    
    foreach ($worker in $worktrees.Keys) {
        $assignment = $plan.workerAssignments[$worker]
        if ($assignment.tasks.Count -eq 0) { continue }
        
        $workerInfo = Start-WorkerProcess `
            -workerId $worker `
            -worktreePath $worktrees[$worker].path `
            -tasks $assignment.tasks `
            -graph $plan.graph
        
        $workerJobs[$worker] = $workerInfo
        $script:OrchestratorState.workers[$worker].status = "running"
        $script:OrchestratorState.workers[$worker].job = $workerInfo.job.Id
    }
    
    Save-StateAtomic $script:OrchestratorState $StateFile
    
    # Monitor loop
    Write-Host ""
    Write-Host "  Monitoring workers..." -ForegroundColor Cyan
    Write-Host ""
    
    $allComplete = $false
    $monitorIteration = 0
    
    while (-not $allComplete) {
        $monitorIteration++
        $allComplete = $true
        
        Write-Host "  --- Monitor Check #$monitorIteration ---" -ForegroundColor DarkGray
        
        foreach ($worker in $workerJobs.Keys) {
            $job = $workerJobs[$worker].job
            $workerStateFile = $workerJobs[$worker].stateFile
            
            # Check job status
            $jobState = Get-Job -Id $job.Id -ErrorAction SilentlyContinue
            
            if ($jobState) {
                Write-Host "    $worker`: $($jobState.State)" -ForegroundColor $(
                    switch ($jobState.State) {
                        "Running" { "Yellow" }
                        "Completed" { "Green" }
                        "Failed" { "Red" }
                        default { "Gray" }
                    }
                )
                
                if ($jobState.State -eq "Running") {
                    $allComplete = $false
                }
                
                # Read worker state for details
                if (Test-Path $workerStateFile) {
                    $workerState = Get-Content $workerStateFile -Raw | ConvertFrom-Json
                    if ($workerState.currentTask) {
                        Write-Host "      Current: $($workerState.currentTask)" -ForegroundColor DarkGray
                    }
                    if ($workerState.completedTasks) {
                        Write-Host "      Completed: $($workerState.completedTasks -join ', ')" -ForegroundColor DarkGreen
                        
                        # Update orchestrator signals
                        foreach ($completed in $workerState.completedTasks) {
                            $script:OrchestratorState.signals["$completed-complete"] = $true
                            if ($script:OrchestratorState.completedTasks -notcontains $completed) {
                                $script:OrchestratorState.completedTasks += $completed
                            }
                        }
                    }
                }
            }
        }
        
        Save-StateAtomic $script:OrchestratorState $StateFile
        
        if (-not $allComplete) {
            Start-Sleep -Seconds 10
        }
    }
    
    # Collect results
    Write-Host ""
    Write-Host "  All workers complete. Collecting results..." -ForegroundColor Cyan
    
    foreach ($worker in $workerJobs.Keys) {
        $job = $workerJobs[$worker].job
        $output = Receive-Job -Id $job.Id
        Write-Host "  Output from $worker`:" -ForegroundColor DarkGray
        Write-Host $output
        Remove-Job -Id $job.Id -Force
    }
    
    $script:OrchestratorState.status = "merging"
    $script:OrchestratorState.endTime = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Save-StateAtomic $script:OrchestratorState $StateFile
    
    return $worktrees
}

# ============================================================================
# MERGE ORCHESTRATION
# ============================================================================

function Merge-WorkerBranches {
    param($worktrees)
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  MERGING WORKER BRANCHES                                             " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Set-Location $script:OriginalPath
    
    $mergeResults = @()
    
    foreach ($worker in ($worktrees.Keys | Sort-Object)) {
        $worktree = $worktrees[$worker]
        $branch = $worktree.branch
        
        Write-Host "  Merging $branch..." -ForegroundColor Yellow
        
        try {
            $mergeOutput = git merge $branch --no-ff -m "JAWS v6: Merge $worker ($branch)" 2>&1
            
            if ($LASTEXITCODE -ne 0 -or $mergeOutput -match "CONFLICT") {
                Write-Host "    [CONFLICT] Conflicts detected in $branch" -ForegroundColor Red
                
                if ($AImergeResolution) {
                    Write-Host "    Attempting AI resolution..." -ForegroundColor Yellow
                    
                    $conflicts = git diff --name-only --diff-filter=U
                    
                    foreach ($file in $conflicts) {
                        $conflictContent = Get-Content $file -Raw
                        
                        $resolverPrompt = @"
You are resolving a git merge conflict. The file contains <<<<<<< and >>>>>>> markers.

FILE: $file

CONFLICTED CONTENT:
$conflictContent

RULES:
1. Output ONLY the resolved file content
2. Preserve ALL intended functionality from both sides
3. No conflict markers in output
4. No explanations, just the resolved content
"@
                        
                        $resolved = claude --dangerously-skip-permissions -p $resolverPrompt 2>&1 | Out-String
                        $resolved = $resolved.Trim()
                        
                        # Remove any markdown code fences
                        $resolved = $resolved -replace '```\w*\n?', '' -replace '```', ''
                        
                        $resolved | Out-File $file -Encoding utf8
                        git add $file
                    }
                    
                    git commit -m "JAWS v6: AI-resolved merge conflicts from $branch"
                    Write-Host "    [OK] AI resolved conflicts" -ForegroundColor Green
                }
                else {
                    Write-Host "    [MANUAL] Resolve conflicts manually, then continue" -ForegroundColor Yellow
                    $mergeResults += @{ worker = $worker; status = "conflict"; branch = $branch }
                    continue
                }
            }
            
            Write-Host "    [OK] Merged $branch" -ForegroundColor Green
            $mergeResults += @{ worker = $worker; status = "merged"; branch = $branch }
        }
        catch {
            Write-Host "    [ERROR] Failed to merge $branch`: $_" -ForegroundColor Red
            $mergeResults += @{ worker = $worker; status = "error"; branch = $branch; error = $_.ToString() }
        }
    }
    
    return $mergeResults
}

function Remove-WorkerWorktrees {
    param($worktrees)
    
    Write-Host ""
    Write-Host "  Cleaning up worktrees..." -ForegroundColor Cyan
    
    Set-Location $script:OriginalPath
    
    foreach ($worker in $worktrees.Keys) {
        $worktree = $worktrees[$worker]
        
        try {
            git worktree remove $worktree.path --force 2>&1 | Out-Null
            git branch -d $worktree.branch 2>&1 | Out-Null
            Write-Host "    [OK] Removed $worker worktree" -ForegroundColor Green
        }
        catch {
            Write-Host "    [WARNING] Could not clean up $worker`: $_" -ForegroundColor Yellow
        }
    }
}

# ============================================================================
# PLAN GUARDIAN (Fresh Context QA)
# ============================================================================

function Invoke-PlanGuardian {
    param($prdPath)
    
    if (-not $PlanGuardian) { return $true }
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host "  PLAN GUARDIAN - Fresh Context Verification                          " -ForegroundColor Magenta
    Write-Host "=======================================================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Get git diff
    $diff = git diff HEAD~10 --stat 2>&1 | Out-String
    $diffFull = git diff HEAD~10 2>&1 | Out-String
    
    # Get PRD
    $prd = Get-Content $prdPath -Raw
    
    $guardianPrompt = @"
You are the PLAN GUARDIAN - a fresh-context verification agent.

You have NO knowledge of how this code was built. You only know:
1. What SHOULD exist (the PRD below)
2. What DOES exist (the git diff below)

YOUR JOB: Verify that what was built matches what was requested.

## PRD (What Should Exist)
$prd

## Git Diff Summary (What Does Exist)
$diff

## Detailed Changes
$($diffFull.Substring(0, [Math]::Min(10000, $diffFull.Length)))

## Verification Checklist

For each task in the PRD marked with [x] (complete):
1. Find evidence in the git diff that it was actually implemented
2. Check that the implementation matches the acceptance criteria
3. Flag any criteria marked complete but not evidenced in code

## Output Format

```json
{
  "overallStatus": "PASS|FAIL|WARNING",
  "verifiedTasks": [
    {
      "taskId": "US-XXX",
      "status": "VERIFIED|UNVERIFIED|PARTIAL",
      "evidence": "description of evidence found",
      "concerns": ["any concerns"]
    }
  ],
  "recommendations": ["list of recommendations"],
  "blockers": ["any blockers that must be fixed"]
}
```

Be strict. If you cannot find evidence, mark as UNVERIFIED.
"@
    
    Write-Host "  Running Plan Guardian verification..." -ForegroundColor Yellow
    
    $result = claude --dangerously-skip-permissions -p $guardianPrompt 2>&1 | Out-String
    
    Write-Host ""
    Write-Host "  Plan Guardian Report:" -ForegroundColor Cyan
    Write-Host $result
    
    # Parse result
    if ($result -match '"overallStatus":\s*"FAIL"') {
        Write-Host ""
        Write-Host "  [GUARDIAN] VERIFICATION FAILED - Review required" -ForegroundColor Red
        return $false
    }
    elseif ($result -match '"overallStatus":\s*"WARNING"') {
        Write-Host ""
        Write-Host "  [GUARDIAN] WARNINGS DETECTED - Review recommended" -ForegroundColor Yellow
        return $true  # Allow to proceed with warnings
    }
    else {
        Write-Host ""
        Write-Host "  [GUARDIAN] VERIFICATION PASSED" -ForegroundColor Green
        return $true
    }
}

# ============================================================================
# CHANGELOG GENERATION
# ============================================================================

function New-V6Changelog {
    $duration = (Get-Date) - $script:StartTime
    $state = Read-StateAtomic $StateFile
    
    $changelogPath = "CHANGELOG-v6-$(Get-Date -Format 'yyyy-MM-dd-HHmm').md"
    
    $workerSummary = ""
    if ($state.workers) {
        foreach ($worker in $state.workers.Keys) {
            $w = $state.workers[$worker]
            $workerSummary += "- **$worker**: $($w.tasks -join ', ')`n"
        }
    }
    
    $content = @"
# JAWS v6 Orchestrated Build Changelog

**Build Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm")
**Duration:** $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s
**Workers Used:** $($state.workers.Keys.Count)

---

## Build Configuration

- Max Workers: $MaxWorkers
- Auto Orchestrate: $AutoOrchestrate
- Plan Guardian: $PlanGuardian
- AI Merge Resolution: $AImergeResolution

---

## Worker Assignments

$workerSummary

---

## Completed Tasks

$($state.completedTasks | ForEach-Object { "- [x] $_" } | Out-String)

## Failed Tasks

$($state.failedTasks | ForEach-Object { "- [ ] $_ (failed)" } | Out-String)

---

## Timeline

- Started: $($state.startTime)
- Ended: $($state.endTime)
- Total Duration: $($duration.ToString())

---

*Generated by JAWS v6 Orchestrator*
"@
    
    $content | Out-File -FilePath $changelogPath -Encoding utf8
    Write-Host "  [CHANGELOG] Generated: $changelogPath" -ForegroundColor Green
    
    return $changelogPath
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

Write-Host "  Phase 1: Analyzing PRD..." -ForegroundColor White

# Get all tasks
$tasks = Get-AllTasks -prdPath $PRDPath

if ($tasks.Count -eq 0) {
    Write-Host ""
    Write-Host "  [COMPLETE] No pending tasks found in PRD!" -ForegroundColor Green
    exit 0
}

Write-Host "  Found $($tasks.Count) pending tasks" -ForegroundColor Cyan

# Build dependency graph
$graph = Build-DependencyGraph -tasks $tasks

# Create parallelization plan
$plan = Get-ParallelizationPlan -graph $graph -maxWorkers $MaxWorkers

if ($DryRun) {
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Yellow
    Write-Host "  DRY RUN COMPLETE - No changes made                                  " -ForegroundColor Yellow
    Write-Host "=======================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To execute this plan, run without -DryRun flag"
    exit 0
}

Write-Host "  Phase 2: Setting up worktrees..." -ForegroundColor White

# Initialize worktrees
$worktrees = Initialize-WorkerWorktrees -plan $plan

if ($worktrees.Count -eq 0) {
    Write-Host "  [ERROR] Failed to create any worktrees" -ForegroundColor Red
    exit 1
}

Write-Host "  Phase 3: Starting orchestration..." -ForegroundColor White

# Start orchestration
$worktrees = Start-Orchestration -plan $plan -worktrees $worktrees

Write-Host "  Phase 4: Merging results..." -ForegroundColor White

# Merge branches
$mergeResults = Merge-WorkerBranches -worktrees $worktrees

Write-Host "  Phase 5: Plan Guardian verification..." -ForegroundColor White

# Plan Guardian
$guardianPassed = Invoke-PlanGuardian -prdPath $PRDPath

Write-Host "  Phase 6: Cleanup..." -ForegroundColor White

# Cleanup
Remove-WorkerWorktrees -worktrees $worktrees

# Generate changelog
if ($GenerateChangelog) {
    New-V6Changelog
}

# Final summary
$duration = (Get-Date) - $script:StartTime
$state = Read-StateAtomic $StateFile

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Green
Write-Host "  JAWS v6 BUILD COMPLETE                                              " -ForegroundColor Green
Write-Host "=======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Duration:        $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s"
Write-Host "  Workers Used:    $($worktrees.Count)"
Write-Host "  Tasks Completed: $($state.completedTasks.Count)"
Write-Host "  Tasks Failed:    $($state.failedTasks.Count)"
Write-Host "  Guardian Status: $(if ($guardianPassed) { 'PASSED' } else { 'REVIEW NEEDED' })"
Write-Host ""

if ($state.failedTasks.Count -gt 0) {
    Write-Host "  Failed tasks: $($state.failedTasks -join ', ')" -ForegroundColor Red
    exit 1
}

exit 0
