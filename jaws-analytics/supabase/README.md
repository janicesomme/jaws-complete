# JAWS Analytics - Supabase Schema

This directory contains the database schema for the JAWS Analytics system.

## Files

- **schema.sql** - Complete database schema with tables, indexes, RLS policies
- **validation-queries.sql** - Test queries to verify schema is working correctly

## Quick Setup

### 1. Create Supabase Project

1. Go to https://supabase.com
2. Create a new project
3. Wait for the project to finish provisioning
4. Note your project URL: `https://[project-ref].supabase.co`

### 2. Apply Schema

Option A: Using Supabase Dashboard (Recommended)
1. Open your Supabase project
2. Go to **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy the entire contents of `schema.sql`
5. Paste into the query editor
6. Click **Run** (or press Ctrl/Cmd + Enter)
7. Verify "Success. No rows returned" message

Option B: Using Supabase CLI
```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link to your project
supabase link --project-ref [your-project-ref]

# Apply schema
supabase db push

# Or run the SQL file directly
psql "postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres" -f schema.sql
```

### 3. Verify Installation

Run the queries from `validation-queries.sql` in the SQL Editor:

**Quick verification:**
```sql
-- Should return 3 tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('jaws_builds', 'jaws_workflows', 'jaws_tables');

-- Should return all 't' (RLS enabled)
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' AND tablename LIKE 'jaws_%';
```

### 4. Get Your Credentials

You'll need these for n8n configuration (US-002):

1. Go to **Project Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://[project-ref].supabase.co`
   - **anon/public key**: Starts with `eyJ...` (for dashboard read access)
   - **service_role key**: Starts with `eyJ...` (for n8n write access)

⚠️ **CRITICAL**: Use the **service_role** key in n8n, NOT the anon key!

## Schema Overview

### Tables

#### jaws_builds
Main table storing high-level build metrics:
- Project identification (name, client, date)
- Iteration metrics (used, max, duration)
- Task completion stats (total, completed, skipped, failed)
- Output counts (workflows, tables created)
- Token/cost estimates
- AI-generated summaries and specs

#### jaws_workflows
Detailed metrics for each n8n workflow:
- Links to parent build (build_id FK)
- Workflow type (orchestrator/sub-workflow/standalone)
- Trigger type (webhook/schedule/manual/execute)
- Node counts (total, Claude, Supabase)
- Token estimates
- Node breakdown (JSONB)

#### jaws_tables
Metrics for each Supabase table:
- Links to parent build (build_id FK)
- Table structure (column count, RLS status)
- Data metrics (row count)
- Purpose description

### Relationships

```
jaws_builds (1) ──< (many) jaws_workflows
            (1) ──< (many) jaws_tables
```

Foreign keys use `ON DELETE CASCADE` - deleting a build removes all related workflows and tables.

### Security (RLS)

**Enabled on all tables** with two policy types:

1. **Service Role Full Access** - Allows n8n to insert/update/delete
   - Used by analytics workflows
   - Requires service_role key

2. **Public Read Access** - Allows dashboard to view data
   - Used by React dashboard
   - Requires anon or authenticated user

## Testing

Run the full test suite from `validation-queries.sql`:

### Level 1: Syntax Validation
- Verify tables exist
- Check column counts
- Confirm RLS enabled
- Verify indexes
- Check foreign keys

### Level 2: Unit Tests
- Test insert operations
- Test update operations
- Test cascade deletes
- Test joins
- Test JSONB columns
- Test triggers

### Level 3: RLS Policy Tests
- Verify service_role policies
- Verify public read policies

### Level 4: Data Integrity Tests
- Test CHECK constraints
- Test NOT NULL constraints
- Test foreign key constraints

## Common Issues

### Issue: RLS blocks inserts from n8n

**Cause**: Using anon key instead of service_role key

**Fix**:
1. Go to Supabase Dashboard → Settings → API
2. Copy the **service_role** key (NOT the anon key)
3. Update n8n credentials with service_role key

### Issue: Foreign key constraint violation

**Cause**: Trying to insert workflow/table with non-existent build_id

**Fix**: Always insert into jaws_builds first, then use the returned UUID for workflows/tables

### Issue: Tables don't appear after running schema.sql

**Cause**: SQL execution failed silently

**Fix**:
1. Check for error messages in SQL Editor
2. Verify you have the correct permissions
3. Try dropping and recreating: Run the DROP statements at the top of schema.sql first

### Issue: Can't see data in dashboard

**Cause**: Public read policies not working

**Fix**: Verify policies exist:
```sql
SELECT policyname, tablename FROM pg_policies
WHERE schemaname = 'public' AND tablename LIKE 'jaws_%';
```

## Maintenance

### View Current Data
```sql
SELECT
  COUNT(*) as builds,
  SUM(workflows_created) as total_workflows,
  SUM(tables_created) as total_tables
FROM jaws_builds;
```

### Delete Old Test Data
```sql
DELETE FROM jaws_builds
WHERE project_name LIKE 'Test%'
AND created_at < now() - interval '7 days';
```

### Backup Schema
```bash
# Using Supabase CLI
supabase db dump -f backup.sql

# Or using pg_dump
pg_dump "postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres" \
  --schema-only \
  --table=jaws_builds \
  --table=jaws_workflows \
  --table=jaws_tables \
  > backup-schema.sql
```

## Next Steps

After setting up the schema:

1. ✅ Complete US-001 acceptance criteria
2. → Proceed to **US-002**: Configure n8n credentials
3. → Update AGENTS.md with Supabase connection pattern

## Acceptance Criteria Checklist

From PRD.md US-001:

- [x] Table `jaws_builds` with all required columns
- [x] Table `jaws_workflows` with all required columns
- [x] Table `jaws_tables` with all required columns
- [x] RLS enabled on all tables
- [x] Service role policy for n8n access
- [x] Indexes on build_id foreign keys

Run validation-queries.sql to verify all criteria are met!
