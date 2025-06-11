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
import {
  CREATE_SUBMISSION,
  CREATE_SUBMISSION_DRAFT,
  DELETE_SUBMISSION_DRAFT,
  SET_MODULE_ITEM_COMPLETION,
} from '@canvas/assignments/graphql/student/Mutations'
import {
  RUBRIC_QUERY,
  SUBMISSION_HISTORIES_QUERY,
  USER_GROUPS_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {assignLocation} from '@canvas/util/globalUtils'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {act, fireEvent, render, screen, waitFor, within} from '@testing-library/react'
import React from 'react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import {COMPLETED_PEER_REVIEW_TEXT, availableReviewCount} from '../../helpers/PeerReviewHelpers'
import TextEntry from '../AttemptType/TextEntry'
import StudentViewContext, {StudentViewContextDefaults} from '../Context'
import SubmissionManager from '../SubmissionManager'
import store from '../stores'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

// Mock the RCE so we can test text entry submissions without loading the whole
// editor
jest.mock('@canvas/rce/RichContentEditor')

jest.mock('../../apis/ContextModuleApi')

jest.mock('@canvas/do-fetch-api-effect')

jest.useFakeTimers()

function renderInContext(overrides = {}, children) {
  const contextProps = {...StudentViewContextDefaults, ...overrides}

  return render(
    <StudentViewContext.Provider value={contextProps}>{children}</StudentViewContext.Provider>,
  )
}

function gradedOverrides() {
  return {
    Submission: {
      rubricAssessmentsConnection: {
        nodes: [
          {
            _id: 1,
            score: 5,
            assessor: {_id: 1, name: 'assessor1', enrollments: []},
          },
          {
            _id: 2,
            score: 10,
            assessor: null,
          },
          {
            _id: 3,
            score: 8,
            assessor: {_id: 2, name: 'assessor2', enrollments: [{type: 'TaEnrollment'}]},
          },
        ],
      },
    },
  }
}

describe('SubmissionManager', () => {
  beforeAll(() => {
    window.INST = window.INST || {}
    window.INST.editorButtons = []
  })

  beforeEach(() => {
    ContextModuleApi.getContextModuleData.mockResolvedValue({})
  })

  it('renders the AttemptTab', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )

    expect(getByTestId('attempt-tab')).toBeInTheDocument()
  })

  it('does not render a submit button when peer review mode is OFF', async () => {
    const props = await mockAssignmentAndSubmission()
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )

    expect(queryByText('Submit')).not.toBeInTheDocument()
  })

  it('renders a submit button when the draft criteria is met for the active type', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })
    const {getByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )

    expect(getByText('Submit Assignment')).toBeInTheDocument()
  })

  it('does not render submit button for observers', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })
    const {queryByText} = renderInContext(
      {allowChangesToSubmission: false, isObserver: true},
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )

    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  it('does not render the submit button if we are not on the latest submission', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.graded,
    })
    const latestSubmission = {attempt: 2, state: 'unsubmitted'}

    const {queryByText} = renderInContext(
      {isLatestAttempt: false, latestSubmission},
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )
    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  it('does not render the submit button if the assignment is locked', async () => {
    const props = await mockAssignmentAndSubmission({
      LockInfo: {isLocked: true},
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )

    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  it('does not render the submit button if the submission cannot be modified', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })

    const {queryByText} = renderInContext(
      {allowChangesToSubmission: false},
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )
    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  it('does not render submit button when the the submission is excused', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {...SubmissionMocks.excused},
    })

    const {queryByText} = renderInContext(
      {lastSubmittedSubmission: props.submission},
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )
    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  it('does not render submit button when there are no attempts left', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {
        submissionTypes: ['online_text_entry'],
        allowedAttempts: 1,
      },
      Submission: {
        attempt: 1,
        state: 'submitted',
      },
    })

    renderInContext(
      {latestSubmission: props.submission},
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )

    expect(screen.queryByRole('button', {name: 'Submit Assignment'})).not.toBeInTheDocument()
  })

  it('renders the submit button when there are attempts left', async () => {
    const props = await mockAssignmentAndSubmission({
      Assignment: {
        submissionTypes: ['online_text_entry'],
        allowedAttempts: 2,
      },
      Submission: {
        attempt: 1,
        state: 'unsubmitted',
      },
    })

    renderInContext(
      {latestSubmission: props.submission},
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>,
    )

    expect(screen.getByRole('button', {name: 'Submit Assignment'})).toBeInTheDocument()
  })

  function testConfetti(testName, {enabled, dueDate, inDocument}) {
    describe(`confetti ${enabled ? 'enabled' : 'disabled'}`, () => {
      beforeEach(() => {
        window.ENV = {
          CONFETTI_ENABLED: enabled,
          ASSIGNMENT_ID: '1',
          COURSE_ID: '1',
        }
      })

      it(testName, async () => {
        jest.spyOn(global.Date, 'parse').mockImplementationOnce(() => new Date(dueDate).valueOf())

        const props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_url'],
          },
          Submission: {
            submissionDraft: {
              activeSubmissionType: 'online_url',
              meetsUrlCriteria: true,
              url: 'http://localhost',
            },
          },
        })

        const variables = {
          assignmentLid: '1',
          submissionID: '1',
          type: 'online_url',
          url: 'http://localhost',
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

        const {getByTestId, queryByTestId} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>,
        )

        act(() => {
          const submitButton = getByTestId('submit-button')
          fireEvent.click(submitButton)
        })
        await waitFor(() => expect(getByTestId('submit-button')).not.toBeDisabled())
        if (inDocument) {
          expect(queryByTestId('confetti-canvas')).toBeInTheDocument()
        } else {
          expect(queryByTestId('confetti-canvas')).not.toBeInTheDocument()
        }
      })
    })
  }

  testConfetti('renders confetti for on time submissions', {
    enabled: true,
    dueDate: Date.now() + 100000,
    inDocument: true,
  })
  testConfetti('does not render confetti if not enabled', {
    enabled: false,
    dueDate: Date.now() + 100000,
    inDocument: false,
  })
  testConfetti('does not render confetti if past the due date', {
    enabled: true,
    dueDate: Date.now() - 100000,
    inDocument: false,
  })
})
