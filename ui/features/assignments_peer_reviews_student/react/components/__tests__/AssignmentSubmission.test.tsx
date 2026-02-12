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
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/util/jquery/apiUserContent', () => ({
  default: {
    convert: (html: string) => html,
  },
}))

vi.mock('@canvas/assignments/react/StudentAnnotationPreview', () => ({
  __esModule: true,
  default: (props: any) => (
    <div data-testid="canvadocs-pane" data-props={JSON.stringify(props)}>
      Mocked Student Annotation Preview
    </div>
  ),
}))

let mockOnSuccessfulPeerReview: (() => void) | null = null
vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

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

vi.mock('@canvas/rubrics/react/RubricAssessment', () => ({
  RubricAssessmentContainerWrapper: (props: any) => (
    <div data-testid="mocked-rubric-assessment" data-props={JSON.stringify(props)}>
      Mocked Rubric Assessment
      <button
        data-testid="mocked-rubric-submit"
        onClick={() => props.onSubmit([{id: '1', points: 4, criterionId: '1', comments: ''}])}
      >
        Submit Assessment
      </button>
    </div>
  ),
}))

vi.mock('../../hooks/useSavePeerReviewRubricAssessment', () => ({
  useSavePeerReviewRubricAssessment: () => ({
    mutate: vi.fn(),
    isPending: false,
  }),
}))

vi.mock('@canvas/local-storage', () => ({
  default: () => ['vertical', vi.fn()],
}))

vi.mock('@canvas/rubrics/react/RubricAssessment/constants', () => ({
  RUBRIC_VIEW_MODE_LOCALSTORAGE_KEY: () => 'rubric_view_mode',
}))

vi.mock('../MediaRecordingSubmissionDisplay', () => ({
  MediaRecordingSubmissionDisplay: (props: any) => (
    <div data-testid="media-recording-submission-display" data-media-id={props.mediaObject?._id}>
      Mocked Media Recording Display
    </div>
  ),
}))

