-- ============================================================================
-- JAWS Analytics - Validation Queries
-- ============================================================================
-- Purpose: Test and verify the database schema is working correctly
-- Run these queries after applying schema.sql
-- ============================================================================

-- ============================================================================
-- LEVEL 1: SYNTAX VALIDATION
-- ============================================================================
-- Verify tables exist with correct structure
-- ============================================================================

-- 1. Verify all three tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('jaws_builds', 'jaws_workflows', 'jaws_tables')
ORDER BY table_name;
-- Expected: 3 rows (jaws_builds, jaws_tables, jaws_workflows)

-- 2. Verify column counts
SELECT
  table_name,
  COUNT(*) as column_count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('jaws_builds', 'jaws_workflows', 'jaws_tables')
GROUP BY table_name
ORDER BY table_name;
-- Expected: jaws_builds (23+), jaws_workflows (11+), jaws_tables (8+)

-- 3. Verify RLS is enabled on all tables
SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE 'jaws_%'
ORDER BY tablename;
-- Expected: All should show 't' (true) for rls_enabled

-- 4. Verify indexes exist
SELECT
  indexname,
  tablename
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename LIKE 'jaws_%'
ORDER BY tablename, indexname;
-- Expected: At least 5 indexes (2 FK + 3 additional)

-- 5. Verify foreign key constraints
SELECT
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
  AND tc.table_name LIKE 'jaws_%'
  AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name;
-- Expected: 2 foreign keys (jaws_workflows.build_id, jaws_tables.build_id)

-- ============================================================================
-- LEVEL 2: UNIT TESTS
-- ============================================================================
-- Test insert, update, and query operations
-- ============================================================================

-- TEST 1: Insert a test build
INSERT INTO jaws_builds (
  project_name,
  client_name,
  build_date,
  iterations_used,
  iterations_max,
  tasks_total,
  tasks_completed,
  tasks_skipped,
  tasks_failed,
  workflows_created,
  tables_created,
  estimated_tokens_per_run,
  estimated_monthly_cost,
  build_duration_minutes
)
VALUES (
  'Test Project - Validation',
  'Test Client',
  now(),
  10,
  50,
  15,
  12,
  2,
  1,
  3,
  2,
  5000,
  75.00,
  45
)
RETURNING
  id,
  project_name,
  client_name,
  iterations_used,
  workflows_created,
  created_at;
-- Expected: Returns 1 row with generated UUID and data

-- TEST 2: Insert test workflows (replace build_id with UUID from TEST 1)
-- Save the build_id from TEST 1 result, then run:
WITH test_build AS (
  SELECT id FROM jaws_builds WHERE project_name = 'Test Project - Validation' ORDER BY created_at DESC LIMIT 1
)
INSERT INTO jaws_workflows (
  build_id,
  workflow_name,
  workflow_type,
  trigger_type,
  node_count,
  claude_nodes,
  supabase_nodes,
  estimated_tokens,
  purpose
)
SELECT
  id,
  'Test Orchestrator Workflow',
  'orchestrator',
  'webhook',
  10,
  2,
  3,
  2000,
  'Main orchestration workflow for testing'
FROM test_build
RETURNING
  id,
  workflow_name,
  workflow_type,
  node_count;
-- Expected: Returns 1 row with workflow details

-- TEST 3: Insert test tables (replace build_id with UUID from TEST 1)
WITH test_build AS (
  SELECT id FROM jaws_builds WHERE project_name = 'Test Project - Validation' ORDER BY created_at DESC LIMIT 1
)
INSERT INTO jaws_tables (
  build_id,
  table_name,
  column_count,
  has_rls,
  row_count,
  purpose
)
SELECT
  id,
  'test_users',
  8,
  true,
  100,
  'Stores user information'
FROM test_build
RETURNING
  id,
  table_name,
  has_rls;
-- Expected: Returns 1 row with table details

-- TEST 4: Verify cascade delete works
-- Query the build with related data
WITH test_build AS (
  SELECT id FROM jaws_builds WHERE project_name = 'Test Project - Validation' ORDER BY created_at DESC LIMIT 1
)
SELECT
  b.project_name,
  COUNT(DISTINCT w.id) as workflow_count,
  COUNT(DISTINCT t.id) as table_count
FROM jaws_builds b
LEFT JOIN jaws_workflows w ON w.build_id = b.id
LEFT JOIN jaws_tables t ON t.build_id = b.id
WHERE b.id = (SELECT id FROM test_build)
GROUP BY b.project_name;
-- Expected: 1 row showing project_name with workflow_count=1, table_count=1

