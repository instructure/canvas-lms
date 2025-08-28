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
import {render, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import CourseWorkWidget from '../CourseWorkWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {defaultGraphQLHandlers} from '../../../../__tests__/testHelpers'

const tomorrow = new Date()
tomorrow.setDate(tomorrow.getDate() + 1)
const dayAfterTomorrow = new Date()
dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 2)
const threeDaysFromNow = new Date()
threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3)

const mockCourseWorkData = {
  legacyNode: {
    _id: '1',
    enrollments: [
      {
        course: {
          _id: '101',
          name: 'Environmental Science',
          assignmentsConnection: {
            nodes: [
              {
                _id: '1',
                name: 'Essay on Climate Change',
                dueAt: threeDaysFromNow.toISOString(),
                pointsPossible: 50,
                htmlUrl: '/courses/101/assignments/1',
                submissionTypes: ['online_text_entry'],
                state: 'published',
                published: true,
                quiz: null,
                discussion: null,
                submissionsConnection: {
                  nodes: [
                    {
                      _id: 'sub1',
                      cachedDueDate: threeDaysFromNow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                    },
                  ],
                },
              },
            ],
          },
        },
      },
      {
        course: {
          _id: '102',
          name: 'Biology',
          assignmentsConnection: {
            nodes: [
              {
                _id: '2',
                name: 'Chapter Quiz Assignment',
                dueAt: tomorrow.toISOString(),
                pointsPossible: 25,
                htmlUrl: '/courses/102/assignments/2',
                submissionTypes: ['online_quiz'],
                state: 'published',
                published: true,
                quiz: {_id: '2', title: 'Chapter 5 Quiz'},
                discussion: null,
                submissionsConnection: {
                  nodes: [
                    {
                      _id: 'sub2',
                      cachedDueDate: tomorrow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                    },
                  ],
                },
              },
            ],
          },
        },
      },
      {
        course: {
          _id: '103',
          name: 'Art History',
          assignmentsConnection: {
            nodes: [
              {
                _id: '3',
                name: 'Discussion Assignment',
                dueAt: dayAfterTomorrow.toISOString(),
                pointsPossible: 15,
                htmlUrl: '/courses/103/assignments/3',
                submissionTypes: ['discussion_topic'],
                state: 'published',
                published: true,
                quiz: null,
                discussion: {_id: '3', title: 'Discussion: Modern Art'},
                submissionsConnection: {
                  nodes: [
                    {
                      _id: 'sub3',
                      cachedDueDate: dayAfterTomorrow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                    },
                  ],
                },
              },
            ],
          },
        },
      },
      {
        course: {
          _id: '104',
          name: 'Chemistry',
          assignmentsConnection: {
            nodes: [
              {
                _id: '4',
                name: 'Lab Report: Chemical Reactions',
                dueAt: null,
                pointsPossible: 40,
                htmlUrl: '/courses/104/assignments/4',
                submissionTypes: ['online_upload'],
                state: 'published',
                published: true,
                quiz: null,
                discussion: null,
                submissionsConnection: {
                  nodes: [
                    {
                      _id: 'sub4',
                      cachedDueDate: null,
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                    },
                  ],
                },
              },
            ],
          },
        },
      },
    ],
  },
}

const mockWidget: Widget = {
  id: 'course-work-widget',
  type: 'course_work',
  position: {col: 1, row: 1},
  size: {width: 2, height: 2},
  title: 'Course Work',
}

const buildDefaultProps = (overrides: Partial<BaseWidgetProps> = {}): BaseWidgetProps => {
  return {
    widget: mockWidget,
    ...overrides,
  }
}

const server = setupServer(
  ...defaultGraphQLHandlers,
  graphql.query('GetUserCourseWork', () => {
    return HttpResponse.json({
      data: mockCourseWorkData,
    })
  }),
)

const renderWithProviders = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {queries: {retry: false}, mutations: {retry: false}},
  })

  return render(<QueryClientProvider client={queryClient}>{component}</QueryClientProvider>)
}

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
})

