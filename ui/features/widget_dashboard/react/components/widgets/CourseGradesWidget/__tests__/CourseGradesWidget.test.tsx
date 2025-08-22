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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import CourseGradesWidget from '../CourseGradesWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'

const mockWidget: Widget = {
  id: 'test-course-grades-widget',
  type: 'course_grades',
  position: {col: 1, row: 1},
  size: {width: 1, height: 1},
  title: 'Course Grades',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const setup = (props: Partial<BaseWidgetProps> = {}) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        // Disable caching to ensure fresh queries
        staleTime: 0,
      },
    },
  })
  const defaultProps = buildDefaultProps(props)
  return render(
    <QueryClientProvider client={queryClient}>
      <CourseGradesWidget {...defaultProps} />
    </QueryClientProvider>,
  )
}

const server = setupServer()

describe('CourseGradesWidget', () => {
  let originalEnv: any

  beforeAll(() => {
    // Set up Canvas ENV with current_user_id
    originalEnv = window.ENV
    window.ENV = {
      ...originalEnv,
      current_user_id: '123',
    }

    server.listen({
      onUnhandledRequest: 'warn',
    })
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
    // Restore original ENV
    window.ENV = originalEnv
  })

  it('renders basic widget', async () => {
    // Set up a basic handler for the initial render
    server.use(
      graphql.query('GetUserCoursesWithGradesConnection', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '123',
              enrollmentsConnection: {
                nodes: [],
                pageInfo: {
                  hasNextPage: false,
                  hasPreviousPage: false,
                  startCursor: null,
                  endCursor: null,
                },
              },
            },
          },
        })
      }),
    )

    setup()

    expect(screen.getByText('Course Grades')).toBeInTheDocument()

    // Wait for query to complete
    await waitFor(() => {
      expect(screen.queryByText('Loading course grades...')).not.toBeInTheDocument()
    })
  })

  describe('pagination', () => {
    const mockPaginatedResponseFirstPage = {
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: {
            nodes: [
              {
                course: {
                  _id: '1',
                  name: 'Course 1',
                  courseCode: 'CS101',
                },
                updatedAt: '2025-01-01T00:00:00Z',
                grades: {
                  currentScore: 95,
                  currentGrade: 'A',
                  finalScore: 95,
                  finalGrade: 'A',
                  overrideScore: null,
                  overrideGrade: null,
                },
              },
              {
                course: {
                  _id: '2',
                  name: 'Course 2',
                  courseCode: 'MATH201',
                },
                updatedAt: '2025-01-01T00:00:00Z',
                grades: {
                  currentScore: 87,
                  currentGrade: 'B+',
                  finalScore: 87,
                  finalGrade: 'B+',
                  overrideScore: null,
                  overrideGrade: null,
                },
              },
            ],
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'cursor1',
              endCursor: 'cursor2',
            },
          },
        },
      },
    }

    const mockPaginatedResponseSecondPage = {
      data: {
        legacyNode: {
          _id: '123',
          enrollmentsConnection: {
            nodes: [
              {
                course: {
                  _id: '3',
                  name: 'Course 3',
                  courseCode: 'BIO301',
                },
                updatedAt: '2025-01-01T00:00:00Z',
                grades: {
                  currentScore: 92,
                  currentGrade: 'A-',
                  finalScore: 92,
                  finalGrade: 'A-',
                  overrideScore: null,
                  overrideGrade: null,
                },
              },
            ],
            pageInfo: {
              hasNextPage: false,
              hasPreviousPage: true,
              startCursor: 'cursor3',
              endCursor: 'cursor3',
            },
          },
        },
      },
    }

    it('shows pagination controls when hasNextPage is true', async () => {
      server.use(
        graphql.query('GetUserCoursesWithGradesConnection', () => {
          return HttpResponse.json(mockPaginatedResponseFirstPage)
        }),
      )

      setup()

      await waitFor(() => {
        expect(screen.getByText('Course 1')).toBeInTheDocument()
      })

      expect(screen.getByLabelText('Course grades pagination')).toBeInTheDocument()
    })

    it('does not show pagination controls when there is only one page', async () => {
      const singlePageResponse = {
        data: {
          legacyNode: {
            _id: '123',
            enrollmentsConnection: {
              nodes: [
                {
                  course: {
                    _id: '1',
                    name: 'Course 1',
                    courseCode: 'CS101',
                  },
                  updatedAt: '2025-01-01T00:00:00Z',
                  grades: {
                    currentScore: 95,
                    currentGrade: 'A',
                    finalScore: 95,
                    finalGrade: 'A',
                    overrideScore: null,
                    overrideGrade: null,
                  },
                },
              ],
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: false,
                startCursor: 'cursor1',
                endCursor: 'cursor1',
              },
            },
          },
        },
      }

      server.use(
        graphql.query('GetUserCoursesWithGradesConnection', () => {
          return HttpResponse.json(singlePageResponse)
        }),
      )

      setup()

      await waitFor(() => {
        expect(screen.getByText('Course 1')).toBeInTheDocument()
      })

      expect(screen.queryByLabelText('Course grades pagination')).not.toBeInTheDocument()
    })

    it('navigates to next page when next button is clicked', async () => {
      let requestCount = 0

      // Set up the handler before rendering the component
      const handler = graphql.query('GetUserCoursesWithGradesConnection', ({variables}) => {
        requestCount++

        if (requestCount === 1) {
          // First page request (initial load)
          expect(variables.after).toBeUndefined()
          return HttpResponse.json(mockPaginatedResponseFirstPage)
        } else {
          // Second page request (after clicking next)
          expect(variables.after).toBe('cursor2')
          return HttpResponse.json(mockPaginatedResponseSecondPage)
        }
      })

      server.use(handler)
      setup()

      // Wait for first page to load
      await waitFor(() => {
        expect(screen.getByText('Course 1')).toBeInTheDocument()
        expect(screen.getByText('Course 2')).toBeInTheDocument()
      })

      // Click page 2
      const nextButton = screen.getByText('2')
      fireEvent.click(nextButton)

      // Wait for second page to load
      await waitFor(() => {
        expect(screen.getByText('Course 3')).toBeInTheDocument()
        expect(screen.queryByText('Course 1')).not.toBeInTheDocument()
        expect(screen.queryByText('Course 2')).not.toBeInTheDocument()
      })

      expect(requestCount).toBe(2)
    })

    it('navigates to previous page when previous button is clicked', async () => {
      let requestCount = 0

      const handler = graphql.query('GetUserCoursesWithGradesConnection', ({variables}) => {
        requestCount++

        if (requestCount === 1) {
          // First request - load first page
          expect(variables.after).toBeUndefined()
          return HttpResponse.json(mockPaginatedResponseFirstPage)
        } else {
          // Second request - navigate to second page
          expect(variables.after).toBe('cursor2')
          return HttpResponse.json(mockPaginatedResponseSecondPage)
        }
      })

      server.use(handler)
      setup()

      // Wait for first page to load
      await waitFor(() => {
        expect(screen.getByText('Course 1')).toBeInTheDocument()
        expect(screen.getByText('Course 2')).toBeInTheDocument()
      })

      // Navigate to page 2
      const nextButton = screen.getByText('2')
      fireEvent.click(nextButton)

      // Wait for second page to load
      await waitFor(() => {
        expect(screen.getByText('Course 3')).toBeInTheDocument()
        expect(screen.queryByText('Course 1')).not.toBeInTheDocument()
      })

      // Now click page 1 to go back
      const prevButton = screen.getByText('1')
      fireEvent.click(prevButton)

      // Wait for first page to load again
      await waitFor(() => {
        expect(screen.getByText('Course 1')).toBeInTheDocument()
        expect(screen.getByText('Course 2')).toBeInTheDocument()
        expect(screen.queryByText('Course 3')).not.toBeInTheDocument()
      })

      // Component uses page history for backward navigation, so only 2 requests
      expect(requestCount).toBe(2)
    })

    it('maintains grade visibility state across page changes', async () => {
      let requestCount = 0

      server.use(
        graphql.query('GetUserCoursesWithGradesConnection', () => {
          requestCount++
          return requestCount === 1
            ? HttpResponse.json(mockPaginatedResponseFirstPage)
            : HttpResponse.json(mockPaginatedResponseSecondPage)
        }),
      )

      setup()

      // Wait for first page to load
      await waitFor(() => {
        expect(screen.getByText('Course 1')).toBeInTheDocument()
      })

      // Toggle grade visibility off
      const showAllGradesToggle = screen.getByLabelText('Show all grades')
      expect(showAllGradesToggle).toBeChecked()
      fireEvent.click(showAllGradesToggle)

      // Verify it's now unchecked
      await waitFor(() => {
        expect(showAllGradesToggle).not.toBeChecked()
      })

      // Navigate to next page
      const nextButton = screen.getByText('2')
      fireEvent.click(nextButton)

      // Wait for second page and verify toggle state is maintained
      await waitFor(() => {
        expect(screen.getByText('Course 3')).toBeInTheDocument()
      })

      const toggleAfterNavigation = screen.getByLabelText('Show all grades')
      expect(toggleAfterNavigation).not.toBeChecked()
    })

    it('shows correct page numbers in pagination component', async () => {
      server.use(
        graphql.query('GetUserCoursesWithGradesConnection', () => {
          return HttpResponse.json(mockPaginatedResponseFirstPage)
        }),
      )

      setup()

      await waitFor(() => {
        expect(screen.getByText('Course 1')).toBeInTheDocument()
      })

      // Check that pagination shows current page as 1 and indicates there are more pages
      const pagination = screen.getByLabelText('Course grades pagination')
      expect(pagination).toBeInTheDocument()

      // Look for page indicators - the exact implementation may vary
      const currentPageIndicator = screen.getByText('1')
      expect(currentPageIndicator.closest('button')).toHaveAttribute('aria-current', 'page')
    })

    it('displays course grade cards in grid layout with pagination', async () => {
      server.use(
        graphql.query('GetUserCoursesWithGradesConnection', () => {
          return HttpResponse.json(mockPaginatedResponseFirstPage)
        }),
      )

      setup()

      await waitFor(() => {
        expect(screen.getByText('Course 1')).toBeInTheDocument()
        expect(screen.getByText('Course 2')).toBeInTheDocument()
      })

      // Verify grade information is displayed
      expect(screen.getByText('CS101')).toBeInTheDocument()
      expect(screen.getByText('MATH201')).toBeInTheDocument()
    })
  })
})
