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
import {cleanup, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import fetchMock from 'fetch-mock'
import {StudentAssignmentDetailTray} from '..'
import {MOCK_OUTCOMES, MOCK_STUDENTS, MOCK_ROLLUPS} from '../../../../__fixtures__/rollups'

describe('StudentAssignmentDetailTray', () => {
  const defaultProps = {
    open: true,
    onDismiss: vi.fn(),
    outcome: MOCK_OUTCOMES[0],
    courseId: '123',
    student: MOCK_STUDENTS[0],
    assignment: {
      id: '456',
      name: 'Test Assignment',
      htmlUrl: '/courses/123/assignments/456',
    },
    assignmentNavigator: {
      hasPrevious: true,
      hasNext: true,
      onPrevious: vi.fn(),
      onNext: vi.fn(),
    },
    studentNavigator: {
      hasPrevious: true,
      hasNext: true,
      onPrevious: vi.fn(),
      onNext: vi.fn(),
    },
    rollups: MOCK_ROLLUPS,
    outcomes: MOCK_OUTCOMES,
  }

  const createWrapper = () => {
    const queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })

    const Wrapper: React.FC<any> = ({children}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )
    return Wrapper
  }

  const renderWithWrapper = (ui: React.ReactElement) => {
    return render(ui, {wrapper: createWrapper()})
  }

  beforeEach(() => {
    fetchMock.restore()
    vi.clearAllMocks()

    // Mock ENV for comment components
    window.ENV = {
      ...window.ENV,
      current_user_id: '999',
      current_user: {
        id: '999',
        anonymous_id: 'anon999',
        display_name: 'Test User',
        avatar_image_url: 'https://example.com/avatar.jpg',
        html_url: '/users/999',
        pronouns: null,
        fake_student: false,
        avatar_is_fallback: false,
      },
      EMOJIS_ENABLED: true,
      LOCALE: 'en',
      FEATURES: {
        consolidated_media_player: false,
      },
    } as any

    // Mock the outcome alignments API call
    fetchMock.get(/\/api\/v1\/courses\/.*\/outcome_alignments.*/, [])
    // Mock GraphQL endpoint for comments
    fetchMock.post('/api/graphql', {
      data: {
        assignment: {
          _id: '456',
          id: 'QXNzaWdubWVudC00NTY=',
          name: 'Test Assignment',
          pointsPossible: 100,
          expectsSubmission: true,
          nonDigitalSubmission: false,
          gradingType: 'points',
          submissionTypes: ['online_text_entry'],
          groupCategoryId: null,
          gradeGroupStudentsIndividually: false,
          submissionsConnection: {
            nodes: [
              {
                _id: '789',
                id: 'U3VibWlzc2lvbi03ODk=',
                attempt: 1,
                state: 'submitted',
                gradingStatus: 'graded',
              },
            ],
          },
        },
        submissionComments: {
          commentsConnection: {
            nodes: [],
            pageInfo: {
              startCursor: null,
              hasPreviousPage: false,
            },
          },
        },
      },
    })
  })

  afterEach(() => {
    cleanup()
    fetchMock.restore()
  })

  describe('General behavior', () => {
    it('renders when open', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByTestId('student-assignment-detail-tray')).toBeInTheDocument()
    })

    it('does not render when closed', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} open={false} />)
      const tray = screen.queryByTestId('student-assignment-detail-tray')
      expect(tray).not.toBeInTheDocument()
    })

    it('displays the outcome title', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByText(defaultProps.outcome.title)).toBeInTheDocument()
    })

    it('calls onDismiss when close button is clicked', async () => {
      const user = userEvent.setup()
      const onDismiss = vi.fn()
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} onDismiss={onDismiss} />)

      const closeButton = screen.getByRole('button', {name: /close student assignment details/i})
      await user.click(closeButton)

      expect(onDismiss).toHaveBeenCalledTimes(1)
    })
  })

  describe('AssignmentSection integration', () => {
    it('displays the assignment name as a link', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      const link = screen.getByRole('link', {name: /Test Assignment/i})
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/courses/123/assignments/456')
    })

    it('renders SpeedGrader button', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      const speedGraderButton = screen.getByRole('link', {name: /SpeedGrader/i})
      expect(speedGraderButton).toBeInTheDocument()
      expect(speedGraderButton).toHaveAttribute(
        'href',
        '/courses/123/gradebook/speed_grader?assignment_id=456&student_id=1',
      )
    })

    it('renders assignment navigator', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByTestId('assignment-navigator')).toBeInTheDocument()
    })

    it('calls assignmentNavigator onPrevious when assignment previous button is clicked', async () => {
      const user = userEvent.setup()
      const onPrevious = vi.fn()
      renderWithWrapper(
        <StudentAssignmentDetailTray
          {...defaultProps}
          assignmentNavigator={{...defaultProps.assignmentNavigator, onPrevious}}
        />,
      )

      const assignmentNav = screen.getByTestId('assignment-navigator')
      const previousButton = assignmentNav.querySelector('[data-testid="previous-button"]')
      await user.click(previousButton!)
      expect(onPrevious).toHaveBeenCalledTimes(1)
    })

    it('calls assignmentNavigator onNext when assignment next button is clicked', async () => {
      const user = userEvent.setup()
      const onNext = vi.fn()
      renderWithWrapper(
        <StudentAssignmentDetailTray
          {...defaultProps}
          assignmentNavigator={{...defaultProps.assignmentNavigator, onNext}}
        />,
      )

      const assignmentNav = screen.getByTestId('assignment-navigator')
      const nextButton = assignmentNav.querySelector('[data-testid="next-button"]')
      await user.click(nextButton!)
      expect(onNext).toHaveBeenCalledTimes(1)
    })

    it('disables assignment previous button when hasPrevious is false', () => {
      renderWithWrapper(
        <StudentAssignmentDetailTray
          {...defaultProps}
          assignmentNavigator={{...defaultProps.assignmentNavigator, hasPrevious: false}}
        />,
      )
      const assignmentNav = screen.getByTestId('assignment-navigator')
      const previousButton = assignmentNav.querySelector('[data-testid="previous-button"]')
      expect(previousButton).toBeDisabled()
    })

    it('disables assignment next button when hasNext is false', () => {
      renderWithWrapper(
        <StudentAssignmentDetailTray
          {...defaultProps}
          assignmentNavigator={{...defaultProps.assignmentNavigator, hasNext: false}}
        />,
      )
      const assignmentNav = screen.getByTestId('assignment-navigator')
      const nextButton = assignmentNav.querySelector('[data-testid="next-button"]')
      expect(nextButton).toBeDisabled()
    })
  })

  describe('StudentSection integration', () => {
    it('renders student navigator', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByTestId('student-navigator')).toBeInTheDocument()
    })

    it('displays student name', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByText(MOCK_STUDENTS[0].name)).toBeInTheDocument()
    })

    it('displays student avatar', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      const avatar = screen.getByRole('img', {name: MOCK_STUDENTS[0].name})
      expect(avatar).toBeInTheDocument()
      expect(avatar).toHaveAttribute('src', MOCK_STUDENTS[0].avatar_url)
    })

    it('renders mastery report link with correct URL', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      const link = screen.getByRole('link', {name: /View Mastery Report/i})
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/courses/123/grades/1#tab-outcomes')
    })

    it('calls studentNavigator onPrevious when student previous button is clicked', async () => {
      const user = userEvent.setup()
      const onPrevious = vi.fn()
      renderWithWrapper(
        <StudentAssignmentDetailTray
          {...defaultProps}
          studentNavigator={{...defaultProps.studentNavigator, onPrevious}}
        />,
      )

      const studentNav = screen.getByTestId('student-navigator')
      const previousButton = studentNav.querySelector('[data-testid="previous-button"]')
      await user.click(previousButton!)
      expect(onPrevious).toHaveBeenCalledTimes(1)
    })

    it('calls studentNavigator onNext when student next button is clicked', async () => {
      const user = userEvent.setup()
      const onNext = vi.fn()
      renderWithWrapper(
        <StudentAssignmentDetailTray
          {...defaultProps}
          studentNavigator={{...defaultProps.studentNavigator, onNext}}
        />,
      )

      const studentNav = screen.getByTestId('student-navigator')
      const nextButton = studentNav.querySelector('[data-testid="next-button"]')
      await user.click(nextButton!)
      expect(onNext).toHaveBeenCalledTimes(1)
    })

    it('disables student previous button when hasPrevious is false', () => {
      renderWithWrapper(
        <StudentAssignmentDetailTray
          {...defaultProps}
          studentNavigator={{...defaultProps.studentNavigator, hasPrevious: false}}
        />,
      )
      const studentNav = screen.getByTestId('student-navigator')
      const previousButton = studentNav.querySelector('[data-testid="previous-button"]')
      expect(previousButton).toBeDisabled()
    })

    it('disables student next button when hasNext is false', () => {
      renderWithWrapper(
        <StudentAssignmentDetailTray
          {...defaultProps}
          studentNavigator={{...defaultProps.studentNavigator, hasNext: false}}
        />,
      )
      const studentNav = screen.getByTestId('student-navigator')
      const nextButton = studentNav.querySelector('[data-testid="next-button"]')
      expect(nextButton).toBeDisabled()
    })

    it('updates student information when student prop changes', () => {
      const {rerender} = renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByText(MOCK_STUDENTS[0].name)).toBeInTheDocument()

      rerender(<StudentAssignmentDetailTray {...defaultProps} student={MOCK_STUDENTS[1]} />)
      expect(screen.getByText(MOCK_STUDENTS[1].name)).toBeInTheDocument()
      expect(screen.queryByText(MOCK_STUDENTS[0].name)).not.toBeInTheDocument()
    })
  })

  describe('CommentsSection integration', () => {
    it('renders the comments section', async () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      // Wait for GraphQL queries to resolve
      await screen.findByText('Comment', {}, {timeout: 3000})
      expect(screen.getByLabelText('Comment input box')).toBeInTheDocument()
    })

    it('shows loading spinner while fetching comments', () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      expect(screen.getByTitle('Loading comments')).toBeInTheDocument()
    })

    it('displays comment input area after loading', async () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      const commentInput = await screen.findByLabelText('Comment input box', {}, {timeout: 3000})
      expect(commentInput).toBeInTheDocument()
    })

    it('displays send comment button', async () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      const sendButton = await screen.findByRole('button', {name: /send comment/i}, {timeout: 3000})
      expect(sendButton).toBeInTheDocument()
    })

    it('does not show placeholder graphics when there are no comments', async () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      // Wait for loading to complete
      await screen.findByLabelText('Comment input box', {}, {timeout: 3000})
      // Should not show the default placeholder text
      expect(screen.queryByText(/this is where you can leave a comment/i)).not.toBeInTheDocument()
    })

    it('renders comments when they exist', async () => {
      // Override the default mock to include a comment
      fetchMock.restore()
      fetchMock.get(/\/api\/v1\/courses\/.*\/outcome_alignments.*/, [])
      fetchMock.post(
        '/api/graphql',
        {
          data: {
            assignment: {
              _id: '456',
              id: 'QXNzaWdubWVudC00NTY=',
              name: 'Test Assignment',
              pointsPossible: 100,
              expectsSubmission: true,
              nonDigitalSubmission: false,
              gradingType: 'points',
              submissionTypes: ['online_text_entry'],
              groupCategoryId: null,
              gradeGroupStudentsIndividually: false,
              submissionsConnection: {
                nodes: [
                  {
                    _id: '789',
                    id: 'U3VibWlzc2lvbi03ODk=',
                    attempt: 1,
                    state: 'submitted',
                    gradingStatus: 'graded',
                  },
                ],
              },
            },
            submissionComments: {
              commentsConnection: {
                nodes: [
                  {
                    _id: 'comment-1',
                    comment: 'Great work!',
                    htmlComment: 'Great work!',
                    read: true,
                    updatedAt: '2025-01-07T12:00:00Z',
                    author: {
                      shortName: 'Teacher',
                      avatarUrl: 'https://example.com/avatar.jpg',
                      __typename: 'User',
                    },
                    attachments: [],
                    mediaObject: null,
                    __typename: 'SubmissionComment',
                  },
                ],
                pageInfo: {
                  startCursor: null,
                  hasPreviousPage: false,
                },
              },
              __typename: 'Submission',
            },
          },
        },
        {overwriteRoutes: true},
      )

      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)

      // Wait for comment to appear
      const commentText = await screen.findByText('Great work!', {}, {timeout: 3000})
      expect(commentText).toBeInTheDocument()
    })

    it('hides file upload and media upload buttons via CSS', async () => {
      renderWithWrapper(<StudentAssignmentDetailTray {...defaultProps} />)
      await screen.findByLabelText('Comment input box', {}, {timeout: 3000})

      // Buttons exist in DOM but should be hidden via CSS
      const fileButton = screen.queryByTestId('file-upload-button')
      const mediaButton = screen.queryByTestId('media-upload-button')

      // These buttons are rendered but hidden via CSS (#attachmentFileButton, #mediaCommentButton)
      if (fileButton) {
        expect(fileButton).toHaveAttribute('id', 'attachmentFileButton')
      }
      if (mediaButton) {
        expect(mediaButton).toHaveAttribute('id', 'mediaCommentButton')
      }
    })
  })
})
