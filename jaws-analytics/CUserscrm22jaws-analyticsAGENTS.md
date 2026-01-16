

### Auto-Trigger Pattern for Analytics Integration
**Pattern:** Add optional analytics trigger after successful script completion

**When to use:**
- Automation scripts that complete a complex workflow
- Need to automatically collect metrics/analytics after completion
- Want to provide visibility into what was built
- Analytics should be optional (not block main workflow)

**Structure:**
```powershell
# Parameters
param(
    [switch]$SkipAnalytics,
    [string]$AnalyticsWebhook = "http://localhost:5678/webhook/analyze-build",
    [string]$ProjectName = "",
    [string]$ClientName = ""
)

# Analytics trigger function
function Invoke-AnalyticsTrigger {
    param($buildPath, $projectName, $clientName, $webhookUrl)
    
    try {
        $body = @{
            build_path = $buildPath
            project_name = $projectName
            client_name = $clientName
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        
        Write-Host "Analytics generated\! Dashboard: http://localhost:3000" -ForegroundColor Cyan
        return $true
    }
    catch {
        Write-Host "Warning: Analytics failed (optional - main workflow succeeded)" -ForegroundColor Yellow
        return $false
    }
}

# After successful completion
if (-not $SkipAnalytics) {
    Invoke-AnalyticsTrigger -buildPath (Get-Location) -projectName $ProjectName -clientName $ClientName -webhookUrl $AnalyticsWebhook
}
```

**Why:**
- **Non-blocking** - Analytics failure doesnt fail main workflow
- **Optional** - Users can skip with `-SkipAnalytics` flag
- **Configurable** - Custom webhook URL, project/client names
- **User-friendly** - Logs dashboard URL for immediate access
- **Auto-detection** - Infers project name from folder if not provided

**Benefits:**
- Automatic documentation of completed work
- No manual step to trigger analytics
- Seamless integration with existing workflow
- Graceful degradation (analytics is enhancement, not requirement)

**Example from this project:** ralph.ps1 US-022
- Triggers analytics webhook after RALPH completes all tasks
- Passes build path and metadata to analytics orchestrator
- Shows dashboard URL for immediate review
- Fails gracefully if webhook unavailable

**Common gotchas:**
- Use try/catch to prevent analytics failures from blocking workflow
- Default sensible values (project name from folder, client = "Internal")
- Log both success and failure states for transparency
- Make webhook URL configurable (dev vs production)

---

