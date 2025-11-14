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

import {act, waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {useWidgetConfig} from '../useWidgetConfig'
import {WidgetDashboardProvider} from '../useWidgetDashboardContext'

const server = setupServer(
  graphql.mutation('UpdateWidgetDashboardConfig', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateWidgetDashboardConfig: {
          widgetId: variables.widgetId,
          filters: variables.filters,
          errors: null,
        },
      },
    })
  }),
)

describe('useWidgetConfig', () => {
  let queryClient: QueryClient

  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
        mutations: {retry: false},
      },
    })
  })

  afterEach(() => {
    server.resetHandlers()
  })

  const createWrapper =
    (widgetConfig?: Record<string, Record<string, unknown>>) =>
    ({children}: {children: React.ReactNode}) => {
      const preferences = widgetConfig
        ? {
            dashboard_view: 'cards',
            hide_dashcard_color_overlays: false,
            custom_colors: {},
            widget_dashboard_config: {filters: widgetConfig},
          }
        : undefined

      return (
        <QueryClientProvider client={queryClient}>
          <WidgetDashboardProvider preferences={preferences}>{children}</WidgetDashboardProvider>
        </QueryClientProvider>
      )
    }

  it('initializes with default value when no initial config provided', () => {
    const {result} = renderHook(() => useWidgetConfig('test-widget', 'testKey', 'defaultValue'), {
      wrapper: createWrapper(),
    })

    expect(result.current[0]).toBe('defaultValue')
  })

  it('initializes with value from initial config when provided', () => {
    const {result} = renderHook(() => useWidgetConfig('test-widget', 'testKey', 'defaultValue'), {
      wrapper: createWrapper({'test-widget': {testKey: 'savedValue'}}),
    })

    expect(result.current[0]).toBe('savedValue')
  })

  it('updates config value and calls mutation', async () => {
    const {result} = renderHook(() => useWidgetConfig('test-widget', 'testKey', 'defaultValue'), {
      wrapper: createWrapper(),
    })

    act(() => {
      result.current[1]('newValue')
    })

    expect(result.current[0]).toBe('newValue')

    await waitFor(() => {
      expect(queryClient.getMutationCache().getAll()).toHaveLength(1)
    })
  })

  it('preserves existing config when updating', async () => {
    const {result} = renderHook(() => useWidgetConfig('test-widget', 'newKey', 'defaultValue'), {
      wrapper: createWrapper({'test-widget': {existingKey: 'existingValue'}}),
    })

    act(() => {
      result.current[1]('newValue')
    })

    await waitFor(() => {
      expect(queryClient.getMutationCache().getAll()).toHaveLength(1)
    })
  })

  it('handles mutation errors gracefully', async () => {
    server.use(
      graphql.mutation('UpdateWidgetDashboardConfig', () => {
        return HttpResponse.json({
          errors: [{message: 'Network error'}],
        })
      }),
    )

    const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => {})

    const {result} = renderHook(() => useWidgetConfig('test-widget', 'testKey', 'defaultValue'), {
      wrapper: createWrapper(),
    })

    act(() => {
      result.current[1]('newValue')
    })

    await waitFor(() => {
      expect(consoleErrorSpy).toHaveBeenCalledWith(
        'Failed to save widget config preference:',
        expect.anything(),
      )
    })

    expect(result.current[0]).toBe('newValue')
    consoleErrorSpy.mockRestore()
  })

  it('transforms existing selectedCourse value when updating other config keys for course work widgets', async () => {
    let capturedVariables: any = null
    server.use(
      graphql.mutation('UpdateWidgetDashboardConfig', ({variables}) => {
        capturedVariables = variables
        return HttpResponse.json({
          data: {
            updateWidgetDashboardConfig: {
              widgetId: variables.widgetId,
              filters: variables.filters,
              errors: null,
            },
          },
        })
      }),
    )

    const {result} = renderHook(
      () => useWidgetConfig('course-work-combined-widget', 'selectedDateFilter', 'all'),
      {
        wrapper: createWrapper({'course-work-combined-widget': {selectedCourse: '44'}}),
      },
    )

    act(() => {
      result.current[1]('next14days')
    })

    await waitFor(() => {
      expect(capturedVariables).not.toBeNull()
      expect(capturedVariables.filters.selectedCourse).toBe('course_44')
      expect(capturedVariables.filters.selectedDateFilter).toBe('next14days')
    })
  })

  it('does not modify selectedCourse if it already has course_ prefix', async () => {
    let capturedVariables: any = null
    server.use(
      graphql.mutation('UpdateWidgetDashboardConfig', ({variables}) => {
        capturedVariables = variables
        return HttpResponse.json({
          data: {
            updateWidgetDashboardConfig: {
              widgetId: variables.widgetId,
              filters: variables.filters,
              errors: null,
            },
          },
        })
      }),
    )

    const {result} = renderHook(
      () => useWidgetConfig('course-work-combined-widget', 'selectedDateFilter', 'all'),
      {
        wrapper: createWrapper({'course-work-combined-widget': {selectedCourse: 'course_44'}}),
      },
    )

    act(() => {
      result.current[1]('next14days')
    })

    await waitFor(() => {
      expect(capturedVariables).not.toBeNull()
      expect(capturedVariables.filters.selectedCourse).toBe('course_44')
      expect(capturedVariables.filters.selectedDateFilter).toBe('next14days')
    })
  })

  it('does not modify selectedCourse if value is "all"', async () => {
    let capturedVariables: any = null
    server.use(
      graphql.mutation('UpdateWidgetDashboardConfig', ({variables}) => {
        capturedVariables = variables
        return HttpResponse.json({
          data: {
            updateWidgetDashboardConfig: {
              widgetId: variables.widgetId,
              filters: variables.filters,
              errors: null,
            },
          },
        })
      }),
    )

    const {result} = renderHook(
      () => useWidgetConfig('course-work-combined-widget', 'selectedDateFilter', 'all'),
      {
        wrapper: createWrapper({'course-work-combined-widget': {selectedCourse: 'all'}}),
      },
    )

    act(() => {
      result.current[1]('next14days')
    })

    await waitFor(() => {
      expect(capturedVariables).not.toBeNull()
      expect(capturedVariables.filters.selectedCourse).toBe('all')
      expect(capturedVariables.filters.selectedDateFilter).toBe('next14days')
    })
  })
})
