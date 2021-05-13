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
  SET_MODULE_ITEM_COMPLETION
} from '@canvas/assignments/graphql/student/Mutations'
import {SUBMISSION_HISTORIES_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {act, fireEvent, render, screen, waitFor, within} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import StudentViewContext, {StudentViewContextDefaults} from '../Context'
import SubmissionManager from '../SubmissionManager'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

// Mock the RCE so we can test text entry submissions without loading the whole
// editor
jest.mock('@canvas/rce/RichContentEditor')

function renderInContext(overrides = {}, children) {
  const contextProps = {...StudentViewContextDefaults, ...overrides}

  return render(
    <StudentViewContext.Provider value={contextProps}>{children}</StudentViewContext.Provider>
  )
}

describe('SubmissionManager', () => {
  it('renders the AttemptTab', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByTestId} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByTestId('attempt-tab')).toBeInTheDocument()
  })

  it('does not render a submit button when the draft criteria is not met', async () => {
    const props = await mockAssignmentAndSubmission()
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  it('renders a submit button when the draft criteria is met for the active type', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
    })
    const {getByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(getByText('Submit Assignment')).toBeInTheDocument()
  })

  it('does not render the submit button if the draft criteria is not met for the active type', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: {
        submissionDraft: {
          activeSubmissionType: 'online_upload',
          body: 'some text here'
        }
      }
    })
    const {queryByText} = render(
      <MockedProvider>
        <SubmissionManager {...props} />
      </MockedProvider>
    )

    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  it('does not render the submit button if we are not on the latest submission', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.graded
    })
    const latestSubmission = {attempt: 2, state: 'unsubmitted'}

    const {queryByText} = renderInContext({latestSubmission}, <SubmissionManager {...props} />)
    expect(queryByText('Submit Assignment')).not.toBeInTheDocument()
  })

  it('does not render the submit button if the assignment is locked', async () => {
    const props = await mockAssignmentAndSubmission({
      LockInfo: {isLocked: true},
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
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
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
    })

    const {queryByText} = renderInContext(
      {allowChangesToSubmission: false},
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
          CONFETTI_ENABLED: enabled
        }
      })

      it(testName, async () => {
        jest.spyOn(global.Date, 'parse').mockImplementationOnce(() => new Date(dueDate).valueOf())

        const props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_url']
          },
          Submission: {
            submissionDraft: {
              activeSubmissionType: 'online_url',
              meetsUrlCriteria: true,
              url: 'http://localhost',
              type: 'online_url'
            }
          }
        })

        const variables = {
          assignmentLid: '1',
          submissionID: '1',
          type: 'online_url',
          url: 'http://localhost'
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
            result: createSubmissionResult
          },
          {
            request: {query: SUBMISSION_HISTORIES_QUERY, variables: {submissionID: '1'}},
            result: submissionHistoriesResult
          }
        ]

        const {getByRole, queryByTestId} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )

        act(() => {
          const submitButton = getByRole('button', {name: 'Submit Assignment'})
          fireEvent.click(submitButton)
        })
        await waitFor(() =>
          expect(getByRole('button', {name: 'Submit Assignment'})).not.toBeDisabled()
        )
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
    inDocument: true
  })
  testConfetti('does not render confetti if not enabled', {
    enabled: false,
    dueDate: Date.now() + 100000,
    inDocument: false
  })
  testConfetti('does not render confetti if past the due date', {
    enabled: true,
    dueDate: Date.now() - 100000,
    inDocument: false
  })

  it('disables the submit button after it is pressed', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit
    })

    const variables = {
      assignmentLid: '1',
      submissionID: '1',
      type: 'online_upload',
      fileIds: ['1']
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
        result: createSubmissionResult
      },
      {
        request: {query: SUBMISSION_HISTORIES_QUERY, variables: {submissionID: '1'}},
        result: submissionHistoriesResult
      }
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
    expect(getByText('Submit Assignment').closest('button')).toHaveAttribute('disabled')
  })

  describe('with multiple submission types drafted', () => {
    it('renders a confirmation modal if the submit button is pressed', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_text_entry', 'online_url']
        },
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_text_entry',
            body: 'some text here',
            meetsTextEntryCriteria: true,
            meetsUrlCriteria: true,
            url: 'http://www.google.com'
          }
        }
      })

      const {getByTestId, getByText} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const submitButton = getByText('Submit Assignment')
      fireEvent.click(submitButton)

      expect(getByTestId('submission-confirmation-modal')).toBeInTheDocument()
      expect(getByTestId('cancel-submit')).toBeInTheDocument()
      expect(getByTestId('confirm-submit')).toBeInTheDocument()
    })
  })

  describe('"Mark as Done" button', () => {
    describe('when ENV.CONTEXT_MODULE_ITEM is set', () => {
      let props

      const successfulResponse = {
        data: {
          setModuleItemCompletion: {}
        },
        errors: null
      }

      const failedResponse = {data: null, errors: 'yes'}

      beforeEach(async () => {
        window.ENV.CONTEXT_MODULE_ITEM = {
          done: false,
          id: '1',
          module_id: '2'
        }

        props = await mockAssignmentAndSubmission()
      })

      afterEach(() => {
        delete window.ENV.CONTEXT_MODULE_ITEM
      })

      it('is rendered as "Mark as done" if the value of "done" is false', async () => {
        const {getByRole} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        const button = getByRole('button', {name: 'Mark as done'})
        expect(button).toBeInTheDocument()
      })

      it('is rendered as "Done" if the value of "done" is true', async () => {
        window.ENV.CONTEXT_MODULE_ITEM.done = true

        const {getByRole} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        const button = getByRole('button', {name: 'Done'})
        expect(button).toBeInTheDocument()
      })

      it('sends a request when clicked', async () => {
        const variables = {
          done: true,
          itemId: '1',
          moduleId: '2'
        }

        const mocks = [
          {
            request: {query: SET_MODULE_ITEM_COMPLETION, variables},
            result: successfulResponse
          }
        ]

        const {getByRole} = render(
          <AlertManagerContext.Provider>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )

        const markAsDoneButton = getByRole('button', {name: 'Mark as done'})
        act(() => {
          fireEvent.click(markAsDoneButton)
        })

        await waitFor(() => expect(getByRole('button', {name: 'Done'})).toBeInTheDocument())
      })

      it('updates itself to the opposite appearance when the request succeeds', async () => {
        const variables = {
          done: true,
          itemId: '1',
          moduleId: '2'
        }

        const mocks = [
          {
            request: {query: SET_MODULE_ITEM_COMPLETION, variables},
            result: successfulResponse
          }
        ]

        const {getByRole} = render(
          <AlertManagerContext.Provider>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )

        const markAsDoneButton = getByRole('button', {name: 'Mark as done'})
        act(() => {
          fireEvent.click(markAsDoneButton)
        })

        await waitFor(() => expect(getByRole('button', {name: 'Done'})).toBeInTheDocument())
      })

      it('does not update its appearance when the request fails', async () => {
        const variables = {
          done: true,
          itemId: '1',
          moduleId: '2'
        }

        const mocks = [
          {
            request: {query: SET_MODULE_ITEM_COMPLETION, variables},
            result: failedResponse
          }
        ]

        const {queryByRole, getByRole} = render(
          <AlertManagerContext.Provider value={{setOnFailure: jest.fn()}}>
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          </AlertManagerContext.Provider>
        )

        const markAsDoneButton = getByRole('button', {name: 'Mark as done'})
        act(() => {
          fireEvent.click(markAsDoneButton)
        })

        await waitFor(() => expect(queryByRole('button', {name: 'Done'})).not.toBeInTheDocument())
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
            submissionTypes: ['online_text_entry']
          },
          Submission: {...SubmissionMocks.submitted}
        })

        const {getByRole} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>
        )

        expect(getByRole('button', {name: 'Try Again'})).toBeInTheDocument()
      })

      it('is not rendered if changes cannot be made to the submission', async () => {
        const props = await mockAssignmentAndSubmission({
          Submission: {...SubmissionMocks.submitted}
        })
        const {queryByRole} = renderInContext(
          {allowChangesToSubmission: false},
          <SubmissionManager {...props} />
        )
        expect(queryByRole('button', 'Try Again')).not.toBeInTheDocument()
      })
    })

    it('is not rendered if nothing has been submitted', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByRole} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByRole('button', 'Try Again')).not.toBeInTheDocument()
    })

    it('is not rendered if excused', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.excused}
      })
      const {queryByRole} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByRole('button', 'Try Again')).not.toBeInTheDocument()
    })

    it('is not rendered if the assignment is locked', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
        Submission: {...SubmissionMocks.submitted}
      })
      const {queryByRole} = render(<SubmissionManager {...props} />)
      expect(queryByRole('button', 'Try Again')).not.toBeInTheDocument()
    })

    it('is not rendered if there are no more attempts', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1},
        Submission: {...SubmissionMocks.submitted}
      })
      const {queryByRole} = render(<SubmissionManager {...props} />)
      expect(queryByRole('button', 'Try Again')).not.toBeInTheDocument()
    })

    it('accounts for any extra attempts awarded to the student', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {allowedAttempts: 1},
        Submission: {...SubmissionMocks.submitted, extraAttempts: 2}
      })
      const {queryByRole} = render(<SubmissionManager {...props} />)
      expect(queryByRole('button', 'Try Again')).toBeInTheDocument()
    })
  })

  describe('"Back to Attempt" button', () => {
    it('is rendered if a draft exists and a previous attempt is shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted}
      })
      const latestSubmission = {attempt: 2, state: 'unsubmitted'}

      const {getByRole} = renderInContext({latestSubmission}, <SubmissionManager {...props} />)

      expect(getByRole('button', {name: /Back to Attempt/})).toBeInTheDocument()
    })

    it('includes the current attempt number', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted}
      })
      const latestSubmission = {attempt: 2, state: 'unsubmitted'}

      const {getByRole} = renderInContext({latestSubmission}, <SubmissionManager {...props} />)
      const button = getByRole('button', {name: /Back to Attempt/})
      expect(button).toHaveTextContent('Back to Attempt 2')
    })

    it('is not rendered if no current draft exists', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted}
      })

      const {queryByRole} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByRole('button', {name: /Back to Attempt/})).not.toBeInTheDocument()
    })

    it('is not rendered if the current draft is selected', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted}
      })
      const latestSubmission = props.submission

      const {queryByRole} = renderInContext({latestSubmission}, <SubmissionManager {...props} />)
      expect(queryByRole('button', {name: /Back to Attempt/})).not.toBeInTheDocument()
    })

    it('calls the showDraftAction function supplied by the context when clicked', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted}
      })

      const latestSubmission = {
        activeSubmissionType: 'online_text_entry',
        attempt: 2,
        state: 'unsubmitted'
      }
      const showDraftAction = jest.fn()

      const {getByRole} = renderInContext(
        {latestSubmission, showDraftAction},
        <SubmissionManager {...props} />
      )

      act(() => {
        fireEvent.click(getByRole('button', {name: /Back to Attempt/}))
      })
      expect(showDraftAction).toHaveBeenCalled()
    })
  })

  describe('"Cancel Attempt" button', () => {
    it('is rendered if a draft exists and is shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 2}
      })

      const {getByRole} = renderInContext(
        {latestSubmission: props.submission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(getByRole('button', {name: /Cancel Attempt/})).toBeInTheDocument()
    })

    it('is not rendered when working on the initial attempt', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 1}
      })

      const {queryByRole} = renderInContext(
        {latestSubmission: props.submission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )
      expect(queryByRole('button', {name: /Cancel Attempt/})).not.toBeInTheDocument()
    })

    it('includes the attempt number in the button text', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 2}
      })

      const {getByRole} = renderInContext(
        {latestSubmission: props.submission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const button = getByRole('button', {name: /Cancel Attempt/})
      expect(button).toHaveTextContent('Cancel Attempt 2')
    })

    it('is not rendered if no draft exists', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted, attempt: 2}
      })

      const {queryByRole} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(queryByRole('button', {name: /Cancel Attempt/})).not.toBeInTheDocument()
    })

    it('is not rendered if a draft exists but is not shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.submitted, attempt: 1}
      })

      const {queryByRole} = renderInContext(
        {latestSubmission: {attempt: 2, state: 'unsubmitted'}},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      expect(queryByRole('button', {name: /Cancel Attempt/})).not.toBeInTheDocument()
    })

    describe('when clicked', () => {
      const confirmationDialog = () => screen.queryByRole('dialog', {label: 'Delete your work?'})
      const confirmButton = () =>
        within(confirmationDialog()).getByRole('button', {name: 'Delete Work'})
      const cancelButton = () => within(confirmationDialog()).getByRole('button', {name: 'Cancel'})

      let cancelDraftAction

      beforeEach(() => {
        cancelDraftAction = jest.fn()
      })

      describe('when the current draft has actual content', () => {
        const renderDraft = async () => {
          const props = await mockAssignmentAndSubmission({
            Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 2, id: '123'}
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
              result: deleteSubmissionDraftResult
            }
          ]

          return renderInContext(
            {latestSubmission: props.submission, cancelDraftAction},
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>
          )
        }

        it('shows a confirmation modal if the current draft has any actual content', async () => {
          const {getByRole} = await renderDraft()

          act(() => {
            fireEvent.click(getByRole('button', {name: /Cancel Attempt/}))
          })
          expect(confirmationDialog()).toBeInTheDocument()
        })

        it('calls the cancelDraftAction function if the user confirms the modal', async () => {
          const {getByRole} = await renderDraft()

          act(() => {
            fireEvent.click(getByRole('button', {name: /Cancel Attempt/}))
          })

          act(() => {
            fireEvent.click(confirmButton())
          })

          waitFor(() => {
            expect(cancelDraftAction).toHaveBeenCalled()
          })
        })

        it('does nothing if the user cancels the modal', async () => {
          const {getByRole} = await renderDraft()

          act(() => {
            fireEvent.click(getByRole('button', {name: /Cancel Attempt/}))
          })

          act(() => {
            fireEvent.click(cancelButton())
          })

          expect(cancelDraftAction).not.toHaveBeenCalled()
        })
      })

      describe('when the current draft has no content', () => {
        const renderDraft = async () => {
          const props = await mockAssignmentAndSubmission({
            Submission: {attempt: 2}
          })

          return renderInContext(
            {latestSubmission: props.submission, cancelDraftAction},
            <MockedProvider>
              <SubmissionManager {...props} />
            </MockedProvider>
          )
        }

        it('does not show a confirmation', async () => {
          const {getByRole} = await renderDraft()

          act(() => {
            fireEvent.click(getByRole('button', {name: /Cancel Attempt/}))
          })
          expect(confirmationDialog()).not.toBeInTheDocument()
        })

        it('calls the cancelDraftAction function', async () => {
          const {getByRole} = await renderDraft()

          act(() => {
            fireEvent.click(getByRole('button', {name: /Cancel Attempt/}))
          })
          expect(cancelDraftAction).toHaveBeenCalled()
        })
      })
    })
  })

  describe('saving text entry drafts', () => {
    let editorContent
    let fakeEditor

    const renderTextAttempt = async ({mocks = []} = {}) => {
      const submission = {
        attempt: 1,
        id: '1',
        state: 'unsubmitted',
        submissionDraft: {
          activeSubmissionType: 'online_text_entry',
          body: 'some draft text',
          meetsTextEntryCriteria: true
        }
      }
      const props = await mockAssignmentAndSubmission({
        Assignment: {
          id: '1',
          submissionTypes: ['online_text_entry']
        },
        Submission: submission
      })

      const result = renderInContext(
        {latestSubmission: submission},
        <MockedProvider mocks={mocks}>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      // Wait for callbacks to fire and the "editor" to be loaded
      await waitFor(() => {
        expect(fakeEditor).not.toBeUndefined()
      })
      return result
    }

    beforeEach(async () => {
      jest.useFakeTimers()

      jest.spyOn(RichContentEditor, 'callOnRCE').mockImplementation(() => editorContent)
      jest.spyOn(RichContentEditor, 'loadNewEditor').mockImplementation((_textarea, options) => {
        fakeEditor = {
          focus: () => {},
          getBody: () => {},
          getContent: jest.fn(() => editorContent),
          mode: {
            set: jest.fn()
          },
          setContent: jest.fn(content => {
            editorContent = content
          }),
          selection: {
            collapse: () => {},
            select: () => {}
          }
        }

        options.tinyOptions.init_instance_callback(fakeEditor)
      })
    })

    afterEach(async () => {
      jest.runOnlyPendingTimers()
      jest.useRealTimers()
    })

    it('shows a "Saving Draft" label when the contents of a text entry have started changing', async () => {
      const {getByText} = await renderTextAttempt()
      act(() => {
        fakeEditor.setContent('some edited draft text')
        jest.advanceTimersByTime(500)
      })

      expect(getByText('Saving Draft')).toBeInTheDocument()
    })

    it('disables the Submit Assignment button while allegedly saving the draft', async () => {
      const {getByRole} = await renderTextAttempt()
      act(() => {
        fakeEditor.setContent('some edited draft text')
        jest.advanceTimersByTime(500)
      })

      expect(getByRole('button', {name: 'Submit Assignment'})).toBeDisabled()
    })

    it('shows a "Draft Saved" label when a text draft has been successfully saved', async () => {
      const variables = {
        activeSubmissionType: 'online_text_entry',
        attempt: 1,
        body: 'some edited draft text',
        id: '1'
      }

      const successfulResult = await mockQuery(CREATE_SUBMISSION_DRAFT, {}, variables)
      const mocks = [
        {
          request: {query: CREATE_SUBMISSION_DRAFT, variables},
          result: successfulResult
        }
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
        id: '1'
      }
      const mocks = [
        {
          request: {query: CREATE_SUBMISSION_DRAFT, variables},
          result: {data: null, errors: 'yes'}
        }
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
          submissionTypes: ['online_text_entry']
        },
        Submission: {...SubmissionMocks.submitted}
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
        Submission: {...SubmissionMocks.submitted}
      })

      const {queryByTestId} = renderInContext(
        {allowChangesToSubmission: false},
        <SubmissionManager {...props} />
      )

      expect(queryByTestId('student-footer')).not.toBeInTheDocument()
    })
  })

  describe('similarity pledge', () => {
    let props

    beforeEach(async () => {
      window.ENV.SIMILARITY_PLEDGE = {
        COMMENTS: 'hi',
        EULA_URL: 'http://someurl.com',
        PLEDGE_TEXT: 'some text'
      }

      props = await mockAssignmentAndSubmission({
        Assignment: {
          submissionTypes: ['online_text_entry', 'online_url']
        },
        Submission: {
          submissionDraft: {
            activeSubmissionType: 'online_text_entry',
            body: 'some text here',
            meetsTextEntryCriteria: true,
            meetsUrlCriteria: true,
            url: 'http://www.google.com'
          }
        }
      })
    })

    afterEach(() => {
      delete window.ENV.SIMILARITY_PLEDGE
    })

    it('is rendered if pledge settings are provided', () => {
      const {getByRole} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const agreementCheckbox = getByRole('checkbox', {name: /I agree to the tool's/})
      expect(agreementCheckbox).toBeInTheDocument()
    })

    it('is not rendered if no pledge settings are provided', () => {
      delete window.ENV.SIMILARITY_PLEDGE

      const {queryByRole} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const agreementCheckbox = queryByRole('checkbox', {name: /I agree to the tool's/})
      expect(agreementCheckbox).not.toBeInTheDocument()
    })

    it('disables the "Submit" button if rendered and the user has not agreed to the pledge', () => {
      const {getByRole} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const submitButton = getByRole('button', {name: 'Submit Assignment'})
      expect(submitButton).toBeDisabled()
    })

    it('enables the "Submit" button after the user agrees to the pledge', () => {
      const {getByRole} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>
      )

      const agreementCheckbox = getByRole('checkbox', {name: /I agree to the tool's/})
      act(() => {
        fireEvent.click(agreementCheckbox)
      })

      const submitButton = getByRole('button', {name: 'Submit Assignment'})
      expect(submitButton).not.toBeDisabled()
    })
  })
})
