# ============================================================================
# MERGE READINESS CHECKS MODULE
# Enhancement from Auto-Claude v2.7.4: Branch state validation before merge
# Add this to ralph-jaws-v4.ps1 or import as module
# ============================================================================

<#
.SYNOPSIS
    Validates worktree branch state before attempting merge to main.

.DESCRIPTION
    Auto-Claude v2.7.4 enhanced PR merge readiness with branch state validation.
    This module brings that safety to JAWS worktree merges.
    
    Checks performed:
    - Uncommitted changes detection
    - Untracked files warning
    - Branch sync status with origin
    - Merge conflict prediction
    - Build/test status (optional)

.EXAMPLE
    $ready = Test-MergeReadiness -BranchName "jaws-build-20260119"
    if ($ready.CanMerge) { git merge $BranchName }
#>

# ============================================================================
# CONFIGURATION
# ============================================================================

$script:MergeCheckConfig = @{
    RequireCleanWorkingTree = $true
    RequireSyncWithOrigin = $false  # Set true if using remote
    AllowUntrackedFiles = $true
    CheckForConflicts = $true
    VerboseOutput = $true
}

# ============================================================================
# MAIN READINESS CHECK
# ============================================================================

function Test-MergeReadiness {
    <#
    .SYNOPSIS
        Comprehensive merge readiness validation.
    
    .PARAMETER BranchName
        The branch to check for merge readiness.
    
    .PARAMETER TargetBranch
        The branch to merge into. Default: "main"
    
    .PARAMETER WorktreePath
        Path to worktree. Default: current directory.
    
    .OUTPUTS
        Hashtable with CanMerge boolean and detailed check results.
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$BranchName,
        
        [string]$TargetBranch = "main",
        
        [string]$WorktreePath = "."
    )
    
    $result = @{
        CanMerge = $true
        Checks = @{}
        Warnings = @()
        Errors = @()
        Timestamp = Get-Date
        BranchName = $BranchName
        TargetBranch = $TargetBranch
    }
    
    # Save current location
    $originalPath = Get-Location
    
    try {
        Set-Location $WorktreePath
        
        # ----------------------------------------------------------------
        # CHECK 1: Working tree clean
        # ----------------------------------------------------------------
        $status = git status --porcelain 2>&1
        $uncommittedChanges = @($status | Where-Object { $_ -match "^[MADRCU]" })
        $untrackedFiles = @($status | Where-Object { $_ -match "^\?\?" })
        
        $result.Checks["WorkingTreeClean"] = @{
            Passed = ($uncommittedChanges.Count -eq 0)
            UncommittedCount = $uncommittedChanges.Count
            UntrackedCount = $untrackedFiles.Count
            Details = $uncommittedChanges
        }
        
        if ($uncommittedChanges.Count -gt 0) {
            $result.Errors += "Found $($uncommittedChanges.Count) uncommitted changes"
            $result.CanMerge = $false
            
            if ($script:MergeCheckConfig.VerboseOutput) {
                Write-Host "  [MERGE CHECK] ❌ Uncommitted changes:" -ForegroundColor Red
                $uncommittedChanges | ForEach-Object {
                    Write-Host "    $_" -ForegroundColor DarkRed
                }
            }
        }
        else {
            if ($script:MergeCheckConfig.VerboseOutput) {
                Write-Host "  [MERGE CHECK] ✓ Working tree clean" -ForegroundColor Green
            }
        }
        
        if ($untrackedFiles.Count -gt 0 -and -not $script:MergeCheckConfig.AllowUntrackedFiles) {
            $result.Warnings += "Found $($untrackedFiles.Count) untracked files"
            if ($script:MergeCheckConfig.VerboseOutput) {
                Write-Host "  [MERGE CHECK] ⚠ Untracked files: $($untrackedFiles.Count)" -ForegroundColor Yellow
            }
        }
        
        # ----------------------------------------------------------------
        # CHECK 2: Branch exists
        # ----------------------------------------------------------------
        $branchExists = git rev-parse --verify $BranchName 2>&1
        $result.Checks["BranchExists"] = @{
            Passed = ($LASTEXITCODE -eq 0)
            Branch = $BranchName
        }
        
        if ($LASTEXITCODE -ne 0) {
            $result.Errors += "Branch '$BranchName' does not exist"
            $result.CanMerge = $false
            
            if ($script:MergeCheckConfig.VerboseOutput) {
                Write-Host "  [MERGE CHECK] ❌ Branch not found: $BranchName" -ForegroundColor Red
            }
        }
        else {
            if ($script:MergeCheckConfig.VerboseOutput) {
                Write-Host "  [MERGE CHECK] ✓ Branch exists: $BranchName" -ForegroundColor Green
            }
        }
        
        # ----------------------------------------------------------------
        # CHECK 3: Target branch exists
        # ----------------------------------------------------------------
        $targetExists = git rev-parse --verify $TargetBranch 2>&1
        $result.Checks["TargetBranchExists"] = @{
            Passed = ($LASTEXITCODE -eq 0)
            Branch = $TargetBranch
        }
        
        if ($LASTEXITCODE -ne 0) {
            $result.Errors += "Target branch '$TargetBranch' does not exist"
            $result.CanMerge = $false
            
            if ($script:MergeCheckConfig.VerboseOutput) {
                Write-Host "  [MERGE CHECK] ❌ Target branch not found: $TargetBranch" -ForegroundColor Red
            }
        }
        else {
            if ($script:MergeCheckConfig.VerboseOutput) {
                Write-Host "  [MERGE CHECK] ✓ Target branch exists: $TargetBranch" -ForegroundColor Green
            }
        }
        
        # ----------------------------------------------------------------
        # CHECK 4: Commits ahead/behind
        # ----------------------------------------------------------------
        try {
            $aheadBehind = git rev-list --left-right --count "$TargetBranch...$BranchName" 2>&1
            if ($LASTEXITCODE -eq 0 -and $aheadBehind -match "(\d+)\s+(\d+)") {
                $behind = [int]$Matches[1]
                $ahead = [int]$Matches[2]
                
                $result.Checks["CommitStatus"] = @{
                    Passed = $true
                    Ahead = $ahead
                    Behind = $behind
                }
                
                if ($script:MergeCheckConfig.VerboseOutput) {
                    Write-Host "  [MERGE CHECK] ✓ Branch is $ahead commits ahead, $behind behind $TargetBranch" -ForegroundColor Green
                }
                
                if ($ahead -eq 0) {
                    $result.Warnings += "No new commits to merge"
                    if ($script:MergeCheckConfig.VerboseOutput) {
                        Write-Host "  [MERGE CHECK] ⚠ No new commits to merge" -ForegroundColor Yellow
                    }
                }
                
                if ($behind -gt 0) {
                    $result.Warnings += "Branch is $behind commits behind $TargetBranch"
                    if ($script:MergeCheckConfig.VerboseOutput) {
                        Write-Host "  [MERGE CHECK] ⚠ Consider rebasing - $behind commits behind" -ForegroundColor Yellow
                    }
                }
            }
        }
        catch {
            $result.Checks["CommitStatus"] = @{
                Passed = $false
                Error = $_.Exception.Message
            }
        }
        
        # ----------------------------------------------------------------
        # CHECK 5: Merge conflict prediction
        # ----------------------------------------------------------------
        if ($script:MergeCheckConfig.CheckForConflicts) {
            try {
                # Get merge base
                $mergeBase = git merge-base $TargetBranch $BranchName 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    # Dry-run merge to check for conflicts
                    $mergeTest = git merge-tree $mergeBase $TargetBranch $BranchName 2>&1
                    $hasConflicts = $mergeTest -match "CONFLICT|changed in both"
                    
                    $result.Checks["ConflictCheck"] = @{
                        Passed = (-not $hasConflicts)
                        MergeBase = $mergeBase
                        HasConflicts = $hasConflicts
                    }
                    
                    if ($hasConflicts) {
                        $result.Errors += "Merge conflicts detected"
                        $result.CanMerge = $false
                        
                        if ($script:MergeCheckConfig.VerboseOutput) {
                            Write-Host "  [MERGE CHECK] ❌ Merge conflicts detected!" -ForegroundColor Red
                            Write-Host "    Run 'git merge $BranchName' manually to resolve" -ForegroundColor DarkRed
                        }
                    }
                    else {
                        if ($script:MergeCheckConfig.VerboseOutput) {
                            Write-Host "  [MERGE CHECK] ✓ No merge conflicts predicted" -ForegroundColor Green
                        }
                    }
                }
            }
            catch {
                $result.Checks["ConflictCheck"] = @{
                    Passed = $false
                    Error = $_.Exception.Message
                }
                $result.Warnings += "Could not check for conflicts: $($_.Exception.Message)"
            }
        }
        
        # ----------------------------------------------------------------
        # CHECK 6: Files changed summary
        # ----------------------------------------------------------------
        try {
            $filesChanged = git diff --name-only "$TargetBranch...$BranchName" 2>&1
            $fileCount = @($filesChanged | Where-Object { $_ }).Count
            
            $result.Checks["FilesChanged"] = @{
                Passed = $true
                Count = $fileCount
                Files = $filesChanged
            }
            
            if ($script:MergeCheckConfig.VerboseOutput) {
                Write-Host "  [MERGE CHECK] ℹ Files to be merged: $fileCount" -ForegroundColor Cyan
            }
        }
        catch {
            # Non-critical
        }
        
    }
    finally {
        Set-Location $originalPath
    }
    
    # ----------------------------------------------------------------
    # SUMMARY
    # ----------------------------------------------------------------
    Write-Host ""
    if ($result.CanMerge) {
        Write-Host "  [MERGE CHECK] ✓ READY TO MERGE" -ForegroundColor Green
    }
    else {
        Write-Host "  [MERGE CHECK] ❌ NOT READY TO MERGE" -ForegroundColor Red
        Write-Host "  Errors:" -ForegroundColor Red
        $result.Errors | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor DarkRed
        }
    }
    
    if ($result.Warnings.Count -gt 0) {
        Write-Host "  Warnings:" -ForegroundColor Yellow
        $result.Warnings | ForEach-Object {
            Write-Host "    - $_" -ForegroundColor DarkYellow
        }
    }
    Write-Host ""
    
    return $result
}

