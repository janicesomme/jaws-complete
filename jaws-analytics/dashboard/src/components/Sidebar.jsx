import React, { useState, useEffect } from 'react'
import { Home, FileText, Menu, X } from 'lucide-react'
import { supabase } from '../lib/supabase'

export default function Sidebar({ activeProject, onProjectSelect }) {
  const [projects, setProjects] = useState([])
  const [loading, setLoading] = useState(true)
  const [isOpen, setIsOpen] = useState(true)
  const [isMobile, setIsMobile] = useState(false)

  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 768)
      if (window.innerWidth < 768) {
        setIsOpen(false)
      }
    }

    checkMobile()
    window.addEventListener('resize', checkMobile)
    return () => window.removeEventListener('resize', checkMobile)
  }, [])

  useEffect(() => {
    fetchProjects()
  }, [])

  const fetchProjects = async () => {
    try {
      const { data, error } = await supabase
        .from('jaws_builds')
        .select('id, project_name, client_name, created_at')
        .order('created_at', { ascending: false })

      if (error) throw error
      setProjects(data || [])
    } catch (error) {
      console.error('Error fetching projects:', error)
    } finally {
      setLoading(false)
    }
  }

  const toggleSidebar = () => {
    setIsOpen(!isOpen)
  }

  return (
    <>
      {/* Mobile menu button */}
      <button
        onClick={toggleSidebar}
        className="md:hidden fixed top-4 left-4 z-50 p-2 rounded-lg bg-white shadow-lg border border-gray-200"
      >
        {isOpen ? <X size={24} /> : <Menu size={24} />}
      </button>

      {/* Overlay for mobile */}
      {isMobile && isOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-30 md:hidden"
          onClick={toggleSidebar}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed md:static inset-y-0 left-0 z-40
          w-64 bg-white border-r border-gray-200
          transform transition-transform duration-200 ease-in-out
          ${isOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}
          ${!isOpen && !isMobile ? 'md:w-0 md:border-0' : ''}
        `}
      >
        <div className="flex flex-col h-full">
          {/* Logo area */}
          <div className="p-6 border-b border-gray-200">
            <h1 className="text-xl font-bold text-gray-900">JAWS Analytics</h1>
            <p className="text-sm text-gray-500 mt-1">Build Dashboard</p>
          </div>

          {/* Navigation */}
          <nav className="flex-1 overflow-y-auto p-4">
            {/* All Projects Link */}
            <button
              onClick={() => onProjectSelect(null)}
              className={`
                w-full flex items-center gap-3 px-4 py-3 rounded-lg mb-2
                transition-colors
                ${!activeProject
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-700 hover:bg-gray-50'
                }
              `}
            >
              <Home size={20} />
              <span className="font-medium">All Projects</span>
            </button>

            {/* Projects List */}
            <div className="mt-6">
              <h3 className="px-4 text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
                Projects
              </h3>

              {loading ? (
                <div className="px-4 py-3 text-sm text-gray-500">
                  Loading projects...
                </div>
              ) : projects.length === 0 ? (
                <div className="px-4 py-3 text-sm text-gray-500">
                  No projects yet
                </div>
              ) : (
                <div className="space-y-1">
                  {projects.map((project) => (
                    <button
                      key={project.id}
                      onClick={() => {
                        onProjectSelect(project.id)
                        if (isMobile) setIsOpen(false)
                      }}
                      className={`
                        w-full flex items-start gap-3 px-4 py-3 rounded-lg
                        transition-colors text-left
                        ${activeProject === project.id
                          ? 'bg-blue-50 text-blue-600'
                          : 'text-gray-700 hover:bg-gray-50'
                        }
                      `}
                    >
                      <FileText size={20} className="mt-0.5 flex-shrink-0" />
                      <div className="min-w-0 flex-1">
                        <div className="font-medium truncate">
                          {project.project_name}
                        </div>
                        {project.client_name && (
                          <div className="text-xs text-gray-500 truncate mt-0.5">
                            {project.client_name}
                          </div>
                        )}
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          </nav>

          {/* Footer */}
          <div className="p-4 border-t border-gray-200">
            <div className="text-xs text-gray-500 text-center">
              JAWS Analytics v1.0
            </div>
          </div>
        </div>
      </aside>
    </>
  )
}
