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
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import RecentGradesWidget from '../RecentGradesWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'
import {ResponsiveProvider} from '../../../../hooks/useResponsiveContext'
import {WidgetDashboardProvider} from '../../../../hooks/useWidgetDashboardContext'
import {clearWidgetDashboardCache} from '../../../../__tests__/testHelpers'

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterEach(() => {
  server.resetHandlers()
})

afterAll(() => {
  server.close()
})

beforeEach(() => {
  window.ENV = {current_user_id: '1'} as any
  clearWidgetDashboardCache()
})

const mockGradedSubmissions = [
  {
    _id: 'sub1',
    score: 95,
    grade: 'A',
    excused: false,
    submittedAt: '2025-11-28T10:00:00Z',
    gradedAt: '2025-11-30T14:30:00Z',
    state: 'graded',
    assignment: {
      _id: '101',
      name: 'Introduction to React Hooks',
      htmlUrl: '/courses/1/assignments/101',
      pointsPossible: 100,
      gradingType: 'letter_grade',
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '1',
        name: 'Advanced Web Development',
        courseCode: 'CS-401',
      },
    },
  },
  {
    _id: 'sub2',
    score: 88,
    grade: 'B+',
    excused: false,
    submittedAt: '2025-11-27T09:00:00Z',
    gradedAt: '2025-11-29T16:45:00Z',
    state: 'graded',
    assignment: {
      _id: '102',
      name: 'Data Structures Quiz',
      htmlUrl: '/courses/2/assignments/102',
      pointsPossible: 100,
      gradingType: 'letter_grade',
      submissionTypes: ['online_quiz'],
      quiz: {_id: '102', title: 'Data Structures Quiz'},
      discussion: null,
      course: {
        _id: '2',
        name: 'Computer Science 101',
        courseCode: 'CS-101',
      },
    },
  },
  {
    _id: 'sub3',
    score: 92,
    grade: 'A-',
    excused: false,
    submittedAt: '2025-11-26T11:30:00Z',
    gradedAt: '2025-11-28T10:15:00Z',
    state: 'graded',
    assignment: {
      _id: '103',
      name: 'Essay on Modern Literature',
      htmlUrl: '/courses/3/assignments/103',
      pointsPossible: 100,
      gradingType: 'letter_grade',
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '3',
        name: 'English Literature 201',
        courseCode: 'ENG-201',
      },
    },
  },
  {
    _id: 'sub4',
    score: 78,
    grade: 'C+',
    excused: false,
    submittedAt: '2025-11-25T15:00:00Z',
    gradedAt: '2025-11-27T09:00:00Z',
    state: 'graded',
    assignment: {
      _id: '104',
      name: 'Calculus Problem Set 5',
      htmlUrl: '/courses/4/assignments/104',
      pointsPossible: 100,
      gradingType: 'letter_grade',
      submissionTypes: ['online_text_entry'],
      quiz: null,
      discussion: null,
      course: {
        _id: '4',
        name: 'Mathematics 301',
        courseCode: 'MATH-301',
      },
    },
  },
  {
    _id: 'sub5',
    score: 90,
    grade: 'A-',
    excused: false,
    submittedAt: '2025-11-24T13:00:00Z',
    gradedAt: '2025-11-26T11:30:00Z',
    state: 'graded',
    assignment: {
      _id: '105',
      name: 'Lab Report: Chemical Reactions',
      htmlUrl: '/courses/5/assignments/105',
      pointsPossible: 100,
      gradingType: 'letter_grade',
      submissionTypes: ['online_upload'],
      quiz: null,
      discussion: null,
      course: {
        _id: '5',
        name: 'Chemistry 202',
        courseCode: 'CHEM-202',
      },
    },
  },
  {
    _id: 'sub6',
    score: 85,
    grade: 'B',
    excused: false,
    submittedAt: '2025-11-23T10:00:00Z',
    gradedAt: '2025-11-25T14:00:00Z',
    state: 'graded',
    assignment: {
      _id: '106',
      name: 'History Presentation',
      htmlUrl: '/courses/6/assignments/106',
      pointsPossible: 100,
      gradingType: 'letter_grade',
      submissionTypes: ['online_upload'],
      quiz: null,
      discussion: null,
      course: {
        _id: '6',
        name: 'World History 101',
        courseCode: 'HIST-101',
      },
    },
  },
]