describe('AssignmentSubmission', () => {
  afterEach(() => {
    cleanup()
    mockOnSuccessfulPeerReview = null
    vi.clearAllMocks()
  })

  const createSubmission = (overrides = {}): Submission => ({
    _id: '1',
    attempt: 1,
    body: '<p>This is a test submission</p>',
    submissionType: 'online_text_entry',
    ...overrides,
  })

  const createRubric = (overrides = {}) => ({
    _id: '3',
    title: 'Test Rubric',
    criteria: [
      {
        _id: '1',
        description: 'Quality',
        long_description: 'Quality of work',
        points: 4,
        criterion_use_range: false,
        ratings: [
          {
            _id: 'rating-1',
            description: 'Excellent',
            long_description: '',
            points: 4,
          },
          {
            _id: 'rating-2',
            description: 'Good',
            long_description: '',
            points: 3,
          },
          {
            _id: 'rating-3',
            description: 'Fair',
            long_description: '',
            points: 2,
          },
        ],
        ignore_for_scoring: false,
      },
    ],
    free_form_criterion_comments: false,
    hide_score_total: false,
    points_possible: 4,
    ratingOrder: 'descending',
    button_display: 'numeric',
    ...overrides,
  })

  const createRubricAssociation = (overrides = {}) => ({
    _id: '1',
    hide_points: false,
    hide_score_total: false,
    use_for_grading: true,
    ...overrides,
  })

  const createRubricAssessment = (overrides = {}) => ({
    _id: 'assessment-1',
    assessmentRatings: [
      {
        _id: 'assessment-rating-1',
        criterion: {_id: '1'},
        comments: 'Great work',
        description: 'Excellent',
        points: 4,
      },
    ],
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
    peerReviewSubAssignment: null,
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
    onPeerReviewSubmitted: jest.fn(),
    hasSeenPeerReviewModal: false,
    isMobile: false,
    isAnonymous: false,
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

    it('switches to Plain Text View when selected', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const select = screen.getByTestId('view-mode-selector')
      await user.click(select)

      const plainTextOption = screen.getByText('Plain Text View')
      await user.click(plainTextOption)

      expect(select).toHaveValue('Plain Text View')
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

  describe('student_annotation submissions', () => {
    it('renders student annotation preview', () => {
      const assignment = createAssignment()
      const submission = createSubmission({
        submissionType: 'student_annotation',
        state: 'submitted',
      })
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission,
            assignment,
          })}
        />,
      )

      expect(screen.getByTestId('canvadocs-pane')).toBeInTheDocument()
    })

    it('renders student annotation preview for graded submissions', () => {
      const assignment = createAssignment()
      const submission = createSubmission({
        submissionType: 'student_annotation',
        state: 'graded',
        attempt: 2,
      })
      render(
        <AssignmentSubmission
          {...createDefaultProps({
            submission,
            assignment,
          })}
        />,
      )

      expect(screen.getByTestId('canvadocs-pane')).toBeInTheDocument()
    })
  })

  describe('media_recording submissions', () => {
    const createMediaObject = () => ({
      _id: 'media-123',
      mediaType: 'video',
      title: 'Test Video Recording',
    })

    it('renders media recording submission display', () => {
      const submission = createSubmission({
        submissionType: 'media_recording',
        mediaObject: createMediaObject(),
      })
      render(<AssignmentSubmission {...createDefaultProps({submission})} />)

      expect(screen.getByTestId('media-recording-submission-display')).toBeInTheDocument()
    })

    it('passes mediaObject to MediaRecordingSubmissionDisplay', () => {
      const mediaObject = createMediaObject()
      const submission = createSubmission({
        submissionType: 'media_recording',
        mediaObject,
      })
      render(<AssignmentSubmission {...createDefaultProps({submission})} />)

      const display = screen.getByTestId('media-recording-submission-display')
      expect(display).toHaveAttribute('data-media-id', 'media-123')
    })

    it('renders error when mediaObject is missing', () => {
      const submission = createSubmission({
        submissionType: 'media_recording',
        mediaObject: null,
      })
      render(<AssignmentSubmission {...createDefaultProps({submission})} />)

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
    })

    it('renders error when mediaObject is undefined', () => {
      const submission = createSubmission({
        submissionType: 'media_recording',
      })
      render(<AssignmentSubmission {...createDefaultProps({submission})} />)

      expect(screen.getByText('Sorry, Something Broke')).toBeInTheDocument()
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
    it('shows comments panel by default', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()
      expect(screen.getByTestId('toggle-comments-button')).toHaveTextContent('Hide Comments')
    })

    it('hides comments tray when toggle button is clicked', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const toggleButton = screen.getByTestId('toggle-comments-button')
      expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()

      await user.click(toggleButton)

      expect(screen.queryByTestId('mocked-comments-tray')).not.toBeInTheDocument()
      expect(toggleButton).toHaveTextContent('Show Comments')
    })

    it('shows comments tray when toggle button is clicked again', async () => {
      const user = userEvent.setup()
      render(<AssignmentSubmission {...createDefaultProps()} />)

      const toggleButton = screen.getByTestId('toggle-comments-button')
      await user.click(toggleButton)
      expect(screen.queryByTestId('mocked-comments-tray')).not.toBeInTheDocument()

      await user.click(toggleButton)
      expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()
      expect(toggleButton).toHaveTextContent('Hide Comments')
    })

    it('renders CommentsTrayContentWithApollo with correct props', () => {
      const submission = createSubmission()
      const assignment = createAssignment()
      render(<AssignmentSubmission {...createDefaultProps({submission, assignment})} />)

      const commentsTray = screen.getByTestId('mocked-comments-tray')
      expect(commentsTray).toBeInTheDocument()

      const props = JSON.parse(commentsTray.getAttribute('data-props') || '{}')
      expect(props.isPeerReviewEnabled).toBe(true)
      expect(props.submission._id).toBe(submission._id)
      expect(props.assignment.courseId).toBe(assignment.courseId)
    })

    it('renders Peer Comments heading when comments are shown', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      expect(screen.getByText('Peer Comments')).toBeInTheDocument()
    })
  })

  describe('peer review footer', () => {
    it('shows submit peer review button when peer review is not completed', () => {
      render(<AssignmentSubmission {...createDefaultProps({isPeerReviewCompleted: false})} />)

      expect(screen.getByTestId('submit-peer-review-button')).toBeInTheDocument()
    })

    it('hides submit peer review button when peer review is completed', () => {
      render(<AssignmentSubmission {...createDefaultProps({isPeerReviewCompleted: true})} />)

      expect(screen.queryByTestId('submit-peer-review-button')).not.toBeInTheDocument()
    })
  })

  describe('error handling', () => {
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

  describe('onPeerReviewSubmitted callback', () => {
    it('calls onPeerReviewSubmitted when comment is successfully submitted', () => {
      const onPeerReviewSubmitted = jest.fn()

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            onPeerReviewSubmitted,
          })}
        />,
      )

      expect(mockOnSuccessfulPeerReview).toBeTruthy()
      mockOnSuccessfulPeerReview!()
      expect(onPeerReviewSubmitted).toHaveBeenCalledTimes(1)
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

  describe('rubric functionality', () => {
    const createAssignmentWithRubric = () =>
      createAssignment({
        rubric: createRubric(),
        rubricAssociation: createRubricAssociation(),
      })

    it('does not render rubric button when assignment has no rubric', () => {
      render(<AssignmentSubmission {...createDefaultProps()} />)

      expect(screen.queryByTestId('toggle-rubric-button')).not.toBeInTheDocument()
    })

    it('renders rubric button when assignment has rubric', () => {
      render(
        <AssignmentSubmission
          {...createDefaultProps({assignment: createAssignmentWithRubric()})}
        />,
      )

      expect(screen.getByTestId('toggle-rubric-button')).toBeInTheDocument()
      expect(screen.getByTestId('toggle-rubric-button')).toHaveTextContent('Show Rubric')
    })

    it('shows rubric panel when rubric button is clicked', async () => {
      const user = userEvent.setup()
      render(
        <AssignmentSubmission
          {...createDefaultProps({assignment: createAssignmentWithRubric()})}
        />,
      )

      const toggleButton = screen.getByTestId('toggle-rubric-button')
      expect(screen.queryByTestId('mocked-rubric-assessment')).not.toBeInTheDocument()

      await user.click(toggleButton)

      expect(screen.getByTestId('mocked-rubric-assessment')).toBeInTheDocument()
      expect(toggleButton).toHaveTextContent('Hide Rubric')
    })

    it('hides rubric panel when rubric button is clicked again', async () => {
      const user = userEvent.setup()
      render(
        <AssignmentSubmission
          {...createDefaultProps({assignment: createAssignmentWithRubric()})}
        />,
      )

      const toggleButton = screen.getByTestId('toggle-rubric-button')
      await user.click(toggleButton)
      expect(screen.getByTestId('mocked-rubric-assessment')).toBeInTheDocument()

      await user.click(toggleButton)
      expect(screen.queryByTestId('mocked-rubric-assessment')).not.toBeInTheDocument()
      expect(toggleButton).toHaveTextContent('Show Rubric')
    })

    it('renders Peer Review Rubric heading when rubric is shown', async () => {
      const user = userEvent.setup()
      render(
        <AssignmentSubmission
          {...createDefaultProps({assignment: createAssignmentWithRubric()})}
        />,
      )

      await user.click(screen.getByTestId('toggle-rubric-button'))

      expect(screen.getByText('Peer Review Rubric')).toBeInTheDocument()
    })

    it('closes comments when rubric is opened', async () => {
      const user = userEvent.setup()
      render(
        <AssignmentSubmission
          {...createDefaultProps({assignment: createAssignmentWithRubric()})}
        />,
      )

      expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()

      await user.click(screen.getByTestId('toggle-rubric-button'))
      expect(screen.queryByTestId('mocked-comments-tray')).not.toBeInTheDocument()
      expect(screen.getByTestId('mocked-rubric-assessment')).toBeInTheDocument()
    })

    it('closes rubric when comments are opened', async () => {
      const user = userEvent.setup()
      render(
        <AssignmentSubmission
          {...createDefaultProps({assignment: createAssignmentWithRubric()})}
        />,
      )

      await user.click(screen.getByTestId('toggle-rubric-button'))
      expect(screen.getByTestId('mocked-rubric-assessment')).toBeInTheDocument()

      await user.click(screen.getByTestId('toggle-comments-button'))
      expect(screen.queryByTestId('mocked-rubric-assessment')).not.toBeInTheDocument()
      expect(screen.getByTestId('mocked-comments-tray')).toBeInTheDocument()
    })

    it('passes correct props to RubricAssessmentContainerWrapper', async () => {
      const user = userEvent.setup()
      const assignment = createAssignmentWithRubric()
      render(<AssignmentSubmission {...createDefaultProps({assignment})} />)

      await user.click(screen.getByTestId('toggle-rubric-button'))

      const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
      const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

      expect(props.rubricTitle).toBe('Test Rubric')
      expect(props.pointsPossible).toBe(4)
      expect(props.isPeerReview).toBe(true)
      expect(props.criteria).toHaveLength(1)
      expect(props.criteria[0].id).toBe('1')
    })

    it('sets rubric to preview mode when peer review is completed', async () => {
      const user = userEvent.setup()
      const assignment = createAssignmentWithRubric()
      render(
        <AssignmentSubmission {...createDefaultProps({assignment, isPeerReviewCompleted: true})} />,
      )

      await user.click(screen.getByTestId('toggle-rubric-button'))

      const rubricAssessment = screen.getByTestId('mocked-rubric-assessment')
      const props = JSON.parse(rubricAssessment.getAttribute('data-props') || '{}')

      expect(props.isPreviewMode).toBe(true)
    })
  })

  describe('peer review submission with rubric', () => {
    const createAssignmentWithRubric = () =>
      createAssignment({
        rubric: createRubric(),
        rubricAssociation: createRubricAssociation(),
      })

    it('does not call handleNext when submitting peer review without completing rubric', async () => {
      const user = userEvent.setup()
      const mockHandleNext = vi.fn()

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            assignment: createAssignmentWithRubric(),
            handleNextPeerReview: mockHandleNext,
          })}
        />,
      )

      await user.click(screen.getByTestId('submit-peer-review-button'))
      expect(mockHandleNext).not.toHaveBeenCalled()
    })

    it('allows submission when rubric is completed', async () => {
      const user = userEvent.setup()
      const mockHandleNext = vi.fn()

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            assignment: createAssignmentWithRubric(),
            rubricAssessment: createRubricAssessment(),
            handleNextPeerReview: mockHandleNext,
          })}
        />,
      )

      await user.click(screen.getByTestId('submit-peer-review-button'))
      expect(mockHandleNext).toHaveBeenCalled()
    })
  })

  describe('error alerts', () => {
    const createAssignmentWithRubric = () =>
      createAssignment({
        rubric: createRubric(),
        rubricAssociation: createRubricAssociation(),
      })

    it('shows error alert when submitting with rubric but rubric not completed', async () => {
      const user = userEvent.setup()
      const mockHandleNext = vi.fn()

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            assignment: createAssignmentWithRubric(),
            handleNextPeerReview: mockHandleNext,
          })}
        />,
      )

      await user.click(screen.getByTestId('submit-peer-review-button'))

      expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
        message: 'You must fill out the rubric in order to submit your peer review.',
        type: 'error',
      })
      expect(mockHandleNext).not.toHaveBeenCalled()
    })

    it('does not show error alert when rubric is completed', async () => {
      const user = userEvent.setup()
      const mockHandleNext = vi.fn()

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            assignment: createAssignmentWithRubric(),
            rubricAssessment: createRubricAssessment(),
            handleNextPeerReview: mockHandleNext,
          })}
        />,
      )

      await user.click(screen.getByTestId('submit-peer-review-button'))

      expect(FlashAlert.showFlashAlert).not.toHaveBeenCalled()
      expect(mockHandleNext).toHaveBeenCalled()
    })

    it('shows error alert when submitting without rubric and no comment completed', async () => {
      const user = userEvent.setup()
      const mockHandleNext = vi.fn()

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            assignment: createAssignment(),
            handleNextPeerReview: mockHandleNext,
          })}
        />,
      )

      await user.click(screen.getByTestId('submit-peer-review-button'))

      expect(FlashAlert.showFlashAlert).toHaveBeenCalledWith({
        message: 'Before you can submit this peer review, you must leave a comment for your peer.',
        type: 'error',
      })
      expect(mockHandleNext).not.toHaveBeenCalled()
    })

    it('does not show error alert when peer review is already completed', async () => {
      const user = userEvent.setup()
      const mockHandleNext = vi.fn()

      render(
        <AssignmentSubmission
          {...createDefaultProps({
            assignment: createAssignment(),
            isPeerReviewCompleted: true,
            handleNextPeerReview: mockHandleNext,
          })}
        />,
      )

      expect(FlashAlert.showFlashAlert).not.toHaveBeenCalled()
    })
  })
})
