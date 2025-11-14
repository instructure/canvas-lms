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
import {http, HttpResponse} from 'msw'
import CourseWorkWidget from '../CourseWorkWidget'
import type {BaseWidgetProps, Widget} from '../../../../types'
import {defaultGraphQLHandlers, clearWidgetDashboardCache} from '../../../../__tests__/testHelpers'
import {WidgetLayoutProvider} from '../../../../hooks/useWidgetLayout'
import {WidgetDashboardEditProvider} from '../../../../hooks/useWidgetDashboardEdit'

const tomorrow = new Date()
tomorrow.setDate(tomorrow.getDate() + 1)
const dayAfterTomorrow = new Date()
dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 2)
const threeDaysFromNow = new Date()
threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3)

const mockWidget: Widget = {
  id: 'course-work-widget',
  type: 'course_work',
  position: {col: 1, row: 1, relative: 1},
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
  http.post('/api/graphql', async ({request}) => {
    const body = (await request.json()) as {query: string; variables: any}
    if (body.query.includes('GetUserCourseWork')) {
      return HttpResponse.json({
        data: {
          legacyNode: {
            _id: '1',
            courseWorkSubmissionsConnection: {
              nodes: [
                {
                  _id: 'sub1',
                  cachedDueDate: threeDaysFromNow.toISOString(),
                  submittedAt: null,
                  late: false,
                  missing: false,
                  excused: false,
                  state: 'unsubmitted',
                  assignment: {
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
                    course: {
                      _id: '101',
                      name: 'Environmental Science',
                    },
                  },
                },
                {
                  _id: 'sub2',
                  cachedDueDate: tomorrow.toISOString(),
                  submittedAt: null,
                  late: false,
                  missing: false,
                  excused: false,
                  state: 'unsubmitted',
                  assignment: {
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
                    course: {
                      _id: '102',
                      name: 'Biology',
                    },
                  },
                },
                {
                  _id: 'sub3',
                  cachedDueDate: dayAfterTomorrow.toISOString(),
                  submittedAt: null,
                  late: false,
                  missing: false,
                  excused: false,
                  state: 'unsubmitted',
                  assignment: {
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
                    course: {
                      _id: '103',
                      name: 'Art History',
                    },
                  },
                },
                {
                  _id: 'sub4',
                  cachedDueDate: null,
                  submittedAt: null,
                  late: false,
                  missing: false,
                  excused: false,
                  state: 'unsubmitted',
                  assignment: {
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
                    course: {
                      _id: '104',
                      name: 'Chemistry',
                    },
                  },
                },
              ],
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: false,
                endCursor: null,
                startCursor: null,
              },
            },
          },
        },
      })
    }
    // Let other handlers from defaultGraphQLHandlers handle other queries
    return new Response('Query not handled', {status: 404})
  }),
)

const renderWithProviders = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {queries: {retry: false}, mutations: {retry: false}},
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardEditProvider>
        <WidgetLayoutProvider>{component}</WidgetLayoutProvider>
      </WidgetDashboardEditProvider>
    </QueryClientProvider>,
  )
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
  clearWidgetDashboardCache()
  window.ENV = {current_user_id: '1'} as any
})

