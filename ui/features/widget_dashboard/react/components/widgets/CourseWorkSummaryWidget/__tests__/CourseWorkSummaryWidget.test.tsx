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
import {render, screen, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import CourseWorkSummaryWidget from '../CourseWorkSummaryWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {defaultGraphQLHandlers, clearWidgetDashboardCache} from '../../../../__tests__/testHelpers'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'

const mockCoursesData = [
  {
    _id: '1',
    name: 'Introduction to Computer Science',
  },
  {
    _id: '2',
    name: 'Advanced Mathematics',
  },
]

const mockStatisticsData = {
  submissionsDueCount: 5,
  missingSubmissionsCount: 2,
  submissionsSubmittedCount: 8,
}

const mockWidget: Widget = {
  id: 'course-work-widget',
  type: 'course_work_summary',
  position: {col: 1, row: 1, relative: 1},
  title: "Today's course work",
}

type Props = BaseWidgetProps

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): Props => {
  const defaultProps: Props = {
    widget: mockWidget,
  }
  return {...defaultProps, ...overrides}
}

const setup = (props: Props = buildDefaultProps()) => {
  // Set up Canvas ENV
  const originalEnv = window.ENV
  window.ENV = {
    ...originalEnv,
    current_user_id: '123',
  }

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  })

  const result = render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardEditProvider>
        <WidgetLayoutProvider>
          <CourseWorkSummaryWidget {...props} />
        </WidgetLayoutProvider>
      </WidgetDashboardEditProvider>
    </QueryClientProvider>,
  )

  return {
    ...result,
    queryClient,
    cleanup: () => {
      window.ENV = originalEnv
      queryClient.clear()
    },
  }
}

const server = setupServer(...defaultGraphQLHandlers)

describe('CourseWorkSummaryWidget', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
  })
  afterAll(() => server.close())

  beforeEach(() => {
    clearWidgetDashboardCache()
    server.use(
      graphql.query('GetUserCourses', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollments: mockCoursesData.map(course => ({
                course,
              })),
            },
          },
        })
      }),
      graphql.query('GetUserCourseStatistics', () => {
        return HttpResponse.json({
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
        })
      }),
    )
  })

  it('renders the widget title', async () => {
    const {cleanup} = setup(buildDefaultProps())

    await waitFor(() => {
      expect(screen.getByText("Today's course work")).toBeInTheDocument()
    })

    cleanup()
  })

  it('renders course filter dropdown with courses', async () => {
    const {cleanup} = setup(buildDefaultProps())

    await waitFor(() => {
      expect(screen.getByDisplayValue('All Courses')).toBeInTheDocument()
    })

    cleanup()
  })

  it('renders submission status filter dropdown', async () => {
    const {cleanup} = setup(buildDefaultProps())

    await waitFor(() => {
      expect(screen.getByDisplayValue('Not submitted')).toBeInTheDocument()
    })

    cleanup()
  })

  it('displays statistics when data is loaded', async () => {
    // Ensure clean handlers for this test
    server.use(
      graphql.query('GetUserCourses', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollments: mockCoursesData.map(course => ({
                course,
              })),
            },
          },
        })
      }),
      graphql.query('GetUserCourseStatistics', () => {
        return HttpResponse.json({
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
        })
      }),
    )

    const {cleanup} = setup(buildDefaultProps())

    // Wait for loading to complete first
    await waitFor(() => {
      expect(screen.queryByText('Loading course work data...')).not.toBeInTheDocument()
    })

    await waitFor(() => {
      expect(screen.getByText('5')).toBeInTheDocument() // Due count (submissionsDueThisWeekCount)
      expect(screen.getByText('2')).toBeInTheDocument() // Missing count (missingSubmissionsCount)
      expect(screen.getByText('8')).toBeInTheDocument() // Submitted count (submittedSubmissionsCount)
    })

    expect(screen.getByText('Due')).toBeInTheDocument()
    expect(screen.getByText('Missing')).toBeInTheDocument()
    expect(screen.getByText('Submitted')).toBeInTheDocument()

    cleanup()
  })

  it('handles zero statistics gracefully', async () => {
    server.use(
      graphql.query('GetUserCourseStatistics', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollments: [
                {
                  course: {
                    _id: '123',
                    name: 'Test Course',
                    submissionStatistics: {
                      submissionsDueCount: 0,
                      missingSubmissionsCount: 0,
                      submissionsSubmittedCount: 0,
                    },
                  },
                },
              ],
            },
          },
        })
      }),
    )

    const {cleanup} = setup(buildDefaultProps())

    await waitFor(() => {
      const zeroElements = screen.getAllByText('0')
      expect(zeroElements).toHaveLength(3) // Due, Missing, Submitted should all be 0
    })

    cleanup()
  })

  it('handles missing current_user_id gracefully', async () => {
    // Set up Canvas ENV without current_user_id
    const originalEnv = window.ENV
    window.ENV = {
      ...originalEnv,
      current_user_id: null,
    }

    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          gcTime: 0,
        },
      },
    })

    const renderResult = render(
      <QueryClientProvider client={queryClient}>
        <WidgetDashboardEditProvider>
          <WidgetLayoutProvider>
            <CourseWorkSummaryWidget {...buildDefaultProps()} />
          </WidgetLayoutProvider>
        </WidgetDashboardEditProvider>
      </QueryClientProvider>,
    )

    await waitFor(() => {
      expect(screen.getByText("Today's course work")).toBeInTheDocument()
      expect(screen.getByDisplayValue('All Courses')).toBeInTheDocument()
    })

    // Clean up
    window.ENV = originalEnv
    queryClient.clear()
    renderResult.unmount()
  })

  it('handles error state for courses', async () => {
    server.use(
      graphql.query('GetUserCourses', () => {
        return HttpResponse.json({
          errors: [{message: 'Failed to fetch courses'}],
        })
      }),
    )

    const {cleanup} = setup(buildDefaultProps())

    await waitFor(() => {
      expect(screen.getByDisplayValue('All Courses')).toBeInTheDocument() // Default fallback
    })

    cleanup()
  })

  it('handles error state for statistics', async () => {
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})

    server.use(
      graphql.query('GetUserCourseStatistics', () => {
        return HttpResponse.json({
          errors: [{message: 'Failed to fetch statistics'}],
        })
      }),
    )

    const {cleanup} = setup(buildDefaultProps())

    await waitFor(() => {
      expect(screen.getByText("Today's course work")).toBeInTheDocument()
      // Component should show error message when statistics query fails
      expect(
        screen.getByText('Failed to load course work data. Please try again.'),
      ).toBeInTheDocument()
    })

    cleanup()
    consoleErrorSpy.mockRestore()
  })

  it('handles empty courses response', async () => {
    server.use(
      graphql.query('GetUserCourses', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollments: [],
            },
          },
        })
      }),
    )

    const {cleanup} = setup(buildDefaultProps())

    await waitFor(() => {
      expect(screen.getByDisplayValue('All Courses')).toBeInTheDocument() // Should still show "All Courses" option
    })

    cleanup()
  })
})
