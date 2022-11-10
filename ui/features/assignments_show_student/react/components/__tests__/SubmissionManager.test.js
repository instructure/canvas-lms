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
} from '@canvas/assignments/graphql/student/Queries'
import {act, fireEvent, render, screen, waitFor, within} from '@testing-library/react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import StudentViewContext, {StudentViewContextDefaults} from '../Context'
import SubmissionManager from '../SubmissionManager'
import TextEntry from '../AttemptType/TextEntry'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

// Mock the RCE so we can test text entry submissions without loading the whole
// editor
jest.mock('@canvas/rce/RichContentEditor')

jest.mock('../../apis/ContextModuleApi')

jest.useFakeTimers()

function renderInContext(overrides = {}, children) {
  const contextProps = {...StudentViewContextDefaults, ...overrides}

  return render(
    <StudentViewContext.Provider value={contextProps}>{children}</StudentViewContext.Provider>
  )
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
      <SubmissionManager {...props} />
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

  describe('Submission completed modal after clicking the "Submit Assignment" button', () => {
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
            workflowState: 'assigned',
          },
          {
            anonymousUser: null,
            anonymousId: 'baT9cx',
            workflowState: 'assigned',
          },
        ],
      }
    })

    afterEach(() => {
      window.ENV = oldEnv
      window.location.assign = assign
    })

    it('is present when there are assigned assessments', async () => {
      const {getByText, getByRole} = render(
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

    it('redirects to the corresponding url when the anonymous peer reviews option is disabled and the "Peer Review" button is clicked', async () => {
      props.submission = {
        ...props.submission,
        assignedAssessments: [
          {
            anonymizedUser: {_id: '1'},
            anonymousId: 'xaU9cd',
            workflowState: 'assigned',
          },
          {
            anonymizedUser: {_id: '2'},
            anonymousId: 'baT9cx',
            workflowState: 'assigned',
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

      const firstAssessment = props.submission.assignedAssessments[0]
      expect(window.location.assign).toHaveBeenCalledWith(
        `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}?reviewee_id=${firstAssessment.anonymizedUser._id}`
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

      const firstAssessment = props.submission.assignedAssessments[0]
      expect(window.location.assign).toHaveBeenCalledWith(
        `/courses/${ENV.COURSE_ID}/assignments/${ENV.ASSIGNMENT_ID}?anonymous_asset_id=${firstAssessment.anonymousId}`
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

        expect(getByTestId('try-again-button')).toBeInTheDocument()
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
          <SubmissionManager {...props} />
        )
        expect(queryByTestId('try-again-button')).not.toBeInTheDocument()
      })

      it('is not rendered if changes cannot be made to the submission', async () => {
        const props = await mockAssignmentAndSubmission({
          Submission: {...SubmissionMocks.submitted},
        })
        const {queryByTestId} = renderInContext(
          {allowChangesToSubmission: false},
          <SubmissionManager {...props} />
        )
        expect(queryByTestId('try-again-button')).not.toBeInTheDocument()
      })
    })

    it('is not rendered if nothing has been submitted', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByTestId('try-again-button')).not.toBeInTheDocument()
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
      expect(queryByTestId('try-again-button')).not.toBeInTheDocument()
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
      expect(queryByTestId('try-again-button')).not.toBeInTheDocument()
    })

    it('is not rendered if the assignment is locked', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
        Submission: {...SubmissionMocks.submitted},
      })
      const {queryByTestId} = render(<SubmissionManager {...props} />)
      expect(queryByTestId('try-again-button')).not.toBeInTheDocument()
    })

    it('is not rendered if there are no more attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1},
        Submission: {...SubmissionMocks.submitted},
      })
      const {queryByTestId} = render(<SubmissionManager {...props} />)
      expect(queryByTestId('try-again-button')).not.toBeInTheDocument()
    })

    it('accounts for any extra attempts awarded to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1},
        Submission: {...SubmissionMocks.submitted, extraAttempts: 2},
      })
      const {queryByTestId} = render(<SubmissionManager {...props} />)
      expect(queryByTestId('try-again-button')).toBeInTheDocument()
    })
  })

  describe('"Back to Attempt" button', () => {
    it('is rendered if a draft exists and a previous attempt is shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = {attempt: 2, state: 'unsubmitted'}

      const {getByTestId} = renderInContext({latestSubmission}, <SubmissionManager {...props} />)

      expect(getByTestId('back-to-attempt-button')).toBeInTheDocument()
    })

    it('includes the current attempt number', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted},
      })
      const latestSubmission = {attempt: 2, state: 'unsubmitted'}

      const {getByTestId} = renderInContext({latestSubmission}, <SubmissionManager {...props} />)
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

      const {queryByTestId} = renderInContext({latestSubmission}, <SubmissionManager {...props} />)
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
        <SubmissionManager {...props} />
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
      const {unmount} = render(<TextEntry submission={{id: '1', _id: '1', state: 'unsubmitted'}} />)
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
        <SubmissionManager {...props} />
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
})
