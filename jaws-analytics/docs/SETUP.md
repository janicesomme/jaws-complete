# JAWS Analytics - Installation and Configuration Guide

## Prerequisites

Before starting, ensure you have:

- **n8n** (v1.0 or later)
- **Supabase account** (free tier works)
- **Claude API key** from Anthropic
- **Node.js** (v18 or later)
- **npm** (v9 or later)
- **Git** (for cloning repository)

## Installation Overview

```
1. Set up Supabase database (15 min)
2. Configure n8n credentials (10 min)
3. Import n8n workflows (10 min)
4. Install dashboard (5 min)
5. Test the system (5 min)

Total: ~45 minutes
```

---

## Step 1: Supabase Database Setup

### 1.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign in or create account
3. Click "New Project"
4. Fill in:
   - **Name**: `jaws-analytics` (or your choice)
   - **Database Password**: (save this securely)
   - **Region**: Choose closest to you
5. Wait for project to provision (~2 minutes)

### 1.2 Run Database Schema

1. In Supabase dashboard, click **SQL Editor** (left sidebar)
2. Click **New Query**
3. Open `supabase/schema.sql` from this repository
4. Copy the entire contents
5. Paste into Supabase SQL Editor
6. Click **Run** (bottom right)
7. Verify success: "Success. No rows returned."

### 1.3 Verify Tables Created

1. Click **Table Editor** (left sidebar)
2. You should see 3 tables:
   - `jaws_builds`
   - `jaws_workflows`
   - `jaws_tables`
3. Click each table to verify columns exist

### 1.4 Get API Keys

1. Click **Project Settings** (gear icon, left sidebar)
2. Click **API** (left menu)
3. Copy and save:
   - **Project URL** (e.g., `https://abcdefgh.supabase.co`)
   - **anon public** key (for dashboard, read-only)
   - **service_role** key (for n8n, full access)

**IMPORTANT**: Keep service_role key secret! Never commit to git.

### 1.5 Test Database Connection

```bash
# Replace with your actual values
export SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="eyJ..."

# Test connection
curl -X GET "$SUPABASE_URL/rest/v1/jaws_builds?limit=1" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"

# Expected: [] (empty array, means table exists)
# Error 401: Wrong API key
# Error 404: Table doesn't exist (re-run schema.sql)
```

---

## Step 2: n8n Setup

### 2.1 Install n8n (if not already installed)

**Option A: npm (recommended for local development)**:
```bash
npm install -g n8n
n8n start
```

**Option B: Docker**:
```bash
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

**Option C: n8n Cloud**:
- Go to [n8n.cloud](https://n8n.cloud)
- Sign up for account
- Create new instance

### 2.2 Access n8n

1. Open browser to `http://localhost:5678` (or your n8n cloud URL)
2. Create account/login
3. You should see n8n dashboard

### 2.3 Configure Supabase Credential

1. Click **Settings** (left sidebar)
2. Click **Credentials**
3. Click **Add Credential**
4. Search for "HTTP Header Auth" (or "Supabase" if available)
5. Fill in:
   - **Name**: `JAWS Analytics Supabase`
   - **Header Name**: `Authorization`
   - **Header Value**: `Bearer YOUR_SERVICE_ROLE_KEY`
6. Click **Create**

**Alternative (using Generic HTTP)**:
- Add another header: `apikey: YOUR_SERVICE_ROLE_KEY`

### 2.4 Configure Claude API Credential

