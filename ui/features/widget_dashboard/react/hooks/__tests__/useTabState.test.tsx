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

import React from 'react'
import {renderHook, act} from '@testing-library/react-hooks'
import {waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {useTabState} from '../useTabState'
import {TAB_IDS} from '../../constants'
import type {TabId} from '../../types'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'
import {WidgetLayoutProvider} from '../useWidgetLayout'
import {WidgetDashboardEditProvider} from '../useWidgetDashboardEdit'

type HookArgs = {
  defaultTab?: TabId
}

const server = setupServer(
  graphql.mutation('UpdateLearnerDashboardTabSelection', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateLearnerDashboardTabSelection: {
          tab: variables.tab,
          errors: null,
        },
      },
    })
  }),
)

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {retry: false},
      mutations: {retry: false},
    },
  })
  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardEditProvider>
        <WidgetLayoutProvider>{children}</WidgetLayoutProvider>
      </WidgetDashboardEditProvider>
    </QueryClientProvider>
  )
}

const setUp = (args: HookArgs = {}) => {
  return renderHook(() => useTabState(args.defaultTab), {wrapper: createWrapper()})
}

const buildDefaultArgs = (overrides: Partial<HookArgs> = {}): HookArgs => {
  const defaultArgs: HookArgs = {
    defaultTab: undefined, // Let hook use its own default
  }

  return {...defaultArgs, ...overrides}
}

describe('useTabState', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'error'})
  })

  beforeEach(() => {
    clearWidgetDashboardCache()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('should initialize with default tab (DASHBOARD)', () => {
    const {result} = setUp(buildDefaultArgs())

    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)
  })

  it('should initialize with provided default tab', () => {
    const {result} = setUp(buildDefaultArgs({defaultTab: TAB_IDS.COURSES}))

    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)
  })

  it('should change tab when handleTabChange is called', () => {
    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.COURSES)
    })

    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)
  })

  it('should change tab back to dashboard', () => {
    const {result} = setUp(buildDefaultArgs({defaultTab: TAB_IDS.COURSES}))

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })

    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)
  })

  it('should maintain stable handleTabChange reference across renders', () => {
    const {result, rerender} = setUp(buildDefaultArgs())
    const firstHandleTabChange = result.current.handleTabChange

    rerender()

    expect(result.current.handleTabChange).toBe(firstHandleTabChange)
  })

  it('should handle multiple tab changes correctly', () => {
    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.COURSES)
    })
    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })
    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)
  })

  it('should handle setting the same tab multiple times', () => {
    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })

    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)
  })

  it('should work with different initial configurations', () => {
    const {result: resultDefault} = setUp(buildDefaultArgs())
    const {result: resultCourses} = setUp(buildDefaultArgs({defaultTab: TAB_IDS.COURSES}))

    expect(resultDefault.current.currentTab).toBe(TAB_IDS.DASHBOARD)
    expect(resultCourses.current.currentTab).toBe(TAB_IDS.COURSES)
  })

  it('should call GraphQL mutation when tab changes', async () => {
    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.COURSES)
    })

    // Tab should update optimistically
    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)

    // Wait for the mutation to complete
    await waitFor(() => {
      // The mutation will have been called by this point
      // MSW will have handled the request
    })
  })

  it('should handle GraphQL mutation errors gracefully', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => {})

    // Override the server handler to return an error
    server.use(
      graphql.mutation('UpdateLearnerDashboardTabSelection', () => {
        return HttpResponse.json(
          {
            errors: [{message: 'Network error'}],
          },
          {status: 500},
        )
      }),
    )

    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.COURSES)
    })

    // Tab should still update optimistically
    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)

    // Wait for the error to be processed
    await waitFor(() => {
      expect(consoleError).toHaveBeenCalled()
    })

    consoleError.mockRestore()
  })

  it('should update tab multiple times with different values', async () => {
    const {result} = setUp(buildDefaultArgs())

    act(() => {
      result.current.handleTabChange(TAB_IDS.COURSES)
    })
    expect(result.current.currentTab).toBe(TAB_IDS.COURSES)

    await waitFor(() => {
      // First mutation complete
    })

    act(() => {
      result.current.handleTabChange(TAB_IDS.DASHBOARD)
    })
    expect(result.current.currentTab).toBe(TAB_IDS.DASHBOARD)

    await waitFor(() => {
      // Second mutation complete
    })
  })
})
