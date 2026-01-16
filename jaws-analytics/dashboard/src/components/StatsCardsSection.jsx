import React from 'react'
import StatsCard from './StatsCard'
import { Workflow, Database, Cpu, CheckCircle } from 'lucide-react'

/**
 * StatsCardsSection displays key metrics at a glance
 *
 * @param {object} data - Build analytics data containing metrics
 */
export default function StatsCardsSection({ data }) {
  // Extract metrics from data (with fallbacks for missing data)
  const workflowsCreated = data?.workflows_created || 0
  const tablesCreated = data?.tables_created || 0
  const estimatedTokensPerRun = data?.estimated_tokens_per_run || 0

  // Calculate completion rate
  const tasksTotal = data?.tasks_total || 0
  const tasksCompleted = data?.tasks_completed || 0
  const completionRate = tasksTotal > 0
    ? Math.round((tasksCompleted / tasksTotal) * 100)
    : 0

  // Format large numbers (e.g., 150000 -> "150K")
  const formatNumber = (num) => {
    if (num >= 1000000) {
      return `${(num / 1000000).toFixed(1)}M`
    }
    if (num >= 1000) {
      return `${(num / 1000).toFixed(1)}K`
    }
    return num.toString()
  }

  return (
    <div className="mb-8">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Key Metrics</h3>

      {/* Grid layout: 4 cards per row on desktop, 2 on tablet, 1 on mobile */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatsCard
          value={workflowsCreated}
          label="Workflows Created"
          icon={Workflow}
        />

        <StatsCard
          value={tablesCreated}
          label="Tables Created"
          icon={Database}
        />

        <StatsCard
          value={formatNumber(estimatedTokensPerRun)}
          label="Est. Tokens/Run"
          icon={Cpu}
        />

        <StatsCard
          value={`${completionRate}%`}
          label="Completion Rate"
          icon={CheckCircle}
        />
      </div>
    </div>
  )
}
