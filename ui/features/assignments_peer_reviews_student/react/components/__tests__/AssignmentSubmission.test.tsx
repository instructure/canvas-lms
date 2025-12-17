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

vi.mock('../CommentsTrayContentWithApollo', () => {
  const MockedCommentsTray = (props: any) => (
    <div data-testid="mocked-comments-tray" data-props={JSON.stringify(props)}>
      Mocked Comments Tray
    </div>
  )
  MockedCommentsTray.displayName = 'CommentsTrayContentWithApollo'
  return {
    __esModule: true,
    default: MockedCommentsTray,
  }
})

describe('AssignmentSubmission', () => {
  afterEach(() => {
    cleanup()
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
    assessmentRequestsForCurrentUser: null,
    ...overrides,
  })

  describe('online_text_entry submissions', () => {
    it('renders text entry content', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(screen.getByTestId('text-entry-content')).toBeInTheDocument()
      expect(screen.getByTestId('text-entry-content')).toHaveTextContent(
        'This is a test submission',
      )
    })

    it('renders Paper View selector by default', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const select = screen.getByTestId('view-mode-selector')
      expect(select).toHaveValue('Paper View')
    })

    it('applies paper class to content by default', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveClass('user_content', 'paper')
    })

    it('switches to Plain Text View when selected', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)

      const plainTextOption = screen.getByText('Plain Text View')
      await user.click(plainTextOption)

      expect(select).toHaveValue('Plain Text View')
    })

    it('applies plain_text class when Plain Text View is selected', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)

      const plainTextOption = screen.getByText('Plain Text View')
      await user.click(plainTextOption)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveClass('user_content', 'plain_text')
    })

    it('applies scrollable container styles', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toHaveStyle({
        overflow: 'auto',
      })
    })

    it('renders HTML content correctly', () => {
      const submission = createSubmission({
        body: '<p>Paragraph 1</p><p>Paragraph 2</p><strong>Bold text</strong>',
      })
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content.innerHTML).toContain('<p>Paragraph 1</p>')
      expect(content.innerHTML).toContain('<p>Paragraph 2</p>')
      expect(content.innerHTML).toContain('<strong>Bold text</strong>')
    })

    it('renders empty string when body is null', () => {
      const submission = createSubmission({body: null})
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toBeEmptyDOMElement()
    })

    it('renders empty string when body is empty', () => {
      const submission = createSubmission({body: ''})
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const content = screen.getByTestId('text-entry-content')
      expect(content).toBeEmptyDOMElement()
    })
  })

  describe('view mode persistence', () => {
    it('maintains selected view mode across re-renders', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const assignment = createAssignment()
      const {rerender} = render(
        <AssignmentSubmission submission={submission} assignment={assignment} />,
      )

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)
      await user.click(screen.getByText('Plain Text View'))

      expect(select).toHaveValue('Plain Text View')

      rerender(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(select).toHaveValue('Plain Text View')
    })

    it('can switch back to Paper View from Plain Text View', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

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
      const submission = createSubmission({
        submissionType: 'online_url',
        url: 'https://example.com',
      })
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(screen.getByTestId('url-entry-content')).toBeInTheDocument()
      expect(screen.getByTestId('url-submission-text')).toHaveTextContent('https://example.com')
    })

    it('renders error when URL is missing', () => {
      const submission = createSubmission({
        submissionType: 'online_url',
        url: null,
      })
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('renders error when URL is empty string', () => {
      const submission = createSubmission({
        submissionType: 'online_url',
        url: '',
      })
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('opens URL in new window when link is clicked', async () => {
      const user = userEvent.setup()
      const mockWindowOpen = vi.fn()
      window.open = mockWindowOpen

      const submission = createSubmission({
        submissionType: 'online_url',
        url: 'https://example.com/test',
      })
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

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
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(screen.getByTestId('file-preview')).toBeInTheDocument()
    })

    it('renders no submission message when attachments is empty', () => {
      const assignment = createAssignment()
      const submission = createSubmission({
        submissionType: 'online_upload',
        attachments: [],
      })
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(screen.getByText('No Submission')).toBeInTheDocument()
    })
  })

  describe('unsupported submission types', () => {
    it('renders error page for unsupported submission type', () => {
      const submission = createSubmission({submissionType: 'unsupported'})
      render(<AssignmentSubmission submission={submission} assignment={createAssignment()} />)

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })
  })

  describe('comments tray', () => {
    it('renders toggle comments button', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(screen.getByTestId('toggle-comments-button')).toBeInTheDocument()
      expect(screen.getByTestId('toggle-comments-button')).toHaveTextContent('Show Comments')
    })

    it('shows comments tray when toggle button is clicked', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const toggleButton = screen.getByTestId('toggle-comments-button')
      expect(screen.queryByTestId('mocked-comments-tray')).not.toBeInTheDocument()

      await user.click(toggleButton)

      expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()
      expect(toggleButton).toHaveTextContent('Hide Comments')
    })

    it('hides comments tray when toggle button is clicked again', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

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
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

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
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      await user.click(screen.getByTestId('toggle-comments-button'))

      const closeButton = screen.getByTestId('close-comments-button')
      expect(closeButton).toBeInTheDocument()
    })

    it('renders Peer Comments heading when comments are shown', async () => {
      const user = userEvent.setup()
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      await user.click(screen.getByTestId('toggle-comments-button'))

      expect(screen.getByText('Peer Comments')).toBeInTheDocument()
    })
  })

  describe('peer review footer', () => {
    it('renders submit peer review button', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
      expect(screen.getByTestId('submit-peer-review-button')).toHaveTextContent(
        'Submit Peer Review',
      )
    })

    it('renders footer with correct layout', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission submission={submission} assignment={assignment} />)

      const footer = screen.getByTestId('peer-review-footer')
      expect(footer).toBeInTheDocument()

      expect(screen.getByTestId('toggle-comments-button')).toBeInTheDocument()
      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
    })

    it('applies correct styling for non-mobile layout', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(
        <AssignmentSubmission submission={submission} assignment={assignment} isMobile={false} />,
      )

      const footer = screen.getByTestId('peer-review-footer')
      expect(footer).toHaveStyle({left: '275px'})
    })

    it('applies correct styling for mobile layout', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(
        <AssignmentSubmission submission={submission} assignment={assignment} isMobile={true} />,
      )

      const footer = screen.getByTestId('peer-review-footer')
      expect(footer).toHaveStyle({left: '0px'})
    })
  })
})
