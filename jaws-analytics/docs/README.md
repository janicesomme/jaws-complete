# JAWS Analytics Dashboard System

## What It Does

The JAWS Analytics Dashboard System automatically analyzes completed RALPH-JAWS builds and generates visual dashboards showing what was built, how it was built, and operational metrics. It transforms build artifacts into professional, client-ready reports and internal technical documentation.

### Key Features

- **Automated Build Analysis**: Reads PRD.md, progress.txt, ralph-state.json, and workflow files to extract metrics
- **AI-Powered Summaries**: Uses Claude API to generate executive and technical summaries
- **Visual Dashboards**: Interactive React-based dashboard with client and technical views
- **Historical Tracking**: Stores all build analytics in Supabase for portfolio tracking
- **Professional Reports**: Export dashboard as branded PDF for client deliverables
- **Portfolio Overview**: View all builds in one place with aggregate business metrics

### Business Value

- **Save Time**: Automates client deliverable creation (2-3 hours per project)
- **Justify Pricing**: Professional visualization of work delivered
- **Track Portfolio**: Business metrics across all builds (total workflows created, value delivered)
- **Enable Transfer**: Makes systems self-documenting for capability transfer

## Who Uses This

- **Janice (Consultant)**: Track portfolio, generate client deliverables, justify pricing
- **Clients**: Understand what was built and operational costs
- **Developers**: Technical deep-dive into build history and architecture

## Quick Start

### Prerequisites

1. **n8n** (v1.0+) - Workflow automation platform
2. **Supabase** - PostgreSQL database with RLS
3. **Claude API Key** - For AI-powered summaries
4. **Node.js** (v18+) - For dashboard and validation scripts
5. **npm** - Package manager

### 5-Minute Setup

```bash
# 1. Clone the repository
git clone <repo-url>
cd jaws-analytics

# 2. Set up Supabase database
# Run the SQL schema from supabase/schema.sql in your Supabase project
# See supabase/README.md for detailed instructions

# 3. Configure credentials in n8n
# - Add Supabase credential (service role key)
# - Add Claude API credential
# See docs/CREDENTIALS-SETUP.md for details

# 4. Import n8n workflows
# Import all workflows from workflows/ directory into n8n
# See workflows/README.md for import instructions

# 5. Install and run dashboard
cd dashboard
npm install
npm run dev
# Dashboard runs on http://localhost:5173
```

### First Analysis

```bash
# Analyze a completed RALPH-JAWS build
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d '{
    "build_path": "/path/to/completed/project",
    "project_name": "My Project",
    "client_name": "Client Name"
  }'

# View the dashboard
# Open http://localhost:5173 in your browser
```

## How It Works

### Data Flow

```
Build Artifacts → n8n Analytics → Supabase → Dashboard → PDF Export
     ↓               ↓              ↓           ↓          ↓
  PRD.md         Extract         Store      Visualize   Client
  progress.txt   Analyze         Track      Interact    Deliverable
  ralph-state    Summarize       Query      Toggle View
  workflows/     Generate        Report     Export
```

### Components

1. **Build Artifact Reader**: Reads all files from project directory
2. **Analyzers**: Extract metrics from PRD, state, workflows
3. **AI Generators**: Create summaries and architecture diagrams
4. **Supabase Storage**: Persist all analytics for historical tracking
5. **Dashboard**: Interactive visualization with client/technical views
6. **PDF Export**: Generate professional branded reports

### Analytics Pipeline

```
Webhook Trigger → Validate Input → Read Artifacts
    ↓
Analyze PRD → Analyze State → Analyze Workflows
    ↓
Estimate Tokens → Calculate Costs
    ↓
Generate AI Summary → Generate Architecture Diagram
    ↓
Create Dashboard Spec → Store in Supabase
    ↓
Return Results (200 or 207 Multi-Status)
```

## Common Use Cases

### For Consultants

**Track Portfolio Metrics**
- View all projects in one dashboard
- See total workflows created, tables designed, estimated value
- Filter and sort by date, client, complexity

**Generate Client Deliverables**
- Run analysis after project completion
- Toggle to client view (hides technical details)
- Export professional PDF with branding
- Include in final deliverable package

**Justify Pricing**
- Show estimated monthly operational costs
- Display token usage and API call estimates
- Demonstrate complexity (node counts, workflow relationships)

### For Clients

**Understand What Was Built**
- Executive summary in plain English
- Visual architecture diagram
- Workflow and table breakdown
- Cost projections for ongoing operations

**Operational Planning**
- Estimated tokens per run
- Monthly cost projections
- Scalability considerations

### For Developers

