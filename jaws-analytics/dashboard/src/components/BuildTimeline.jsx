import React from 'react'
import { CheckCircle, XCircle, AlertCircle, Clock } from 'lucide-react'

/**
 * BuildTimeline component displays build progression with phases, checkpoints, and failures
 * Shows how the build progressed over time with iteration counts
 *
 * @param {Object} buildData - Build data with phases, iterations, checkpoints, failures
 * @param {string} viewMode - 'client' or 'technical' view mode
 */
export default function BuildTimeline({ buildData = {}, viewMode = 'client' }) {
  const {
    iterations_used = 0,
    iterations_max = 0,
    phases = [],
    checkpoints_triggered = 0,
    rabbit_holes_detected = 0,
    build_duration_minutes = 0
  } = buildData

  // Default phases if none provided
  const defaultPhases = [
    {
      phase: 1,
      name: 'Foundation',
      checkpoint: 'FOUNDATION',
      iterations_start: 1,
      iterations_end: 5,
      tasks_completed: 2,
      tasks_total: 2,
      status: 'completed'
    },
    {
      phase: 2,
      name: 'Analytics Engine',
      checkpoint: 'ANALYTICS',
      iterations_start: 6,
      iterations_end: 15,
      tasks_completed: 5,
      tasks_total: 5,
      status: 'completed'
    },
    {
      phase: 3,
      name: 'AI Summary',
      checkpoint: 'AI',
      iterations_start: 16,
      iterations_end: 20,
      tasks_completed: 2,
      tasks_total: 2,
      status: 'completed'
    },
    {
      phase: 4,
      name: 'Storage & Orchestration',
      checkpoint: 'STORAGE',
      iterations_start: 21,
      iterations_end: 30,
      tasks_completed: 3,
      tasks_total: 3,
      status: 'completed'
    },
    {
      phase: 5,
      name: 'Dashboard Frontend',
      checkpoint: 'DASHBOARD',
      iterations_start: 31,
      iterations_end: 42,
      tasks_completed: 4,
      tasks_total: 6,
      status: 'in_progress'
    }
  ]

  const phasesData = phases.length > 0 ? phases : defaultPhases

  // Calculate progress percentage
  const progressPercentage = iterations_max > 0
    ? Math.round((iterations_used / iterations_max) * 100)
    : 0

  // Get status icon
  const getStatusIcon = (status) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-5 h-5 text-green-600" />
      case 'in_progress':
        return <Clock className="w-5 h-5 text-blue-600" />
      case 'failed':
        return <XCircle className="w-5 h-5 text-red-600" />
      default:
        return <AlertCircle className="w-5 h-5 text-gray-400" />
    }
  }

  // Get status color for phase bar
  const getStatusColor = (status) => {
    switch (status) {
      case 'completed':
        return 'bg-green-500'
      case 'in_progress':
        return 'bg-blue-500'
      case 'failed':
        return 'bg-red-500'
      default:
        return 'bg-gray-300'
    }
  }

  // Calculate width percentage for each phase
  const calculatePhaseWidth = (phase) => {
    const iterationCount = phase.iterations_end - phase.iterations_start + 1
    return iterations_used > 0
      ? Math.round((iterationCount / iterations_used) * 100)
      : Math.round(100 / phasesData.length)
  }

  if (!buildData || Object.keys(buildData).length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-500">No timeline data available</p>
      </div>
    )
  }

  return (
    <div>
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Build Timeline</h3>

      {/* Summary Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div className="p-4 bg-gray-50 rounded-lg border border-gray-200">
          <p className="text-xs text-gray-600 mb-1">Total Iterations</p>
          <p className="text-2xl font-bold text-gray-900">
            {iterations_used} <span className="text-sm text-gray-500">/ {iterations_max}</span>
          </p>
        </div>
        <div className="p-4 bg-gray-50 rounded-lg border border-gray-200">
          <p className="text-xs text-gray-600 mb-1">Progress</p>
          <p className="text-2xl font-bold text-gray-900">{progressPercentage}%</p>
        </div>
        <div className="p-4 bg-gray-50 rounded-lg border border-gray-200">
          <p className="text-xs text-gray-600 mb-1">Checkpoints</p>
          <p className="text-2xl font-bold text-gray-900">{checkpoints_triggered}</p>
        </div>
        <div className="p-4 bg-gray-50 rounded-lg border border-gray-200">
          <p className="text-xs text-gray-600 mb-1">Duration</p>
          <p className="text-2xl font-bold text-gray-900">
            {build_duration_minutes > 60
              ? `${Math.floor(build_duration_minutes / 60)}h ${build_duration_minutes % 60}m`
              : `${build_duration_minutes}m`
            }
          </p>
        </div>
      </div>

      {/* Timeline Visualization */}
      <div className="mb-6">
        <div className="flex items-center mb-2">
          <span className="text-sm font-medium text-gray-700">Phase Progress</span>
        </div>

        {/* Gantt-style Phase Bar */}
        <div className="flex h-12 rounded-lg overflow-hidden border border-gray-200">
          {phasesData.map((phase, index) => (
            <div
              key={index}
              className={`${getStatusColor(phase.status)} flex items-center justify-center text-white text-xs font-semibold px-2 border-r border-white last:border-r-0`}
              style={{ width: `${calculatePhaseWidth(phase)}%` }}
              title={`Phase ${phase.phase}: ${phase.name} (${phase.iterations_end - phase.iterations_start + 1} iterations)`}
            >
              <span className="truncate">P{phase.phase}</span>
            </div>
          ))}
        </div>

        {/* Legend */}
        <div className="flex flex-wrap gap-4 mt-3 text-xs text-gray-600">
          <div className="flex items-center">
            <div className="w-3 h-3 bg-green-500 rounded mr-2"></div>
            <span>Completed</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-blue-500 rounded mr-2"></div>
            <span>In Progress</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-red-500 rounded mr-2"></div>
            <span>Failed</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-gray-300 rounded mr-2"></div>
            <span>Pending</span>
          </div>
        </div>
      </div>

      {/* Detailed Phase List */}
      <div className="space-y-4">
        {phasesData.map((phase, index) => (
          <div
            key={index}
            className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
          >
            <div className="flex items-start justify-between">
              <div className="flex items-start space-x-3 flex-1">
                <div className="mt-0.5">
                  {getStatusIcon(phase.status)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-1">
                    <h4 className="text-sm font-semibold text-gray-900">
                      Phase {phase.phase}: {phase.name}
                    </h4>
                    <span className={`px-2 py-1 text-xs font-medium rounded ${
                      phase.status === 'completed' ? 'bg-green-100 text-green-800' :
                      phase.status === 'in_progress' ? 'bg-blue-100 text-blue-800' :
                      phase.status === 'failed' ? 'bg-red-100 text-red-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {phase.status.replace('_', ' ').toUpperCase()}
                    </span>
                  </div>

                  <div className="flex flex-wrap gap-4 text-xs text-gray-600 mt-2">
                    <span>Iterations: {phase.iterations_start}-{phase.iterations_end}</span>
                    <span>Tasks: {phase.tasks_completed}/{phase.tasks_total}</span>
                    <span className="font-medium text-indigo-600">
                      CHECKPOINT: {phase.checkpoint}
                    </span>
                  </div>

                  {/* Technical View: Show individual iterations */}
                  {viewMode === 'technical' && phase.iterations && (
                    <div className="mt-3 p-3 bg-gray-50 rounded border border-gray-200">
                      <p className="text-xs font-semibold text-gray-700 mb-2">Individual Iterations:</p>
                      <div className="flex flex-wrap gap-2">
                        {phase.iterations.map((iter, iterIndex) => (
                          <div
                            key={iterIndex}
                            className={`px-2 py-1 text-xs rounded ${
                              iter.status === 'success' ? 'bg-green-100 text-green-800' :
                              iter.status === 'failure' ? 'bg-red-100 text-red-800' :
                              'bg-gray-100 text-gray-800'
                            }`}
                            title={iter.task || 'Iteration ' + iter.number}
                          >
                            #{iter.number}
                            {iter.retry && <span className="ml-1 text-yellow-600">↻</span>}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Warnings/Issues Section */}
      {(rabbit_holes_detected > 0 || checkpoints_triggered > 0) && (
        <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
          <h4 className="text-sm font-semibold text-yellow-900 mb-2 flex items-center">
            <AlertCircle className="w-4 h-4 mr-2" />
            Build Issues Detected
          </h4>
          <div className="text-sm text-yellow-800 space-y-1">
            {checkpoints_triggered > 0 && (
              <p>• {checkpoints_triggered} checkpoint(s) triggered during build</p>
            )}
            {rabbit_holes_detected > 0 && (
              <p>• {rabbit_holes_detected} rabbit hole(s) detected and avoided</p>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