-- TEST 5: Query with joins (verify relationships)
WITH test_build AS (
  SELECT id FROM jaws_builds WHERE project_name = 'Test Project - Validation' ORDER BY created_at DESC LIMIT 1
)
SELECT
  b.project_name,
  b.client_name,
  w.workflow_name,
  w.workflow_type,
  w.node_count
FROM jaws_builds b
JOIN jaws_workflows w ON w.build_id = b.id
WHERE b.id = (SELECT id FROM test_build);
-- Expected: Returns workflow details joined with build info

-- TEST 6: Test updated_at trigger
WITH test_build AS (
  SELECT id FROM jaws_builds WHERE project_name = 'Test Project - Validation' ORDER BY created_at DESC LIMIT 1
)
UPDATE jaws_builds
SET workflows_created = 5
WHERE id = (SELECT id FROM test_build)
RETURNING id, workflows_created, updated_at;
-- Expected: updated_at should be newer than created_at

-- TEST 7: Verify JSONB column works
WITH test_build AS (
  SELECT id FROM jaws_builds WHERE project_name = 'Test Project - Validation' ORDER BY created_at DESC LIMIT 1
)
UPDATE jaws_builds
SET dashboard_spec = '{"version": "1.0", "charts": ["tokens", "timeline"]}'::jsonb
WHERE id = (SELECT id FROM test_build)
RETURNING id, dashboard_spec->>'version' as spec_version;
-- Expected: Returns spec_version = '1.0'

-- ============================================================================
-- LEVEL 3: RLS POLICY TESTS
-- ============================================================================
-- Verify RLS policies are working correctly
-- ============================================================================

-- TEST 8: Verify service_role policies exist
SELECT
  schemaname,
  tablename,
  policyname,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename LIKE 'jaws_%'
  AND policyname LIKE '%service%'
ORDER BY tablename, policyname;
-- Expected: 3 policies (one for each table) with service_role access

-- TEST 9: Verify public read policies exist
SELECT
  schemaname,
  tablename,
  policyname,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename LIKE 'jaws_%'
  AND policyname LIKE '%public%'
ORDER BY tablename, policyname;
-- Expected: 3 policies (one for each table) allowing SELECT

-- ============================================================================
-- LEVEL 4: DATA INTEGRITY TESTS
-- ============================================================================
-- Verify constraints and data validation
-- ============================================================================

-- TEST 10: Test CHECK constraint on workflow_type
-- This should FAIL (expected behavior)
/*
WITH test_build AS (
  SELECT id FROM jaws_builds WHERE project_name = 'Test Project - Validation' ORDER BY created_at DESC LIMIT 1
)
INSERT INTO jaws_workflows (build_id, workflow_name, workflow_type, trigger_type, node_count)
SELECT id, 'Invalid Workflow', 'invalid-type', 'webhook', 1
FROM test_build;
*/
-- Expected: ERROR - violates check constraint

-- TEST 11: Test NOT NULL constraint
-- This should FAIL (expected behavior)
/*
INSERT INTO jaws_builds (project_name, iterations_used, iterations_max)
VALUES (NULL, 10, 50);
*/
-- Expected: ERROR - null value in column "project_name" violates not-null constraint

-- TEST 12: Test foreign key constraint
-- This should FAIL (expected behavior)
/*
INSERT INTO jaws_workflows (
  build_id,
  workflow_name,
  workflow_type,
  trigger_type,
  node_count
)
VALUES (
  '00000000-0000-0000-0000-000000000000', -- Non-existent build_id
  'Orphan Workflow',
  'standalone',
  'webhook',
  1
);
*/
-- Expected: ERROR - violates foreign key constraint

-- ============================================================================
-- CLEANUP TEST DATA
-- ============================================================================
-- Remove test data after validation
-- ============================================================================

-- Delete test build (will cascade to workflows and tables)
DELETE FROM jaws_builds
WHERE project_name = 'Test Project - Validation';
-- Expected: Deletes 1 row (and cascades to related tables)

-- Verify cleanup
SELECT COUNT(*) as remaining_test_records
FROM jaws_builds
WHERE project_name = 'Test Project - Validation';
-- Expected: 0 rows

-- ============================================================================
-- SUMMARY QUERY
-- ============================================================================
-- Quick overview of all data in the system
-- ============================================================================

SELECT
  (SELECT COUNT(*) FROM jaws_builds) as total_builds,
  (SELECT COUNT(*) FROM jaws_workflows) as total_workflows,
  (SELECT COUNT(*) FROM jaws_tables) as total_tables;
-- Shows current record counts across all tables