**Technical Deep-Dive**
- Iteration-by-iteration build history
- Checkpoint triggers and rabbit hole detection
- Node-by-node workflow breakdown
- Failed task analysis with retry tracking
- AGENTS.md learnings captured

**System Maintenance**
- Architecture diagrams for onboarding
- Complete workflow documentation
- Database schema visualization
- Token usage optimization opportunities

## Dashboard Views

### Client View

**What Clients See:**
- Executive summary (business value, ROI talking points)
- High-level stats (workflows, tables, completion rate)
- Simplified architecture diagram
- Cost projections (monthly operational estimates)
- Value proposition

**What's Hidden:**
- Iteration failures and retries
- Node-level workflow breakdowns
- Technical debt indicators
- AGENTS.md learnings

### Technical View

**Additional Information:**
- Technical summary (implementation details)
- Iteration history with failure tracking
- Node-by-node workflow breakdown
- Checkpoint triggers and rabbit holes
- Retry patterns and resilience
- AGENTS.md patterns captured

## PDF Export

Generated PDFs include:

1. **Cover Page**: Project name, client, date, Janice's branding
2. **Executive Summary**: High-level overview for stakeholders
3. **Key Metrics**: Stats cards (workflows, tables, costs, completion)
4. **Architecture**: System diagram with explanations
5. **Workflow Breakdown**: Table of all workflows with details
6. **Cost Projections**: Token usage and monthly estimates
7. **Timeline**: Build progression and checkpoint summary

**File Naming**: `[project-name]-analytics.pdf`

## System Architecture

### Technology Stack

- **Analytics Engine**: n8n workflows (19 workflows total)
- **Database**: Supabase (PostgreSQL + RLS)
- **AI**: Claude API (claude-sonnet-4-20250514)
- **Dashboard**: React + Vite + Tailwind CSS + Recharts
- **Export**: jsPDF for PDF generation

### Database Schema

**jaws_builds** - Main build records
- Project metadata (name, client, dates)
- Iteration metrics (used, max, duration)
- Task counts (completed, failed, skipped)
- High-level counts (workflows, tables)
- Cost estimates (tokens, monthly)
- Build quality (checkpoints, rabbit holes)
- Summaries and specs (JSONB)

**jaws_workflows** - Workflow details
- Workflow metadata (name, type, trigger)
- Node counts (total, Claude, Supabase)
- Token estimates
- Purpose and breakdown (JSONB)

**jaws_tables** - Database table details
- Table metadata (name, columns, RLS)
- Row counts
- Purpose

See `supabase/schema.sql` for complete schema.

### Workflow Organization

**Main Orchestrator**:
- `analytics-orchestrator.json` - Coordinates all sub-workflows

**Core Analyzers**:
- `build-artifact-reader.json` - Reads project files
- `prd-analyzer.json` - Extracts PRD metrics
- `state-analyzer.json` - Analyzes ralph-state.json
- `workflow-analyzer.json` - Analyzes n8n workflows
- `token-estimator.json` - Estimates API costs

**AI Generators**:
- `ai-summary-generator.json` - Creates summaries
- `architecture-diagram-generator.json` - Generates Mermaid diagrams

**Output**:
- `dashboard-spec-generator.json` - Compiles dashboard JSON
- `supabase-storage.json` - Persists to database

**Test Wrappers**:
- `*-test.json` - Webhook wrappers for standalone testing

See `workflows/README.md` for detailed workflow documentation.

## Key Concepts

### Build Artifacts

Files read from completed RALPH-JAWS projects:

**Required**:
- `PRD.md` - Project requirements with acceptance criteria
- `progress.txt` - Iteration history and task completion
- `ralph-state.json` - State machine data

**Optional**:
- `workflows/*.json` - n8n workflow definitions
- `AGENTS.md` - Learnings and patterns captured

### Analysis Levels

**Level 1 - Syntax**: Files exist, JSON is valid, structure correct
**Level 2 - Unit**: Individual analyzers work correctly
**Level 3 - Integration**: Full pipeline runs end-to-end

### Multi-Status Response

HTTP 207 indicates partial success:
- Some sub-workflows succeeded
- Some sub-workflows failed
- Dashboard displays available data
- Errors array shows what failed

**Status Codes**:
- 200: All steps succeeded
- 207: Partial success (some failures)
- 400: Input validation failed
- 500: Orchestrator failure

### Token Estimation

Estimates Claude API usage:
- Counts characters in prompts (~4 chars = 1 token)
- Adds dynamic content estimate (default 200 tokens)
- Includes max_tokens from response
- Calculates cost using Claude pricing

**Pricing** (as of 2025):
- Input: $3/million tokens
- Output: $15/million tokens