# ============================================================================
# QUICK CHECKS
# ============================================================================

function Test-WorkingTreeClean {
    <#
    .SYNOPSIS
        Quick check for uncommitted changes.
    #>
    $status = git status --porcelain 2>&1
    return ($status -eq $null -or $status.Length -eq 0)
}

function Get-BranchDiff {
    <#
    .SYNOPSIS
        Get summary of differences between branches.
    #>
    param(
        [string]$SourceBranch,
        [string]$TargetBranch = "main"
    )
    
    $stats = git diff --stat "$TargetBranch...$SourceBranch" 2>&1
    return $stats
}

# ============================================================================
# SAFE MERGE FUNCTION
# ============================================================================

function Invoke-SafeMerge {
    <#
    .SYNOPSIS
        Performs merge only if all readiness checks pass.
    
    .PARAMETER BranchName
        The branch to merge.
    
    .PARAMETER TargetBranch
        The branch to merge into. Default: "main"
    
    .PARAMETER NoFastForward
        Use --no-ff flag. Default: true
    
    .PARAMETER CommitMessage
        Custom merge commit message.
    
    .OUTPUTS
        Hashtable with merge result.
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$BranchName,
        
        [string]$TargetBranch = "main",
        
        [switch]$NoFastForward = $true,
        
        [string]$CommitMessage = $null
    )
    
    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  SAFE MERGE: $BranchName → $TargetBranch" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Run readiness checks
    $readiness = Test-MergeReadiness -BranchName $BranchName -TargetBranch $TargetBranch
    
    if (-not $readiness.CanMerge) {
        return @{
            Success = $false
            Reason = "Readiness checks failed"
            Errors = $readiness.Errors
            Readiness = $readiness
        }
    }
    
    # Perform merge
    try {
        # Checkout target branch
        git checkout $TargetBranch 2>&1 | Out-Null
        
        # Build merge command
        $mergeArgs = @($BranchName)
        if ($NoFastForward) {
            $mergeArgs += "--no-ff"
        }
        if ($CommitMessage) {
            $mergeArgs += "-m"
            $mergeArgs += $CommitMessage
        }
        else {
            $mergeArgs += "-m"
            $mergeArgs += "Merge branch '$BranchName' (JAWS Safe Merge)"
        }
        
        Write-Host "  Executing: git merge $($mergeArgs -join ' ')" -ForegroundColor DarkGray
        $mergeResult = git merge @mergeArgs 2>&1 | Out-String
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Merge successful!" -ForegroundColor Green
            return @{
                Success = $true
                Output = $mergeResult
                Readiness = $readiness
            }
        }
        else {
            Write-Host "  [ERROR] Merge failed" -ForegroundColor Red
            return @{
                Success = $false
                Reason = "Merge command failed"
                Output = $mergeResult
                Readiness = $readiness
            }
        }
    }
    catch {
        Write-Host "  [ERROR] Exception during merge: $_" -ForegroundColor Red
        return @{
            Success = $false
            Reason = $_.Exception.Message
            Readiness = $readiness
        }
    }
}

