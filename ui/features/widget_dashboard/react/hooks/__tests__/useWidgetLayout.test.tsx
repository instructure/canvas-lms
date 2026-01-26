/*
 * Copyright (C) 2025 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {act} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import React from 'react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {WidgetLayoutProvider, useWidgetLayout} from '../useWidgetLayout'
import {WidgetDashboardEditProvider} from '../useWidgetDashboardEdit'
import {WidgetDashboardProvider} from '../useWidgetDashboardContext'

const server = setupServer()

beforeAll(() => {
  server.listen({onUnhandledRequest: 'warn'})
})

afterAll(() => {
  server.close()
})

afterEach(() => {
  server.resetHandlers()
})

const createWrapper = ({children}: {children: React.ReactNode}) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {retry: false},
      mutations: {retry: false},
    },
  })

  return (
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider>
        <WidgetDashboardEditProvider>
          <WidgetLayoutProvider>{children}</WidgetLayoutProvider>
        </WidgetDashboardEditProvider>
      </WidgetDashboardProvider>
    </QueryClientProvider>
  )
}

describe('useWidgetLayout', () => {
  describe('removeWidget', () => {
    it('removes widget from config', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const initialWidgetCount = result.current.config.widgets.length
      const widgetToRemove = result.current.config.widgets[0]

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      expect(result.current.config.widgets).toHaveLength(initialWidgetCount - 1)
      expect(result.current.config.widgets.find(w => w.id === widgetToRemove.id)).toBeUndefined()
    })

    it('recalculates positions after removing widget', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widgetToRemove = result.current.config.widgets[0]
      const column = widgetToRemove.position.col

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      const remainingWidgetsInColumn = result.current.config.widgets.filter(
        w => w.position.col === column,
      )

      remainingWidgetsInColumn.forEach((widget, index) => {
        expect(widget.position.row).toBe(index + 1)
      })
    })

    it('recalculates relative positions after removing widget', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widgetToRemove = result.current.config.widgets[0]

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      result.current.config.widgets.forEach((widget, index) => {
        expect(widget.position.relative).toBe(index + 1)
      })
    })

    it('handles removing non-existent widget gracefully', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const initialWidgetCount = result.current.config.widgets.length

      act(() => {
        result.current.removeWidget('non-existent-widget-id')
      })

      expect(result.current.config.widgets).toHaveLength(initialWidgetCount)
    })

    it('can remove all widgets', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widgetIds = result.current.config.widgets.map(w => w.id)

      act(() => {
        widgetIds.forEach(id => {
          result.current.removeWidget(id)
        })
      })

      expect(result.current.config.widgets).toHaveLength(0)
    })

    it('removes widget from left column and normalizes remaining widgets', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const leftColumnWidgets = result.current.config.widgets.filter(w => w.position.col === 1)
      const widgetToRemove = leftColumnWidgets[0]

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      const remainingLeftColumnWidgets = result.current.config.widgets.filter(
        w => w.position.col === 1,
      )
      expect(remainingLeftColumnWidgets).toHaveLength(leftColumnWidgets.length - 1)
    })

    it('removes widget from right column and normalizes remaining widgets', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const rightColumnWidgets = result.current.config.widgets.filter(w => w.position.col === 2)
      if (rightColumnWidgets.length === 0) {
        return
      }

      const widgetToRemove = rightColumnWidgets[0]

      act(() => {
        result.current.removeWidget(widgetToRemove.id)
      })

      const remainingRightColumnWidgets = result.current.config.widgets.filter(
        w => w.position.col === 2,
      )
      expect(remainingRightColumnWidgets).toHaveLength(rightColumnWidgets.length - 1)
    })
  })

  describe('moveWidgetToPosition', () => {
    it('moves widget to new position in same column', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widget = result.current.config.widgets[0]
      const targetCol = widget.position.col
      const targetRow = 3

      act(() => {
        result.current.moveWidgetToPosition(widget.id, targetCol, targetRow)
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)
      expect(movedWidget?.position.col).toBe(targetCol)
    })

    it('moves widget to different column', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 1)
      if (!widget) return

      act(() => {
        result.current.moveWidgetToPosition(widget.id, 2, 1)
      })

      const movedWidget = result.current.config.widgets.find(w => w.id === widget.id)
      expect(movedWidget?.position.col).toBe(2)
    })

    it('shifts widgets down when inserting at specific position', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widget = result.current.config.widgets.find(w => w.position.col === 1)
      if (!widget) return

      const col2WidgetsBefore = result.current.config.widgets.filter(w => w.position.col === 2)

      act(() => {
        result.current.moveWidgetToPosition(widget.id, 2, 1)
      })

      const col2WidgetsAfter = result.current.config.widgets.filter(w => w.position.col === 2)
      expect(col2WidgetsAfter).toHaveLength(col2WidgetsBefore.length + 1)

      const widgetsAtOrAfterRow1 = col2WidgetsAfter.filter(w => w.position.row >= 1)
      expect(widgetsAtOrAfterRow1.length).toBeGreaterThan(0)
    })

    it('normalizes row numbers after move', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widget = result.current.config.widgets[0]

      act(() => {
        result.current.moveWidgetToPosition(widget.id, widget.position.col, 10)
      })

      const colWidgets = result.current.config.widgets
        .filter(w => w.position.col === widget.position.col)
        .sort((a, b) => a.position.row - b.position.row)

      colWidgets.forEach((w, index) => {
        expect(w.position.row).toBe(index + 1)
      })
    })

    it('recalculates relative positions after move', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widget = result.current.config.widgets[0]

      act(() => {
        result.current.moveWidgetToPosition(widget.id, 2, 1)
      })

      result.current.config.widgets.forEach((w, index) => {
        expect(w.position.relative).toBeGreaterThan(0)
      })
    })

    it('handles moving non-existent widget gracefully', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const initialConfig = JSON.stringify(result.current.config)

      act(() => {
        result.current.moveWidgetToPosition('non-existent-widget', 1, 1)
      })

      expect(JSON.stringify(result.current.config)).toBe(initialConfig)
    })
  })

  describe('addWidget', () => {
    it('adds widget to config with correct properties', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const initialWidgetCount = result.current.config.widgets.length

      act(() => {
        result.current.addWidget('course_work_summary', "Today's course work", 1, 2)
      })

      expect(result.current.config.widgets).toHaveLength(initialWidgetCount + 1)

      const addedWidget = result.current.config.widgets.find(w =>
        w.id.startsWith('course_work_summary-widget-'),
      )

      expect(addedWidget).toBeDefined()
      expect(addedWidget?.type).toBe('course_work_summary')
      expect(addedWidget?.position.col).toBe(1)
      expect(addedWidget?.title).toBe("Today's course work")
    })

    it('generates unique IDs for widgets', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const initialCount = result.current.config.widgets.length

      act(() => {
        result.current.addWidget('course_work_summary', 'Course Work Summary', 1, 1)
        result.current.addWidget('announcements', 'Announcements', 1, 2)
      })

      expect(result.current.config.widgets).toHaveLength(initialCount + 2)

      const addedWidgets = result.current.config.widgets.slice(initialCount)
      const firstId = addedWidgets[0]?.id
      const secondId = addedWidgets[1]?.id

      expect(firstId).toBeDefined()
      expect(secondId).toBeDefined()
      expect(firstId).not.toBe(secondId)
    })

    it('normalizes row numbers after adding widget', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      act(() => {
        result.current.addWidget('course_work_summary', 'Course Work Summary', 1, 1)
      })

      const widgetsInColumn1 = result.current.config.widgets.filter(w => w.position.col === 1)

      widgetsInColumn1.forEach((widget, index) => {
        expect(widget.position.row).toBe(index + 1)
      })
    })

    it('recalculates relative positions after adding widget', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      act(() => {
        result.current.addWidget('course_work_summary', 'Course Work Summary', 1, 1)
      })

      result.current.config.widgets.forEach((widget, index) => {
        expect(widget.position.relative).toBe(index + 1)
      })
    })

    it('can add widgets to different columns', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      act(() => {
        result.current.addWidget('course_work_summary', 'Course Work Summary', 1, 1)
        result.current.addWidget('announcements', 'Announcements', 2, 1)
      })

      const col1Widgets = result.current.config.widgets.filter(w => w.position.col === 1)
      const col2Widgets = result.current.config.widgets.filter(w => w.position.col === 2)

      const addedToCol1 = col1Widgets.find(w => w.id.startsWith('course_work_summary-widget-'))
      const addedToCol2 = col2Widgets.find(w => w.id.startsWith('announcements-widget-'))

      expect(addedToCol1).toBeDefined()
      expect(addedToCol2).toBeDefined()
    })
  })

  describe('resetConfig', () => {
    it('resets config to default when no saved config exists', () => {
      const {result} = renderHook(() => useWidgetLayout(), {wrapper: createWrapper})

      const widget = result.current.config.widgets[0]
      act(() => {
        result.current.removeWidget(widget.id)
      })

      const modifiedCount = result.current.config.widgets.length

      act(() => {
        result.current.resetConfig()
      })

      expect(result.current.config.widgets).toHaveLength(modifiedCount + 1)
    })

    it('should revert to saved config instead of default when user has custom layout', () => {
      const savedConfig = {
        columns: 2,
        widgets: [
          {
            id: 'custom-saved-widget',
            type: 'announcements',
            position: {col: 1, row: 1, relative: 1},
            title: 'My Saved Widget',
          },
        ],
      }

      const createWrapperWithSavedConfig = ({children}: {children: React.ReactNode}) => {
        const queryClient = new QueryClient({
          defaultOptions: {
            queries: {retry: false},
            mutations: {retry: false},
          },
        })

        return (
          <QueryClientProvider client={queryClient}>
            <WidgetDashboardProvider
              preferences={{
                dashboard_view: 'cards',
                hide_dashcard_color_overlays: false,
                custom_colors: {},
                widget_dashboard_config: {
                  layout: savedConfig,
                },
              }}
            >
              <WidgetDashboardEditProvider>
                <WidgetLayoutProvider>{children}</WidgetLayoutProvider>
              </WidgetDashboardEditProvider>
            </WidgetDashboardProvider>
          </QueryClientProvider>
        )
      }

      const {result} = renderHook(() => useWidgetLayout(), {
        wrapper: createWrapperWithSavedConfig,
      })

      expect(result.current.config.widgets).toHaveLength(1)
      expect(result.current.config.widgets[0].id).toBe('custom-saved-widget')

      act(() => {
        result.current.addWidget('course_grades', 'Grades', 1, 2)
      })

      expect(result.current.config.widgets).toHaveLength(2)

      act(() => {
        result.current.resetConfig()
      })

      expect(result.current.config.widgets).toHaveLength(1)
      expect(result.current.config.widgets[0].id).toBe('custom-saved-widget')
    })

    it('should revert to most recently saved config after multiple save/cancel cycles', async () => {
      server.use(
        graphql.mutation('UpdateWidgetDashboardLayout', () => {
          return HttpResponse.json({
            data: {
              updateWidgetDashboardLayout: {
                layout: null,
                errors: null,
              },
            },
          })
        }),
      )

      const initialConfig = {
        columns: 2,
        widgets: [
          {
            id: 'initial-widget',
            type: 'announcements',
            position: {col: 1, row: 1, relative: 1},
            title: 'Initial Widget',
          },
        ],
      }

      const createWrapperWithInitialConfig = ({children}: {children: React.ReactNode}) => {
        const queryClient = new QueryClient({
          defaultOptions: {
            queries: {retry: false},
            mutations: {retry: false},
          },
        })

        return (
          <QueryClientProvider client={queryClient}>
            <WidgetDashboardProvider
              preferences={{
                dashboard_view: 'cards',
                hide_dashcard_color_overlays: false,
                custom_colors: {},
                widget_dashboard_config: {
                  layout: initialConfig,
                },
              }}
            >
              <WidgetDashboardEditProvider>
                <WidgetLayoutProvider>{children}</WidgetLayoutProvider>
              </WidgetDashboardEditProvider>
            </WidgetDashboardProvider>
          </QueryClientProvider>
        )
      }

      const {result} = renderHook(() => useWidgetLayout(), {
        wrapper: createWrapperWithInitialConfig,
      })

      expect(result.current.config.widgets).toHaveLength(1)
      expect(result.current.config.widgets[0].id).toBe('initial-widget')

      act(() => {
        result.current.addWidget('course_grades', 'Grades', 1, 2)
      })

      expect(result.current.config.widgets).toHaveLength(2)

      await act(async () => {
        await result.current.saveLayout()
      })

      act(() => {
        result.current.addWidget('people', 'People', 2, 1)
      })

      expect(result.current.config.widgets).toHaveLength(3)

      act(() => {
        result.current.resetConfig()
      })

      expect(result.current.config.widgets).toHaveLength(2)
      expect(result.current.config.widgets.some(w => w.id === 'initial-widget')).toBe(true)
      expect(result.current.config.widgets.some(w => w.type === 'course_grades')).toBe(true)
      expect(result.current.config.widgets.some(w => w.type === 'people')).toBe(false)
    })
  })
})
