-- ============================================================================
-- JAWS Analytics Database Schema
-- ============================================================================
-- Purpose: Store build analytics for RALPH-JAWS projects
-- Tables: jaws_builds, jaws_workflows, jaws_tables
-- Security: RLS enabled with service_role access policies
-- ============================================================================

-- Drop existing tables if they exist (for clean reinstall)
DROP TABLE IF EXISTS jaws_tables CASCADE;
DROP TABLE IF EXISTS jaws_workflows CASCADE;
DROP TABLE IF EXISTS jaws_builds CASCADE;

-- ============================================================================
-- TABLE: jaws_builds
-- ============================================================================
-- Stores high-level build metrics for each RALPH-JAWS project
-- ============================================================================

CREATE TABLE jaws_builds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Project identification
  project_name TEXT NOT NULL,
  client_name TEXT,
  build_date TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Iteration metrics
  iterations_used INT NOT NULL DEFAULT 0,
  iterations_max INT NOT NULL DEFAULT 0,

  -- Task completion metrics
  tasks_total INT NOT NULL DEFAULT 0,
  tasks_completed INT NOT NULL DEFAULT 0,
  tasks_skipped INT NOT NULL DEFAULT 0,
  tasks_failed INT NOT NULL DEFAULT 0,

  -- Build output counts
  workflows_created INT NOT NULL DEFAULT 0,
  tables_created INT NOT NULL DEFAULT 0,

  -- Token and cost estimates
  estimated_tokens_per_run INT NOT NULL DEFAULT 0,
  estimated_monthly_cost DECIMAL(10,2) DEFAULT 0.00,

  -- Build execution metrics
  build_duration_minutes INT DEFAULT 0,
  checkpoints_triggered INT DEFAULT 0,
  rabbit_holes_detected INT DEFAULT 0,

  -- AI-generated summaries and specs
  prd_summary TEXT,
  architecture_mermaid TEXT,
  dashboard_spec JSONB,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add comment for documentation
COMMENT ON TABLE jaws_builds IS 'Stores high-level analytics for each RALPH-JAWS build project';

-- ============================================================================
-- TABLE: jaws_workflows
-- ============================================================================
-- Stores detailed metrics for each n8n workflow created in a build
-- ============================================================================

CREATE TABLE jaws_workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign key to parent build
  build_id UUID NOT NULL REFERENCES jaws_builds(id) ON DELETE CASCADE,

  -- Workflow identification
  workflow_name TEXT NOT NULL,
  workflow_type TEXT NOT NULL CHECK (workflow_type IN ('orchestrator', 'sub-workflow', 'standalone')),
  trigger_type TEXT NOT NULL CHECK (trigger_type IN ('webhook', 'schedule', 'manual', 'execute')),

  -- Node metrics
  node_count INT NOT NULL DEFAULT 0,
  claude_nodes INT NOT NULL DEFAULT 0,
  supabase_nodes INT NOT NULL DEFAULT 0,

  -- Token estimates
  estimated_tokens INT NOT NULL DEFAULT 0,

  -- Description and breakdown
  purpose TEXT,
  nodes_breakdown JSONB,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add comment for documentation
COMMENT ON TABLE jaws_workflows IS 'Stores detailed metrics for n8n workflows created in each build';

-- ============================================================================
-- TABLE: jaws_tables
-- ============================================================================
-- Stores metrics for each Supabase table created in a build
-- ============================================================================

CREATE TABLE jaws_tables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Foreign key to parent build
  build_id UUID NOT NULL REFERENCES jaws_builds(id) ON DELETE CASCADE,

  -- Table identification
  table_name TEXT NOT NULL,

  -- Table metrics
  column_count INT NOT NULL DEFAULT 0,
  has_rls BOOLEAN DEFAULT false,
  row_count INT DEFAULT 0,

  -- Description
  purpose TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add comment for documentation
COMMENT ON TABLE jaws_tables IS 'Stores metrics for Supabase tables created in each build';

-- ============================================================================
-- INDEXES
-- ============================================================================
-- Foreign key indexes for performance
-- ============================================================================

CREATE INDEX idx_jaws_workflows_build_id ON jaws_workflows(build_id);
CREATE INDEX idx_jaws_tables_build_id ON jaws_tables(build_id);

-- Additional useful indexes
CREATE INDEX idx_jaws_builds_project_name ON jaws_builds(project_name);
CREATE INDEX idx_jaws_builds_client_name ON jaws_builds(client_name);
CREATE INDEX idx_jaws_builds_build_date ON jaws_builds(build_date DESC);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Enable RLS and create policies for service_role access
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE jaws_builds ENABLE ROW LEVEL SECURITY;
ALTER TABLE jaws_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE jaws_tables ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICY: Service Role Full Access (for n8n)
-- ============================================================================
-- CRITICAL: These policies allow the service_role key to bypass RLS
-- This is required for n8n workflows to insert/update/delete data
-- ============================================================================

-- jaws_builds policies
CREATE POLICY "Service role has full access to jaws_builds"
  ON jaws_builds
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- jaws_workflows policies
CREATE POLICY "Service role has full access to jaws_workflows"
  ON jaws_workflows
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- jaws_tables policies
CREATE POLICY "Service role has full access to jaws_tables"
  ON jaws_tables
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- RLS POLICY: Public Read Access (for dashboard)
-- ============================================================================
-- Optional: Allow public read access for dashboard viewing
-- Remove these if you want to restrict dashboard access
-- ============================================================================

-- Public read access to builds
CREATE POLICY "Public read access to jaws_builds"
  ON jaws_builds
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Public read access to workflows
CREATE POLICY "Public read access to jaws_workflows"
  ON jaws_workflows
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- Public read access to tables
CREATE POLICY "Public read access to jaws_tables"
  ON jaws_tables
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ============================================================================
-- FUNCTION: Update updated_at timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to jaws_builds
CREATE TRIGGER update_jaws_builds_updated_at
  BEFORE UPDATE ON jaws_builds
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these to verify the schema was created correctly
-- ============================================================================

-- Verify all tables exist
SELECT
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('jaws_builds', 'jaws_workflows', 'jaws_tables')
ORDER BY table_name;

-- Verify RLS is enabled
SELECT
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE 'jaws_%'
ORDER BY tablename;

-- Verify indexes exist
SELECT
  indexname,
  tablename
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename LIKE 'jaws_%'
ORDER BY tablename, indexname;

-- ============================================================================
-- SAMPLE INSERT TEST
-- ============================================================================
-- Uncomment to test basic insert functionality
-- ============================================================================

/*
-- Test insert to jaws_builds
INSERT INTO jaws_builds (
  project_name,
  client_name,
  build_date,
  iterations_used,
  iterations_max,
  tasks_total,
  tasks_completed
)
VALUES (
  'Test Project',
  'Test Client',
  now(),
  10,
  50,
  15,
  12
)
RETURNING id, project_name, created_at;

-- Test insert to jaws_workflows (use build_id from above)
INSERT INTO jaws_workflows (
  build_id,
  workflow_name,
  workflow_type,
  trigger_type,
  node_count,
  claude_nodes,
  purpose
)
VALUES (
  '00000000-0000-0000-0000-000000000000', -- Replace with actual build_id
  'Test Workflow',
  'standalone',
  'webhook',
  5,
  1,
  'Test workflow for verification'
)
RETURNING id, workflow_name, created_at;
*/
