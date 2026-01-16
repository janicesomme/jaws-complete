import React from 'react'
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts'

/**
 * TokenUsageChart component displays token usage breakdown as a donut chart
 * Shows token distribution by workflow with tooltips and monthly cost projection
 *
 * @param {Array} workflows - Array of workflow objects with workflow_name and estimated_tokens
 * @param {number} monthlyRuns - Estimated number of runs per month (default: 30)
 * @param {number} costPerMillion - Cost per million tokens in dollars (default: 3 for input)
 */
export default function TokenUsageChart({ workflows = [], monthlyRuns = 30, costPerMillion = 3 }) {
  // Transform workflow data for chart
  const chartData = workflows
    .filter(w => w.estimated_tokens > 0)
    .map(w => ({
      name: w.workflow_name,
      tokens: w.estimated_tokens,
      percentage: 0 // Will be calculated below
    }))

  // Calculate total tokens and percentages
  const totalTokens = chartData.reduce((sum, item) => sum + item.tokens, 0)
  chartData.forEach(item => {
    item.percentage = ((item.tokens / totalTokens) * 100).toFixed(1)
  })

  // Calculate monthly cost projection
  const tokensPerRun = totalTokens
  const tokensPerMonth = tokensPerRun * monthlyRuns
  const monthlyCost = (tokensPerMonth / 1000000) * costPerMillion

  // Color palette for chart segments
  const COLORS = [
    '#4F46E5', // Indigo
    '#10B981', // Green
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#84CC16'  // Lime
  ]

  // Custom tooltip
  const CustomTooltip = ({ active, payload }) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      return (
        <div className="bg-white p-3 border border-gray-200 rounded-lg shadow-lg">
          <p className="text-sm font-semibold text-gray-900">{data.name}</p>
          <p className="text-sm text-gray-600 mt-1">
            Tokens: {data.tokens.toLocaleString()}
          </p>
          <p className="text-sm text-gray-600">
            Percentage: {data.percentage}%
          </p>
        </div>
      )
    }
    return null
  }

  // Custom legend
  const CustomLegend = ({ payload }) => {
    return (
      <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-2">
        {payload.map((entry, index) => (
          <div key={`legend-${index}`} className="flex items-center">
            <div
              className="w-3 h-3 rounded-full mr-2"
              style={{ backgroundColor: entry.color }}
            />
            <span className="text-sm text-gray-700 truncate" title={entry.value}>
              {entry.value}
            </span>
          </div>
        ))}
      </div>
    )
  }

  if (chartData.length === 0) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-500">No token usage data available</p>
      </div>
    )
  }

  return (
    <div>
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Token Usage Distribution</h3>

      {/* Donut Chart */}
      <ResponsiveContainer width="100%" height={400}>
        <PieChart>
          <Pie
            data={chartData}
            dataKey="tokens"
            nameKey="name"
            cx="50%"
            cy="50%"
            innerRadius={80}
            outerRadius={140}
            paddingAngle={2}
            label={({ percentage }) => `${percentage}%`}
          >
            {chartData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip content={<CustomTooltip />} />
          <Legend content={<CustomLegend />} />
        </PieChart>
      </ResponsiveContainer>

      {/* Monthly Cost Projection */}
      <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
        <h4 className="text-sm font-semibold text-blue-900 mb-2">Monthly Cost Projection</h4>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <p className="text-xs text-blue-700">Tokens per Run</p>
            <p className="text-lg font-bold text-blue-900">{tokensPerRun.toLocaleString()}</p>
          </div>
          <div>
            <p className="text-xs text-blue-700">Estimated Runs/Month</p>
            <p className="text-lg font-bold text-blue-900">{monthlyRuns}</p>
          </div>
          <div>
            <p className="text-xs text-blue-700">Monthly Cost</p>
            <p className="text-lg font-bold text-blue-900">${monthlyCost.toFixed(2)}</p>
          </div>
        </div>
        <p className="text-xs text-blue-600 mt-3">
          Based on ${costPerMillion}/million tokens ({tokensPerMonth.toLocaleString()} tokens/month)
        </p>
      </div>
    </div>
  )
}
