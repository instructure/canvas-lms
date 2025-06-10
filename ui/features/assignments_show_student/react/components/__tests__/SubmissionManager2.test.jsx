/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {CREATE_SUBMISSION} from '@canvas/assignments/graphql/student/Mutations'
import {SUBMISSION_HISTORIES_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {assignLocation} from '@canvas/util/globalUtils'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {act, fireEvent, render, screen, within} from '@testing-library/react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import SubmissionManager from '../SubmissionManager'
import {availableReviewCount} from '../../helpers/PeerReviewHelpers'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

// Mock the RCE so we can test text entry submissions without loading the whole
// editor
jest.mock('@canvas/rce/RichContentEditor')

jest.mock('../../apis/ContextModuleApi')

jest.mock('@canvas/do-fetch-api-effect')

jest.useFakeTimers()

describe('SubmissionManager', () => {
  beforeAll(() => {
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  beforeEach(() => {
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  describe('Peer Review modal after clicking the "Submit Assignment" button', () => {
    let props, createSubmissionResult, submissionHistoriesResult, mocks, oldEnv
    const variables = {
      assignmentLid: '1',
      submissionID: '1',
      type: 'online_upload',
      fileIds: ['1'],
    }

    beforeEach(async () => {
      oldEnv = window.ENV
      window.ENV = {
        ASSIGNMENT_ID: '1',
        COURSE_ID: '1',
        ASSET_REPORTS: [],
      }

      createSubmissionResult = await mockQuery(CREATE_SUBMISSION, {}, variables)
      submissionHistoriesResult = await mockQuery(
        SUBMISSION_HISTORIES_QUERY,
        {Node: {__typename: 'Submission'}},
        {submissionID: '1'},
      )
      mocks = [
        {
          request: {query: CREATE_SUBMISSION, variables},
          result: createSubmissionResult,
        },
        {
          request: {query: SUBMISSION_HISTORIES_QUERY, variables: {submissionID: '1'}},
          result: submissionHistoriesResult,
        },
      ]
      props = await mockAssignmentAndSubmission({
        Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      })
      props.submission = {
        ...props.submission,
        assignedAssessments: [
          {
            anonymousUser: null,
            anonymousId: 'xaU9cd',
            workflowState: 'completed',
            assetSubmissionType: 'online_text_entry',
          },
          {
            anonymousUser: null,
            anonymousId: 'baT9cx',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      }
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('is present when there are assigned assessments', async () => {
      const {getByText, getByRole, findByText} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        </AlertManagerContext.Provider>,
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      await act(async () => {
        jest.runOnlyPendingTimers()
      })

      expect(window.ENV.ASSET_REPORTS).not.toBeDefined()
      const peerReviewButton = getByRole('button', {name: 'Peer Review'})
      expect(peerReviewButton).toBeInTheDocument()
      expect(await findByText('Your work has been submitted.')).toBeTruthy()
      expect(await findByText('Check back later to view feedback.')).toBeTruthy()
      const assignedAssessmentsTotal = props.submission.assignedAssessments.filter(
        a => a.workflowState === 'assigned',
      ).length
      const availableTotal = availableReviewCount(props.submission.assignedAssessments)
      expect(
        await findByText(`You have ${assignedAssessmentsTotal} Peer Review to complete.`),
      ).toBeTruthy()
      expect(await findByText(`Peer submissions ready for review: ${availableTotal}`)).toBeTruthy()
    })

    it('is not present when there are no assigned assessments', async () => {
      props.submission.assignedAssessments = []

      const {getByText, queryByRole} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        </AlertManagerContext.Provider>,
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      await act(async () => {
        jest.runOnlyPendingTimers()
      })

      const peerReviewButton = queryByRole('button', {name: 'Peer Review'})
      expect(peerReviewButton).not.toBeInTheDocument()
    })

    it('renders a disabled "Peer Review" button when there are no available peer reviews', async () => {
      props.submission = {
        ...props.submission,
        assignedAssessments: [
          {
            anonymizedUser: {_id: '1'},
            anonymousId: 'xaU9cd',
            workflowState: 'completed',
            assetSubmissionType: 'online_text_entry',
          },
          {
            anonymizedUser: {_id: '2'},
            anonymousId: 'baT9cx',
            workflowState: 'completed',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      }

      const {getByText} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        </AlertManagerContext.Provider>,
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      await act(async () => {
        jest.runOnlyPendingTimers()
      })

      expect(getByText('Peer Review').closest('button')).toBeDisabled()
    })

    it('redirects to the corresponding url when the anonymous peer reviews option is disabled and the "Peer Review" button is clicked', async () => {
      props.submission = {
        ...props.submission,
        assignedAssessments: [
          {
            anonymizedUser: {_id: '1'},
            anonymousId: 'xaU9cd',
            workflowState: 'completed',
            assetSubmissionType: 'online_text_entry',
          },
          {
            anonymizedUser: {_id: '2'},
            anonymousId: 'baT9cx',
            workflowState: 'assigned',
            assetSubmissionType: 'online_text_entry',
          },
        ],
      }

      const {getByText, queryByRole} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        </AlertManagerContext.Provider>,
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      await act(async () => {
        jest.runOnlyPendingTimers()
      })

      const peerReviewButton = queryByRole('button', {name: 'Peer Review'})
      fireEvent.click(peerReviewButton)

      const availableAssessment = props.submission.assignedAssessments[1]
      expect(assignLocation).toHaveBeenCalledWith(
        `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}?reviewee_id=${availableAssessment.anonymizedUser._id}`,
      )
    })

    it('redirects to the corresponding url when the anonymous peer reviews option is enabled and the "Peer Review" button is clicked', async () => {
      const {getByText, queryByRole} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        </AlertManagerContext.Provider>,
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      await act(async () => {
        jest.runOnlyPendingTimers()
      })

      const peerReviewButton = queryByRole('button', {name: 'Peer Review'})
      fireEvent.click(peerReviewButton)

      const availableAssessment = props.submission.assignedAssessments[1]
      expect(assignLocation).toHaveBeenCalledWith(
        `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}?anonymous_asset_id=${availableAssessment.anonymousId}`,
      )
    })
  })

  it('disables the submit button after it is pressed', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })

    const variables = {
      assignmentLid: '1',
      submissionID: '1',
      type: 'online_upload',
      fileIds: ['1'],
    }
    const createSubmissionResult = await mockQuery(CREATE_SUBMISSION, {}, variables)
    const submissionHistoriesResult = await mockQuery(
      SUBMISSION_HISTORIES_QUERY,
      {Node: {__typename: 'Submission'}},
      {submissionID: '1'},
    )
    const mocks = [
      {
        request: {query: CREATE_SUBMISSION, variables},
        result: createSubmissionResult,
      },
      {
        request: {query: SUBMISSION_HISTORIES_QUERY, variables: {submissionID: '1'}},
        result: submissionHistoriesResult,
      },
    ]

    const {getByText} = render(
      <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
        <MockedProvider mocks={mocks}>
          <SubmissionManager {...props} />
        </MockedProvider>
      </AlertManagerContext.Provider>,
    )

    const submitButton = getByText('Submit Assignment')
    fireEvent.click(submitButton)
    expect(getByText('Submit Assignment').closest('button')).toBeDisabled()
  })

  describe('with multiple submission types drafted', () => {
    it('renders a confirmation modal if the submit button is pressed', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_text_entry', 'online_url'],
        },
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_text_entry',
            body: 'some text here',
            meetsTextEntryCriteria: true,
            meetsUrlCriteria: true,
            url: 'http://www.google.com',
          },
        },
      })

      const {getByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
      )

      const submitButton = getByTestId('submit-button')
      fireEvent.click(submitButton)

      const confirmationDialog = await screen.findByRole('dialog', {label: 'Delete your work?'})
      expect(confirmationDialog).toHaveTextContent('You are submitting a Text submission')

      const cancelButton = within(confirmationDialog).getByTestId('cancel-button')
      const confirmButton = within(confirmationDialog).getByTestId('confirm-button')

      expect(cancelButton).toBeInTheDocument()
      expect(cancelButton).toHaveTextContent('Cancel')
      expect(confirmButton).toBeInTheDocument()
      expect(confirmButton).toHaveTextContent('Okay')
      fireEvent.click(cancelButton)
    })
  })
})
