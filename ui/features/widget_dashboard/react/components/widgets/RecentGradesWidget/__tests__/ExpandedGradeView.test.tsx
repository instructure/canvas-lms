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
import {http, HttpResponse} from 'msw'
import {ExpandedGradeView} from '../ExpandedGradeView'
import type {RecentGradeSubmission} from '../../../../types'
import {WidgetDashboardProvider} from '../../../../hooks/useWidgetDashboardContext'

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

  server.use(
    http.post('/api/graphql', () => {
      return HttpResponse.json(mockEmptySubmissionDetailsResponse)
    }),
  )
})

const mockSubmission: RecentGradeSubmission = {
  _id: 'sub1',
  score: 85,
  grade: 'B',
  excused: false,
  submittedAt: '2025-11-28T10:00:00Z',
  gradedAt: '2025-11-30T14:30:00Z',
  state: 'graded',
  assignment: {
    _id: '101',
    name: 'Test Assignment',
    htmlUrl: '/courses/1/assignments/101',
    pointsPossible: 100,
    gradingType: 'letter_grade',
    submissionTypes: ['online_text_entry'],
    quiz: null,
    discussion: null,
    course: {
      _id: '1',
      name: 'Test Course',
      courseCode: 'TEST-101',
    },
  },
}

const mockSharedCourseData = [
  {
    courseId: '1',
    courseCode: 'TEST-101',
    courseName: 'Test Course',
    currentGrade: 88,
    gradingScheme: 'percentage' as const,
    lastUpdated: '2025-11-30T14:30:00Z',
  },
]

const renderWithContext = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {queries: {retry: false}, mutations: {retry: false}},
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <WidgetDashboardProvider sharedCourseData={mockSharedCourseData}>
        {component}
      </WidgetDashboardProvider>
    </QueryClientProvider>,
  )
}

const mockSubmissionDetailsResponse = {
  data: {
    legacyNode: {
      _id: 'sub1',
      rubricAssessmentsConnection: {
        nodes: [
          {
            _id: 'rubric1',
            score: 85,
            assessmentRatings: [
              {
                _id: 'rating1',
                criterion: {
                  _id: 'criterion1',
                  description: 'Content Quality',
                  longDescription: 'How well does the content address the topic?',
                  points: 50,
                },
                description: 'Good work',
                points: 45,
                comments: 'Nice job on the analysis',
                commentsHtml: '<p>Nice job on the analysis</p>',
              },
            ],
          },
        ],
      },
      recentCommentsConnection: {
        nodes: [
          {
            _id: 'comment1',
            comment: 'Great work on this assignment!',
            htmlComment: '<p>Great work on this assignment!</p>',
            author: {
              _id: 'teacher1',
              name: 'Mr. Smith',
            },
            createdAt: '2025-11-30T14:30:00Z',
          },
        ],
      },
      allCommentsConnection: {
        pageInfo: {
          totalCount: 3,
        },
      },
    },
  },
}

const mockEmptySubmissionDetailsResponse = {
  data: {
    legacyNode: {
      _id: 'sub1',
      rubricAssessmentsConnection: {
        nodes: [],
      },
      recentCommentsConnection: {
        nodes: [],
      },
      allCommentsConnection: {
        pageInfo: {
          totalCount: 0,
        },
      },
    },
  },
}

