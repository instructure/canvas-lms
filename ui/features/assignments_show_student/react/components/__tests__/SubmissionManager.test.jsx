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
  SUBMISSION_HISTORIES_QUERY,
  USER_GROUPS_QUERY,
  RUBRIC_QUERY,
} from '@canvas/assignments/graphql/student/Queries'
import {act, fireEvent, render, screen, waitFor, within} from '@testing-library/react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProviderWithIntrospectionMatching as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithIntrospectionMatching'
import React from 'react'
import StudentViewContext, {StudentViewContextDefaults} from '../Context'
import SubmissionManager from '../SubmissionManager'
import TextEntry from '../AttemptType/TextEntry'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import doFetchApi from '@canvas/do-fetch-api-effect'
import store from '../stores'
import {availableReviewCount, COMPLETED_PEER_REVIEW_TEXT} from '../../helpers/PeerReviewHelpers'

// Mock the RCE so we can test text entry submissions without loading the whole
// editor
jest.mock('@canvas/rce/RichContentEditor')

jest.mock('../../apis/ContextModuleApi')

jest.mock('@canvas/do-fetch-api-effect')

jest.useFakeTimers()

function renderInContext(overrides = {}, children) {
  const contextProps = {...StudentViewContextDefaults, ...overrides}

  return render(
    <StudentViewContext.Provider value={contextProps}>{children}</StudentViewContext.Provider>
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
    Course: {
      account: {
        outcomeProficiency: {
          proficiencyRatingsConnection: {
            nodes: [{}],
          },
        },
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
      </MockedProvider>
    )

    expect(getByTestId('attempt-tab')).toBeInTheDocument()
  })

  it('renders a disabled submit button when the draft criteria is not met', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByText('Submit Assignment').closest('button')).toBeDisabled()
  })

  it('does not render a submit button when peer review mode is OFF', async () => {
    const props = await mockAssignmentAndSubmission()
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
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
      </MockedProvider>
    )

    expect(getByText('Submit Assignment')).toBeInTheDocument()
  })

  it('renders a disabled submit button if the draft criteria is not met for the active type', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        submissionDraft: {
          activeSubmissionType: 'online_upload',
          body: 'some text here',
        },
      },
    })
    const {getByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByText('Submit Assignment').closest('button')).toBeDisabled()
  })

  it('renders a disabled submit button if data placeholders are still present', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        submissionDraft: {
          meetsAssignmentCriteria: true,
          activeSubmissionType: 'online_text_entry',
          body: '<p><span aria-label="Loading" data-placeholder-for="filename"> </span></p>',
        },
      },
    })
    const {getByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByText('Submit Assignment').closest('button')).toBeDisabled()
  })

  it('does not render submit button for observers', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
    })
    const {queryByText} = renderInContext(
      {allowChangesToSubmission: false, isObserver: true},
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
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
      </MockedProvider>
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
      </MockedProvider>
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
      </MockedProvider>
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
      </MockedProvider>
    )
    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  function testConfetti(testName, {enabled, dueDate, inDocument}) {
    // eslint-disable-next-line jest/valid-describe
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
              type: 'online_url',
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
          {submissionID: '1'}
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
          </AlertManagerContext.Provider>
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

  describe('Peer Review modal after clicking the "Submit Assignment" button', () => {
    const {assign} = window.location
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
      }
      delete window.location
      window.location = {assign: jest.fn(), origin: 'http://localhost'}

      createSubmissionResult = await mockQuery(CREATE_SUBMISSION, {}, variables)
      submissionHistoriesResult = await mockQuery(
        SUBMISSION_HISTORIES_QUERY,
        {Node: {__typename: 'Submission'}},
        {submissionID: '1'}
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
      window.location.assign = assign
    })

    it('is present when there are assigned assessments', async () => {
      const {getByText, getByRole, findByText} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        </AlertManagerContext.Provider>
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      await act(async () => {
        jest.runOnlyPendingTimers()
      })

      const peerReviewButton = getByRole('button', {name: 'Peer Review'})
      expect(peerReviewButton).toBeInTheDocument()
      expect(await findByText('Your work has been submitted.')).toBeTruthy()
      expect(await findByText('Check back later to view feedback.')).toBeTruthy()
      const assignedAssessmentsTotal = props.submission.assignedAssessments.filter(
        a => a.workflowState === 'assigned'
      ).length
      const availableTotal = availableReviewCount(props.submission.assignedAssessments)
      expect(
        await findByText(`You have ${assignedAssessmentsTotal} Peer Review to complete.`)
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
        </AlertManagerContext.Provider>
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
        </AlertManagerContext.Provider>
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
        </AlertManagerContext.Provider>
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      await act(async () => {
        jest.runOnlyPendingTimers()
      })

      const peerReviewButton = queryByRole('button', {name: 'Peer Review'})
      fireEvent.click(peerReviewButton)

      const availableAssessment = props.submission.assignedAssessments[1]
      expect(window.location.assign).toHaveBeenCalledWith(
        `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}?reviewee_id=${availableAssessment.anonymizedUser._id}`
      )
    })

    it('redirects to the corresponding url when the anonymous peer reviews option is enabled and the "Peer Review" button is clicked', async () => {
      const {getByText, queryByRole} = render(
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        </AlertManagerContext.Provider>
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      await act(async () => {
        jest.runOnlyPendingTimers()
      })

      const peerReviewButton = queryByRole('button', {name: 'Peer Review'})
      fireEvent.click(peerReviewButton)

      const availableAssessment = props.submission.assignedAssessments[1]
      expect(window.location.assign).toHaveBeenCalledWith(
        `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}?anonymous_asset_id=${availableAssessment.anonymousId}`
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
      {submissionID: '1'}
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
      </AlertManagerContext.Provider>
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
        </MockedProvider>
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

  describe('"Mark as Done" button', () => {
    describe('when ENV.CONTEXT_MODULE_ITEM is set', () => {
      let props

      const successfulResponse = {
        data: {
          setModuleItemCompletion: {
            __typename: '',
            moduleItem: null,
            errors: null,
          },
        },
        errors: null,
      }

      const failedResponse = {data: null, errors: 'yes'}

      beforeEach(async () => {
        window.ENV.CONTEXT_MODULE_ITEM = {
          done: false,
          id: '1',
          module_id: '2',
        }

        props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_url'],
          },
        })
      })

      afterEach(() => {
        delete window.ENV.CONTEXT_MODULE_ITEM
      })

      it('is rendered as "Mark as done" if the value of "done" is false', async () => {
        const {getByTestId} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        const markAsDoneButton = getByTestId('set-module-item-completion-button')
        expect(markAsDoneButton).toHaveTextContent('Mark as done')
      })

      it('is rendered as "Done" if the value of "done" is true', async () => {
        window.ENV.CONTEXT_MODULE_ITEM.done = true

        const {getByTestId} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        const markAsDoneButton = getByTestId('set-module-item-completion-button')
        expect(markAsDoneButton).toHaveTextContent('Done')
      })

      it('sends a request when clicked', async () => {
        const variables = {
          done: true,
          itemId: '1',
          moduleId: '2',
        }

        const mocks = [
          {
            request: {query: SET_MODULE_ITEM_COMPLETION, variables},
            result: successfulResponse,
          },
        ]

        const {getByTestId} = render(
          <AlertManagerContext.Provider
            value={{...StudentViewContextDefaults, setOnFailure: jest.fn()}}
          >
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )

        const markAsDoneButton = getByTestId('set-module-item-completion-button')
        expect(markAsDoneButton).toHaveTextContent('Mark as done')
        act(() => {
          fireEvent.click(markAsDoneButton)
        })

        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        expect(getByTestId('set-module-item-completion-button')).toHaveTextContent('Done')
      })

      it('updates itself to the opposite appearance when the request succeeds', async () => {
        const variables = {
          done: true,
          itemId: '1',
          moduleId: '2',
        }

        const mocks = [
          {
            request: {query: SET_MODULE_ITEM_COMPLETION, variables},
            result: successfulResponse,
          },
        ]

        const {getByTestId} = render(
          <AlertManagerContext.Provider value={{...StudentViewContextDefaults}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )

        const markAsDoneButton = getByTestId('set-module-item-completion-button')
        expect(markAsDoneButton).toHaveTextContent('Mark as done')
        act(() => {
          fireEvent.click(markAsDoneButton)
        })

        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        expect(getByTestId('set-module-item-completion-button')).toHaveTextContent('Done')
      })

      it('does not update its appearance when the request fails', async () => {
        const variables = {
          done: true,
          itemId: '1',
          moduleId: '2',
        }

        const mocks = [
          {
            request: {query: SET_MODULE_ITEM_COMPLETION, variables},
            result: failedResponse,
          },
        ]

        const {getByTestId} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn()}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )

        const markAsDoneButton = getByTestId('set-module-item-completion-button')
        expect(markAsDoneButton).toHaveTextContent('Mark as done')
        act(() => {
          fireEvent.click(markAsDoneButton)
        })

        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        expect(markAsDoneButton).toHaveTextContent('Mark as done')
      })
    })

    it('does not render if ENV.CONTEXT_MODULE_ITEM is not set', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('set-module-item-completion-button')).not.toBeInTheDocument()
    })
  })

  describe('"Try Again" button', () => {
    describe('if submitted and there are more attempts', () => {
      it('is rendered if changes can be made to the submission', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_text_entry'],
          },
          Submission: {...SubmissionMocks.submitted},
        })

        const {getByTestId} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        expect(getByTestId('new-attempt-button')).toBeInTheDocument()
      })

      it('is not rendered for observers', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_text_entry'],
          },
          Submission: {...SubmissionMocks.submitted},
        })
        const {queryByTestId} = renderInContext(
          {allowChangesToSubmission: false, isObserver: true},
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )
        expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
      })

      it('is not rendered if changes cannot be made to the submission', async () => {
        const props = await mockAssignmentAndSubmission({
          Submission: {...SubmissionMocks.submitted},
        })
        const {queryByTestId} = renderInContext(
          {allowChangesToSubmission: false},
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )
        expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
      })
    })

    it('is not rendered if nothing has been submitted', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
    })

    it('is not rendered if the student has been graded before submitting', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {
          ...SubmissionMocks.graded,
          attempt: 0,
        },
      })
      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
    })

    it('is not rendered if excused', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.excused},
      })
      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
    })

    it('is not rendered if the assignment is locked', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
        Submission: {...SubmissionMocks.submitted},
      })
      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
    })

    it('is not rendered if there are no more attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1},
        Submission: {...SubmissionMocks.submitted},
      })
      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
    })

    it('accounts for any extra attempts awarded to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1},
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = {attempt: 1, extraAttempts: 2}

      const {queryByTestId} = renderInContext(
        {latestSubmission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('new-attempt-button')).toBeInTheDocument()
    })

    it('is not shown when looking at prevous attempts when all allowed attempts have been used', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1},
        Submission: {...SubmissionMocks.submitted, attempt: 1, extraAttempts: 2},
      })
      const latestSubmission = {attempt: 4, extraAttempts: 3}

      const {queryByTestId} = renderInContext(
        {latestSubmission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
    })
  })

  describe('"Back to Attempt" button', () => {
    it('is rendered if a draft exists and a previous attempt is shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = {attempt: 2, state: 'unsubmitted'}

      const {getByTestId} = renderInContext(
        {latestSubmission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(getByTestId('back-to-attempt-button')).toBeInTheDocument()
    })

    it('includes the current attempt number', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = {attempt: 2, state: 'unsubmitted'}

      const {getByTestId} = renderInContext(
        {latestSubmission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      const button = getByTestId('back-to-attempt-button')
      expect(button).toHaveTextContent('Back to Attempt 2')
    })

    it('is not rendered if no current draft exists', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })

      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('back-to-attempt-button')).not.toBeInTheDocument()
    })

    it('is not rendered if the current draft is selected', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = props.submission

      const {queryByTestId} = renderInContext(
        {latestSubmission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('back-to-attempt-button')).not.toBeInTheDocument()
    })

    it('calls the showDraftAction function supplied by the context when clicked', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })

      const latestSubmission = {
        activeSubmissionType: 'online_text_entry',
        attempt: 2,
        state: 'unsubmitted',
      }
      const showDraftAction = jest.fn()

      const {getByTestId} = renderInContext(
        {latestSubmission, showDraftAction},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      act(() => {
        fireEvent.click(getByTestId('back-to-attempt-button'))
      })
      expect(showDraftAction).toHaveBeenCalled()
    })
  })

  describe('"Cancel Attempt" button', () => {
    it('is rendered if a draft exists and is shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 2},
      })

      const {getByTestId} = renderInContext(
        {latestSubmission: props.submission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(getByTestId('cancel-attempt-button')).toBeInTheDocument()
    })

    it('is not rendered when working on the initial attempt', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 1},
      })

      const {queryByTestId} = renderInContext(
        {latestSubmission: props.submission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('cancel-attempt-button')).not.toBeInTheDocument()
    })

    it('includes the attempt number in the button text', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 2},
      })

      const {getByTestId} = renderInContext(
        {latestSubmission: props.submission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const button = getByTestId('cancel-attempt-button')
      expect(button).toHaveTextContent('Cancel Attempt 2')
    })

    it('is not rendered if no draft exists', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted, attempt: 2},
      })

      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(queryByTestId('cancel-attempt-button')).not.toBeInTheDocument()
    })

    it('is not rendered if a draft exists but is not shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted, attempt: 1},
      })

      const {queryByTestId} = renderInContext(
        {latestSubmission: {attempt: 2, state: 'unsubmitted'}},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(queryByTestId('cancel-attempt-button')).not.toBeInTheDocument()
    })

    describe('when clicked', () => {
      const confirmationDialog = async () =>
        screen.findByRole('dialog', {label: 'Delete your work?'})
      const confirmButton = async () =>
        within(await confirmationDialog()).getByRole('button', {name: 'Delete Work'})
      const cancelButton = async () =>
        within(await confirmationDialog()).getByRole('button', {name: 'Cancel'})

      let cancelDraftAction

      beforeEach(() => {
        cancelDraftAction = jest.fn()
      })

      afterEach(async () => {
        const dialog = screen.queryByRole('dialog', {label: 'Delete your work?'})
        if (dialog != null) {
          fireEvent.click(await cancelButton())
        }
      })

      // TODO (EVAL-2018): the confirmation dialog isn't playing nice with the
      // rest of the tests.  Unskip in the aforementioned ticket, or in a future
      // ticket when we redo the dialog.
      describe.skip('when the current draft has actual content', () => {
        const renderDraft = async () => {
          const props = await mockAssignmentAndSubmission({
            Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 2, id: '123'},
          })

          const variables = {submissionId: '123'}
          const deleteSubmissionDraftResult = await mockQuery(
            DELETE_SUBMISSION_DRAFT,
            {},
            variables
          )

          const mocks = [
            {
              request: {query: DELETE_SUBMISSION_DRAFT, variables},
              result: deleteSubmissionDraftResult,
            },
            {
              request: {query: USER_GROUPS_QUERY, variables: {userID: '1'}},
              result: await mockQuery(
                USER_GROUPS_QUERY,
                {
                  Node: {__typename: 'User'},
                  User: {groups: []},
                },
                {userID: '1'}
              ),
            },
          ]

          return renderInContext(
            {latestSubmission: props.submission, cancelDraftAction},
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          )
        }

        it('shows a confirmation modal if the current draft has any actual content', async () => {
          const {getByTestId} = await renderDraft()

          act(() => {
            fireEvent.click(getByTestId('cancel-attempt-button'))
          })
          expect(await confirmationDialog()).toBeInTheDocument()
        })

        it('calls the cancelDraftAction function if the user confirms the modal', async () => {
          const {getByTestId} = await renderDraft()
          fireEvent.click(getByTestId('cancel-attempt-button'))
          fireEvent.click(await confirmButton())
          await waitFor(() => {
            expect(cancelDraftAction).toHaveBeenCalled()
          })
        })

        it('does nothing if the user cancels the modal', async () => {
          const {getByTestId} = await renderDraft()

          fireEvent.click(getByTestId('cancel-attempt-button'))
          fireEvent.click(await cancelButton())

          expect(cancelDraftAction).not.toHaveBeenCalled()
        })
      })

      describe('when the current draft has no content', () => {
        const renderDraft = async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {
              id: '1',
              submissionTypes: ['online_url'],
            },
            Submission: {attempt: 2},
          })

          return renderInContext(
            {latestSubmission: props.submission, cancelDraftAction},
            <MockedProvider>
              <SubmissionManager {...props} />
            </MockedProvider>
          )
        }

        it('does not show a confirmation', async () => {
          const {getByTestId} = await renderDraft()

          act(() => {
            fireEvent.click(getByTestId('cancel-attempt-button'))
          })
          expect(screen.queryByRole('dialog', {label: 'Delete your work?'})).not.toBeInTheDocument()
        })

        it('calls the cancelDraftAction function', async () => {
          const {getByTestId} = await renderDraft()

          act(() => {
            fireEvent.click(getByTestId('cancel-attempt-button'))
          })
          expect(cancelDraftAction).toHaveBeenCalled()
        })
      })
    })
  })

  describe('saving text entry drafts', () => {
    beforeAll(async () => {
      // This gets the lazy loaded components loaded before our specs.
      // otherwise, the first one (at least) will fail.
      const {unmount} = render(
        <TextEntry focusOnInit={false} submission={{id: '1', _id: '1', state: 'unsubmitted'}} />
      )
      await waitFor(() => {
        expect(tinymce.editors[0]).toBeDefined()
      })
      unmount()
    })

    let fakeEditor
    const renderTextAttempt = async ({mocks = []} = {}) => {
      const submission = {
        attempt: 1,
        id: '1',
        state: 'unsubmitted',
        submissionDraft: {
          activeSubmissionType: 'online_text_entry',
          body: 'some draft text',
          meetsTextEntryCriteria: true,
        },
      }
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          id: '1',
          submissionTypes: ['online_text_entry'],
        },
        Submission: submission,
      })

      const result = renderInContext(
        {latestSubmission: submission},
        <MockedProvider mocks={mocks}>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      // Wait for callbacks to fire and the "editor" to be loaded
      await waitFor(
        () => {
          expect(tinymce?.editors[0]).toBeDefined()
        },
        {timeout: 4000}
      )
      fakeEditor = tinymce.editors[0]
      return result
    }

    beforeEach(async () => {
      jest.useFakeTimers()
      tinymce.editors = []
      fakeEditor = undefined
      const alert = document.createElement('div')
      alert.id = 'flash_screenreader_holder'
      alert.setAttribute('role', 'alert')
      document.body.appendChild(alert)
    })

    afterEach(async () => {
      jest.runOnlyPendingTimers()
      jest.useRealTimers()
    })

    it('shows a "Saving Draft" label when the contents of a text entry have started changing', async () => {
      const {findByText} = await renderTextAttempt()
      act(() => {
        fakeEditor.setContent('some edited draft text')
        jest.advanceTimersByTime(500)
      })

      expect(await findByText('Saving Draft')).toBeInTheDocument()
    })

    it('disables the Submit Assignment button while allegedly saving the draft', async () => {
      const {getByTestId} = await renderTextAttempt()
      act(() => {
        fakeEditor.setContent('some edited draft text')
        jest.advanceTimersByTime(500)
      })

      expect(getByTestId('submit-button')).toBeDisabled()
    })

    it('shows a "Draft Saved" label when a text draft has been successfully saved', async () => {
      const variables = {
        activeSubmissionType: 'online_text_entry',
        attempt: 1,
        body: 'some edited draft text',
        id: '1',
      }

      const successfulResult = await mockQuery(CREATE_SUBMISSION_DRAFT, {}, variables)
      const mocks = [
        {
          request: {query: CREATE_SUBMISSION_DRAFT, variables},
          result: successfulResult,
        },
      ]

      const {findByText} = await renderTextAttempt({mocks})

      act(() => {
        fakeEditor.setContent('some edited draft text')
        jest.advanceTimersByTime(5000)
      })

      expect(await findByText('Draft Saved')).toBeInTheDocument()
    })

    it('shows a "Error Saving Draft" label when a problem has occurred while saving', async () => {
      const variables = {
        activeSubmissionType: 'online_text_entry',
        attempt: 1,
        body: 'some edited draft text',
        id: '1',
      }
      const mocks = [
        {
          request: {query: CREATE_SUBMISSION_DRAFT, variables},
          result: {data: null, errors: 'yes'},
        },
      ]

      const {findByText} = await renderTextAttempt({mocks})

      act(() => {
        fakeEditor.setContent('some edited draft text')
        jest.advanceTimersByTime(5000)
      })

      expect(await findByText('Error Saving Draft')).toBeInTheDocument()
    })
  })

  describe('footer', () => {
    it('is rendered if at least one button can be shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_text_entry'],
        },
        Submission: {...SubmissionMocks.submitted},
      })

      const {getByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(getByTestId('student-footer')).toBeInTheDocument()
    })

    it('is not rendered if no buttons can be shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })

      const {queryByTestId} = renderInContext(
        {allowChangesToSubmission: false},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(queryByTestId('student-footer')).not.toBeInTheDocument()
    })

    describe('modules', () => {
      let oldEnv

      beforeEach(() => {
        oldEnv = window.ENV
        window.ENV = {
          ...oldEnv,
          ASSIGNMENT_ID: '1',
          COURSE_ID: '1',
        }

        ContextModuleApi.getContextModuleData.mockClear()
      })

      afterEach(() => {
        window.ENV = oldEnv
      })

      it('renders next and previous module links if they exist for the assignment', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_text_entry'],
          },
          Submission: {...SubmissionMocks.submitted},
        })

        ContextModuleApi.getContextModuleData.mockResolvedValue({
          next: {url: '/next', tooltipText: {string: 'some module'}},
          previous: {url: '/previous', tooltipText: {string: 'some module'}},
        })

        const {getByTestId} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())
        const footer = getByTestId('student-footer')
        expect(
          within(footer).getByTestId('previous-assignment-btn', {name: /Previous/})
        ).toBeInTheDocument()
        expect(
          within(footer).getByTestId('next-assignment-btn', {name: /Next/})
        ).toBeInTheDocument()
      })

      it('does not render module buttons if no next/previous modules exist for the assignment', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_text_entry'],
          },
          Submission: {...SubmissionMocks.submitted},
        })

        ContextModuleApi.getContextModuleData.mockResolvedValue({})

        const {queryByRole} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        await waitFor(() => expect(ContextModuleApi.getContextModuleData).toHaveBeenCalled())
        expect(queryByRole('link', {name: /Previous/})).not.toBeInTheDocument()
        expect(queryByRole('link', {name: /Next/})).not.toBeInTheDocument()
      })
    })
  })

  describe('similarity pledge', () => {
    let props

    beforeEach(async () => {
      window.ENV.SIMILARITY_PLEDGE = {
        COMMENTS: 'hi',
        EULA_URL: 'http://someurl.com',
        PLEDGE_TEXT: 'some text',
      }

      props = await mockAssignmentAndSubmission({
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
    })

    afterEach(() => {
      delete window.ENV.SIMILARITY_PLEDGE
    })

    it('is rendered if pledge settings are provided', () => {
      const {getByLabelText} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(getByLabelText(/I agree to the tool's/)).toBeInTheDocument()
    })

    it('is not rendered if no pledge settings are provided', () => {
      delete window.ENV.SIMILARITY_PLEDGE

      const {queryByLabelText} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(queryByLabelText(/I agree to the tool's/)).not.toBeInTheDocument()
    })

    it('disables the "Submit" button if rendered and the user has not agreed to the pledge', () => {
      const {getByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const submitButton = getByTestId('submit-button')
      expect(submitButton).toBeDisabled()
    })

    it('enables the "Submit" button after the user agrees to the pledge', () => {
      const {getByLabelText, getByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const agreementCheckbox = getByLabelText(/I agree to the tool's/)
      act(() => {
        fireEvent.click(agreementCheckbox)
      })

      const submitButton = getByTestId('submit-button')
      expect(submitButton).not.toBeDisabled()
    })
  })

  describe('peer reviews', () => {
    describe('without rubrics', () => {
      it('does not render a submit button', async () => {
        const props = await mockAssignmentAndSubmission()
        props.assignment.env.peerReviewModeEnabled = true
        const {queryByText} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
      })
    })
    describe('with rubrics', () => {
      const originalENV = window.ENV
      let props, mocks

      function generateAssessmentItem(
        criterionId,
        {hasComments = false, hasValue = false, hasValidValue = true}
      ) {
        return {
          commentFocus: true,
          comments: hasComments ? 'foo bar' : '',
          criterion_id: criterionId,
          description: `Criterion ${criterionId}`,
          editComments: true,
          id: 'blank',
          points: {
            text: '',
            valid: hasValidValue,
            value: hasValue ? Math.floor(Math.random() * 10) : undefined,
          },
        }
      }

      function setCurrentUserAsAssessmentOwner() {
        window.ENV = {...originalENV, COURSE_ID: '4', current_user: {id: '2'}}
      }

      function setOtherUserAsAssessmentOwner() {
        window.ENV = {...originalENV, COURSE_ID: '4', current_user: {id: '4'}}
      }

      async function setMocks() {
        const variables = {
          courseID: '1',
          assignmentLid: '1',
          submissionID: '1',
          submissionAttempt: 0,
        }
        const overrides = gradedOverrides()
        const allOverrides = [
          {
            Node: {__typename: 'Assignment'},
            Assignment: {rubric: {}, rubricAssociation: {}},
            Rubric: {
              criteria: [{}],
            },
            ...overrides,
          },
        ]
        const fetchRubricResult = await mockQuery(RUBRIC_QUERY, allOverrides, variables)
        mocks = [
          {
            request: {query: RUBRIC_QUERY, variables},
            result: fetchRubricResult,
          },
          {
            request: {query: RUBRIC_QUERY, variables},
            result: fetchRubricResult,
          },
        ]
      }

      beforeEach(() => {
        doFetchApi.mockResolvedValue({})
      })

      beforeEach(async () => {
        doFetchApi.mockClear()
        setCurrentUserAsAssessmentOwner()
        await setMocks()
        const rubricData = mocks[0].result.data
        const assessments = rubricData.submission.rubricAssessmentsConnection.nodes

        store.setState({
          displayedAssessment: assessments[0],
        })

        props = await mockAssignmentAndSubmission()
        props.assignment.rubric = rubricData.assignment.rubric
        props.assignment.rubric.criteria.push({...props.assignment.rubric.criteria[0], id: '2'})
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true
        props.assignment.env.revieweeId = '4'
      })

      afterEach(() => {
        window.ENV = originalENV
        store.setState({
          displayedAssessment: null,
        })
      })

      it('renders a submit button when the assessment has not been submitted', async () => {
        setOtherUserAsAssessmentOwner()
        const {queryByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        await new Promise(resolve => setTimeout(resolve, 1000))
        expect(queryByText('Submit')).toBeInTheDocument()
      })

      it('does not render a submit button when the assessment has been submitted', async () => {
        const {queryByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        await new Promise(resolve => setTimeout(resolve, 1000))
        expect(queryByText('Submit')).not.toBeInTheDocument()
      })

      it('renders a enabled submit button when every criterion has a comment', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {getByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        await new Promise(resolve => setTimeout(resolve, 1000))
        expect(getByText('Submit').closest('button')).toBeEnabled()
      })

      it('renders a enabled submit button when every criterion has a valid point', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasValue: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasValue: true}),
            ],
          },
        })

        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true

        const {getByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        await new Promise(resolve => setTimeout(resolve, 1000))
        expect(getByText('Submit').closest('button')).toBeEnabled()
      })

      it('renders a disabled submit button when atleast one criterion has an invalid points value', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasValue: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {
                hasValue: true,
                hasValidValue: false,
              }),
            ],
          },
        })

        const {getByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        await new Promise(resolve => setTimeout(resolve, 1000))
        expect(getByText('Submit').closest('button')).toBeDisabled()
      })

      it('sends a http request with anonymous peer reviews disabled to the rubrics assessments endpoint when the user clicks on Submit button', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {queryByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        await new Promise(resolve => setTimeout(resolve, 1000))
        fireEvent.click(queryByText('Submit'))

        const rubricAssociationId = mocks[0].result.data.assignment.rubricAssociation._id
        expect(doFetchApi).toHaveBeenCalledWith(
          expect.objectContaining({
            method: 'POST',
            path: `/courses/${window.ENV.COURSE_ID}/rubric_associations/${rubricAssociationId}/assessments`,
            body: expect.stringContaining('user_id%5D=4'),
          })
        )
      })

      it('sends a http request with anonymous peer reviews enabled to the rubrics assessments endpoint when the user clicks on Submit button', async () => {
        delete props.assignment.env.revieweeId
        props.assignment.env.anonymousAssetId = 'ad0f'

        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {findByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...props} />
          </MockedProvider>
        )
        await new Promise(resolve => setTimeout(resolve, 1000))
        fireEvent.click(await findByText('Submit'))

        const rubricAssociationId = mocks[0].result.data.assignment.rubricAssociation._id
        expect(doFetchApi).toHaveBeenCalledWith(
          expect.objectContaining({
            method: 'POST',
            path: `/courses/${window.ENV.COURSE_ID}/rubric_associations/${rubricAssociationId}/assessments`,
            body: expect.stringContaining('anonymous_id%5D=ad0f'),
          })
        )
      })

      it('creates a success alert when the http request was sent successfully', async () => {
        setOtherUserAsAssessmentOwner()
        const setOnSuccess = jest.fn()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {findByText} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )
        await new Promise(resolve => setTimeout(resolve, 1000))
        fireEvent.click(await findByText('Submit'))

        await waitFor(() => {
          expect(setOnSuccess).toHaveBeenCalledWith('Rubric was successfully submitted')
        })
      })

      it('renders peer review modal for remaining rubric assessments', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })
        const assetId = props.submission._id
        const reviewerSubmission = {
          id: 'test-id',
          _id: 'test-id',
          assignedAssessments: [
            {
              assetId,
              workflowState: 'assigned',
              assetSubmissionType: 'online-text',
            },
            {
              assetId: 'some other user id',
              workflowState: 'assigned',
              assetSubmissionType: 'online-text',
            },
          ],
        }
        props.reviewerSubmission = reviewerSubmission
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true

        const {getByText, findByText} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )
        await new Promise(resolve => setTimeout(resolve, 1))
        const submitButton = getByText('Submit')
        fireEvent.click(submitButton)

        expect(await findByText('You have 1 more Peer Review to complete.')).toBeTruthy()
      })

      it('renders peer review modal for completing all rubric assessments', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })
        const assetId = props.submission._id
        const reviewerSubmission = {
          id: 'test-id',
          _id: 'test-id',
          assignedAssessments: [
            {
              assetId,
              workflowState: 'assigned',
              assetSubmissionType: 'online-text',
            },
            {
              assetId: 'some other user id',
              workflowState: 'completed',
              assetSubmissionType: 'online-text',
            },
          ],
        }
        props.reviewerSubmission = reviewerSubmission
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true

        const {getByText, findByText} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )
        await new Promise(resolve => setTimeout(resolve, 1))
        const submitButton = getByText('Submit')
        fireEvent.click(submitButton)

        expect(await findByText(COMPLETED_PEER_REVIEW_TEXT)).toBeTruthy()
      })

      it('calls the onSuccessfulPeerReview function to re-render page when a peer review with rubric is successful', async () => {
        setOtherUserAsAssessmentOwner()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })
        const assetId = props.submission._id
        const reviewerSubmission = {
          id: 'test-id',
          _id: 'test-id',
          assignedAssessments: [
            {
              assetId,
              workflowState: 'assigned',
              assetSubmissionType: 'online-text',
            },
            {
              assetId: 'some other user id',
              workflowState: 'assigned',
              assetSubmissionType: 'online-text',
            },
          ],
        }

        props.reviewerSubmission = reviewerSubmission
        props.assignment.env.peerReviewModeEnabled = true
        props.assignment.env.peerReviewAvailable = true
        const onSuccessfulPeerReviewMockFunction = jest.fn()

        const prop = {
          ...props,
          onSuccessfulPeerReview: onSuccessfulPeerReviewMockFunction,
        }

        const {getByText, findByText} = render(
          <MockedProvider mocks={mocks}>
            <SubmissionManager {...prop} />
          </MockedProvider>
        )
        await new Promise(resolve => setTimeout(resolve, 1))
        const submitButton = getByText('Submit')
        fireEvent.click(submitButton)

        await waitFor(() => expect(onSuccessfulPeerReviewMockFunction).toHaveBeenCalled())
        expect(props.reviewerSubmission.assignedAssessments[0].workflowState).toEqual('completed')
      })

      it('creates an error alert when the http request fails', async () => {
        setOtherUserAsAssessmentOwner()
        doFetchApi.mockImplementation(() => Promise.reject(new Error('Network error')))
        const setOnFailure = jest.fn()
        store.setState({
          displayedAssessment: {
            score: 5,
            data: [
              generateAssessmentItem(props.assignment.rubric.criteria[0].id, {hasComments: true}),
              generateAssessmentItem(props.assignment.rubric.criteria[1].id, {hasComments: true}),
            ],
          },
        })

        const {findByText} = render(
          <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess: jest.fn()}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )

        await new Promise(resolve => setTimeout(resolve, 1000))
        fireEvent.click(await findByText('Submit'))

        await waitFor(() => {
          expect(setOnFailure).toHaveBeenCalledWith('Error submitting rubric')
        })
      })
    })
  })
})
