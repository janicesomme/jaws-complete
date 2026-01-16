import React from 'react'

/**
 * Reusable StatsCard component for displaying key metrics
 *
 * @param {number|string} value - The main metric value to display
 * @param {string} label - The label/description for the metric
 * @param {React.Component} icon - Lucide React icon component
 * @param {object} trend - Optional trend object with direction ('up'|'down') and value
 */
export default function StatsCard({ value, label, icon: Icon, trend }) {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
      {/* Icon and Value Section */}
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600 mb-1">{label}</p>
          <p className="text-3xl font-bold text-gray-900">{value}</p>
        </div>
        {Icon && (
          <div className="flex-shrink-0 p-3 bg-blue-50 rounded-lg">
            <Icon className="w-6 h-6 text-blue-600" />
          </div>
        )}
      </div>

      {/* Optional Trend Indicator */}
      {trend && (
        <div className="mt-4 flex items-center">
          {trend.direction === 'up' ? (
            <svg className="w-4 h-4 text-green-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" />
            </svg>
          ) : (
            <svg className="w-4 h-4 text-red-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
            </svg>
          )}
          <span className={`text-sm font-medium ${trend.direction === 'up' ? 'text-green-600' : 'text-red-600'}`}>
            {trend.value}
          </span>
        </div>
      )}
    </div>
  )
}
