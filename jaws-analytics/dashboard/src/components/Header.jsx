import React from 'react'
import { Eye, Code, Download } from 'lucide-react'

export default function Header({ viewMode, onViewModeChange, onExportPDF }) {
  return (
    <header className="bg-white border-b border-gray-200 sticky top-0 z-20">
      <div className="px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg flex items-center justify-center">
            <span className="text-white font-bold text-xl">J</span>
          </div>
          <div>
            <h2 className="text-lg font-semibold text-gray-900">
              Analytics Dashboard
            </h2>
            <p className="text-sm text-gray-500">
              Project insights and metrics
            </p>
          </div>
        </div>

        {/* Export and View Toggle */}
        <div className="flex items-center gap-4">
          {/* Export PDF Button */}
          {onExportPDF && (
            <button
              onClick={onExportPDF}
              className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
              title="Export dashboard as PDF"
            >
              <Download size={18} />
              <span className="font-medium text-sm">Export PDF</span>
            </button>
          )}

          {/* View Toggle */}
          <div className="flex items-center gap-2 bg-gray-100 rounded-lg p-1">
          <button
            onClick={() => onViewModeChange('client')}
            className={`
              flex items-center gap-2 px-4 py-2 rounded-md transition-colors
              ${viewMode === 'client'
                ? 'bg-white text-blue-600 shadow-sm'
                : 'text-gray-600 hover:text-gray-900'
              }
            `}
          >
            <Eye size={18} />
            <span className="font-medium text-sm">Client View</span>
          </button>
          <button
            onClick={() => onViewModeChange('technical')}
            className={`
              flex items-center gap-2 px-4 py-2 rounded-md transition-colors
              ${viewMode === 'technical'
                ? 'bg-white text-blue-600 shadow-sm'
                : 'text-gray-600 hover:text-gray-900'
              }
            `}
          >
            <Code size={18} />
            <span className="font-medium text-sm">Technical View</span>
          </button>
          </div>
        </div>
      </div>
    </header>
  )
}
