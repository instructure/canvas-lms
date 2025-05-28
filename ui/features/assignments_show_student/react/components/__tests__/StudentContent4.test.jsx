/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {MockedProvider} from '@apollo/client/testing'
import {render} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import StudentViewContext from '../Context'
import StudentContent from '../StudentContent'
import ContextModuleApi from '../../apis/ContextModuleApi'

injectGlobalAlertContainers()

jest.mock('../AttemptSelect')

jest.mock('../../apis/ContextModuleApi')

jest.mock('../../../../../shared/immersive-reader/ImmersiveReader', () => {
  return {
    initializeReaderButton: jest.fn(),
  }
})

describe('Assignment Student Content View', () => {
  let oldEnv

  beforeEach(() => {
    oldEnv = window.ENV
    window.ENV = {...window.ENV}
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  describe('Add Comment/View Feedback button', () => {
    it('renders as "Add Comment" by default', async () => {
      const props = await mockAssignmentAndSubmission()
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getByText('Add Comment')).toBeInTheDocument()
    })

    it('shows the unread comments badge if there are unread comments', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {unreadCommentCount: 1, feedbackForCurrentAttempt: true},
      })
      const {getByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getByTestId('view_feedback_button')).toHaveTextContent('View Feedback')
      expect(getByTestId('unread_comments_badge')).toBeInTheDocument()
    })

    it('does not show unread comments if the assignment grade is not posted', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {unreadCommentCount: 1, feedbackForCurrentAttempt: false},
      })
      props.submission.gradingStatus = 'needs_grading'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('unread_comments_badge')).not.toBeInTheDocument()
    })

    it('does not show the unread comments badge if there are no unread comments', async () => {
      const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 0}})
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('unread_comments_badge')).not.toBeInTheDocument()
    })

    it('renders as "Add Comment" by default for nonDigitalSubmission', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {nonDigitalSubmission: true},
        Submission: {...SubmissionMocks.submitted},
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getByText('Add Comment')).toBeInTheDocument()
    })

    it('renders as "View Feedback" for observers', async () => {
      const props = await mockAssignmentAndSubmission()

      const {getByText} = render(
        <StudentViewContext.Provider
          value={{
            allowChangesToSubmission: false,
            isObserver: true,
            latestSubmission: props.submission,
          }}
        >
          <MockedProvider>
            <StudentContent {...props} />
          </MockedProvider>
        </StudentViewContext.Provider>,
      )
      expect(getByText('View Feedback')).toBeInTheDocument()
    })

    it('renders as "View Feedback" if feedback exists', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {feedbackForCurrentAttempt: true},
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getByText('View Feedback')).toBeInTheDocument()
    })

    it('renders as "View Feedback" if feedback exists for nonDigitalSubmission', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {nonDigitalSubmission: true},
        Submission: {feedbackForCurrentAttempt: true},
      })
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getByText('View Feedback')).toBeInTheDocument()
    })

    it('renders as "Add Comment" and disabled if unsubmitted attempt>1', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.unsubmitted,
          attempt: 2,
        },
      })
      props.assignment.env.peerReviewModeEnabled = false
      props.assignment.env.peerReviewAvailable = false
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getByText('Add Comment').closest('button')).toBeDisabled()
    })

    it('renders additional info button if unsubmitted attempt>1', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.unsubmitted,
          attempt: 2,
        },
      })
      props.assignment.env.peerReviewModeEnabled = false
      props.assignment.env.peerReviewAvailable = false
      const {getByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      const screenText = getByText(
        /After the first attempt, you cannot leave comments until you submit the assignment./,
      )
      expect(screenText).toBeInTheDocument()
    })

    it('does not render additional info button if unsubmitted attempt==1', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.unsubmitted,
          attempt: 1,
        },
      })
      const {queryByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(
        queryByRole('button', {
          name: /After the first attempt, you cannot leave comments until you submit the assignment./,
        }),
      ).not.toBeInTheDocument()
    })

    it('does not render additional info button if submitted attempt>1', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.submitted,
          attempt: 2,
        },
      })
      const {queryByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(
        queryByRole('button', {
          name: /After the first attempt, you cannot leave comments until you submit the assignment./,
        }),
      ).not.toBeInTheDocument()
    })

    it('does not show the unread comments badge if peerReviewModeEnabled is set to true', async () => {
      const props = await mockAssignmentAndSubmission({Submission: {unreadCommentCount: 1}})
      props.assignment.env.peerReviewModeEnabled = true
      props.reviewerSubmission = {
        ...props.submission,
        assignedAssessments: [
          {
            assetId: '1',
            anonymousUser: null,
            anonymousId: 'xaU9cd',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      }
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('unread_comments_badge')).not.toBeInTheDocument()
    })

    it('shows the unread comments badge if peerReviewModeEnabled is set to false', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {unreadCommentCount: 1, feedbackForCurrentAttempt: true},
      })
      props.assignment.env.peerReviewModeEnabled = false
      const {getByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getByTestId('view_feedback_button')).toHaveTextContent('View Feedback')
      expect(getByTestId('unread_comments_badge')).toBeInTheDocument()
    })
  })
  describe('submission workflow tracker', () => {
    it('is rendered when a submission exists and the assignment is available', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('submission-workflow-tracker')).toBeInTheDocument()
    })

    it('is not rendered when no submission object is present', async () => {
      const props = await mockAssignmentAndSubmission({Query: {submission: null}})
      props.allSubmissions = [{id: '1', _id: '1'}]
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })

    it('is not rendered when there is no current user', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.currentUser = null
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })

    it('is not rendered when the assignment has not been unlocked yet', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.modulePrereq = 'simulate not null'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })

    it('is not rendered when the assignment has uncompleted prerequisites', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.unlockDate = 'soon'
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })

    it('is rendered if peerReviewModeEnabled is set to false', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = false
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('submission-workflow-tracker')).toBeInTheDocument()
    })

    it('is not rendered if peerReviewModeEnabled is set to true', async () => {
      const props = await mockAssignmentAndSubmission()
      props.assignment.env.peerReviewModeEnabled = true
      props.assignment.env.peerReviewAvailable = true
      props.reviewerSubmission = {
        ...props.submission,
        assignedAssessments: [
          {
            assetId: '1',
            anonymousUser: null,
            anonymousId: 'xaU9cd',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      }
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('submission-workflow-tracker')).not.toBeInTheDocument()
    })
  })
})
