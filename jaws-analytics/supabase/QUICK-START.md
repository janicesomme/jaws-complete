# Quick Start - JAWS Analytics Database

## 3-Minute Setup

### Step 1: Create Supabase Project (1 min)
1. Go to https://supabase.com/dashboard
2. Click "New Project"
3. Choose organization, name: `jaws-analytics`
4. Set a database password (save it!)
5. Choose region closest to you
6. Click "Create Project" and wait ~2 minutes

### Step 2: Apply Schema (1 min)
1. In Supabase dashboard, click **SQL Editor** (left sidebar)
2. Click **New Query**
3. Open `schema.sql` in this folder
4. Copy ALL contents (Ctrl+A, Ctrl+C)
5. Paste into SQL Editor
6. Click **Run** (or Ctrl+Enter)
7. Should see: "Success. No rows returned"

### Step 3: Verify (30 seconds)
Copy and run this in SQL Editor:
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('jaws_builds', 'jaws_workflows', 'jaws_tables');
```

Should return 3 rows. ✅ Done!

### Step 4: Get Credentials (30 seconds)
1. Go to **Settings** → **API** (left sidebar)
2. Copy these two values:

**Project URL:**
```
https://[your-project-ref].supabase.co
```

**Service Role Key:** (for n8n - keep secret!)
```
eyJ[...very long string...]
```

**Anon Key:** (for dashboard - public-safe)
```
eyJ[...different long string...]
```

Save these! You'll need them for US-002.

---

## What You Just Built

Three tables to store analytics:

```
jaws_builds (main)
  ├── jaws_workflows (1-to-many)
  └── jaws_tables (1-to-many)
```

**jaws_builds**: Project-level metrics (iterations, tasks, costs)
**jaws_workflows**: Each n8n workflow details
**jaws_tables**: Each Supabase table created

**Security**: RLS enabled, service_role can write, public can read.

---

## Next: Test It

Run queries from `validation-queries.sql` to test everything works.

**Quick test:** Insert a sample build:
```sql
INSERT INTO jaws_builds (project_name, client_name, iterations_used)
VALUES ('Test Build', 'Test Client', 5)
RETURNING id, project_name, created_at;
```

Should return a UUID and timestamp. Then delete:
```sql
DELETE FROM jaws_builds WHERE project_name = 'Test Build';
```

---

## Troubleshooting

**"Success. No rows returned" after running schema.sql?**
✅ That's correct! It means schema was created.

**Tables don't show up?**
- Refresh the page
- Check for errors in SQL Editor output
- Verify you're in the correct project

**Need to start over?**
Run this first, then re-run schema.sql:
```sql
DROP TABLE IF EXISTS jaws_tables CASCADE;
DROP TABLE IF EXISTS jaws_workflows CASCADE;
DROP TABLE IF EXISTS jaws_builds CASCADE;
```

---

## Files in This Folder

- **schema.sql** - Run this once to create everything
- **validation-queries.sql** - Run these to test (optional but recommended)
- **README.md** - Full documentation with examples
- **QUICK-START.md** - This file

---

**Status:** Ready for US-002 (Configure n8n credentials)