1. Get Claude API key from [console.anthropic.com](https://console.anthropic.com)
2. In n8n, click **Settings** → **Credentials**
3. Click **Add Credential**
4. Search for "HTTP Header Auth"
5. Fill in:
   - **Name**: `Claude API - JAWS Analytics`
   - **Header Name**: `x-api-key`
   - **Header Value**: `sk-ant-YOUR_API_KEY`
6. Click **Create**

### 2.5 Test Credentials

**Test Supabase**:
1. Create new workflow
2. Add **HTTP Request** node
3. Configure:
   - Method: GET
   - URL: `https://YOUR_PROJECT.supabase.co/rest/v1/jaws_builds?limit=1`
   - Authentication: Select your Supabase credential
4. Execute node
5. Should return empty array `[]`

**Test Claude**:
1. Add **HTTP Request** node
2. Configure:
   - Method: POST
   - URL: `https://api.anthropic.com/v1/messages`
   - Authentication: Select your Claude credential
   - Headers: Add `anthropic-version: 2023-06-01`
   - Body JSON:
     ```json
     {
       "model": "claude-sonnet-4-20250514",
       "max_tokens": 50,
       "messages": [{"role": "user", "content": "Test"}]
     }
     ```
3. Execute node
4. Should return Claude response

---

## Step 3: Import n8n Workflows

### 3.1 Import Main Orchestrator

1. In n8n, click **Workflows** (left sidebar)
2. Click **Add Workflow** → **Import**
3. Click **Select File**
4. Navigate to `workflows/analytics-orchestrator.json`
5. Click **Import**
6. Workflow appears in editor

### 3.2 Import All Sub-Workflows

Repeat import process for each workflow:

**Core Workflows** (import in this order):
1. `build-artifact-reader.json`
2. `prd-analyzer.json`
3. `state-analyzer.json`
4. `workflow-analyzer.json`
5. `token-estimator.json`
6. `ai-summary-generator.json`
7. `architecture-diagram-generator.json`
8. `dashboard-spec-generator.json`
9. `supabase-storage.json`

**Test Wrappers** (optional, for testing):
1. `prd-analyzer-test.json`
2. `workflow-analyzer-test.json`
3. `token-estimator-test.json`
4. `state-analyzer-test.json`
5. `ai-summary-generator-test.json`
6. `architecture-diagram-generator-test.json`
7. `dashboard-spec-generator-test.json`
8. `supabase-storage-test.json`

### 3.3 Activate Workflows

For each imported workflow:
1. Open workflow in editor
2. Click **Active** toggle (top right) to turn it ON
3. Click **Save**

**CRITICAL**: After activating workflows with webhooks, **restart n8n**:
```bash
# Stop n8n (Ctrl+C)
# Start n8n
n8n start
```

Webhooks only register on startup!

### 3.4 Verify Webhooks

```bash
# Test main orchestrator webhook
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d '{"build_path": "/invalid/path"}'

# Expected: 400 error (input validation)
# NOT Expected: 404 (means webhook not registered)
```

If you get 404:
- Verify workflow is active
- Restart n8n
- Check webhook path in workflow matches

---

## Step 4: Dashboard Installation

### 4.1 Install Dependencies

```bash
cd dashboard
npm install
```

This installs:
- React
- Vite
- Tailwind CSS
- Recharts
- Supabase JS Client
- jsPDF
- Lucide React icons

### 4.2 Configure Environment

Create `dashboard/.env.local`:

```bash
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

**IMPORTANT**: Use **anon** key for dashboard (not service_role)!

### 4.3 Start Development Server

```bash
npm run dev
```

Dashboard runs on `http://localhost:5173`

### 4.4 Verify Dashboard

1. Open `http://localhost:5173` in browser
2. Should see "All Projects Overview" page
3. Should be empty (no projects analyzed yet)
4. No errors in browser console

---

## Step 5: Test the System

### 5.1 Prepare Test Data

Use this repository itself as test data:

```bash
# This project has all required files
/path/to/jaws-analytics/
├── PRD.md ✓
├── progress.txt ✓
├── ralph-state.json ✓
├── AGENTS.md ✓
└── workflows/ ✓
```

### 5.2 Run Analysis

**Replace `/path/to/jaws-analytics` with actual path**:

```bash
curl -X POST http://localhost:5678/webhook/analyze-build \
  -H "Content-Type: application/json" \
  -d '{
    "build_path": "C:/Users/crm22/jaws-analytics",
    "project_name": "JAWS Analytics Dashboard",
    "client_name": "Internal"
  }'
```

**Expected Response** (200 or 207):
```json
{
  "status": 200,
  "result": "success",
  "summary": {
    "steps_total": 9,
    "steps_succeeded": 9,
    "steps_failed": 0
  }
}
```

If 207 (partial success):
- Check `errors` array to see what failed
- Common issue: Claude API key invalid/rate limited
- System still works with partial data

### 5.3 View Results in Dashboard

1. Refresh dashboard in browser
2. Should see project card: "JAWS Analytics Dashboard"
3. Click on project
4. View the generated dashboard:
   - Stats cards
   - Workflow breakdown
   - Architecture diagram
   - Build timeline
5. Toggle between Client and Technical views
6. Test PDF export

### 5.4 Verify Database

```bash
# Check data was inserted
curl -X GET "$SUPABASE_URL/rest/v1/jaws_builds?select=project_name,workflows_created,created_at" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"

# Expected: Array with your project
[
  {
    "project_name": "JAWS Analytics Dashboard",
    "workflows_created": 19,
    "created_at": "2025-01-15T..."
  }
]
```

---

## Configuration Reference

### Environment Variables

**Project Root `.env`** (optional):
```bash
# Supabase
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
SUPABASE_ANON_KEY=eyJ...

# Claude API
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-sonnet-4-20250514

# n8n
N8N_URL=http://localhost:5678

# Paths
PROJECTS_BASE_PATH=/path/to/projects
```

**Dashboard `.env.local`** (required):
```bash
VITE_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

### n8n Credentials Configuration

**Supabase Credential**:
- Type: HTTP Header Auth
- Name: `JAWS Analytics Supabase`
- Authentication Method: Generic Credential
- Headers:
  - `Authorization: Bearer SERVICE_ROLE_KEY`
  - `apikey: SERVICE_ROLE_KEY`

**Claude API Credential**:
- Type: HTTP Header Auth
- Name: `Claude API - JAWS Analytics`
- Authentication Method: Generic Credential
- Headers:
  - `x-api-key: YOUR_API_KEY`
  - `anthropic-version: 2023-06-01`

---

## Troubleshooting

### Issue: Workflow import fails with "SQLITE_CONSTRAINT"

**Cause**: Workflow JSON missing `"active"` field

**Solution**: Add to workflow JSON before import:
```json
{
  "name": "Workflow Name",
  "active": false,
  "nodes": [...]
}
```

### Issue: Webhook returns 404

**Cause**: n8n hasn't registered webhook routes

**Solution**:
1. Verify workflow is active (toggle ON)
2. Restart n8n server
3. Wait 10 seconds for startup
4. Test webhook again

### Issue: Supabase "insufficient privileges"

**Cause**: Using anon key instead of service_role key in n8n

**Solution**:
1. Verify n8n credential uses service_role key
2. Check RLS policies include service_role access:
   ```sql
   CREATE POLICY "service_role_all"
     ON jaws_builds FOR ALL TO service_role
     USING (true) WITH CHECK (true);
   ```

### Issue: Dashboard shows no data

**Causes**:
1. Wrong Supabase URL/key in `.env.local`
2. No data in database yet
3. CORS not configured

**Solutions**:
1. Check environment variables match Supabase project
2. Run analysis first (Step 5.2)
3. Verify CORS settings in Supabase (usually auto-configured)

### Issue: Claude API rate limit

**Cause**: Too many requests in short time

**Solution**:
1. Wait 60 seconds and retry
2. Reduce analysis frequency
3. Upgrade Claude API plan
4. Add retry logic with exponential backoff (already in workflows)

### Issue: PDF export fails

**Causes**:
1. Missing data in dashboard spec
2. Browser compatibility (older browsers)
3. jsPDF version mismatch

**Solutions**:
1. Verify all data fields present in project
2. Use modern browser (Chrome, Firefox, Edge)
3. Check browser console for specific error
4. Reinstall dashboard dependencies: `npm install`

### Issue: File not found during analysis

**Cause**: Incorrect build_path or file permissions

**Solution**:
1. Verify path is absolute (not relative)
2. Check path uses correct slashes:
   - Windows: `C:/Users/...` or `C:\\Users\\...`
   - Unix: `/home/user/...`
3. Verify files exist: `ls /path/to/project`
4. Check n8n has read permissions

### Issue: Mermaid diagram not rendering

**Cause**: Invalid Mermaid syntax from Claude

**Solution**:
1. Check browser console for Mermaid errors
2. Copy diagram code to [mermaid.live](https://mermaid.live) to validate
3. If invalid, re-run analysis (Claude may generate better syntax)
4. Fallback: Shows text description if diagram fails

---

## Advanced Configuration

### Custom File Paths

If using Docker n8n, mount volumes:

```yaml
# docker-compose.yml
version: '3'
services:
  n8n:
    image: n8nio/n8n
    ports:
      - 5678:5678
    volumes:
      - ~/.n8n:/home/node/.n8n
      - /path/to/projects:/data/projects  # Add this
```

Then use paths like `/data/projects/project-name` in analysis requests.

### Multiple Environments

**Development**:
```bash
# .env.development
VITE_SUPABASE_URL=https://dev-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

**Production**:
```bash
# .env.production
VITE_SUPABASE_URL=https://prod-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

Build for production:
```bash
npm run build -- --mode production
```

### n8n Cloud Configuration

1. Same credential setup in cloud UI
2. Webhook URLs change to: `https://YOUR_INSTANCE.app.n8n.cloud/webhook/analyze-build`
3. Update API calls to use cloud URL
4. File access requires alternative (git repo, HTTP endpoint, S3, etc.)

### Supabase Edge Functions (Optional)

Instead of n8n, deploy analyzers as Supabase Edge Functions:

```bash
# Install Supabase CLI
npm install -g supabase

# Deploy function
supabase functions deploy analyze-build
```

Update dashboard to call Edge Function instead of n8n webhook.

---

## Production Deployment

### n8n Production

**Option 1: VPS/Server**:
```bash
# Install as systemd service
npm install -g n8n pm2
pm2 start n8n --name "n8n-jaws-analytics"
pm2 save
pm2 startup
```

**Option 2: Docker**:
```bash
docker run -d \
  --name n8n \
  --restart always \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n
```

**Option 3: n8n Cloud**:
- Already production-ready
- No server management
- Costs apply

### Dashboard Production

**Netlify**:
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Build
cd dashboard
npm run build

# Deploy
netlify deploy --prod --dir=dist
```

**Vercel**:
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd dashboard
vercel --prod
```

**Static Host** (S3, Cloudflare Pages, etc.):
```bash
npm run build
# Upload dist/ folder to hosting
```

### Environment Variables in Production

**Netlify/Vercel**:
1. Go to project settings
2. Add environment variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
3. Redeploy

**Docker**:
```bash
docker run -d \
  -e VITE_SUPABASE_URL="https://..." \
  -e VITE_SUPABASE_ANON_KEY="eyJ..." \
  your-dashboard-image
```

### SSL/HTTPS

**n8n**:
- Use reverse proxy (nginx, Caddy)
- Or use n8n Cloud (HTTPS included)

**Dashboard**:
- Netlify/Vercel: HTTPS automatic
- Custom host: Use Let's Encrypt or Cloudflare

---

## Backup and Recovery

### Database Backup

**Manual Export**:
1. Supabase Dashboard → Table Editor
2. Select table → Export as CSV
3. Repeat for all tables

**PostgreSQL Dump**:
```bash
# Get connection string from Supabase project settings
pg_dump "postgresql://postgres:password@db.abcdefgh.supabase.co:5432/postgres" \
  --schema=public \
  --table=jaws_builds \
  --table=jaws_workflows \
  --table=jaws_tables \
  > backup.sql
```

**Restore**:
```bash
psql "postgresql://..." < backup.sql
```

### Workflow Backup

Workflows are in `workflows/` directory:
```bash
# Backup
cp -r workflows workflows-backup-2025-01-15

# Or export from n8n UI
# Workflows → Select Workflow → Export
```

### Dashboard Backup

Code is in git repository:
```bash
git add .
git commit -m "Backup dashboard"
git push
```

---

## Upgrading

### Update n8n

```bash
npm update -g n8n
# or
docker pull n8nio/n8n
```

### Update Dashboard

```bash
cd dashboard
npm update
npm run build
```

### Update Database Schema

1. Create migration SQL file
2. Test on development database
3. Run on production:
   ```sql
   -- Add new column
   ALTER TABLE jaws_builds ADD COLUMN new_field TEXT;

   -- Create index
   CREATE INDEX idx_new_field ON jaws_builds(new_field);
   ```
4. Update `supabase/schema.sql` with changes

### Update Workflows

1. Make changes in n8n UI
2. Export updated workflow
3. Save to `workflows/` directory
4. Update version number in workflow name
5. Document in `workflows/README.md`

---

## Next Steps

After successful setup:

1. **Analyze Your First Project**:
   - Use completed RALPH-JAWS build
   - Run analysis webhook
   - Review dashboard

2. **Customize PDF Branding**:
   - Edit `dashboard/src/utils/pdfExport.js`
   - Update logo, colors, footer

3. **Set Up Auto-Trigger**:
   - Add webhook call to RALPH completion script
   - See US-022 in PRD.md

4. **Explore AGENTS.md**:
   - Learn patterns from this project
   - Apply to future builds

5. **Read Documentation**:
   - `docs/README.md` - Usage guide
   - `docs/TECHNICAL.md` - Architecture details
   - `workflows/README.md` - Workflow details

---

**Setup Complete!** 🎉

You now have a fully functional analytics system. Run your first analysis and view the dashboard.

**Need Help?**
- Check `docs/README.md` FAQ section
- Review `docs/TECHNICAL.md` for deep-dive
- Check Supabase logs for database issues
- Check n8n execution history for workflow errors

---

**Last Updated**: 2025-01-15
**Maintained By**: RALPH
**For**: Janice's AI Automation Consulting
