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

import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import {useProgressOverview} from '../useProgressOverview'
import {WidgetDashboardProvider} from '../useWidgetDashboardContext'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'

const mockProgressData = [
  {
    course: {
      _id: '1',
      name: 'Environmental Science',
      courseCode: 'ENVS150',
      submissionStatistics: {
        submittedAndGradedCount: 8,
        submittedNotGradedCount: 2,
        missingSubmissionsCount: 1,
        submissionsDueCount: 3,
      },
    },
  },
  {
    course: {
      _id: '2',
      name: 'Calculus II',
      courseCode: 'MATH201',
      submissionStatistics: {
        submittedAndGradedCount: 5,
        submittedNotGradedCount: 1,
        missingSubmissionsCount: 2,
        submissionsDueCount: 4,
      },
    },
  },
]

const mockGqlResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollmentsConnection: {
        nodes: mockProgressData,
      },
    },
  },
}

const setup = (envOverrides = {}, dashboardProps = {}) => {
  const originalEnv = window.ENV
  window.ENV = {
    ...originalEnv,
    current_user_id: '123',
    ...envOverrides,
  }

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  const result = renderHook(() => useProgressOverview(), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>
        <WidgetDashboardProvider {...dashboardProps}>{children}</WidgetDashboardProvider>
      </QueryClientProvider>
    ),
  })

  return {
    ...result,
    queryClient,
    cleanup: () => {
      window.ENV = originalEnv
      result.unmount()
    },
  }
}

const server = setupServer(
  graphql.query('GetUserProgressOverview', () => {
    return HttpResponse.json(mockGqlResponse)
  }),
)

beforeAll(() => server.listen())
afterEach(() => {
  server.resetHandlers()
  clearWidgetDashboardCache()
})
afterAll(() => server.close())

describe('useProgressOverview', () => {
  it('fetches and returns progress overview data', async () => {
    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data).toHaveLength(2)
    expect(result.current.data?.[0]).toEqual({
      courseId: '1',
      courseName: 'Environmental Science',
      courseCode: 'ENVS150',
      submittedAndGradedCount: 8,
      submittedNotGradedCount: 2,
      missingSubmissionsCount: 1,
      submissionsDueCount: 3,
    })

    cleanup()
  })

  it('handles empty enrollments', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: [],
              },
            },
          },
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data).toEqual([])

    cleanup()
  })

  it('filters out courses with null submissionStatistics', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: [
                  mockProgressData[0],
                  {
                    course: {
                      _id: '3',
                      name: 'Course Without Stats',
                      courseCode: 'TEST303',
                      submissionStatistics: null,
                    },
                  },
                ],
              },
            },
          },
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data).toHaveLength(1)
    expect(result.current.data?.[0].courseId).toBe('1')

    cleanup()
  })

  it('handles errors', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({errors: [{message: 'Failed to fetch'}]}, {status: 500})
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
    })

    expect(result.current.error).toBeTruthy()

    cleanup()
  })

  it('supports observer mode', async () => {
    const observedUserId = '456'

    server.use(
      graphql.query('GetUserProgressOverview', ({variables}) => {
        expect(variables.observedUserId).toBe(observedUserId)
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup({}, {observedUserId})

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data).toHaveLength(2)

    cleanup()
  })

  it('defaults count fields to 0 when missing', async () => {
    server.use(
      graphql.query('GetUserProgressOverview', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: [
                  {
                    course: {
                      _id: '1',
                      name: 'Test Course',
                      courseCode: 'TEST101',
                      submissionStatistics: {},
                    },
                  },
                ],
              },
            },
          },
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.data?.[0]).toEqual({
      courseId: '1',
      courseName: 'Test Course',
      courseCode: 'TEST101',
      submittedAndGradedCount: 0,
      submittedNotGradedCount: 0,
      missingSubmissionsCount: 0,
      submissionsDueCount: 0,
    })

    cleanup()
  })
})
