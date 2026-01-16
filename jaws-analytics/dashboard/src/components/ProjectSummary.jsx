import React from 'react'
import { FileText, Code2, TrendingUp, AlertCircle } from 'lucide-react'

/**
 * ProjectSummary component displays AI-generated summaries
 * Shows executive summary in Client view, technical summary in Technical view
 *
 * @param {Object} summaries - AI-generated summaries object
 * @param {string} viewMode - 'client' or 'technical' view mode
 */
export default function ProjectSummary({ summaries = {}, viewMode = 'client' }) {
  const {
    executive_summary = '',
    technical_summary = '',
    value_proposition = '',
    architecture_description = ''
  } = summaries

  // Show different content based on view mode
  if (viewMode === 'client') {
    return (
      <div className="space-y-6">
        {/* Executive Summary */}
        {executive_summary && (
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center mb-3">
              <FileText className="w-5 h-5 text-blue-600 mr-2" />
              <h3 className="text-lg font-semibold text-gray-900">Executive Summary</h3>
            </div>
            <p className="text-gray-700 leading-relaxed">
              {executive_summary}
            </p>
          </div>
        )}

        {/* Value Proposition */}
        {value_proposition && (
          <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg border border-blue-200 p-6">
            <div className="flex items-center mb-3">
              <TrendingUp className="w-5 h-5 text-blue-600 mr-2" />
              <h3 className="text-lg font-semibold text-gray-900">Value Delivered</h3>
            </div>
            <p className="text-gray-700 leading-relaxed">
              {value_proposition}
            </p>
          </div>
        )}

        {/* Placeholder for default data */}
        {!executive_summary && !value_proposition && (
          <div className="bg-white rounded-lg border border-gray-200 p-6">
            <div className="flex items-center mb-3">
              <FileText className="w-5 h-5 text-blue-600 mr-2" />
              <h3 className="text-lg font-semibold text-gray-900">Project Overview</h3>
            </div>
            <p className="text-gray-700 leading-relaxed">
              This analytics dashboard provides a comprehensive view of your RALPH-JAWS build,
              showing workflows created, database schema, token usage estimates, and build progression.
              Switch to Technical View to see detailed implementation metrics.
            </p>
          </div>
        )}
      </div>
    )
  }

  // Technical View
  return (
    <div className="space-y-6">
      {/* Technical Summary */}
      {technical_summary && (
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center mb-3">
            <Code2 className="w-5 h-5 text-indigo-600 mr-2" />
            <h3 className="text-lg font-semibold text-gray-900">Technical Summary</h3>
          </div>
          <p className="text-gray-700 leading-relaxed whitespace-pre-line">
            {technical_summary}
          </p>
        </div>
      )}

      {/* Architecture Description */}
      {architecture_description && (
        <div className="bg-gray-50 rounded-lg border border-gray-200 p-6">
          <div className="flex items-center mb-3">
            <AlertCircle className="w-5 h-5 text-gray-600 mr-2" />
            <h3 className="text-lg font-semibold text-gray-900">Architecture Notes</h3>
          </div>
          <p className="text-gray-700 leading-relaxed">
            {architecture_description}
          </p>
        </div>
      )}

      {/* Placeholder for default data */}
      {!technical_summary && !architecture_description && (
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center mb-3">
            <Code2 className="w-5 h-5 text-indigo-600 mr-2" />
            <h3 className="text-lg font-semibold text-gray-900">Technical Overview</h3>
          </div>
          <div className="text-gray-700 leading-relaxed space-y-3">
            <p>
              This build created a complete analytics system with the following technical components:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>n8n workflows for data extraction and analysis</li>
              <li>Supabase database schema with RLS policies</li>
              <li>Claude API integration for AI-generated summaries</li>
              <li>React dashboard with Recharts visualizations</li>
              <li>Multi-level validation strategy (syntax, unit, integration)</li>
            </ul>
            <p className="text-sm text-gray-600 mt-4">
              Use the expandable rows in the Workflow Breakdown table to see node-by-node implementation details.
            </p>
          </div>
        </div>
      )}
    </div>
  )
}
