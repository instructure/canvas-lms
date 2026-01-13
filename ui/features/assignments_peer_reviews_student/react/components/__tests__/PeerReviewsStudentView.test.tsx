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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import PeerReviewsStudentView from '../PeerReviewsStudentView'
import {executeQuery} from '@canvas/graphql'
import {useAllocatePeerReviews} from '../../hooks/useAllocatePeerReviews'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import {useReviewerSubmissionQuery} from '../../hooks/useReviewerSubmissionQuery'

vi.mock('@canvas/graphql', () => ({
  executeQuery: vi.fn(),
}))

vi.mock('@canvas/util/jquery/apiUserContent', () => ({
  default: {
    convert: (html: string) => html,
  },
}))

vi.mock('../../hooks/useAllocatePeerReviews', () => ({
  useAllocatePeerReviews: vi.fn(),
}))

vi.mock('../../hooks/useReviewerSubmissionQuery', () => ({
  useReviewerSubmissionQuery: jest.fn(),
}))

const mockExecuteQuery = vi.mocked(executeQuery)
const mockUseAllocatePeerReviews = vi.mocked(useAllocatePeerReviews)
const mockUseReviewerSubmissionQuery = vi.mocked(useReviewerSubmissionQuery)

type PeerReviewsStudentViewProps = React.ComponentProps<typeof PeerReviewsStudentView>

const buildDefaultProps = (
  overrides: Partial<PeerReviewsStudentViewProps> = {},
): PeerReviewsStudentViewProps => ({
  assignmentId: '1',
  breakpoints: {
    mobileOnly: false,
    tablet: false,
    desktop: true,
  },
  ...overrides,
})

function setup(props: Partial<PeerReviewsStudentViewProps> = {}) {
  const defaultProps = buildDefaultProps(props)
  return render(
    <MockedQueryProvider>
      <PeerReviewsStudentView {...defaultProps} />
    </MockedQueryProvider>,
  )
}

