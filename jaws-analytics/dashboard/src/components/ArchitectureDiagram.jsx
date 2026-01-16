import React, { useEffect, useRef, useState } from 'react'
import mermaid from 'mermaid'
import { AlertCircle, Maximize2, Minimize2 } from 'lucide-react'

/**
 * ArchitectureDiagram renders Mermaid diagrams showing system architecture
 *
 * @param {string} mermaidCode - Mermaid syntax to render
 * @param {string} title - Optional title for the diagram section
 */
export default function ArchitectureDiagram({ mermaidCode, title = 'System Architecture' }) {
  const containerRef = useRef(null)
  const [error, setError] = useState(null)
  const [isExpanded, setIsExpanded] = useState(false)
  const [isRendered, setIsRendered] = useState(false)

  useEffect(() => {
    // Initialize Mermaid with configuration
    mermaid.initialize({
      startOnLoad: false,
      theme: 'default',
      securityLevel: 'loose',
      fontFamily: 'inherit'
    })
  }, [])

  useEffect(() => {
    // Reset state when mermaidCode changes
    setError(null)
    setIsRendered(false)

    if (!mermaidCode || typeof mermaidCode !== 'string' || mermaidCode.trim() === '') {
      setError('No diagram data available')
      return
    }

    const renderDiagram = async () => {
      try {
        if (!containerRef.current) return

        // Clear previous content
        containerRef.current.innerHTML = ''

        // Generate unique ID for this diagram
        const id = `mermaid-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`

        // Render the mermaid diagram
        const { svg } = await mermaid.render(id, mermaidCode)

        if (containerRef.current) {
          containerRef.current.innerHTML = svg
          setIsRendered(true)
        }
      } catch (err) {
        console.error('Mermaid rendering error:', err)
        setError(err.message || 'Failed to render diagram')
        setIsRendered(false)
      }
    }

    renderDiagram()
  }, [mermaidCode])

  const toggleExpanded = () => {
    setIsExpanded(!isExpanded)
  }

  // Fallback to text if rendering fails
  if (error) {
    return (
      <div className="mb-8">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">{title}</h3>
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-start space-x-3 mb-4">
            <AlertCircle className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium text-gray-900">Diagram Unavailable</p>
              <p className="text-sm text-gray-600 mt-1">{error}</p>
            </div>
          </div>
          {mermaidCode && (
            <details className="mt-4">
              <summary className="text-sm font-medium text-gray-700 cursor-pointer hover:text-gray-900">
                View raw diagram code
              </summary>
              <pre className="mt-2 p-4 bg-gray-50 rounded border border-gray-200 text-xs text-gray-800 overflow-x-auto">
                {mermaidCode}
              </pre>
            </details>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="mb-8">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
        {isRendered && (
          <button
            onClick={toggleExpanded}
            className="flex items-center space-x-2 px-3 py-1.5 text-sm font-medium text-gray-700 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
            aria-label={isExpanded ? 'Collapse diagram' : 'Expand diagram'}
          >
            {isExpanded ? (
              <>
                <Minimize2 className="w-4 h-4" />
                <span>Collapse</span>
              </>
            ) : (
              <>
                <Maximize2 className="w-4 h-4" />
                <span>Expand</span>
              </>
            )}
          </button>
        )}
      </div>

      <div
        className={`bg-white rounded-lg border border-gray-200 p-6 transition-all ${
          isExpanded ? 'fixed inset-4 z-50 overflow-auto' : ''
        }`}
      >
        {isExpanded && (
          <div className="flex justify-end mb-4">
            <button
              onClick={toggleExpanded}
              className="px-3 py-1.5 text-sm font-medium text-gray-700 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors"
            >
              Close
            </button>
          </div>
        )}
        <div
          ref={containerRef}
          className={`flex items-center justify-center ${
            isExpanded ? 'min-h-[calc(100vh-12rem)]' : 'min-h-[400px]'
          }`}
        />
        {!isRendered && !error && (
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="text-center">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
              <p className="mt-2 text-sm text-gray-600">Rendering diagram...</p>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