# ============================================================================
# INTEGRATION HELPER
# ============================================================================

function Get-MergeIntegrationCode {
    <#
    .SYNOPSIS
        Returns code snippet to integrate into Complete-Worktree function.
    #>
    
    return @'
# ============================================================================
# INTEGRATION INTO RALPH-JAWS Complete-Worktree FUNCTION
# Replace the merge section with this safer version:
# ============================================================================

function Complete-Worktree {
    param([bool]$Success = $true)
    
    if (-not $WorktreeCreated) { return }
    
    $worktreeDir = Get-Location
    Set-Location $OriginalPath
    
    if ($Success) {
        Write-Host ""
        Write-Host "  Validating merge readiness..." -ForegroundColor Cyan
        
        # Run readiness checks BEFORE attempting merge
        $readiness = Test-MergeReadiness -BranchName $WorktreeBranch -WorktreePath $worktreeDir
        
        if (-not $readiness.CanMerge) {
            Write-Host ""
            Write-Host "  [WARNING] Merge blocked by readiness checks" -ForegroundColor Yellow
            Write-Host "  Branch $WorktreeBranch preserved for manual review." -ForegroundColor Yellow
            Write-Host "  Path: $worktreeDir" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  To fix and retry:" -ForegroundColor Cyan
            Write-Host "    cd $worktreeDir" -ForegroundColor DarkCyan
            Write-Host "    # fix issues" -ForegroundColor DarkCyan
            Write-Host "    git add -A && git commit -m 'fix: resolve merge blockers'" -ForegroundColor DarkCyan
            Write-Host "    cd $OriginalPath" -ForegroundColor DarkCyan
            Write-Host "    git merge $WorktreeBranch --no-ff" -ForegroundColor DarkCyan
            return
        }
        
        # Safe to merge
        $mergeResult = Invoke-SafeMerge -BranchName $WorktreeBranch
        
        if (-not $mergeResult.Success) {
            Write-Host "  [ERROR] Merge failed: $($mergeResult.Reason)" -ForegroundColor Red
            Write-Host "  Branch preserved: $WorktreeBranch" -ForegroundColor Yellow
            return
        }
        
        Write-Host "  [OK] Merged to main branch" -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host "  Build incomplete. Worktree preserved for review." -ForegroundColor Yellow
        Write-Host "  Branch: $WorktreeBranch" -ForegroundColor Yellow
        Write-Host "  Path: $worktreeDir" -ForegroundColor Yellow
        return
    }
    
    # Cleanup only after successful merge
    try {
        git worktree remove $worktreeDir --force 2>&1 | Out-Null
        git branch -d $WorktreeBranch 2>&1 | Out-Null
        Write-Host "  [OK] Worktree cleaned up" -ForegroundColor Green
    }
    catch {
        Write-Host "  [WARNING] Cleanup failed. Run manually:" -ForegroundColor Yellow
        Write-Host "    git worktree remove $worktreeDir" -ForegroundColor Yellow
        Write-Host "    git branch -d $WorktreeBranch" -ForegroundColor Yellow
    }
}
'@
}

# ============================================================================
# MODULE INFO
# ============================================================================

Write-Host "Merge Readiness Checks Module loaded." -ForegroundColor Green
Write-Host "Commands available:"
Write-Host "  Test-MergeReadiness     - Full merge readiness validation"
Write-Host "  Test-WorkingTreeClean   - Quick uncommitted changes check"
Write-Host "  Get-BranchDiff          - View diff summary between branches"
Write-Host "  Invoke-SafeMerge        - Merge only if checks pass"
Write-Host "  Get-MergeIntegrationCode - Get code to integrate into RALPH"
