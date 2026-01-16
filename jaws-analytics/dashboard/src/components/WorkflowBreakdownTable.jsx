import React, { useState } from 'react'
import { ChevronDown, ChevronRight } from 'lucide-react'

/**
 * WorkflowBreakdownTable component displays detailed workflow information
 *
 * @param {Array} workflows - Array of workflow objects with details
 * @param {string} viewMode - 'client' or 'technical' for expandable rows
 */
export default function WorkflowBreakdownTable({ workflows = [], viewMode = 'client' }) {
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' })
  const [expandedRows, setExpandedRows] = useState(new Set())

  // Handle sorting
  const handleSort = (key) => {
    let direction = 'asc'
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc'
    }
    setSortConfig({ key, direction })
  }

  // Sort workflows based on current config
  const sortedWorkflows = React.useMemo(() => {
    if (!sortConfig.key || !workflows || workflows.length === 0) {
      return workflows
    }

    const sorted = [...workflows].sort((a, b) => {
      const aValue = a[sortConfig.key]
      const bValue = b[sortConfig.key]

      if (aValue === null || aValue === undefined) return 1
      if (bValue === null || bValue === undefined) return -1

      if (typeof aValue === 'string') {
        return sortConfig.direction === 'asc'
          ? aValue.localeCompare(bValue)
          : bValue.localeCompare(aValue)
      }

      return sortConfig.direction === 'asc'
        ? aValue - bValue
        : bValue - aValue
    })

    return sorted
  }, [workflows, sortConfig])

  // Toggle row expansion
  const toggleRowExpansion = (workflowId) => {
    const newExpanded = new Set(expandedRows)
    if (newExpanded.has(workflowId)) {
      newExpanded.delete(workflowId)
    } else {
      newExpanded.add(workflowId)
    }
    setExpandedRows(newExpanded)
  }

  // Sort icon component
  const SortIcon = ({ columnKey }) => {
    if (sortConfig.key !== columnKey) {
      return (
        <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
        </svg>
      )
    }
    return sortConfig.direction === 'asc' ? (
      <svg className="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
      </svg>
    ) : (
      <svg className="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
      </svg>
    )
  }

  if (!workflows || workflows.length === 0) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-8">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Workflow Breakdown</h3>
        <p className="text-gray-600 text-center py-8">No workflow data available</p>
      </div>
    )
  }

  return (
    <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
      <div className="px-6 py-4 border-b border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900">Workflow Breakdown</h3>
        <p className="text-sm text-gray-600 mt-1">
          {workflows.length} workflow{workflows.length !== 1 ? 's' : ''} analyzed
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              {viewMode === 'technical' && (
                <th scope="col" className="w-12 px-6 py-3"></th>
              )}
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                onClick={() => handleSort('workflow_name')}
              >
                <div className="flex items-center space-x-1">
                  <span>Workflow Name</span>
                  <SortIcon columnKey="workflow_name" />
                </div>
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                onClick={() => handleSort('workflow_type')}
              >
                <div className="flex items-center space-x-1">
                  <span>Type</span>
                  <SortIcon columnKey="workflow_type" />
                </div>
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                onClick={() => handleSort('trigger_type')}
              >
                <div className="flex items-center space-x-1">
                  <span>Trigger</span>
                  <SortIcon columnKey="trigger_type" />
                </div>
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                onClick={() => handleSort('node_count')}
              >
                <div className="flex items-center space-x-1">
                  <span>Nodes</span>
                  <SortIcon columnKey="node_count" />
                </div>
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                onClick={() => handleSort('estimated_tokens')}
              >
                <div className="flex items-center space-x-1">
                  <span>Est. Tokens</span>
                  <SortIcon columnKey="estimated_tokens" />
                </div>
              </th>
              <th
                scope="col"
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              >
                Purpose
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {sortedWorkflows.map((workflow, index) => (
              <React.Fragment key={workflow.id || index}>
                <tr className="hover:bg-gray-50 transition-colors">
                  {viewMode === 'technical' && (
                    <td className="px-6 py-4 whitespace-nowrap">
                      <button
                        onClick={() => toggleRowExpansion(workflow.id || index)}
                        className="text-gray-400 hover:text-gray-600 focus:outline-none"
                        aria-label={expandedRows.has(workflow.id || index) ? 'Collapse row' : 'Expand row'}
                      >
                        {expandedRows.has(workflow.id || index) ? (
                          <ChevronDown className="w-5 h-5" />
                        ) : (
                          <ChevronRight className="w-5 h-5" />
                        )}
                      </button>
                    </td>
                  )}
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">
                      {workflow.workflow_name || 'Unnamed Workflow'}
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      workflow.workflow_type === 'orchestrator'
                        ? 'bg-purple-100 text-purple-800'
                        : workflow.workflow_type === 'sub-workflow'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}>
                      {workflow.workflow_type || 'unknown'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                      {workflow.trigger_type || 'manual'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {workflow.node_count || 0}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {workflow.estimated_tokens ? workflow.estimated_tokens.toLocaleString() : '0'}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600 max-w-md truncate">
                    {workflow.purpose || 'No description available'}
                  </td>
                </tr>

                {/* Expandable row for Technical view with node breakdown */}
                {viewMode === 'technical' && expandedRows.has(workflow.id || index) && (
                  <tr className="bg-gray-50">
                    <td colSpan={7} className="px-6 py-4">
                      <div className="ml-8">
                        <h4 className="text-sm font-semibold text-gray-900 mb-3">Node Breakdown</h4>
                        {workflow.nodes_breakdown && typeof workflow.nodes_breakdown === 'object' ? (
                          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                            {Object.entries(workflow.nodes_breakdown).map(([nodeType, count]) => (
                              <div
                                key={nodeType}
                                className="bg-white rounded-lg border border-gray-200 p-3"
                              >
                                <div className="text-xs font-medium text-gray-500 uppercase tracking-wide">
                                  {nodeType.replace(/_/g, ' ')}
                                </div>
                                <div className="text-lg font-semibold text-gray-900 mt-1">
                                  {count}
                                </div>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <p className="text-sm text-gray-600">No node breakdown available</p>
                        )}

                        {/* Additional technical details */}
                        <div className="mt-4 grid grid-cols-2 gap-4">
                          {workflow.claude_nodes !== undefined && (
                            <div className="bg-white rounded-lg border border-gray-200 p-3">
                              <div className="text-xs font-medium text-gray-500 uppercase tracking-wide">
                                Claude API Nodes
                              </div>
                              <div className="text-lg font-semibold text-blue-600 mt-1">
                                {workflow.claude_nodes}
                              </div>
                            </div>
                          )}
                          {workflow.supabase_nodes !== undefined && (
                            <div className="bg-white rounded-lg border border-gray-200 p-3">
                              <div className="text-xs font-medium text-gray-500 uppercase tracking-wide">
                                Supabase Nodes
                              </div>
                              <div className="text-lg font-semibold text-green-600 mt-1">
                                {workflow.supabase_nodes}
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                  </tr>
                )}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
