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
import {useCourseWorkStatistics} from '../useCourseWorkStatistics'
import {WidgetDashboardProvider} from '../useWidgetDashboardContext'
import {clearWidgetDashboardCache} from '../../__tests__/testHelpers'

const mockStatisticsData = {
  submissionsDueCount: 5,
  missingSubmissionsCount: 2,
  submissionsSubmittedCount: 8,
}

const mockGqlResponse = {
  data: {
    legacyNode: {
      _id: '123',
      enrollments: [
        {
          course: {
            _id: '123',
            name: 'Test Course',
            submissionStatistics: mockStatisticsData,
          },
        },
      ],
    },
  },
}

const errorMsg = 'Failed to fetch submission statistics'

const buildDefaultProps = (overrides = {}) => ({
  startDate: new Date('2025-08-01'),
  endDate: new Date('2025-08-31'),
  courseId: '123',
  ...overrides,
})

const setup = (props = {}, envOverrides = {}, dashboardProps = {}) => {
  // Set up Canvas ENV with current_user_id
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

  const hookParams = buildDefaultProps(props)
  const result = renderHook(() => useCourseWorkStatistics(hookParams), {
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
      queryClient.clear()
    },
  }
}

const server = setupServer()

describe('useCourseWorkStatistics', () => {
  beforeAll(() => {
    server.listen()
  })
  beforeEach(() => {
    window.ENV = {current_user_id: '123'} as any
    clearWidgetDashboardCache()
  })
  afterEach(() => {
    server.resetHandlers()
  })
  afterAll(() => server.close())

  it('should return loading state initially', () => {
    server.use(
      graphql.query('GetUserCourseStatistics', ({variables}) => {
        expect(variables.userId).toBe('123')
        expect(variables.startDate).toBeDefined()
        expect(variables.endDate).toBeDefined()
        // Return a delayed response to test loading state
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(HttpResponse.json(mockGqlResponse))
          }, 100)
        })
      }),
    )

    const {result, cleanup} = setup()

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })

  it('should return statistics data on successful request', async () => {
    server.use(
      graphql.query('GetUserCourseStatistics', ({variables}) => {
        expect(variables.userId).toBe('123')
        expect(variables.startDate).toBeDefined()
        expect(variables.endDate).toBeDefined()
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual({
        due: mockStatisticsData.submissionsDueCount,
        missing: mockStatisticsData.missingSubmissionsCount,
        submitted: mockStatisticsData.submissionsSubmittedCount,
      })
      expect(result.current.error).toBeNull()
    })

    cleanup()
  })

  it('should pass date parameters to GraphQL query', async () => {
    const customStartDate = new Date('2025-07-01')
    const customEndDate = new Date('2025-07-31')

    server.use(
      graphql.query('GetUserCourseStatistics', ({variables}) => {
        expect(variables.userId).toBe('123')
        expect(variables.startDate).toBeDefined()
        expect(variables.endDate).toBeDefined()
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup({
      startDate: customStartDate,
      endDate: customEndDate,
    })

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual({
        due: mockStatisticsData.submissionsDueCount,
        missing: mockStatisticsData.missingSubmissionsCount,
        submitted: mockStatisticsData.submissionsSubmittedCount,
      })
    })

    cleanup()
  })

  it('should handle GraphQL errors', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    server.use(
      graphql.query('GetUserCourseStatistics', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toBeUndefined()
      expect(result.current.error?.message).toContain(errorMsg)
    })

    cleanup()
    consoleErrorSpy.mockRestore()
  })

  it('should handle network errors', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    server.use(
      graphql.query('GetUserCourseStatistics', () => {
        return new HttpResponse(null, {status: 500})
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toBeUndefined()
      expect(result.current.error).toBeTruthy()
    })

    cleanup()
    consoleErrorSpy.mockRestore()
  })

  it('should handle null submission statistics', async () => {
    const nullResponse = {
      data: {
        legacyNode: {
          _id: '123',
          enrollments: null,
        },
      },
    }

    server.use(
      graphql.query('GetUserCourseStatistics', () => {
        return HttpResponse.json(nullResponse)
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual({due: 0, missing: 0, submitted: 0})
      expect(result.current.error).toBeNull()
    })

    cleanup()
  })

  it('should refetch statistics when courseId changes', async () => {
    let callCount = 0

    server.use(
      graphql.query('GetUserCourseStatistics', ({variables}) => {
        callCount++
        expect(variables.userId).toBe('123')
        return HttpResponse.json(mockGqlResponse)
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(callCount).toBe(1)
    })

    // Trigger refetch
    result.current.refetch()

    await waitFor(() => {
      expect(callCount).toBe(2)
    })

    cleanup()
  })

  it('should handle zero statistics gracefully', async () => {
    const zeroStatsData = {
      submissionsDueCount: 0,
      missingSubmissionsCount: 0,
      submissionsSubmittedCount: 0,
    }

    const zeroStatsResponse = {
      data: {
        legacyNode: {
          _id: '123',
          enrollments: [
            {
              course: {
                _id: '123',
                submissionStatistics: zeroStatsData,
              },
            },
          ],
        },
      },
    }

    server.use(
      graphql.query('GetUserCourseStatistics', () => {
        return HttpResponse.json(zeroStatsResponse)
      }),
    )

    const {result, cleanup} = setup()

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
      expect(result.current.data).toEqual({due: 0, missing: 0, submitted: 0})
      expect(result.current.error).toBeNull()
    })

    cleanup()
  })

  it('should skip request when current_user_id is missing', () => {
    const {result, cleanup} = setup({}, {current_user_id: undefined})

    expect(result.current.isLoading).toBe(false)
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeNull()

    cleanup()
  })

  describe('enrollment deduplication', () => {
    it('should deduplicate multiple enrollments for same course', async () => {
      const duplicateEnrollmentResponse = {
        data: {
          legacyNode: {
            _id: '123',
            enrollments: [
              {
                course: {
                  _id: '123',
                  name: 'Test Course',
                  submissionStatistics: mockStatisticsData,
                },
              },
              {
                course: {
                  _id: '123', // Same course ID
                  name: 'Test Course',
                  submissionStatistics: mockStatisticsData,
                },
              },
            ],
          },
        },
      }

      server.use(
        graphql.query('GetUserCourseStatistics', () => {
          return HttpResponse.json(duplicateEnrollmentResponse)
        }),
      )

      const {result, cleanup} = setup()

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
        expect(result.current.data).toEqual({
          due: mockStatisticsData.submissionsDueCount,
          missing: mockStatisticsData.missingSubmissionsCount,
          submitted: mockStatisticsData.submissionsSubmittedCount,
        })
      })

      cleanup()
    })

    it('should aggregate statistics from different courses correctly', async () => {
      const multiCourseResponse = {
        data: {
          legacyNode: {
            _id: '123',
            enrollments: [
              {
                course: {
                  _id: '123',
                  name: 'Course 1',
                  submissionStatistics: {
                    submissionsDueCount: 3,
                    missingSubmissionsCount: 1,
                    submissionsSubmittedCount: 2,
                  },
                },
              },
              {
                course: {
                  _id: '456',
                  name: 'Course 2',
                  submissionStatistics: {
                    submissionsDueCount: 2,
                    missingSubmissionsCount: 1,
                    submissionsSubmittedCount: 3,
                  },
                },
              },
            ],
          },
        },
      }

      server.use(
        graphql.query('GetUserCourseStatistics', () => {
          return HttpResponse.json(multiCourseResponse)
        }),
      )

      const {result, cleanup} = setup({courseId: undefined}) // Test all courses

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
        expect(result.current.data).toEqual({
          due: 5, // 3 + 2
          missing: 2, // 1 + 1
          submitted: 5, // 2 + 3
        })
      })

      cleanup()
    })

    it('should handle null submissionStatistics gracefully', async () => {
      const nullStatsResponse = {
        data: {
          legacyNode: {
            _id: '123',
            enrollments: [
              {
                course: {
                  _id: '123',
                  name: 'Course 1',
                  submissionStatistics: null,
                },
              },
              {
                course: {
                  _id: '456',
                  name: 'Course 2',
                  submissionStatistics: mockStatisticsData,
                },
              },
            ],
          },
        },
      }

      server.use(
        graphql.query('GetUserCourseStatistics', () => {
          return HttpResponse.json(nullStatsResponse)
        }),
      )

      const {result, cleanup} = setup({courseId: undefined})

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
        // Should only count statistics from Course 2
        expect(result.current.data).toEqual({
          due: mockStatisticsData.submissionsDueCount,
          missing: mockStatisticsData.missingSubmissionsCount,
          submitted: mockStatisticsData.submissionsSubmittedCount,
        })
      })

      cleanup()
    })
  })
})