const mockWidget: Widget = {
  id: 'recent-grades-widget',
  type: 'recent_grades',
  position: {col: 1, row: 1, relative: 1},
  title: 'Recent grades & feedback',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const mockSharedCourseData = [
  {
    courseId: '1',
    courseCode: 'CS-401',
    courseName: 'Advanced Web Development',
    currentGrade: 95,
    gradingScheme: 'percentage' as const,
    lastUpdated: '2025-11-30T14:30:00Z',
  },
  {
    courseId: '2',
    courseCode: 'CS-101',
    courseName: 'Computer Science 101',
    currentGrade: 88,
    gradingScheme: 'percentage' as const,
    lastUpdated: '2025-11-29T16:45:00Z',
  },
  {
    courseId: '3',
    courseCode: 'ENG-201',
    courseName: 'English Literature 201',
    currentGrade: 92,
    gradingScheme: 'percentage' as const,
    lastUpdated: '2025-11-28T10:15:00Z',
  },
]

const setup = (props: Partial<BaseWidgetProps> = {}, matches: string[] = ['desktop']) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
      },
    },
  })
  const defaultProps = buildDefaultProps(props)
  return render(
    <QueryClientProvider client={queryClient}>
      <ResponsiveProvider matches={matches}>
        <WidgetDashboardProvider sharedCourseData={mockSharedCourseData}>
          <WidgetDashboardEditProvider>
            <WidgetLayoutProvider>
              <RecentGradesWidget {...defaultProps} />
            </WidgetLayoutProvider>
          </WidgetDashboardEditProvider>
        </WidgetDashboardProvider>
      </ResponsiveProvider>
    </QueryClientProvider>,
  )
}