## Configuration

### Environment Variables

Create `.env` file in project root:

```bash
# Supabase
SUPABASE_URL=https://[project-ref].supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
SUPABASE_ANON_KEY=eyJ...

# Claude API
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-sonnet-4-20250514

# n8n (optional, if not running locally)
N8N_URL=http://localhost:5678

# File Paths (optional)
PROJECTS_BASE_PATH=/path/to/projects
```

See `docs/CREDENTIALS-SETUP.md` for detailed credential configuration.

### n8n Credentials

Configure in n8n UI (Settings → Credentials):

1. **Supabase API**
   - Host: Your Supabase URL
   - Service Role Key: (NOT anon key)

2. **Claude API**
   - Header: x-api-key
   - Value: Your Anthropic API key

3. **File System**
   - Built-in n8n file access
   - Mount volumes if using Docker

## Maintenance

### Updating Workflows

```bash
# Export updated workflow from n8n
# Save to workflows/ directory
# Update version number in workflow name
# Document changes in workflows/README.md
```

### Database Migrations

```bash
# Create new migration file
# Run SQL in Supabase SQL Editor
# Update supabase/schema.sql with changes
# Document in supabase/CHANGELOG.md (if exists)
```

### Adding New Metrics

1. Update database schema (add columns to jaws_builds)
2. Update analyzer workflows to extract new metrics
3. Update dashboard-spec-generator to include in output
4. Update dashboard components to display new metrics
5. Update PDF export to include in reports

## Troubleshooting

### Common Issues

**Problem**: Webhook returns 404
**Solution**:
- Verify workflow is active (n8n UI)
- Restart n8n server to register webhooks
- Check webhook path matches exactly

**Problem**: "Insufficient privileges" error in Supabase
**Solution**:
- Verify using service_role key (not anon key)
- Check RLS policies include service_role access
- See supabase/README.md for policy examples

**Problem**: Claude API rate limit exceeded
**Solution**:
- Reduce analysis frequency
- Add retry logic with exponential backoff
- Consider batching analyses

**Problem**: Dashboard shows no data
**Solution**:
- Check Supabase connection (anon key for dashboard)
- Verify data exists in jaws_builds table
- Check browser console for errors
- Ensure CORS is configured in Supabase

**Problem**: PDF export fails
**Solution**:
- Check browser console for errors
- Verify all required data fields present
- Try with smaller dataset first
- Check jsPDF version compatibility

### Validation

**Test the full pipeline**:
```bash
# Run syntax validation
node -e "JSON.parse(require('fs').readFileSync('workflows/analytics-orchestrator.json', 'utf8')); console.log('Valid')"

# Test individual analyzers
curl -X POST http://localhost:5678/webhook-test/analyze-prd -d @test-data.json

# Run end-to-end test
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d '{
    "build_path": "./test-project",
    "project_name": "Test",
    "client_name": "Internal"
  }'
```

### Getting Help

- Check `docs/TECHNICAL.md` for workflow details
- Check `docs/SETUP.md` for installation issues
- Check `supabase/README.md` for database issues
- Check `workflows/README.md` for workflow-specific docs
- Review AGENTS.md for patterns and gotchas

## FAQ

**Q: Can I analyze non-n8n projects?**
A: Yes, but workflow analysis will be skipped. PRD and state analysis still work.

**Q: How much does this cost to run?**
A: Depends on Claude API usage. Typical analysis: ~5,000-10,000 tokens ($0.05-$0.15 per project).

**Q: Can I customize the PDF branding?**
A: Yes, edit `dashboard/src/utils/pdfExport.js` to change logo, colors, footer.

**Q: Does this work with RALPH v2 or older?**
A: Designed for RALPH-JAWS v3 format. Older versions may need schema adjustments.

**Q: Can I host the dashboard publicly?**
A: Yes, but secure your Supabase RLS policies and use anon key (read-only).

**Q: How do I backup my analytics data?**
A: Use Supabase dashboard to export tables, or use pg_dump for PostgreSQL backups.

## What's Next

### Planned Enhancements (Phase 2)

- Real-time monitoring of running workflows
- Actual token tracking from Anthropic billing
- Multi-user authentication and access control
- Mobile app version
- Integration with external project management tools
- Automated re-analysis on PRD changes
- Comparison view for multiple builds

### Contributing

This is an internal tool for Janice's AI Automation Consulting. Patterns and learnings should be documented in `AGENTS.md` for future use.

## License

Internal tool - All rights reserved.

---

**Generated by**: RALPH (Resilient Autonomous Loop with Human-in-the-loop)
**For**: Janice's AI Automation Consulting
**Last Updated**: 2025-01-15
