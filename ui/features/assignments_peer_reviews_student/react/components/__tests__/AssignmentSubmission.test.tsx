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
import AssignmentSubmission from '../AssignmentSubmission'
import {Submission} from '@canvas/assignments/react/AssignmentsPeerReviewsStudentTypes'

vi.mock('@canvas/util/jquery/apiUserContent', () => ({
  default: {
    convert: (html: string) => html,
  },
}))

let mockOnSuccessfulPeerReview: (() => void) | null = null

vi.mock('../CommentsTrayContentWithApollo', () => {
  const MockedCommentsTray = (props: any) => {
    // Store the callback so tests can trigger it
    mockOnSuccessfulPeerReview = props.onSuccessfulPeerReview
    return (
      <div
        data-testid="mocked-comments-tray"
        data-props={JSON.stringify({
          ...props,
          onSuccessfulPeerReview: undefined, // Don't serialize function
        })}
      >
        Mocked Comments Tray
      </div>
    )
  }
  MockedCommentsTray.displayName = 'CommentsTrayContentWithApollo'
  return {
    __esModule: true,
    default: MockedCommentsTray,
  }
})

describe('AssignmentSubmission', () => {
  afterEach(() => {
    cleanup()
    mockOnSuccessfulPeerReview = null
  })

  const createSubmission = (overrides = {}): Submission => ({
    _id: '1',
    attempt: 1,
    body: '<p>This is a test submission</p>',
    submissionType: 'online_text_entry',
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
    isPeerReviewCompleted: false,
    handleNextPeerReview: jest.fn(),
    onCommentSubmitted: jest.fn(),
    hasSeenPeerReviewModal: false,
    isMobile: false,
    ...overrides,
  })

  describe('online_text_entry submissions', () => {
    it('renders text entry content', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      expect(screen.getByTestId('text-entry-content')).toBeInTheDocument()
      expect(screen.getByTestId('text-entry-content')).toHaveTextContent(
        'This is a test submission',
      )
    })

    it('renders Paper View selector by default', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const select = screen.getByTestId('view-mode-selector')
      expect(select).toHaveValue('Paper View')
    })

    it('applies paper class to content by default', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveClass('user_content', 'paper')
    })

    it('switches to Plain Text View when selected', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)

      const plainTextOption = screen.getByText('Plain Text View')
      await user.click(plainTextOption)

      expect(select).toHaveValue('Plain Text View')
    })

    it('applies plain_text class when Plain Text View is selected', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)

      const plainTextOption = screen.getByText('Plain Text View')
      await user.click(plainTextOption)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveClass('user_content', 'plain_text')
    })

    it('applies scrollable container styles', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveStyle({
        overflow: 'auto',
      })
    })

    it('renders HTML content correctly', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission: createSubmission({
              body: '<p>Paragraph 1</p><p>Paragraph 2</p><strong>Bold text</strong>',
            }),
          })}
        />,
      )

      const content = screen.getByTestId('text-entry-content')
      expect(content.innerHTML).toContain('<p>Paragraph 1</p>')
      expect(content.innerHTML).toContain('<p>Paragraph 2</p>')
      expect(content.innerHTML).toContain('<strong>Bold text</strong>')
    })

    it('renders empty string when body is null', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({submission: createSubmission({body: null})})}
        />,
      )

      const content = screen.getByTestId('text-entry-content')
      expect(content).toBeEmptyDOMElement()
    })

    it('renders empty string when body is empty', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({submission: createSubmission({body: ''})})}
        />,
      )

      const content = screen.getByTestId('text-entry-content')
      expect(content).toBeEmptyDOMElement()
    })
  })

  describe('view mode persistence', () => {
    it('maintains selected view mode across re-renders', async () => {
      const user = userEvent.setup()
      const props = createDefaultProps()
      const {rerender} = render(<AssignmentSubmission {...props} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)
      await user.click(screen.getByText('Plain Text View'))

      expect(select).toHaveValue('Plain Text View')

      rerender(<AssignmentSubmission {...props} />)

      expect(select).toHaveValue('Plain Text View')
    })

    it('can switch back to Paper View from Plain Text View', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const select = screen.getByTestId('view-mode-selector')

      await user.click(select)
      await user.click(screen.getByText('Plain Text View'))
      expect(select).toHaveValue('Plain Text View')

      await user.click(select)
      await user.click(screen.getByText('Paper View'))
      expect(select).toHaveValue('Paper View')

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveClass('user_content', 'paper')
    })
  })

  describe('online_url submissions', () => {
    it('renders URL submission content', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission: createSubmission({
              submissionType: 'online_url',
              url: 'https://example.com',
            }),
          })}
        />,
      )

      expect(screen.getByTestId('url-entry-content')).toBeInTheDocument()
      expect(screen.getByTestId('url-submission-text')).toHaveTextContent('https://example.com')
    })

    it('renders error when URL is missing', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission: createSubmission({
              submissionType: 'online_url',
              url: null,
            }),
          })}
        />,
      )

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('renders error when URL is empty string', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission: createSubmission({
              submissionType: 'online_url',
              url: '',
            }),
          })}
        />,
      )

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('opens URL in new window when link is clicked', async () => {
      const user = userEvent.setup()
      const mockWindowOpen = vi.fn()
      window.open = mockWindowOpen

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission: createSubmission({
              submissionType: 'online_url',
              url: 'https://example.com/test',
            }),
          })}
        />,
      )

      const link = screen.getByTestId('url-submission-text')
      await user.click(link)

      expect(mockWindowOpen).toHaveBeenCalledWith('https://example.com/test')
    })
  })

  describe('online_upload submissions', () => {
    it('renders file submission preview', () => {
      const assignment = createAssignment()
      const submission = createSubmission({
        submissionType: 'online_upload',
        attachments: [
          {
            _id: '101',
            displayName: 'test-file.pdf',
            mimeClass: 'pdf',
            size: '1.2 MB',
            thumbnailUrl: null,
            submissionPreviewUrl: 'http://example.com/preview/101',
            url: 'http://example.com/download/101',
          },
        ],
      })
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission,
            assignment,
          })}
        />,
      )

      expect(screen.getByTestId('file-preview')).toBeInTheDocument()
    })

    it('renders no submission message when attachments is empty', () => {
      const assignment = createAssignment()
      const submission = createSubmission({
        submissionType: 'online_upload',
        attachments: [],
      })
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission,
            assignment,
          })}
        />,
      )

      expect(screen.getByText('No Submission')).toBeInTheDocument()
    })
  })

  describe('unsupported submission types', () => {
    it('renders error page for unsupported submission type', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({submission: createSubmission({submissionType: 'unsupported'})})}
        />,
      )

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  describe('comments tray', () => {
    it('renders toggle comments button', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      expect(screen.getByTestId('toggle-comments-button')).toBeInTheDocument()
      expect(screen.getByTestId('toggle-comments-button')).toHaveTextContent('Show Comments')
    })

    it('shows comments tray when toggle button is clicked', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const toggleButton = screen.getByTestId('toggle-comments-button')
      expect(screen.queryByTestId('mocked-comments-tray')).not.toBeInTheDocument()

      await user.click(toggleButton)

      expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()
      expect(toggleButton).toHaveTextContent('Hide Comments')
    })

    it('hides comments tray when toggle button is clicked again', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const toggleButton = screen.getByTestId('toggle-comments-button')
      await user.click(toggleButton)
      expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()

      await user.click(toggleButton)
      expect(screen.queryByTestId('mocked-comments-tray')).not.toBeInTheDocument()
      expect(toggleButton).toHaveTextContent('Show Comments')
    })

    it('renders CommentsTrayContentWithApollo with correct props', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission {...createDefaultProps({submission, assignment})} />)

      await user.click(screen.getByTestId('toggle-comments-button'))

      const commentsTray = screen.getByTestId('mocked-comments-tray')
      expect(commentsTray).toBeInTheDocument()

      const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')
      expect(props.isPeerReviewEnabled).toBe(true)
      expect(props.submission._id).toBe(submission._id)
      expect(props.assignment.courseId).toBe(assignment.courseId)
    })

    it('includes close button for comments tray', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      await user.click(screen.getByTestId('toggle-comments-button'))

      const closeButton = screen.getByTestId('close-comments-button')
      expect(closeButton).toBeInTheDocument()
    })

    it('renders Peer Comments heading when comments are shown', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      await user.click(screen.getByTestId('toggle-comments-button'))

      expect(screen.getByText('Peer Comments')).toBeInTheDocument()
    })
  })

  describe('peer review footer', () => {
    it('renders submit peer review button', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
      expect(screen.getByTestId('submit-peer-review-button')).toHaveTextContent(
        'Submit Peer Review',
      )
    })

    it('renders footer with correct layout', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const footer = screen.getByTestId('peer-review-footer')
      expect(footer).toBeInTheDocument()

      expect(screen.getByTestId('toggle-comments-button')).toBeInTheDocument()
      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
    })

    it('applies correct styling for non-mobile layout', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const footer = screen.getByTestId('peer-review-footer')
      expect(footer).toHaveStyle({left: '275px'})
    })

    it('applies correct styling for mobile layout', () => {
      render(<AssignmentSubmission {...createDefaultProps({isMobile: true})} />)

      const footer = screen.getByTestId('peer-review-footer')
      expect(footer).toHaveStyle({left: '0px'})
    })

    it('shows submit peer review button when peer review is not completed', () => {
      render(<AssignmentSubmission {...createDefaultProps({isPeerReviewCompleted: false})} />)

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
    })

    it('hides submit peer review button when peer review is completed', () => {
      render(<AssignmentSubmission {...createDefaultProps({isPeerReviewCompleted: true})} />)

      expect(screen.queryByTestId('submit-peer-review-button')).not.toBeInTheDocument()
    })
  })

  describe('error messages', () => {
    it('renders error page for unsupported submission type', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({submission: createSubmission({submissionType: 'fake_type'})})}
        />,
      )

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  describe('submit button visibility with hasSeenPeerReviewModal', () => {
    it('shows button if peer review modal not seen', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            hasSeenPeerReviewModal: false,
          })}
        />,
      )

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
    })

    it('hides button if peer review modal has been seen', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            isPeerReviewCompleted: false,
            hasSeenPeerReviewModal: true,
          })}
        />,
      )

      expect(screen.queryByTestId('submit-peer-review-button')).not.toBeInTheDocument()
    })

    it('hides button when peer review is completed', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            isPeerReviewCompleted: true,
            hasSeenPeerReviewModal: false,
          })}
        />,
      )

      expect(screen.queryByTestId('submit-peer-review-button')).not.toBeInTheDocument()
    })

    it('hides button when both peer review completed and modal seen', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            isPeerReviewCompleted: true,
            hasSeenPeerReviewModal: true,
          })}
        />,
      )

      expect(screen.queryByTestId('submit-peer-review-button')).not.toBeInTheDocument()
    })
  })

  describe('onCommentSubmitted callback', () => {
    it('calls onCommentSubmitted when comment is successfully submitted', async () => {
      const onCommentSubmitted = jest.fn()
      const user = userEvent.setup()

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            onCommentSubmitted,
          })}
        />,
      )

      await user.click(screen.getByTestId('toggle-comments-button'))

      expect(mockOnSuccessfulPeerReview).toBeTruthy()
      mockOnSuccessfulPeerReview!()
      expect(onCommentSubmitted).toHaveBeenCalledTimes(1)
    })
  })

  describe('submission change detection', () => {
    it('maintains button visibility when same submission is re-rendered with updated isPeerReviewCompleted', () => {
      const props = createDefaultProps({
        submission: createSubmission({_id: 'submission-1'}),
        isPeerReviewCompleted: false,
        hasSeenPeerReviewModal: false,
      })

      const {rerender} = render(<AssignmentSubmission {...props} />)

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()

      rerender(<AssignmentSubmission {...props} isPeerReviewCompleted={true} />)

      // Button should still be visible because initialIsPeerReviewCompleted was false
      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
    })

    it('resets button visibility when navigating to a different submission', () => {
      const props = createDefaultProps({
        submission: createSubmission({_id: 'submission-1'}),
        isPeerReviewCompleted: false,
        hasSeenPeerReviewModal: false,
      })

      const {rerender} = render(<AssignmentSubmission {...props} />)

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()

      rerender(
        <AssignmentSubmission
          {...props}
          submission={createSubmission({_id: 'submission-2'})}
          isPeerReviewCompleted={true}
        />,
      )

      expect(screen.queryByTestId('submit-peer-review-button')).not.toBeInTheDocument()
    })

    it('resets button visibility when navigating to another incomplete submission', () => {
      const props = createDefaultProps({
        submission: createSubmission({_id: 'submission-1'}),
        isPeerReviewCompleted: true,
        hasSeenPeerReviewModal: false,
      })

      const {rerender} = render(<AssignmentSubmission {...props} />)

      expect(screen.queryByTestId('submit-peer-review-button')).not.toBeInTheDocument()

      rerender(
        <AssignmentSubmission
          {...props}
          submission={createSubmission({_id: 'submission-2'})}
          isPeerReviewCompleted={false}
        />,
      )

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
    })

    it('preserves button visibility through re-render of same submission', () => {
      const props = createDefaultProps({
        submission: createSubmission({_id: 'submission-1'}),
        isPeerReviewCompleted: false,
        hasSeenPeerReviewModal: false,
      })

      const {rerender} = render(<AssignmentSubmission {...props} />)

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()

      // re-renders with updated isPeerReviewCompleted
      rerender(<AssignmentSubmission {...props} isPeerReviewCompleted={true} />)
      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
    })
  })
})
