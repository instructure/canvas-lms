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
import userEvent from '@testing-library/user-event'
import {CommentsPanel} from '../CommentsPanel'

vi.mock('../CommentsTrayContentWithApollo', () => {
  const MockedCommentsTray = (props: any) => (
    <div data-testid="mocked-comments-tray" data-props={JSON.stringify(props)}>
      Mocked Comments Tray
      <button data-testid="mock-peer-review-success" onClick={() => props.onSuccessfulPeerReview()}>
        Submit Comment
      </button>
    </div>
  )
  MockedCommentsTray.displayName = 'CommentsTrayContentWithApollo'
  return {
    __esModule: true,
    default: MockedCommentsTray,
  }
})

describe('CommentsPanel', () => {
  const createSubmission = (overrides = {}) => ({
    _id: '1',
    attempt: 1,
    body: '<p>This is a test submission</p>',
    submissionType: 'online_text_entry',
    user: {
      _id: '123',
      name: 'Test Student',
    },
    ...overrides,
  })

  const createAssignment = (overrides = {}) => ({
    _id: '1',
    name: 'Test Assignment',
    dueAt: null,
    description: null,
    expectsSubmission: true,
    nonDigitalSubmission: false,
    pointsPossible: 10,
    courseId: '1',
    peerReviews: null,
    submissionsConnection: null,
    assignedToDates: null,
    assessmentRequestsForCurrentUser: null,
    ...overrides,
  })

  const createReviewerSubmission = (overrides = {}) => ({
    _id: 'reviewer-sub-1',
    id: 'reviewer-sub-1-id',
    attempt: 1,
    assignedAssessments: [
      {
        assetId: 'asset-1',
        workflowState: 'assigned',
        assetSubmissionType: 'online_text_entry',
      },
    ],
    ...overrides,
  })

  const createDefaultProps = (overrides = {}) => ({
    submission: createSubmission(),
    assignment: createAssignment(),
    reviewerSubmission: createReviewerSubmission(),
    isMobile: false,
    isOpen: true,
    onClose: vi.fn(),
    onSuccessfulPeerReview: vi.fn(),
    ...overrides,
  })

  it('renders without crashing', () => {
    render(<CommentsPanel {...createDefaultProps()} />)
    expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()
  })

  it('renders heading with correct text', () => {
    render(<CommentsPanel {...createDefaultProps()} />)
    expect(screen.getByText('Peer Comments')).toBeInTheDocument()
  })

  it('renders close button', () => {
    render(<CommentsPanel {...createDefaultProps()} />)
    expect(screen.getByTestId('close-comments-button')).toBeInTheDocument()
  })

  it('calls onClose when close button is clicked', async () => {
    const user = userEvent.setup()
    const mockOnClose = vi.fn()
    render(<CommentsPanel {...createDefaultProps({onClose: mockOnClose})} />)

    const closeButtonContainer = screen.getByTestId('close-comments-button')
    const button = closeButtonContainer.querySelector('button')
    if (button) {
      await user.click(button)
    }

    expect(mockOnClose).toHaveBeenCalledTimes(1)
  })

  it('passes submission to CommentsTrayContentWithApollo', () => {
    const submission = createSubmission()
    render(<CommentsPanel {...createDefaultProps({submission})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.submission._id).toBe(submission._id)
    expect(props.submission.body).toBe(submission.body)
  })

  it('passes assignment to CommentsTrayContentWithApollo', () => {
    const assignment = createAssignment()
    render(<CommentsPanel {...createDefaultProps({assignment})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.assignment._id).toBe(assignment._id)
    expect(props.assignment.courseId).toBe(assignment.courseId)
  })

  it('passes isPeerReviewEnabled as true to CommentsTrayContentWithApollo', () => {
    render(<CommentsPanel {...createDefaultProps()} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.isPeerReviewEnabled).toBe(true)
  })

  it('passes reviewerSubmission to CommentsTrayContentWithApollo', () => {
    const reviewerSubmission = createReviewerSubmission()
    render(<CommentsPanel {...createDefaultProps({reviewerSubmission})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.reviewerSubmission._id).toBe(reviewerSubmission._id)
  })

  it('passes null reviewerSubmission when not provided', () => {
    render(<CommentsPanel {...createDefaultProps({reviewerSubmission: null})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.reviewerSubmission).toBeNull()
  })

  it('passes renderTray based on isMobile prop', () => {
    render(<CommentsPanel {...createDefaultProps({isMobile: true})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.renderTray).toBe(true)
  })

  it('passes renderTray as false when not mobile', () => {
    render(<CommentsPanel {...createDefaultProps({isMobile: false})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.renderTray).toBe(false)
  })

  it('passes isOpen prop to CommentsTrayContentWithApollo', () => {
    render(<CommentsPanel {...createDefaultProps({isOpen: true})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.open).toBe(true)
  })

  it('passes false open when isOpen is false', () => {
    render(<CommentsPanel {...createDefaultProps({isOpen: false})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.open).toBe(false)
  })

  it('passes usePeerReviewModal as false to CommentsTrayContentWithApollo', () => {
    render(<CommentsPanel {...createDefaultProps()} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.usePeerReviewModal).toBe(false)
  })

  it('calls onSuccessfulPeerReview when comment is submitted successfully', async () => {
    const user = userEvent.setup()
    const mockOnSuccess = vi.fn()
    render(<CommentsPanel {...createDefaultProps({onSuccessfulPeerReview: mockOnSuccess})} />)

    const submitButton = screen.getByTestId('mock-peer-review-success')
    await user.click(submitButton)

    expect(mockOnSuccess).toHaveBeenCalledTimes(1)
  })

  it('renders with mobile layout', () => {
    render(<CommentsPanel {...createDefaultProps({isMobile: true})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    expect(commentsTray).toBeInTheDocument()
  })

  it('renders with desktop layout', () => {
    render(<CommentsPanel {...createDefaultProps({isMobile: false})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    expect(commentsTray).toBeInTheDocument()
  })

  it('updates when submission changes', () => {
    const {rerender} = render(<CommentsPanel {...createDefaultProps()} />)

    const newSubmission = createSubmission({_id: '2', body: 'New submission'})
    rerender(<CommentsPanel {...createDefaultProps({submission: newSubmission})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.submission._id).toBe('2')
  })

  it('updates when assignment changes', () => {
    const {rerender} = render(<CommentsPanel {...createDefaultProps()} />)

    const newAssignment = createAssignment({_id: '2', name: 'New Assignment'})
    rerender(<CommentsPanel {...createDefaultProps({assignment: newAssignment})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.assignment._id).toBe('2')
  })

  it('handles anonymous submission', () => {
    const submission = createSubmission({
      user: null,
      anonymousId: 'anon-123',
    })
    render(<CommentsPanel {...createDefaultProps({submission})} />)

    const commentsTray = screen.getByTestId('mocked-comments-tray')
    const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

    expect(props.submission.anonymousId).toBe('anon-123')
    expect(props.submission.user).toBeNull()
  })

  describe('Read-only mode', () => {
    it('passes isReadOnly as true to CommentsTrayContentWithApollo when isReadOnly is true', () => {
      render(<CommentsPanel {...createDefaultProps({isReadOnly: true})} />)

      const commentsTray = screen.getByTestId('mocked-comments-tray')
      const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

      expect(props.isReadOnly).toBe(true)
    })

    it('passes isReadOnly as false to CommentsTrayContentWithApollo when isReadOnly is false', () => {
      render(<CommentsPanel {...createDefaultProps({isReadOnly: false})} />)

      const commentsTray = screen.getByTestId('mocked-comments-tray')
      const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

      expect(props.isReadOnly).toBe(false)
    })

    it('defaults isReadOnly to false when not provided', () => {
      render(<CommentsPanel {...createDefaultProps()} />)

      const commentsTray = screen.getByTestId('mocked-comments-tray')
      const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')

      expect(props.isReadOnly).toBe(false)
    })
  })
})
