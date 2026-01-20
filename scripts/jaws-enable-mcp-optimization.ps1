# ============================================================================
# ENABLE MCP OPTIMIZATION
# Run once to enable Claude Code's lazy loading for MCP tools
# ============================================================================
#
# What this does:
#   - Enables the new MCP search tool in Claude Code 2.17+
#   - MCP tool definitions load on-demand instead of all at once
#   - Saves 10-30% context window per MCP server
#
# Usage:
#   .\enable-mcp-optimization.ps1           # Enable globally (recommended)
#   .\enable-mcp-optimization.ps1 -Project  # Enable for current project only
#   .\enable-mcp-optimization.ps1 -Check    # Just check current status
#
# ============================================================================

param(
    [switch]$Project,  # Apply to current project only (not global)
    [switch]$Check     # Just check status, don't modify
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  MCP OPTIMIZATION SETUP                                              " -ForegroundColor Cyan
Write-Host "  Enables lazy loading for MCP tools in Claude Code 2.17+            " -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""

# Determine paths
$globalClaudeDir = Join-Path $env:USERPROFILE ".claude"
$globalSettingsPath = Join-Path $globalClaudeDir "settings.json"
$projectClaudeDir = ".claude"
$projectSettingsPath = Join-Path $projectClaudeDir "settings.json"

# Function to check if optimization is enabled in a settings file
function Test-MCPOptimization {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    try {
        $settings = Get-Content $Path -Raw | ConvertFrom-Json
        return $settings.env.CLAUDE_CODE_ENABLE_TOOL_SEARCH -eq "true"
    }
    catch {
        return $false
    }
}

# Function to enable optimization in a settings file
function Enable-MCPOptimization {
    param([string]$Path, [string]$Dir)
    
    # Create directory if needed
    if (-not (Test-Path $Dir)) {
        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        Write-Host "  Created: $Dir" -ForegroundColor DarkGray
    }
    
    # Load or create settings
    $settings = @{}
    if (Test-Path $Path) {
        try {
            $content = Get-Content $Path -Raw
            if ($content.Trim()) {
                $settings = $content | ConvertFrom-Json -AsHashtable
            }
        }
        catch {
            Write-Host "  Warning: Could not parse existing settings, creating new" -ForegroundColor Yellow
            $settings = @{}
        }
    }
    
    # Ensure env section exists
    if (-not $settings.ContainsKey("env")) {
        $settings["env"] = @{}
    }
    
    # Add the setting
    $settings["env"]["CLAUDE_CODE_ENABLE_TOOL_SEARCH"] = "true"
    
    # Write back
    $settings | ConvertTo-Json -Depth 10 | Out-File $Path -Encoding utf8
    
    return $true
}

# Check current status
Write-Host "  Checking current status..." -ForegroundColor White
Write-Host ""

$globalEnabled = Test-MCPOptimization $globalSettingsPath
$projectEnabled = Test-MCPOptimization $projectSettingsPath

Write-Host "  Global (~/.claude/settings.json):  " -NoNewline
if ($globalEnabled) {
    Write-Host "ENABLED" -ForegroundColor Green
} else {
    Write-Host "NOT ENABLED" -ForegroundColor Yellow
}

Write-Host "  Project (.claude/settings.json):   " -NoNewline
if ($projectEnabled) {
    Write-Host "ENABLED" -ForegroundColor Green
} else {
    Write-Host "NOT ENABLED" -ForegroundColor DarkGray
}

Write-Host ""

# If just checking, exit here
if ($Check) {
    if ($globalEnabled -or $projectEnabled) {
        Write-Host "  Status: MCP optimization is ACTIVE" -ForegroundColor Green
    } else {
        Write-Host "  Status: MCP optimization is NOT ACTIVE" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Run without -Check to enable:" -ForegroundColor White
        Write-Host "    .\enable-mcp-optimization.ps1         # Global (recommended)" -ForegroundColor DarkGray
        Write-Host "    .\enable-mcp-optimization.ps1 -Project # This project only" -ForegroundColor DarkGray
    }
    Write-Host ""
    exit 0
}

# Enable optimization
if ($Project) {
    # Project-level only
    if ($projectEnabled) {
        Write-Host "  Already enabled for this project." -ForegroundColor Green
    } else {
        Write-Host "  Enabling for current project..." -ForegroundColor White
        Enable-MCPOptimization -Path $projectSettingsPath -Dir $projectClaudeDir
        Write-Host "  [OK] Enabled at: $projectSettingsPath" -ForegroundColor Green
    }
} else {
    # Global (default)
    if ($globalEnabled) {
        Write-Host "  Already enabled globally." -ForegroundColor Green
    } else {
        Write-Host "  Enabling globally..." -ForegroundColor White
        Enable-MCPOptimization -Path $globalSettingsPath -Dir $globalClaudeDir
        Write-Host "  [OK] Enabled at: $globalSettingsPath" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "  DONE                                                                " -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  What this changes:" -ForegroundColor White
Write-Host "    - MCP tools load on-demand (not all at startup)" -ForegroundColor DarkGray
Write-Host "    - Saves 10-30% context window per MCP server" -ForegroundColor DarkGray
Write-Host "    - Claude searches for tools only when needed" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "    - Restart Claude Code for changes to take effect" -ForegroundColor DarkGray
Write-Host "    - Run 'claude' then '/context' to verify MCP tools show 'loaded on demand'" -ForegroundColor DarkGray
Write-Host ""
