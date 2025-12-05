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
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import PeerReviewsStudentView from '../PeerReviewsStudentView'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(),
}))

jest.mock('@canvas/util/jquery/apiUserContent', () => ({
  convert: (html: string) => html,
}))

jest.mock('../../hooks/useAllocatePeerReviews', () => ({
  useAllocatePeerReviews: jest.fn(),
}))

const {executeQuery} = require('@canvas/graphql')
const mockExecuteQuery = executeQuery as jest.MockedFunction<typeof executeQuery>

const {useAllocatePeerReviews} = require('../../hooks/useAllocatePeerReviews')
const mockUseAllocatePeerReviews = useAllocatePeerReviews as jest.MockedFunction<
  typeof useAllocatePeerReviews
>

type PeerReviewsStudentViewProps = React.ComponentProps<typeof PeerReviewsStudentView>

const buildDefaultProps = (
  overrides: Partial<PeerReviewsStudentViewProps> = {},
): PeerReviewsStudentViewProps => ({
  assignmentId: '1',
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
  const mockMutate = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
    queryClient.clear()
    mockUseAllocatePeerReviews.mockReturnValue({
      mutate: mockMutate,
    })
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
      expect(getByText('Failed to load assignment details')).toBeInTheDocument()
    })
  })

  it('renders assignment details successfully', async () => {
    mockExecuteQuery.mockResolvedValueOnce({
      assignment: {
        _id: '1',
        name: 'Test Peer Review Assignment',
        dueAt: '2025-12-31T23:59:59Z',
        description: '<p>This is the assignment description</p>',
        courseId: '100',
        peerReviews: {
          count: 2,
        },
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
        <PeerReviewsStudentView assignmentId="13" />
      </MockedQueryProvider>,
    )

    await waitFor(() => {
      expect(mockMutate).toHaveBeenCalledTimes(1)
    })
  })
})