describe('ExpandedGradeView', () => {
  it('renders the expanded view', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('expanded-grade-view-sub1')).toBeInTheDocument()
  })

  it('renders the grade display with assignment grade', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('grade-display-sub1')).toBeInTheDocument()
    expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('B')
  })

  it('displays course grade from shared course data', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('course-grade-label-sub1')).toHaveTextContent('Course grade: 88%')
  })

  it('displays rubric and feedback sections with data', async () => {
    server.use(
      http.post('/api/graphql', () => {
        return HttpResponse.json(mockSubmissionDetailsResponse)
      }),
    )

    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)

    await waitFor(() => {
      expect(screen.getByTestId('rubric-section-sub1')).toBeInTheDocument()
    })

    expect(screen.getByTestId('rubric-section-heading-sub1')).toHaveTextContent('Rubric')
    expect(screen.getByTestId('feedback-section-sub1')).toBeInTheDocument()
    expect(screen.getByTestId('feedback-section-heading-sub1')).toHaveTextContent('Feedback')
  })

  it('shows feedback section with "None" when no comments', async () => {
    server.use(
      http.post('/api/graphql', () => {
        return HttpResponse.json(mockEmptySubmissionDetailsResponse)
      }),
    )

    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)

    await waitFor(() => {
      expect(screen.queryByTestId('submission-details-loading-sub1')).not.toBeInTheDocument()
    })

    expect(screen.queryByTestId('rubric-section-sub1')).not.toBeInTheDocument()
    expect(screen.getByTestId('feedback-section-sub1')).toBeInTheDocument()
    expect(screen.getByTestId('feedback-none-sub1')).toHaveTextContent('None')
  })

  it('displays error state when submission details fetch fails', async () => {
    server.use(
      http.post('/api/graphql', () => {
        return HttpResponse.json({
          errors: [{message: 'GraphQL error'}],
        })
      }),
    )

    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)

    await waitFor(() => {
      expect(screen.getByTestId('submission-details-error-sub1')).toBeInTheDocument()
    })

    expect(screen.getByTestId('submission-details-error-sub1')).toHaveTextContent(
      'Error loading submission details',
    )
  })

  it('shows view inline feedback link in feedback section with assignment name and count', async () => {
    server.use(
      http.post('/api/graphql', () => {
        return HttpResponse.json(mockSubmissionDetailsResponse)
      }),
    )

    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)

    await waitFor(() => {
      expect(screen.getByTestId('view-inline-feedback-link-sub1')).toHaveTextContent(
        'View all inline feedback for Test Assignment (3)',
      )
    })
  })

  it('renders the open assignment link with assignment name', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    const link = screen.getByTestId('open-assignment-link-sub1')
    expect(link).toHaveTextContent('View Test Assignment')
    expect(link).toHaveAttribute('href', '/courses/1/assignments/101')
  })

  it('renders the open what-if grading tool link with assignment name', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    const link = screen.getByTestId('open-whatif-link-sub1')
    expect(link).toHaveTextContent('View Test Assignment what-if grading tool')
    expect(link).toHaveAttribute('href', '/courses/1/grades')
  })

  it('renders the message instructor link with course name', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    const link = screen.getByTestId('message-instructor-link-sub1')
    expect(link).toHaveTextContent('Message Test Course Instructor')
    expect(link).toHaveAttribute('href', '/conversations?context_id=course_1&compose=true')
  })

  it('displays course grade when no course data available', () => {
    const queryClient = new QueryClient({
      defaultOptions: {queries: {retry: false}, mutations: {retry: false}},
    })

    render(
      <QueryClientProvider client={queryClient}>
        <WidgetDashboardProvider sharedCourseData={[]}>
          <ExpandedGradeView submission={mockSubmission} />
        </WidgetDashboardProvider>
      </QueryClientProvider>,
    )
    expect(screen.getByTestId('course-grade-label-sub1')).toHaveTextContent('Course grade: N/A')
  })

  describe('grading type support', () => {
    it('displays percentage grade for percent grading type', () => {
      const submission = {
        ...mockSubmission,
        grade: '85',
        score: 85,
        assignment: {
          ...mockSubmission.assignment,
          gradingType: 'percent',
          pointsPossible: 100,
        },
      }
      renderWithContext(<ExpandedGradeView submission={submission} />)
      expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('85%')
    })

    it('displays points grade for points grading type', () => {
      const submission = {
        ...mockSubmission,
        grade: '8.5',
        score: 8.5,
        assignment: {
          ...mockSubmission.assignment,
          gradingType: 'points',
          pointsPossible: 10,
        },
      }
      renderWithContext(<ExpandedGradeView submission={submission} />)
      expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('8.5')
    })

    it('displays letter grade for letter_grade grading type', () => {
      const submission = {
        ...mockSubmission,
        grade: 'B+',
        assignment: {
          ...mockSubmission.assignment,
          gradingType: 'letter_grade',
        },
      }
      renderWithContext(<ExpandedGradeView submission={submission} />)
      expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('B+')
    })

    it('displays Complete for pass_fail grading type with passing grade', () => {
      const submission = {
        ...mockSubmission,
        grade: 'complete',
        score: 1,
        assignment: {
          ...mockSubmission.assignment,
          gradingType: 'pass_fail',
        },
      }
      renderWithContext(<ExpandedGradeView submission={submission} />)
      expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('complete')
    })

    it('displays Incomplete for pass_fail grading type with failing grade', () => {
      const submission = {
        ...mockSubmission,
        grade: 'incomplete',
        score: 0,
        assignment: {
          ...mockSubmission.assignment,
          gradingType: 'pass_fail',
        },
      }
      renderWithContext(<ExpandedGradeView submission={submission} />)
      expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('incomplete')
    })

    it('displays Excused for excused submissions', () => {
      const submission = {
        ...mockSubmission,
        grade: null,
        score: null,
        excused: true,
        assignment: {
          ...mockSubmission.assignment,
          gradingType: 'points',
        },
      }
      renderWithContext(<ExpandedGradeView submission={submission} />)
      expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('Excused')
    })

    it('displays GPA for gpa_scale grading type', () => {
      const submission = {
        ...mockSubmission,
        grade: '4.0',
        assignment: {
          ...mockSubmission.assignment,
          gradingType: 'gpa_scale',
        },
      }
      renderWithContext(<ExpandedGradeView submission={submission} />)
      expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('4.0')
    })

    it('displays No grade when grade is null', () => {
      const submission = {
        ...mockSubmission,
        grade: null,
        score: null,
        assignment: {
          ...mockSubmission.assignment,
          gradingType: 'points',
        },
      }
      renderWithContext(<ExpandedGradeView submission={submission} />)
      expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('No grade')
    })
  })
})
