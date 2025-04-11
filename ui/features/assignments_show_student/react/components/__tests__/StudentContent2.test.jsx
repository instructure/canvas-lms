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
import {fireEvent, render, waitFor, within} from '@testing-library/react'
import {
  mockAssignmentAndSubmission,
  mockQuery,
  mockSubmission,
} from '@canvas/assignments/graphql/studentMocks'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import {AssignmentMocks} from '@canvas/assignments/graphql/student/Assignment'
import {RUBRIC_QUERY, SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
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

  it('does not render the attempt select if allSubmissions is not provided', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('does not render the attempt select if the assignment has non-digital submissions', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {nonDigitalSubmission: true},
      Submission: {...SubmissionMocks.submitted},
    })
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('does not render the attempt select if peerReviewModeEnabled is set to true', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    props.assignment.env.peerReviewModeEnabled = true
    props.assignment.env.peerReviewAvailable = true
    props.allSubmissions = [props.submission]
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
    expect(queryByTestId('attemptSelect')).not.toBeInTheDocument()
  })

  it('renders the attempt select if peerReviewModeEnabled is set to false', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.submitted},
    })
    props.assignment.env.peerReviewModeEnabled = false
    props.allSubmissions = [props.submission]
    const {queryByTestId} = render(
      <MockedProvider>
        <StudentContent {...props} />
      </MockedProvider>,
    )
    expect(queryByTestId('attemptSelect')).toBeInTheDocument()
  })

  describe('when the assignment does not expect digital submissions', () => {
    let props

    beforeEach(async () => {
      oldEnv = window.ENV
      window.ENV = {...window.ENV}

      props = await mockAssignmentAndSubmission({
        Assignment: {
          ...AssignmentMocks.onPaper,
          name: 'this is my assignment',
        },
        Submission: {},
      })
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders the assignment details', async () => {
      const {getAllByText} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getAllByText(/this is my assignment/)).not.toHaveLength(0)
    })

    it('does not render the interface for submitting to the assignment', async () => {
      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByTestId('assignment-2-student-content-tabs')).not.toBeInTheDocument()
    })

    it('renders only View Submission link when assignment accepts lti tool submissions and the submission is graded but LTI_TOOL is falsy', async () => {
      props.assignment.submissionTypes = ['external_tool']
      props.submission.state = 'graded'
      // in this case, LTI_TOOL is null

      const {getByTestId, queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      const submissionDetailsLink = getByTestId('view-submission-link')
      expect(submissionDetailsLink).toBeInTheDocument()
      expect(queryByTestId('lti-external-tool')).not.toBeInTheDocument()
    })

    it('only the LTI tool iframe LTI_TOOL is true and the submission is not graded', async () => {
      window.ENV.LTI_TOOL = 'true'
      props.submission.state = 'unsubmitted'

      const {queryByTestId, getByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      expect(queryByTestId('view-submission-link')).not.toBeInTheDocument()
      expect(getByTestId('lti-external-tool')).toBeInTheDocument()
    })

    it('neither renders the View Submission link nor the LTI iframe when LTI_TOOL is false, and assignment does not accept external_tool', async () => {
      props.submission.state = 'graded'
      props.assignment.submissionTypes = ['file_upload']

      const {queryByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      expect(queryByTestId('view-submission-link')).not.toBeInTheDocument()
      expect(queryByTestId('lti-external-tool')).not.toBeInTheDocument()
    })

    it('both LTI Iframe and submission link when all their requirements are true', async () => {
      props.assignment.submissionTypes = ['external_tool']
      props.submission.state = 'graded'
      window.ENV.LTI_TOOL = 'true'
      const {getByTestId} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      const lti_external_tool = getByTestId('lti-external-tool')
      expect(lti_external_tool).toBeInTheDocument()
      const view_submission_link = getByTestId('view-submission-link')
      expect(view_submission_link).toBeInTheDocument()
    })

    it('renders a "Mark as Done" button if the assignment is part of a module with a mark-as-done requirement', async () => {
      window.ENV.CONTEXT_MODULE_ITEM = {
        done: false,
        id: '123',
        module_id: '456',
      }

      const {getByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(getByRole('button', {name: 'Mark as done'})).toBeInTheDocument()
    })

    it('does not render a "Mark as Done" button if the assignment lacks mark-as-done requirements', async () => {
      const {queryByRole} = render(
        <MockedProvider>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      expect(queryByRole('button', {name: 'Mark as done'})).not.toBeInTheDocument()
    })

    it.skip('renders the rubric if the assignment has one', async () => {
      window.ENV.ASSIGNMENT_ID = '1'
      window.ENV.COURSE_ID = '1'
      window.ENV.current_user = {id: '2'}
      props.assignment.rubric = {}

      const variables = {
        courseID: '1',
        assignmentLid: '1',
        submissionAttempt: 0,
        submissionID: '1',
      }
      const overrides = {
        Account: {outcomeProficiency: {proficiencyRatingsConnection: null}},
        Assignment: {rubric: {}},
        Course: {id: '1'},
        Node: {__typename: 'Assignment'},
        Rubric: {
          criteria: [],
          title: 'Some On-paper Rubric',
        },
      }
      const result = await mockQuery(RUBRIC_QUERY, overrides, variables)
      const mocks = [
        {
          request: {
            query: RUBRIC_QUERY,
            variables,
          },
          result,
        },
      ]

      const {findByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>,
      )

      expect(await findByText('View Rubric')).toBeInTheDocument()
    })

    describe('module links', () => {
      beforeEach(() => {
        window.ENV.ASSIGNMENT_ID = '1'
        window.ENV.COURSE_ID = '1'

        ContextModuleApi.getContextModuleData.mockClear()
      })

      it('renders next and previous module links if they exist for the assignment', async () => {
        ContextModuleApi.getContextModuleData.mockResolvedValue({
          next: {url: '/next', tooltipText: {string: 'Next'}},
          previous: {url: '/previous', tooltipText: {string: 'Previous'}},
        })

        const {getByTestId} = render(
          <MockedProvider>
            <StudentContent {...props} />
          </MockedProvider>,
        )
        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())

        const footer = getByTestId('student-footer')
        expect(within(footer).getByRole('link', {name: /Previous/})).toBeInTheDocument()
        expect(within(footer).getByRole('link', {name: /Next/})).toBeInTheDocument()
      })

      it('does not render module links if no next/previous modules exist for the assignment', async () => {
        ContextModuleApi.getContextModuleData.mockResolvedValue({})

        const {queryByRole} = render(
          <MockedProvider>
            <StudentContent {...props} />
          </MockedProvider>,
        )
        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())

        expect(queryByRole('link', {name: /Previous/})).not.toBeInTheDocument()
        expect(queryByRole('link', {name: /Next/})).not.toBeInTheDocument()
      })
    })
  })

  describe('when the comments tray is opened', () => {
    const makeMocks = async () => {
      const variables = {submissionAttempt: 0, submissionId: '1'}
      const overrides = {
        Node: {__typename: 'Submission'},
        SubmissionCommentConnection: {nodes: []},
      }
      const result = await mockQuery(SUBMISSION_COMMENT_QUERY, overrides, variables)
      return [
        {
          request: {
            query: SUBMISSION_COMMENT_QUERY,
            variables,
          },
          result,
        },
      ]
    }

    it('renders Comments', async () => {
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {findByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      fireEvent.click(await findByText(/add comment/i))
      expect(await findByText(/attempt 1 feedback/i)).toBeInTheDocument()
    })

    it('renders spinner while lazy loading comments', async () => {
      const mocks = await makeMocks()
      const props = await mockAssignmentAndSubmission()
      const {getAllByTitle, getByText} = render(
        <MockedProvider mocks={mocks}>
          <StudentContent {...props} />
        </MockedProvider>,
      )
      fireEvent.click(getByText('Add Comment'))
      expect(getAllByTitle('Loading')[0]).toBeInTheDocument()
    })
  })
})