describe('RecentGradesWidget', () => {
  beforeEach(() => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetRecentGrades')) {
          const {after} = body.variables
          const startIndex = after ? parseInt(atob(after), 10) : 0
          const submissions = mockGradedSubmissions.slice(startIndex, startIndex + 5)

          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: submissions,
                  pageInfo: {
                    hasNextPage: startIndex + 5 < mockGradedSubmissions.length,
                    hasPreviousPage: startIndex > 0,
                    endCursor: submissions.length > 0 ? btoa(String(startIndex + 5)) : null,
                    startCursor: startIndex > 0 ? btoa(String(startIndex)) : null,
                    totalCount: mockGradedSubmissions.length,
                  },
                },
              },
            },
          })
        }
      }),
    )
  })

  it('renders widget with title', () => {
    setup()
    expect(screen.getByText('Recent grades & feedback')).toBeInTheDocument()
  })

  it('displays list of recent grades', async () => {
    setup()

    await waitFor(() => {
      expect(screen.getByTestId('recent-grades-list')).toBeInTheDocument()
      expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
      expect(screen.getByText('Data Structures Quiz')).toBeInTheDocument()
    })
  })

  it('displays grade items with correct information', async () => {
    setup()

    await waitFor(() => {
      expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
      expect(screen.getByTestId('grade-status-badge-sub1')).toBeInTheDocument()
      expect(screen.getByTestId('grade-status-badge-sub1')).toHaveTextContent('Graded')
    })
  })

  it('displays pagination controls', async () => {
    setup()
    await waitFor(() => {
      expect(screen.getByTestId('pagination-container')).toBeInTheDocument()
    })
  })

  it('paginates through grade items', async () => {
    const user = userEvent.setup()
    setup()

    await waitFor(() => {
      expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
      expect(screen.queryByText('History Presentation')).not.toBeInTheDocument()
    })

    await waitFor(() => {
      expect(screen.getByTestId('pagination-container')).toBeInTheDocument()
    })

    const paginationContainer = screen.getByTestId('pagination-container')
    const pageButtons = paginationContainer.querySelectorAll('button')
    const page2Button = Array.from(pageButtons).find(button => button.textContent === '2')
    expect(page2Button).toBeInTheDocument()

    if (page2Button) {
      await user.click(page2Button)

      await waitFor(() => {
        expect(screen.getByText('History Presentation')).toBeInTheDocument()
        expect(screen.queryByText('Introduction to React Hooks')).not.toBeInTheDocument()
      })
    }
  })

  it('displays course filter with courses', async () => {
    setup()

    await waitFor(() => {
      expect(screen.getByTestId('course-filter-select')).toBeInTheDocument()
    })

    const select = screen.getByTestId('course-filter-select')
    await userEvent.click(select)

    await waitFor(() => {
      expect(screen.getAllByText('Advanced Web Development').length).toBeGreaterThan(0)
      expect(screen.getAllByText('Computer Science 101').length).toBeGreaterThan(0)
    })
  })

  it('filters grades by course when course is selected', async () => {
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetRecentGrades')) {
          const {courseFilter} = body.variables
          const filteredSubmissions = courseFilter
            ? mockGradedSubmissions.filter(sub => sub.assignment.course._id === courseFilter)
            : mockGradedSubmissions

          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: filteredSubmissions.slice(0, 5),
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                    totalCount: filteredSubmissions.length,
                  },
                },
              },
            },
          })
        }
      }),
    )

    setup()

    await waitFor(() => {
      expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
    })

    const select = screen.getByTestId('course-filter-select')
    await userEvent.click(select)

    await waitFor(() => {
      expect(screen.getAllByText('Advanced Web Development').length).toBeGreaterThan(0)
    })

    const courseOptions = screen.getAllByText('Advanced Web Development')
    await userEvent.click(courseOptions[courseOptions.length - 1])

    await waitFor(() => {
      expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
    })
  })

  it('displays assignment titles', async () => {
    setup()

    await waitFor(() => {
      const assignmentTitle = screen.getByTestId('assignment-title-sub1')
      expect(assignmentTitle).toBeInTheDocument()
      expect(assignmentTitle).toHaveTextContent('Introduction to React Hooks')
    })
  })

  it('handles loading state', () => {
    setup({isLoading: true})
    expect(screen.getByText('Loading recent grades...')).toBeInTheDocument()
    expect(screen.queryByTestId('recent-grades-list')).not.toBeInTheDocument()
  })

  it('handles error state', () => {
    const onRetry = vi.fn()
    setup({error: 'Failed to load grades', onRetry})

    expect(screen.getByText('Failed to load grades')).toBeInTheDocument()
    expect(screen.getByTestId('recent-grades-widget-retry-button')).toBeInTheDocument()
  })

  it('calls onRetry when retry button is clicked', async () => {
    const user = userEvent.setup()
    const onRetry = vi.fn()
    setup({error: 'Failed to load grades', onRetry})

    const retryButton = screen.getByTestId('recent-grades-widget-retry-button')
    await user.click(retryButton)

    expect(onRetry).toHaveBeenCalledTimes(1)
  })

  it('displays correct number of items per page', async () => {
    setup()

    await waitFor(() => {
      const gradeItems = screen.getAllByTestId(/^grade-item-/)
      expect(gradeItems).toHaveLength(5)
    })
  })

  it('displays grading status badges correctly', async () => {
    setup()

    await waitFor(() => {
      const badge = screen.getByTestId('grade-status-badge-sub1')
      expect(badge).toHaveTextContent('Graded')
    })
  })

  it('displays timestamps for each grade', async () => {
    setup()

    await waitFor(() => {
      expect(screen.getByTestId('grade-timestamp-sub1')).toBeInTheDocument()
    })
  })

  it('handles empty submissions gracefully', async () => {
    server.use(
      http.post('/api/graphql', async () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '1',
              courseWorkSubmissionsConnection: {
                nodes: [],
                pageInfo: {
                  hasNextPage: false,
                  hasPreviousPage: false,
                  endCursor: null,
                  startCursor: null,
                  totalCount: 0,
                },
              },
            },
          },
        })
      }),
    )

    setup()

    await waitFor(() => {
      expect(screen.getByText('No recent grades available')).toBeInTheDocument()
    })
  })

  it('handles GraphQL errors', async () => {
    server.use(
      http.post('/api/graphql', async () => {
        return HttpResponse.json(
          {
            errors: [{message: 'Failed to fetch submissions'}],
          },
          {status: 500},
        )
      }),
    )

    setup()

    await waitFor(() => {
      expect(screen.getByText(/GraphQL Error/i)).toBeInTheDocument()
    })
  })

  it('expands grade details when expand button is clicked', async () => {
    const user = userEvent.setup()
    setup()

    await waitFor(() => {
      expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
    })

    const expandButton = screen.getByTestId('expand-grade-sub1')
    expect(expandButton).toBeInTheDocument()

    await user.click(expandButton)

    await waitFor(() => {
      expect(screen.getByTestId('expanded-grade-view-sub1')).toBeInTheDocument()
    })
  })

  it('collapses grade details when collapse button is clicked', async () => {
    const user = userEvent.setup()
    setup()

    await waitFor(() => {
      expect(screen.getByText('Introduction to React Hooks')).toBeInTheDocument()
    })

    const expandButton = screen.getByTestId('expand-grade-sub1')
    await user.click(expandButton)

    await waitFor(() => {
      expect(screen.getByTestId('expanded-grade-view-sub1')).toBeInTheDocument()
    })

    await user.click(expandButton)

    await waitFor(() => {
      expect(screen.queryByTestId('expanded-grade-view-sub1')).not.toBeInTheDocument()
    })
  })

  it('does not show expand button for ungraded items', async () => {
    server.use(
      http.post('/api/graphql', async () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '1',
              courseWorkSubmissionsConnection: {
                nodes: [
                  {
                    _id: 'sub-ungraded',
                    score: null,
                    grade: null,
                    submittedAt: '2025-11-28T10:00:00Z',
                    gradedAt: null,
                    state: 'submitted',
                    assignment: {
                      _id: '201',
                      name: 'Ungraded Assignment',
                      htmlUrl: '/courses/1/assignments/201',
                      pointsPossible: 100,
                      gradingType: 'points',
                      submissionTypes: ['online_text_entry'],
                      quiz: null,
                      discussion: null,
                      course: {
                        _id: '1',
                        name: 'Test Course',
                        courseCode: 'TEST-101',
                      },
                    },
                  },
                ],
                pageInfo: {
                  hasNextPage: false,
                  hasPreviousPage: false,
                  endCursor: null,
                  startCursor: null,
                  totalCount: 1,
                },
              },
            },
          },
        })
      }),
    )

    setup()

    await waitFor(() => {
      expect(screen.getByText('Ungraded Assignment')).toBeInTheDocument()
      expect(screen.getByTestId('grade-status-badge-sub-ungraded')).toHaveTextContent('Not graded')
    })

    expect(screen.queryByTestId('expand-grade-sub-ungraded')).not.toBeInTheDocument()
  })
})