describe('CourseWorkWidget', () => {
  it('renders widget with mock course work items', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    expect(screen.getByText('Course Work')).toBeInTheDocument()

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

    // Check that assignment type icons are displayed with correct data-testids
    expect(screen.getAllByTestId('assignment-icon')).toHaveLength(2) // Two assignments in mock data
    expect(screen.getByTestId('quiz-icon')).toBeInTheDocument()
    expect(screen.getByTestId('discussion-icon')).toBeInTheDocument()

    // Check that points are displayed (they're combined with due date text)
    expect(screen.getByText(/50 pts/)).toBeInTheDocument()
    expect(screen.getByText(/25 pts/)).toBeInTheDocument()
    expect(screen.getByText(/15 pts/)).toBeInTheDocument()
    expect(screen.getByText(/40 pts/)).toBeInTheDocument()
  })

  it('displays "Go to course" links for each course work item', async () => {
    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    await screen.findByText('Essay on Climate Change')

    expect(screen.getByTestId('course-work-item-course-link-1')).toBeInTheDocument()
    expect(screen.getByTestId('course-work-item-course-link-1')).toHaveAttribute(
      'href',
      '/courses/101',
    )
    expect(screen.getByTestId('course-work-item-course-link-2')).toBeInTheDocument()
    expect(screen.getByTestId('course-work-item-course-link-2')).toHaveAttribute(
      'href',
      '/courses/102',
    )
    expect(screen.getByTestId('course-work-item-course-link-3')).toBeInTheDocument()
    expect(screen.getByTestId('course-work-item-course-link-3')).toHaveAttribute(
      'href',
      '/courses/103',
    )
    expect(screen.getByTestId('course-work-item-course-link-4')).toBeInTheDocument()
    expect(screen.getByTestId('course-work-item-course-link-4')).toHaveAttribute(
      'href',
      '/courses/104',
    )
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
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
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
                  },
                },
              },
            },
          })
        }
        return new Response('Query not handled', {status: 404})
      }),
    )

    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    await screen.findByText('No upcoming course work')
    expect(screen.getByDisplayValue('All Courses')).toBeInTheDocument()
  })

  it('handles loading state', () => {
    // Mock with a delayed response to test loading state
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
          return new Promise(resolve => {
            setTimeout(() => {
              resolve(
                HttpResponse.json({
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
                        },
                      },
                    },
                  },
                }),
              )
            }, 100)
          })
        }
        return new Response('Query not handled', {status: 404})
      }),
    )

    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    expect(screen.getByLabelText('Loading widget data...')).toBeInTheDocument()
  })

  it('handles error state', async () => {
    jest.spyOn(console, 'error').mockImplementation()

    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
          return HttpResponse.json({errors: [{message: 'Internal Server Error'}]}, {status: 200})
        }
        return new Response('Query not handled', {status: 404})
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

  it('displays correct submission statuses based on submission data', async () => {
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    server.use(
      http.post('/api/graphql', async ({request}) => {
        const body = (await request.json()) as {query: string; variables: any}
        if (body.query.includes('GetUserCourseWork')) {
          return HttpResponse.json({
            data: {
              legacyNode: {
                _id: '1',
                courseWorkSubmissionsConnection: {
                  nodes: [
                    {
                      _id: 'sub1',
                      cachedDueDate: tomorrow.toISOString(),
                      submittedAt: new Date().toISOString(),
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'submitted',
                      assignment: {
                        _id: '1',
                        name: 'Submitted Assignment',
                        dueAt: tomorrow.toISOString(),
                        pointsPossible: 50,
                        htmlUrl: '/courses/101/assignments/1',
                        submissionTypes: ['online_text_entry'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {_id: '101', name: 'Course 1'},
                      },
                    },
                    {
                      _id: 'sub2',
                      cachedDueDate: yesterday.toISOString(),
                      submittedAt: null,
                      late: true,
                      missing: false,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '2',
                        name: 'Late Assignment',
                        dueAt: yesterday.toISOString(),
                        pointsPossible: 25,
                        htmlUrl: '/courses/102/assignments/2',
                        submissionTypes: ['online_upload'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {_id: '102', name: 'Course 2'},
                      },
                    },
                    {
                      _id: 'sub3',
                      cachedDueDate: yesterday.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: true,
                      excused: false,
                      state: 'unsubmitted',
                      assignment: {
                        _id: '3',
                        name: 'Missing Assignment',
                        dueAt: yesterday.toISOString(),
                        pointsPossible: 30,
                        htmlUrl: '/courses/103/assignments/3',
                        submissionTypes: ['online_text_entry'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {_id: '103', name: 'Course 3'},
                      },
                    },
                    {
                      _id: 'sub4',
                      cachedDueDate: threeDaysFromNow.toISOString(),
                      submittedAt: null,
                      late: false,
                      missing: false,
                      excused: false,
                      state: 'pending_review',
                      assignment: {
                        _id: '4',
                        name: 'Pending Review Assignment',
                        dueAt: threeDaysFromNow.toISOString(),
                        pointsPossible: 40,
                        htmlUrl: '/courses/105/assignments/4',
                        submissionTypes: ['online_text_entry'],
                        state: 'published',
                        published: true,
                        quiz: null,
                        discussion: null,
                        course: {_id: '105', name: 'Course 5'},
                      },
                    },
                  ],
                  pageInfo: {
                    hasNextPage: false,
                    hasPreviousPage: false,
                    endCursor: null,
                    startCursor: null,
                  },
                },
              },
            },
          })
        }
        return new Response('Query not handled', {status: 404})
      }),
    )

    renderWithProviders(<CourseWorkWidget {...buildDefaultProps()} />)

    // Wait for data to load and check specific status labels
    await screen.findByText('Submitted')
    expect(screen.getByText('Late')).toBeInTheDocument()
    expect(screen.getByText('Missing')).toBeInTheDocument()
    expect(screen.getByText('Pending Review')).toBeInTheDocument()
  })
})