describe('PeerReviewsStudentView', () => {
  let globalEnv: GlobalEnv
  const mockMutate = vi.fn()
  const ENV = {
    current_user_id: '123',
    restrict_quantitative_data: false,
  }

  beforeAll(() => {
    globalEnv = {...window.ENV}
  })

  beforeEach(() => {
    vi.clearAllMocks()
    queryClient.clear()
    window.ENV = {...globalEnv, ...ENV}
    mockUseAllocatePeerReviews.mockReturnValue({
      mutate: mockMutate,
    } as any)
    mockUseReviewerSubmissionQuery.mockReturnValue({
      data: {
        _id: 'reviewer-sub-1',
        id: 'U3VibWlzc2lvbi0x',
        attempt: 1,
        assignedAssessments: [],
      },
      isLoading: false,
      isError: false,
    } as any)
  })

  it('renders loading state initially', () => {
    mockExecuteQuery.mockImplementation(() => new Promise(() => {}))

    const {getByText} = setup()

    expect(getByText('Loading assignment details')).toBeInTheDocument()
  })

  it('renders error state when query fails', async () => {
    mockExecuteQuery.mockRejectedValueOnce(new Error('Failed to fetch'))

    const {getByText} = setup()

    await waitFor(() => {
      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  it('renders error state when query returns null data', async () => {
    mockExecuteQuery.mockResolvedValueOnce(null)

    const {getByText} = setup()

    await waitFor(() => {
      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  it('renders error state when query returns undefined assignment', async () => {
    mockExecuteQuery.mockResolvedValueOnce({assignment: undefined})

    const {getByText} = setup()

    await waitFor(() => {
      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  it('renders error state when query returns empty object', async () => {
    mockExecuteQuery.mockResolvedValueOnce({})

    const {getByText} = setup()

    await waitFor(() => {
      expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  it('renders assignment details successfully', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '1',
        name: 'Test Peer Review Assignment',
        description: '<p>This is the assignment description</p>',
        courseId: '100',
        peerReviews: {
          count: 2,
          submissionRequired: false,
        },
        submissionsConnection: {
          nodes: [{_id: 'sub-1', submissionStatus: 'submitted'}],
        },
        assignedToDates: [
          {
            dueAt: '2025-12-31T23:59:59Z',
            peerReviewDates: {
              dueAt: '2025-12-31T23:59:59Z',
              unlockAt: null,
              lockAt: null,
            },
          },
        ],
        assessmentRequestsForCurrentUser: [
          {
            _id: 'ar-1',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-01T00:00:00Z',
          },
          {
            _id: 'ar-2',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-02T00:00:00Z',
          },
        ],
      },
    })

    const {getByTestId, getByText} = setup()

    await waitFor(() => {
      expect(getByTestId('title')).toHaveTextContent('Test Peer Review Assignment')
    })

    expect(getByTestId('due-date')).toBeInTheDocument()
    expect(getByText('Assignment Details')).toBeInTheDocument()
  })

  it('renders assignment without due date', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '2',
        name: 'Assignment Without Due Date',
        dueAt: null,
        description: '<p>Description here</p>',
        courseId: '100',
        peerReviews: {
          count: 1,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: [],
      },
    })

    const {getByTestId, queryByTestId} = setup({assignmentId: '2'})

    await waitFor(() => {
      expect(getByTestId('title')).toHaveTextContent('Assignment Without Due Date')
    })

    expect(queryByTestId('due-date')).not.toBeInTheDocument()
  })

  it('renders assignment without description', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '3',
        name: 'Assignment Without Description',
        dueAt: '2025-12-31T23:59:59Z',
        description: null,
        courseId: '100',
        peerReviews: {
          count: 2,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: [],
      },
    })

    const {getByTestId, getByText} = setup({assignmentId: '3'})

    await waitFor(() => {
      expect(getByTestId('title')).toHaveTextContent('Assignment Without Description')
    })

    expect(getByText('No additional details were added for this assignment.')).toBeInTheDocument()
  })

  it('renders both tabs', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '5',
        name: 'Test Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Description</p>',
        courseId: '100',
        peerReviews: {
          count: 1,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: [],
      },
    })

    const {getByText} = setup({assignmentId: '5'})

    await waitFor(() => {
      expect(getByText('Assignment Details')).toBeInTheDocument()
    })

    expect(getByText('Submission')).toBeInTheDocument()
  })

  it('renders peer review selector when assessment requests exist', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '6',
        name: 'Peer Review Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Assignment description</p>',
        courseId: '100',
        peerReviews: {
          count: 2,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: [
          {
            _id: 'ar-1',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-01T00:00:00Z',
          },
          {
            _id: 'ar-2',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-02T00:00:00Z',
          },
        ],
      },
    })

    const {getByTestId} = setup({assignmentId: '6'})

    await waitFor(() => {
      expect(getByTestId('peer-review-selector')).toBeInTheDocument()
    })
  })

  it('renders peer review selector with no reviews message when assessment requests are null', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '8',
        name: 'Assignment No Reviews',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Description</p>',
        courseId: '100',
        peerReviews: {
          count: 0,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: null,
      },
    })

    const {getByTestId} = setup({assignmentId: '8'})

    await waitFor(() => {
      const selector = getByTestId('peer-review-selector')
      expect(selector).toBeInTheDocument()
      expect(selector).toHaveAttribute('value', 'No peer reviews available')
    })
  })

  it('calls allocate when assessment requests count is less than peer reviews required', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '10',
        name: 'Test Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Description</p>',
        courseId: '100',
        peerReviews: {
          count: 3,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: [
          {
            _id: 'ar-1',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-01T00:00:00Z',
          },
        ],
      },
    })

    setup({assignmentId: '10'})

    await waitFor(() => {
      expect(mockMutate).toHaveBeenCalledWith({
        courseId: '100',
        assignmentId: '10',
      })
    })
  })

  describe('Submission tab', () => {
    it('renders submission when assessment request has a submission', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '9',
          name: 'Assignment With Submission',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          assignedToDates: null,
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
              submission: {
                _id: 'sub-1',
                attempt: 1,
                body: '<p>Student submission text</p>',
                submissionType: 'online_text_entry',
              },
            },
          ],
        },
      })

      const {getByText} = setup({assignmentId: '9'})

      await waitFor(() => {
        expect(getByText('Submission')).toBeInTheDocument()
      })
    })

    it('renders AssignmentSubmission component with correct submission data', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '11',
          name: 'Assignment With Text Entry',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          assignedToDates: null,
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
              submission: {
                _id: 'sub-1',
                attempt: 1,
                body: '<p>This is the peer review submission</p>',
                submissionType: 'online_text_entry',
              },
            },
          ],
        },
      })

      const {getByTestId, getByText} = setup({assignmentId: '11'})

      await waitFor(() => {
        expect(getByText('Submission')).toBeInTheDocument()
      })

      const user = userEvent.setup()
      await user.click(getByText('Submission'))

      await waitFor(() => {
        expect(getByTestId('text-entry-content')).toBeInTheDocument()
      })

      expect(getByTestId('text-entry-content')).toHaveTextContent(
        'This is the peer review submission',
      )
    })

    it('updates submission display when peer review selection changes', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '12',
          name: 'Multiple Peer Reviews',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          assignedToDates: null,
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
              submission: {
                _id: 'sub-1',
                attempt: 1,
                body: '<p>First submission</p>',
                submissionType: 'online_text_entry',
              },
            },
            {
              _id: 'ar-2',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-02T00:00:00Z',
              submission: {
                _id: 'sub-2',
                attempt: 1,
                body: '<p>Second submission</p>',
                submissionType: 'online_text_entry',
              },
            },
          ],
        },
      })

      const {getByTestId, getByText} = setup({assignmentId: '12'})

      await waitFor(() => {
        expect(getByText('Submission')).toBeInTheDocument()
      })

      const user = userEvent.setup()
      await user.click(getByText('Submission'))

      await waitFor(() => {
        expect(getByTestId('text-entry-content')).toHaveTextContent('First submission')
      })

      const selector = getByTestId('peer-review-selector')
      await user.click(selector)

      const secondOption = getByText('Peer Review (2 of 2)')
      await user.click(secondOption)

      await waitFor(() => {
        expect(getByTestId('text-entry-content')).toHaveTextContent('Second submission')
      })
    })
  })

  it('does not call allocate when assessment requests count equals peer reviews required', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '11',
        name: 'Test Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Description</p>',
        courseId: '100',
        peerReviews: {
          count: 2,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: [
          {
            _id: 'ar-1',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-01T00:00:00Z',
          },
          {
            _id: 'ar-2',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-02T00:00:00Z',
          },
        ],
      },
    })

    setup({assignmentId: '11'})

    await waitFor(() => {
      expect(mockMutate).not.toHaveBeenCalled()
    })
  })

  it('does not call allocate when no peer reviews are required', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '12',
        name: 'Test Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Description</p>',
        courseId: '100',
        peerReviews: {
          count: 0,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: [],
      },
    })

    setup({assignmentId: '12'})

    await waitFor(() => {
      expect(mockMutate).not.toHaveBeenCalled()
    })
  })

  it('calls allocate only once even if component re-renders', async () => {
    mockExecuteQuery.mockResolvedValue({
      assignment: {
        _id: '13',
        name: 'Test Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>Description</p>',
        courseId: '100',
        peerReviews: {
          count: 2,
        },
        assignedToDates: null,
        assessmentRequestsForCurrentUser: [
          {
            _id: 'ar-1',
            available: true,
            workflowState: 'assigned',
            createdAt: '2025-11-01T00:00:00Z',
          },
        ],
      },
    })

    const {rerender} = setup({assignmentId: '13'})

    await waitFor(() => {
      expect(mockMutate).toHaveBeenCalledTimes(1)
    })

    rerender(
      <MockedQueryProvider>
        <PeerReviewsStudentView
          assignmentId="13"
          breakpoints={{mobileOnly: false, tablet: false, desktop: true}}
        />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(mockMutate).toHaveBeenCalledTimes(1)
    })
  })

  describe('Tab switching', () => {
    it('switches between Assignment Details and Submission tabs', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '13',
          name: 'Tab Switching Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Assignment description here</p>',
          assignedToDates: null,
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
              submission: {
                _id: 'sub-1',
                attempt: 1,
                body: '<p>Submission text</p>',
                submissionType: 'online_text_entry',
              },
            },
          ],
        },
      })

      const {getByText, getByTestId} = setup({assignmentId: '13'})

      await waitFor(() => {
        expect(getByText('Assignment Details')).toBeInTheDocument()
      })

      expect(getByText('Assignment description here')).toBeInTheDocument()

      const user = userEvent.setup()
      await user.click(getByText('Submission'))

      await waitFor(() => {
        expect(getByTestId('text-entry-content')).toBeInTheDocument()
      })
    })

    it('defaults to Assignment Details tab on initial render', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '14',
          name: 'Default Tab Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description content</p>',
          assignedToDates: null,
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
              submission: {
                _id: 'sub-1',
                attempt: 1,
                body: '<p>Submission</p>',
                submissionType: 'online_text_entry',
              },
            },
          ],
        },
      })

      const {getByText} = setup({assignmentId: '14'})

      await waitFor(() => {
        expect(getByText('Description content')).toBeInTheDocument()
      })
    })
  })

  describe('Mobile view', () => {
    it('renders mobile tab labels when mobileOnly is true', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '15',
          name: 'Mobile Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          assignedToDates: null,
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByText} = setup({
        assignmentId: '15',
        breakpoints: {mobileOnly: true, tablet: false, desktop: false},
      })

      await waitFor(() => {
        expect(getByText('Assignment')).toBeInTheDocument()
      })

      expect(getByText('Peer Review')).toBeInTheDocument()
    })

    it('renders desktop tab labels when mobileOnly is false', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '16',
          name: 'Desktop Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          assignedToDates: null,
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByText} = setup({
        assignmentId: '16',
        breakpoints: {mobileOnly: false, tablet: false, desktop: true},
      })

      await waitFor(() => {
        expect(getByText('Assignment Details')).toBeInTheDocument()
      })

      expect(getByText('Submission')).toBeInTheDocument()
    })

    it('renders divider on mobile', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '17',
          name: 'Mobile Divider Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          assignedToDates: null,
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {container} = setup({
        assignmentId: '17',
        breakpoints: {mobileOnly: true, tablet: false, desktop: false},
      })

      await waitFor(() => {
        const dividers = container.querySelectorAll('hr')
        expect(dividers.length).toBeGreaterThan(0)
      })
    })
  })

  describe('Submission required for peer reviews', () => {
    it('shows submission required view when submissionRequired is true and user has not submitted', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '18',
          name: 'Submission Required Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: true,
          },
          submissionsConnection: {
            nodes: [],
          },
          assessmentRequestsForCurrentUser: [],
          assignedToDates: [
            {
              dueAt: '2025-12-31T23:59:59Z',
              peerReviewDates: {
                dueAt: '2025-12-31T23:59:59Z',
                unlockAt: null,
              },
            },
          ],
        },
      })

      const {getByText, getByTestId} = setup({assignmentId: '18'})

      await waitFor(() => {
        expect(
          getByText('You must submit your own work before you can review your peers.'),
        ).toBeInTheDocument()
      })

      expect(getByTestId('title')).toHaveTextContent('Submission Required Test Peer Review')
      expect(getByTestId('due-date')).toBeInTheDocument()
    })

    it('does not call allocate when submissionRequired is true and user has not submitted', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '22',
          name: 'No Allocate Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 3,
            submissionRequired: true,
          },
          submissionsConnection: {
            nodes: [],
          },
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
            },
          ],
        },
      })

      setup({assignmentId: '22'})

      await waitFor(() => {
        expect(mockMutate).not.toHaveBeenCalled()
      })
    })

    it('shows peer review interface when submissionRequired is true and user has submitted', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '19',
          name: 'User Has Submitted Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: true,
          },
          submissionsConnection: {
            nodes: [{_id: 'sub-1', submissionStatus: 'submitted'}],
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByText} = setup({assignmentId: '19'})

      await waitFor(() => {
        expect(getByText('Assignment Details')).toBeInTheDocument()
      })
    })

    it('shows peer review interface when submissionRequired is false even if user has not submitted', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '20',
          name: 'Submission Not Required Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: false,
          },
          submissionsConnection: {
            nodes: [],
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByText} = setup({assignmentId: '20'})

      await waitFor(() => {
        expect(getByText('Assignment Details')).toBeInTheDocument()
      })
    })

    it('shows peer review interface when submissionRequired is null', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '21',
          name: 'Submission Required Null Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: null,
          },
          submissionsConnection: {
            nodes: [],
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByText} = setup({assignmentId: '21'})

      await waitFor(() => {
        expect(getByText('Assignment Details')).toBeInTheDocument()
      })
    })

    it('does not show peer review selector when submission is required and user has not submitted', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '23',
          name: 'No Selector Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: true,
          },
          submissionsConnection: {
            nodes: [],
          },
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
            },
          ],
        },
      })

      const {queryByTestId, getByText} = setup({assignmentId: '23'})

      await waitFor(() => {
        expect(
          getByText('You must submit your own work before you can review your peers.'),
        ).toBeInTheDocument()
      })

      expect(queryByTestId('peer-review-selector')).not.toBeInTheDocument()
    })

    it('shows peer review selector when submission is required and user has submitted', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '24',
          name: 'Show Selector Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: true,
          },
          submissionsConnection: {
            nodes: [{_id: 'sub-1', submissionStatus: 'submitted'}],
          },
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2025-11-01T00:00:00Z',
            },
          ],
        },
      })

      const {getByTestId} = setup({assignmentId: '24'})

      await waitFor(() => {
        expect(getByTestId('peer-review-selector')).toBeInTheDocument()
      })
    })

    it('does not show tabs when submission is required and user has not submitted', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '25',
          name: 'No Tabs Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: true,
          },
          submissionsConnection: {
            nodes: [],
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {queryByText, getByText} = setup({assignmentId: '25'})

      await waitFor(() => {
        expect(
          getByText('You must submit your own work before you can review your peers.'),
        ).toBeInTheDocument()
      })

      expect(queryByText('Assignment Details')).not.toBeInTheDocument()
      expect(queryByText('Submission')).not.toBeInTheDocument()
    })

    it('shows tabs when submission is required and user has submitted', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '26',
          name: 'Show Tabs Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: true,
          },
          submissionsConnection: {
            nodes: [{_id: 'sub-1', submissionStatus: 'submitted'}],
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByText} = setup({assignmentId: '26'})

      await waitFor(() => {
        expect(getByText('Assignment Details')).toBeInTheDocument()
      })

      expect(getByText('Submission')).toBeInTheDocument()
    })
  })

  describe('Locked peer review', () => {
    beforeEach(() => {
      vi.useFakeTimers()
      vi.setSystemTime(new Date('2020-10-01T12:00:00Z'))
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('renders locked view when peer review is locked before assignment due date', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '18',
          name: 'Locked Assignment',
          dueAt: '2020-09-15T16:00:00Z',
          description: '<p>Description</p>',
          assessmentRequestsForCurrentUser: [],
          assignedToDates: [
            {
              dueAt: '2020-10-20T16:00:00Z',
              peerReviewDates: null,
            },
          ],
        },
      })

      const {getByTestId, queryByTestId} = setup({assignmentId: '18'})

      await waitFor(() => {
        expect(getByTestId('locked-peer-review')).toBeInTheDocument()
      })

      expect(queryByTestId('peer-review-selector')).not.toBeInTheDocument()
    })

    it('renders locked view when peer review is locked before peer review unlock date', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '19',
          name: 'Locked Peer Review',
          dueAt: '2020-09-15T16:00:00Z',
          description: '<p>Description</p>',
          assessmentRequestsForCurrentUser: [],
          assignedToDates: [
            {
              dueAt: '2020-09-15T16:00:00Z',
              peerReviewDates: {
                unlockAt: '2020-10-31T06:00:00Z',
                dueAt: null,
                lockAt: null,
              },
            },
          ],
        },
      })

      const {getByTestId, queryByTestId} = setup({assignmentId: '19'})

      await waitFor(() => {
        expect(getByTestId('locked-peer-review')).toBeInTheDocument()
      })

      expect(queryByTestId('peer-review-selector')).not.toBeInTheDocument()
    })

    it('renders normal view when peer review is not locked', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '20',
          name: 'Unlocked Assignment',
          dueAt: '2020-09-15T16:00:00Z',
          description: '<p>Description</p>',
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2020-09-10T00:00:00Z',
            },
          ],
          assignedToDates: [
            {
              dueAt: '2020-09-20T16:00:00Z',
              peerReviewDates: null,
            },
          ],
        },
      })

      const {getByTestId, queryByTestId} = setup({assignmentId: '20'})

      await waitFor(() => {
        expect(getByTestId('peer-review-selector')).toBeInTheDocument()
      })

      expect(queryByTestId('locked-peer-review')).not.toBeInTheDocument()
    })

    it('renders normal view when peer review unlock date has passed', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '21',
          name: 'Unlocked Peer Review',
          dueAt: '2020-09-15T16:00:00Z',
          description: '<p>Description</p>',
          assessmentRequestsForCurrentUser: [
            {
              _id: 'ar-1',
              available: true,
              workflowState: 'assigned',
              createdAt: '2020-09-10T00:00:00Z',
            },
          ],
          assignedToDates: [
            {
              dueAt: '2020-09-20T16:00:00Z',
              peerReviewDates: {
                unlockAt: '2020-09-30T06:00:00Z',
                dueAt: null,
                lockAt: null,
              },
            },
          ],
        },
      })

      const {getByTestId, queryByTestId} = setup({assignmentId: '21'})

      await waitFor(() => {
        expect(getByTestId('peer-review-selector')).toBeInTheDocument()
      })

      expect(queryByTestId('locked-peer-review')).not.toBeInTheDocument()
    })

    it('renders locked message with correct date', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '22',
          name: 'Locked With Date',
          dueAt: '2020-09-15T16:00:00Z',
          description: '<p>Description</p>',
          assessmentRequestsForCurrentUser: [],
          assignedToDates: [
            {
              dueAt: '2020-10-20T16:00:00Z',
              peerReviewDates: null,
            },
          ],
        },
      })

      const {getByText} = setup({assignmentId: '22'})

      await waitFor(() => {
        expect(getByText(/This assignment is locked until/)).toBeInTheDocument()
      })
    })

    it('does not allocate peer reviews when peer review is locked', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '23',
          name: 'Locked Assignment No Allocate',
          dueAt: '2020-09-15T16:00:00Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 3,
          },
          assessmentRequestsForCurrentUser: [],
          assignedToDates: [
            {
              dueAt: '2020-10-20T16:00:00Z',
              peerReviewDates: null,
            },
          ],
        },
      })

      setup({assignmentId: '23'})

      await waitFor(() => {
        expect(mockMutate).not.toHaveBeenCalled()
      })
    })
  })

  describe('useReviewerSubmissionQuery', () => {
    it('called with correct parameters', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '22',
          name: 'Hook Parameters Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {count: 1},
          assessmentRequestsForCurrentUser: [],
        },
      })

      setup({assignmentId: '22'})

      await waitFor(() => {
        expect(mockUseReviewerSubmissionQuery).toHaveBeenCalledWith('22', '123')
      })
    })
  })

  describe('Points display', () => {
    it('displays total points when points are provided', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '27',
          name: 'Points Display Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 3,
            submissionRequired: false,
            pointsPossible: 6,
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByTestId} = setup({assignmentId: '27'})

      await waitFor(() => {
        expect(getByTestId('total-points')).toBeInTheDocument()
      })

      expect(getByTestId('total-points')).toHaveTextContent('6 Points Possible')
    })

    it('displays singular "Point" when points are 1', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '28',
          name: 'Single Point Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 3,
            submissionRequired: false,
            pointsPossible: 1,
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByTestId} = setup({assignmentId: '28'})

      await waitFor(() => {
        expect(getByTestId('total-points')).toBeInTheDocument()
      })

      expect(getByTestId('total-points')).toHaveTextContent('1 Point Possible')
    })

    it('displays 0 points when points are zero', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '29',
          name: 'Zero Points Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 3,
            submissionRequired: false,
            pointsPossible: 0,
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {getByTestId} = setup({assignmentId: '29'})

      await waitFor(() => {
        expect(getByTestId('total-points')).toBeInTheDocument()
      })

      expect(getByTestId('total-points')).toHaveTextContent('0 Points Possible')
    })

    it('does not display points when points are null', async () => {
      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '30',
          name: 'Null Points Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 2,
            submissionRequired: false,
            pointsPossible: null,
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {queryByTestId} = setup({assignmentId: '30'})

      await waitFor(() => {
        expect(queryByTestId('total-points')).not.toBeInTheDocument()
      })
    })

    it('does not display points when restrict_quantitative_data is enabled', async () => {
      window.ENV.restrict_quantitative_data = true

      mockExecuteQuery.mockResolvedValueOnce({
        assignment: {
          _id: '31',
          name: 'RQD Test',
          dueAt: '2025-12-31T23:59:59Z',
          description: '<p>Description</p>',
          courseId: '100',
          peerReviews: {
            count: 3,
            submissionRequired: false,
            pointsPossible: 10,
          },
          assessmentRequestsForCurrentUser: [],
        },
      })

      const {queryByTestId} = setup({assignmentId: '31'})

      await waitFor(() => {
        expect(queryByTestId('total-points')).not.toBeInTheDocument()
      })

      window.ENV.restrict_quantitative_data = false
    })
  })
})
