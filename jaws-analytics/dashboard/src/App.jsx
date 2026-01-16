import React, { useState, useEffect } from 'react'
import Sidebar from './components/Sidebar'
import Header from './components/Header'
import ProjectSummary from './components/ProjectSummary'
import StatsCardsSection from './components/StatsCardsSection'
import ArchitectureDiagram from './components/ArchitectureDiagram'
import WorkflowBreakdownTable from './components/WorkflowBreakdownTable'
import TokenUsageChart from './components/TokenUsageChart'
import BuildTimeline from './components/BuildTimeline'
import AllProjectsOverview from './components/AllProjectsOverview'
import { generatePDF } from './utils/pdfExport'

export default function App() {
  const [activeProject, setActiveProject] = useState(null)
  const [viewMode, setViewMode] = useState('client')

  // Test data for stats cards (US-014)
  const testBuildData = {
    workflows_created: 8,
    tables_created: 4,
    estimated_tokens_per_run: 150000,
    tasks_total: 15,
    tasks_completed: 14
  }

  // Test data for architecture diagram (US-015)
  const testMermaidDiagram = `graph TD
    A[Analytics Orchestrator] --> B[PRD Analyzer]
    A --> C[State Analyzer]
    A --> D[Workflow Analyzer]
    A --> E[Token Estimator]
    B --> F[AI Summary Generator]
    C --> F
    D --> F
    E --> F
    F --> G[Dashboard Spec Generator]
    G --> H[Supabase Storage]
    H --> I[Dashboard Display]

    style A fill:#4F46E5,stroke:#4338CA,color:#fff
    style I fill:#10B981,stroke:#059669,color:#fff`

  // Test data for workflow breakdown table (US-016)
  const testWorkflowData = [
    {
      id: '1',
      workflow_name: 'Analytics Orchestrator',
      workflow_type: 'orchestrator',
      trigger_type: 'webhook',
      node_count: 27,
      estimated_tokens: 45000,
      purpose: 'Coordinates all analysis sub-workflows and aggregates results',
      claude_nodes: 0,
      supabase_nodes: 1,
      nodes_breakdown: {
        'webhook': 1,
        'code': 15,
        'execute_workflow': 9,
        'if': 2
      }
    },
    {
      id: '2',
      workflow_name: 'PRD Analyzer',
      workflow_type: 'sub-workflow',
      trigger_type: 'execute',
      node_count: 10,
      estimated_tokens: 12000,
      purpose: 'Extracts structured metrics from PRD.md including tasks, phases, and completion status',
      claude_nodes: 0,
      supabase_nodes: 0,
      nodes_breakdown: {
        'execute_workflow_trigger': 1,
        'code': 9
      }
    },
    {
      id: '3',
      workflow_name: 'Workflow Analyzer',
      workflow_type: 'sub-workflow',
      trigger_type: 'execute',
      node_count: 8,
      estimated_tokens: 8500,
      purpose: 'Analyzes n8n workflow JSON files to identify node types and token usage',
      claude_nodes: 0,
      supabase_nodes: 0,
      nodes_breakdown: {
        'execute_workflow_trigger': 1,
        'code': 7
      }
    },
    {
      id: '4',
      workflow_name: 'AI Summary Generator',
      workflow_type: 'sub-workflow',
      trigger_type: 'execute',
      node_count: 5,
      estimated_tokens: 35000,
      purpose: 'Generates human-readable summaries and value propositions using Claude API',
      claude_nodes: 1,
      supabase_nodes: 0,
      nodes_breakdown: {
        'execute_workflow_trigger': 1,
        'code': 2,
        'http_request': 2
      }
    },
    {
      id: '5',
      workflow_name: 'Dashboard Spec Generator',
      workflow_type: 'sub-workflow',
      trigger_type: 'execute',
      node_count: 11,
      estimated_tokens: 0,
      purpose: 'Compiles all analysis results into dashboard-ready JSON specification',
      claude_nodes: 0,
      supabase_nodes: 0,
      nodes_breakdown: {
        'execute_workflow_trigger': 1,
        'code': 8,
        'write_file': 1,
        'response': 1
      }
    },
    {
      id: '6',
      workflow_name: 'Supabase Storage',
      workflow_type: 'sub-workflow',
      trigger_type: 'execute',
      node_count: 18,
      estimated_tokens: 0,
      purpose: 'Persists build analytics to Supabase database tables',
      claude_nodes: 0,
      supabase_nodes: 3,
      nodes_breakdown: {
        'execute_workflow_trigger': 1,
        'code': 9,
        'http_request': 6,
        'if': 2
      }
    }
  ]

  // Test data for AI summaries (US-019)
  const testSummaries = {
    executive_summary: "This analytics system automatically transforms RALPH-JAWS build artifacts into professional dashboards and reports. It analyzes 8 n8n workflows, 4 database tables, and provides comprehensive metrics on build progression, token usage, and operational costs. The system enables automated client deliverable creation, saving 2-3 hours per project while providing data-driven insights for business decisions.",
    technical_summary: "The system implements a multi-workflow orchestration pattern with graceful degradation. The analytics orchestrator coordinates 9 sub-workflows that extract metrics from PRD.md, ralph-state.json, and workflow JSON files. Claude API integration generates natural language summaries and Mermaid diagrams. All data persists in Supabase with RLS policies for secure access. The dashboard uses React with Recharts for visualizations and supports both client-facing and technical deep-dive views.",
    value_proposition: "Automates client deliverable creation (2-3 hours saved per project). Professional visualization justifies project pricing. Historical analytics track cumulative business value across all builds. Self-documenting systems enable capability transfer to clients.",
    architecture_description: "Webhook-triggered orchestrator pattern with 9 specialized analyzers. Each analyzer is idempotent and continues on failure to maximize data collection. Results compile into dashboard-spec.json for frontend consumption."
  }

  // Test data for build timeline (US-018)
  const testTimelineData = {
    iterations_used: 42,
    iterations_max: 50,
    checkpoints_triggered: 4,
    rabbit_holes_detected: 2,
    build_duration_minutes: 245,
    phases: [
      {
        phase: 1,
        name: 'Foundation',
        checkpoint: 'FOUNDATION',
        iterations_start: 1,
        iterations_end: 5,
        tasks_completed: 2,
        tasks_total: 2,
        status: 'completed',
        iterations: [
          { number: 1, status: 'success', task: 'US-001: Create Supabase Schema' },
          { number: 2, status: 'success', task: 'US-001: Verify RLS policies' },
          { number: 3, status: 'success', task: 'US-002: Configure credentials' },
          { number: 4, status: 'success', task: 'US-002: Test connections' },
          { number: 5, status: 'success', task: 'CHECKPOINT: Foundation verified' }
        ]
      },
      {
        phase: 2,
        name: 'Analytics Engine',
        checkpoint: 'ANALYTICS',
        iterations_start: 6,
        iterations_end: 18,
        tasks_completed: 5,
        tasks_total: 5,
        status: 'completed',
        iterations: [
          { number: 6, status: 'success', task: 'US-003: Build artifact reader' },
          { number: 7, status: 'failure', task: 'US-004: PRD analyzer - regex issues' },
          { number: 8, status: 'success', task: 'US-004: PRD analyzer - fixed', retry: true },
          { number: 9, status: 'success', task: 'US-005: Workflow analyzer' },
          { number: 10, status: 'success', task: 'US-006: Token estimator' },
          { number: 11, status: 'success', task: 'US-007: State analyzer' },
          { number: 12, status: 'success', task: 'CHECKPOINT: Analytics complete' }
        ]
      },
      {
        phase: 3,
        name: 'AI Summary',
        checkpoint: 'AI',
        iterations_start: 19,
        iterations_end: 25,
        tasks_completed: 2,
        tasks_total: 2,
        status: 'completed',
        iterations: [
          { number: 19, status: 'success', task: 'US-008: AI summary generator' },
          { number: 20, status: 'failure', task: 'US-009: Mermaid diagram - invalid syntax' },
          { number: 21, status: 'success', task: 'US-009: Mermaid diagram - fixed', retry: true },
          { number: 22, status: 'success', task: 'CHECKPOINT: AI summaries verified' }
        ]
      },
      {
        phase: 4,
        name: 'Storage & Orchestration',
        checkpoint: 'STORAGE',
        iterations_start: 26,
        iterations_end: 35,
        tasks_completed: 3,
        tasks_total: 3,
        status: 'completed',
        iterations: [
          { number: 26, status: 'success', task: 'US-010: Dashboard spec generator' },
          { number: 27, status: 'success', task: 'US-011: Supabase storage' },
          { number: 28, status: 'failure', task: 'US-012: Orchestrator - missing error handling' },
          { number: 29, status: 'success', task: 'US-012: Orchestrator - added graceful degradation', retry: true },
          { number: 30, status: 'success', task: 'CHECKPOINT: Storage integration verified' }
        ]
      },
      {
        phase: 5,
        name: 'Dashboard Frontend',
        checkpoint: 'DASHBOARD',
        iterations_start: 36,
        iterations_end: 42,
        tasks_completed: 5,
        tasks_total: 6,
        status: 'in_progress',
        iterations: [
          { number: 36, status: 'success', task: 'US-013: Layout and navigation' },
          { number: 37, status: 'success', task: 'US-014: Stats cards' },
          { number: 38, status: 'success', task: 'US-015: Architecture diagram' },
          { number: 39, status: 'success', task: 'US-016: Workflow breakdown table' },
          { number: 40, status: 'success', task: 'US-017: Token usage chart' },
          { number: 41, status: 'success', task: 'US-018: Build timeline' },
          { number: 42, status: 'pending', task: 'US-019: Client vs Technical toggle' }
        ]
      }
    ]
  }

  // Load view preference from localStorage
  useEffect(() => {
    const savedViewMode = localStorage.getItem('viewMode')
    if (savedViewMode) {
      setViewMode(savedViewMode)
    }
  }, [])

  // Save view preference to localStorage
  const handleViewModeChange = (mode) => {
    setViewMode(mode)
    localStorage.setItem('viewMode', mode)
  }

  // Handle PDF export
  const handleExportPDF = async () => {
    if (!activeProject) {
      alert('Please select a project to export')
      return
    }

    try {
      // Prepare data for PDF generation
      const pdfData = {
        buildData: testBuildData,
        summaries: testSummaries,
        mermaidCode: testMermaidDiagram,
        workflows: testWorkflowData,
        timelineData: testTimelineData,
        projectName: 'JAWS Analytics System', // Would come from actual project data
        clientName: 'Janice\'s AI Automation Consulting'
      }

      // Generate PDF
      const filename = await generatePDF(pdfData, viewMode)

      // Show success message
      console.log(`PDF exported successfully: ${filename}`)
    } catch (error) {
      console.error('Error generating PDF:', error)
      alert('Failed to generate PDF. Please try again.')
    }
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar Navigation */}
      <Sidebar
        activeProject={activeProject}
        onProjectSelect={setActiveProject}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <Header
          viewMode={viewMode}
          onViewModeChange={handleViewModeChange}
          onExportPDF={activeProject ? handleExportPDF : null}
        />

        {/* Main Content */}
        <main className="flex-1 overflow-y-auto p-6">
          {activeProject ? (
            <div className="max-w-7xl mx-auto">
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 mb-6">
                <h2 className="text-2xl font-bold text-gray-900 mb-4">
                  Project Dashboard
                </h2>
                <p className="text-gray-600">
                  Project ID: {activeProject}
                </p>
                <p className="text-gray-600 mt-2">
                  View Mode: {viewMode === 'client' ? 'Client' : 'Technical'}
                </p>
              </div>

              {/* Project Summary Section (US-019) */}
              <div className="mb-6">
                <ProjectSummary summaries={testSummaries} viewMode={viewMode} />
              </div>

              {/* Stats Cards Section (US-014) */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 mb-6">
                <StatsCardsSection data={testBuildData} />
              </div>

              {/* Architecture Diagram Section (US-015) */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 mb-6">
                <ArchitectureDiagram mermaidCode={testMermaidDiagram} />
              </div>

              {/* Workflow Breakdown Table Section (US-016) */}
              <div className="mb-6">
                <WorkflowBreakdownTable workflows={testWorkflowData} viewMode={viewMode} />
              </div>

              {/* Token Usage Chart Section (US-017) */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 mb-6">
                <TokenUsageChart workflows={testWorkflowData} />
              </div>

              {/* Build Timeline Section (US-018) */}
              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 mb-6">
                <BuildTimeline buildData={testTimelineData} viewMode={viewMode} />
              </div>

              <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                  <p className="text-sm text-blue-800">
                    Additional dashboard components will be added in subsequent user stories (US-019 onwards)
                  </p>
                </div>
              </div>
            </div>
          ) : (
            <AllProjectsOverview onProjectSelect={setActiveProject} />
          )}
        </main>
      </div>
    </div>
  )
}