describe('CourseWorkWidget', () => {
  it('renders widget with mock course work items', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    expect(screen.getByText('Course Work')).toBeInTheDocument()
    expect(screen.getByText('Filter by course')).toBeInTheDocument()

    // Wait for data to load
    await screen.findByText('Essay on Climate Change')
    expect(screen.getByText('Chapter 5 Quiz')).toBeInTheDocument()
    expect(screen.getByText('Discussion: Modern Art')).toBeInTheDocument()
    expect(screen.getByText('Lab Report: Chemical Reactions')).toBeInTheDocument()
  })

  it('displays course work items with correct information', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    // Wait for data to load
    await screen.findByText('Environmental Science')

    // Check that course names are displayed
    expect(screen.getByText('Biology')).toBeInTheDocument()
    expect(screen.getByText('Art History')).toBeInTheDocument()
    expect(screen.getByText('Chemistry')).toBeInTheDocument()

    // Check that assignment types are displayed (use getAllByText for multiple elements)
    expect(screen.getAllByText('Assignment')).toHaveLength(2) // Two assignments in mock data
    expect(screen.getByText('Quiz')).toBeInTheDocument()
    expect(screen.getByText('Discussion')).toBeInTheDocument()

    // Check that points are displayed (they're combined with due date text)
    expect(screen.getByText(/50 pts/)).toBeInTheDocument()
    expect(screen.getByText(/25 pts/)).toBeInTheDocument()
    expect(screen.getByText(/15 pts/)).toBeInTheDocument()
    expect(screen.getByText(/40 pts/)).toBeInTheDocument()
  })

  it('displays due dates correctly', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    // Wait for data to load by looking for multiple due dates
    const dueDates = await screen.findAllByText(/Due.*at/)

    // Should display formatted due dates (use getAllByText for multiple matches)
    expect(dueDates.length).toBeGreaterThan(0)

    // The "No due date" text should be present for items without due dates
    // Switch to "Missing" filter to see assignments without due dates\n    const dateFilterSelect = screen.getByDisplayValue('Next 3 days')\n    fireEvent.click(dateFilterSelect)\n    \n    const missingOption = await screen.findByText('Missing')\n    fireEvent.click(missingOption)\n\n    // Wait for filter to apply and check for "No due date" text\n    await waitFor(() => {\n      expect(screen.getByText(/No due date/)).toBeInTheDocument()\n    })
  })

  it('sorts items by due date with soonest first', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    // Wait for data to load
    await screen.findByText('Chapter 5 Quiz')

    // Check the order by verifying the earliest due date appears first
    const quizText = screen.getByText('Chapter 5 Quiz')
    const labText = screen.getByText('Lab Report: Chemical Reactions')

    // Get all text content and check ordering
    const allText = screen.getByTestId('widget-course-work-widget').textContent
    const quizIndex = allText?.indexOf('Chapter 5 Quiz') ?? -1
    const labIndex = allText?.indexOf('Lab Report: Chemical Reactions') ?? -1

    // Quiz (earliest due date) should appear before Lab (no due date)
    expect(quizIndex).toBeLessThan(labIndex)
    expect(quizText).toBeInTheDocument()
    expect(labText).toBeInTheDocument()
  })

  it('handles course filtering', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    // Wait for data to load
    await screen.findByText('Essay on Climate Change')

    // Initial state should show all items
    expect(screen.getByText('Chapter 5 Quiz')).toBeInTheDocument()

    // The select should be present with "All Courses" selected by default
    expect(screen.getByDisplayValue('All Courses')).toBeInTheDocument()
  })

  it('displays empty state when no items are found', async () => {
    server.use(
      graphql.query('GetUserCourseWork', () => {
        return HttpResponse.json({
          data: {
            legacyNode: {
              _id: '1',
              enrollments: [],
            },
          },
        })
      }),
    )

    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    await screen.findByText('No upcoming course work')
    expect(screen.getByDisplayValue('All Courses')).toBeInTheDocument()
  })

  it('renders action link to view all courses', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    const viewAllLink = await screen.findByTestId('view-all-courses-link')
    expect(viewAllLink).toBeInTheDocument()
    expect(viewAllLink).toHaveAttribute('href', '/courses')
  })

  it('handles loading state', () => {
    // Mock with a delayed response to test loading state
    server.use(
      graphql.query('GetUserCourseWork', () => {
        return new Promise(resolve => {
          setTimeout(() => {
            resolve(HttpResponse.json({data: mockCourseWorkData}))
          }, 100)
        })
      }),
    )

    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    expect(screen.getByLabelText('Loading widget data...')).toBeInTheDocument()
  })

  it('handles error state', async () => {
    server.use(
      graphql.query('GetUserCourseWork', () => {
        return HttpResponse.json({errors: [{message: 'Internal Server Error'}]}, {status: 500})
      }),
    )

    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    await screen.findByText('Failed to load course work. Please try again.')
    expect(screen.getByTestId('course-work-widget-retry-button')).toBeInTheDocument()
  })

  it('creates clickable links to course work items', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    // Wait for data to load
    const essayLink = await screen.findByTestId('course-work-item-link-1')
    expect(essayLink).toHaveAttribute('href', '/courses/101/assignments/1')

    const quizLink = screen.getByTestId('course-work-item-link-2')
    expect(quizLink).toHaveAttribute('href', '/courses/102/assignments/2')

    const discussionLink = screen.getByTestId('course-work-item-link-3')
    expect(discussionLink).toHaveAttribute('href', '/courses/103/assignments/3')

    const labLink = screen.getByTestId('course-work-item-link-4')
    expect(labLink).toHaveAttribute('href', '/courses/104/assignments/4')
  })
})
