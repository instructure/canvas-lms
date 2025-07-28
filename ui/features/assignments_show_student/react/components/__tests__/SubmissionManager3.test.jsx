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
import {SET_MODULE_ITEM_COMPLETION} from '@canvas/assignments/graphql/student/Mutations'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import fakeENV from '@canvas/test-utils/fakeENV'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {act, fireEvent, render} from '@testing-library/react'
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

      const failedResponse = {
        errors: [
          {
            message: 'Failed to update module item completion',
            extensions: {code: 'INTERNAL_SERVER_ERROR'},
          },
        ],
      }

      beforeEach(async () => {
        fakeENV.setup({
          CONTEXT_MODULE_ITEM: {
            done: false,
            id: '1',
            module_id: '2',
          },
        })

        props = await mockAssignmentAndSubmission({
          Assignment: {
            submissionTypes: ['online_url'],
          },
        })
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it('is rendered as "Mark as done" if the value of "done" is false', async () => {
        const {getByTestId} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        const markAsDoneButton = getByTestId('set-module-item-completion-button')
        expect(markAsDoneButton).toHaveTextContent('Mark as done')
      })

      it('is rendered as "Done" if the value of "done" is true', async () => {
        fakeENV.setup({
          CONTEXT_MODULE_ITEM: {
            done: true,
            id: '1',
            module_id: '2',
          },
        })

        const {getByTestId} = render(
          <MockedProvider>
            <SubmissionManager {...props} />
          </MockedProvider>,
        )

        const markAsDoneButton = getByTestId('set-module-item-completion-button')
        expect(markAsDoneButton).toHaveTextContent('Done')
      })

      // fickle
      it.skip('sends a request when clicked', async () => {
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
          </AlertManagerContext.Provider>,
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

      it.skip('updates itself to the opposite appearance when the request succeeds', async () => {
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
          </AlertManagerContext.Provider>,
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
          </AlertManagerContext.Provider>,
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
        </MockedProvider>,
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
          </MockedProvider>,
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
          </MockedProvider>,
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
          </MockedProvider>,
        )
        expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
      })
    })

    it('is not rendered if nothing has been submitted', async () => {
      const props = await mockAssignmentAndSubmission()
      const {queryByTestId} = render(
        <MockedProvider>
          <SubmissionManager {...props} />
        </MockedProvider>,
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
        </MockedProvider>,
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
        </MockedProvider>,
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
        </MockedProvider>,
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
        </MockedProvider>,
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
        </MockedProvider>,
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
        </MockedProvider>,
      )
      expect(queryByTestId('new-attempt-button')).not.toBeInTheDocument()
    })
  })
})
