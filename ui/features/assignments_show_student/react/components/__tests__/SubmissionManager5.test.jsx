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

import {DELETE_SUBMISSION_DRAFT} from '@canvas/assignments/graphql/student/Mutations'
import {USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {act, fireEvent, render, screen, waitFor, within} from '@testing-library/react'
import React from 'react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import StudentViewContext, {StudentViewContextDefaults} from '../Context'
import SubmissionManager from '../SubmissionManager'

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

  describe('"Cancel Attempt" button', () => {
    it('is rendered if a draft exists and is shown', async () => {
      const props = await mockAssignmentAndSubmission({
        Submission: {...SubmissionMocks.onlineUploadReadyToSubmit, attempt: 2},
      })

      const {getByTestId} = renderInContext(
        {latestSubmission: props.submission},
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
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
        </MockedProvider>,
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
        </MockedProvider>,
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
        </MockedProvider>,
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
        </MockedProvider>,
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
            variables,
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
                {userID: '1'},
              ),
            },
          ]

          return renderInContext(
            {latestSubmission: props.submission, cancelDraftAction},
            <MockedProvider mocks={mocks}>
              <SubmissionManager {...props} />
            </MockedProvider>,
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
            </MockedProvider>,
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
})
