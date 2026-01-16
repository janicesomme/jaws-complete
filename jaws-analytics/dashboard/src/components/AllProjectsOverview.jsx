import React, { useState, useEffect } from 'react'
import {
  TrendingUp,
  Workflow,
  Database,
  CheckCircle,
  Calendar,
  User,
  ArrowUpDown,
  Search,
  Grid,
  List
} from 'lucide-react'
import { supabase } from '../lib/supabase'

export default function AllProjectsOverview({ onProjectSelect }) {
  const [projects, setProjects] = useState([])
  const [loading, setLoading] = useState(true)
  const [viewMode, setViewMode] = useState('grid') // 'grid' or 'list'
  const [sortBy, setSortBy] = useState('date') // 'date', 'name', 'workflows', 'status'
  const [sortOrder, setSortOrder] = useState('desc') // 'asc' or 'desc'
  const [searchQuery, setSearchQuery] = useState('')

  // Summary stats
  const [summaryStats, setSummaryStats] = useState({
    totalProjects: 0,
    totalWorkflows: 0,
    totalEstimatedValue: 0,
    avgCompletionRate: 0
  })

  useEffect(() => {
    fetchProjectsData()
  }, [])

  const fetchProjectsData = async () => {
    try {
      // Fetch all builds
      const { data: builds, error: buildsError } = await supabase
        .from('jaws_builds')
        .select('*')
        .order('created_at', { ascending: false })

      if (buildsError) throw buildsError

      // Fetch workflow counts for each build
      const { data: workflowCounts, error: workflowError } = await supabase
        .from('jaws_workflows')
        .select('build_id')

      if (workflowError) throw workflowError

      // Group workflows by build_id
      const workflowsByBuild = {}
      workflowCounts?.forEach(wf => {
        workflowsByBuild[wf.build_id] = (workflowsByBuild[wf.build_id] || 0) + 1
      })

      // Enrich builds with workflow counts
      const enrichedProjects = builds?.map(build => ({
        ...build,
        workflow_count: workflowsByBuild[build.id] || build.workflows_created || 0,
        completion_rate: build.tasks_total > 0
          ? Math.round((build.tasks_completed / build.tasks_total) * 100)
          : 0,
        status: build.tasks_completed === build.tasks_total ? 'completed' : 'in_progress'
      })) || []

      setProjects(enrichedProjects)

      // Calculate summary stats
      const totalProjects = enrichedProjects.length
      const totalWorkflows = enrichedProjects.reduce((sum, p) => sum + (p.workflow_count || 0), 0)
      const totalEstimatedValue = enrichedProjects.reduce((sum, p) => {
        // Estimate value: $150/hour * (build_duration_minutes / 60) * 1.5 (consulting markup)
        const hours = (p.build_duration_minutes || 0) / 60
        return sum + (hours * 150 * 1.5)
      }, 0)
      const avgCompletionRate = totalProjects > 0
        ? Math.round(enrichedProjects.reduce((sum, p) => sum + p.completion_rate, 0) / totalProjects)
        : 0

      setSummaryStats({
        totalProjects,
        totalWorkflows,
        totalEstimatedValue: Math.round(totalEstimatedValue),
        avgCompletionRate
      })
    } catch (error) {
      console.error('Error fetching projects:', error)
    } finally {
      setLoading(false)
    }
  }

  // Filter projects based on search query
  const filteredProjects = projects.filter(project => {
    const searchLower = searchQuery.toLowerCase()
    return (
      project.project_name?.toLowerCase().includes(searchLower) ||
      project.client_name?.toLowerCase().includes(searchLower)
    )
  })

  // Sort projects
  const sortedProjects = [...filteredProjects].sort((a, b) => {
    let comparison = 0

    switch (sortBy) {
      case 'name':
        comparison = (a.project_name || '').localeCompare(b.project_name || '')
        break
      case 'date':
        comparison = new Date(a.created_at || 0) - new Date(b.created_at || 0)
        break
      case 'workflows':
        comparison = (a.workflow_count || 0) - (b.workflow_count || 0)
        break
      case 'status':
        comparison = (a.completion_rate || 0) - (b.completion_rate || 0)
        break
      default:
        comparison = 0
    }

    return sortOrder === 'asc' ? comparison : -comparison
  })

  const toggleSort = (field) => {
    if (sortBy === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')
    } else {
      setSortBy(field)
      setSortOrder('desc')
    }
  }

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A'
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
          <p className="text-gray-600">Loading projects...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">All Projects</h1>
        <p className="text-gray-600 mt-2">Overview of all RALPH-JAWS builds</p>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-blue-50 rounded-lg">
              <TrendingUp className="text-blue-600" size={24} />
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Projects</p>
              <p className="text-2xl font-bold text-gray-900">{summaryStats.totalProjects}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-green-50 rounded-lg">
              <Workflow className="text-green-600" size={24} />
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Workflows Built</p>
              <p className="text-2xl font-bold text-gray-900">{summaryStats.totalWorkflows}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-purple-50 rounded-lg">
              <Database className="text-purple-600" size={24} />
            </div>
            <div>
              <p className="text-sm text-gray-600">Total Estimated Value</p>
              <p className="text-2xl font-bold text-gray-900">
                ${summaryStats.totalEstimatedValue.toLocaleString()}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 bg-orange-50 rounded-lg">
              <CheckCircle className="text-orange-600" size={24} />
            </div>
            <div>
              <p className="text-sm text-gray-600">Avg Completion Rate</p>
              <p className="text-2xl font-bold text-gray-900">{summaryStats.avgCompletionRate}%</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters and Controls */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
        <div className="flex flex-col md:flex-row gap-4 items-start md:items-center justify-between">
          {/* Search */}
          <div className="flex-1 max-w-md">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
              <input
                type="text"
                placeholder="Search projects or clients..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          {/* Sort Controls */}
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-600">Sort by:</span>
            <button
              onClick={() => toggleSort('date')}
              className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                sortBy === 'date'
                  ? 'bg-blue-50 text-blue-600'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Date {sortBy === 'date' && (sortOrder === 'desc' ? '↓' : '↑')}
            </button>
            <button
              onClick={() => toggleSort('name')}
              className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                sortBy === 'name'
                  ? 'bg-blue-50 text-blue-600'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Name {sortBy === 'name' && (sortOrder === 'desc' ? '↓' : '↑')}
            </button>
            <button
              onClick={() => toggleSort('workflows')}
              className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                sortBy === 'workflows'
                  ? 'bg-blue-50 text-blue-600'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Workflows {sortBy === 'workflows' && (sortOrder === 'desc' ? '↓' : '↑')}
            </button>
            <button
              onClick={() => toggleSort('status')}
              className={`px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                sortBy === 'status'
                  ? 'bg-blue-50 text-blue-600'
                  : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
              }`}
            >
              Status {sortBy === 'status' && (sortOrder === 'desc' ? '↓' : '↑')}
            </button>
          </div>

          {/* View Toggle */}
          <div className="flex items-center gap-2 bg-gray-100 rounded-lg p-1">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded ${
                viewMode === 'grid'
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
              title="Grid view"
            >
              <Grid size={18} />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded ${
                viewMode === 'list'
                  ? 'bg-white text-blue-600 shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
              title="List view"
            >
              <List size={18} />
            </button>
          </div>
        </div>
      </div>

      {/* Projects Display */}
      {sortedProjects.length === 0 ? (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8 text-center">
          <p className="text-gray-600">
            {searchQuery ? 'No projects match your search.' : 'No projects yet. Run an analytics workflow to see data here.'}
          </p>
        </div>
      ) : viewMode === 'grid' ? (
        /* Grid View */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {sortedProjects.map((project) => (
            <div
              key={project.id}
              onClick={() => onProjectSelect(project.id)}
              className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 cursor-pointer hover:shadow-md hover:border-blue-300 transition-all"
            >
              {/* Status Badge */}
              <div className="flex items-center justify-between mb-4">
                <span
                  className={`px-2 py-1 rounded-full text-xs font-medium ${
                    project.status === 'completed'
                      ? 'bg-green-100 text-green-700'
                      : 'bg-blue-100 text-blue-700'
                  }`}
                >
                  {project.completion_rate}% Complete
                </span>
                <span className="text-xs text-gray-500">
                  {formatDate(project.created_at)}
                </span>
              </div>

              {/* Project Name */}
              <h3 className="text-lg font-bold text-gray-900 mb-2 truncate" title={project.project_name}>
                {project.project_name}
              </h3>

              {/* Client Name */}
              {project.client_name && (
                <div className="flex items-center gap-2 text-sm text-gray-600 mb-4">
                  <User size={16} />
                  <span className="truncate">{project.client_name}</span>
                </div>
              )}

              {/* Metrics */}
              <div className="grid grid-cols-2 gap-4 pt-4 border-t border-gray-200">
                <div>
                  <p className="text-xs text-gray-500">Workflows</p>
                  <p className="text-lg font-semibold text-gray-900">{project.workflow_count}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Tables</p>
                  <p className="text-lg font-semibold text-gray-900">{project.tables_created || 0}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : (
        /* List View */
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Project
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Client
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Workflows
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {sortedProjects.map((project) => (
                <tr
                  key={project.id}
                  onClick={() => onProjectSelect(project.id)}
                  className="cursor-pointer hover:bg-gray-50 transition-colors"
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-gray-900">{project.project_name}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-600">{project.client_name || '-'}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-600">{formatDate(project.created_at)}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-gray-900">{project.workflow_count}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${
                        project.status === 'completed'
                          ? 'bg-green-100 text-green-700'
                          : 'bg-blue-100 text-blue-700'
                      }`}
                    >
                      {project.completion_rate}%
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
