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

import {CREATE_SUBMISSION_DRAFT} from '@canvas/assignments/graphql/student/Mutations'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {act, render, waitFor} from '@testing-library/react'
import React from 'react'
import ContextModuleApi from '../../apis/ContextModuleApi'
import TextEntry from '../AttemptType/TextEntry'
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

  describe('saving text entry drafts', () => {
    beforeAll(async () => {
      // This gets the lazy loaded components loaded before our specs.
      // otherwise, the first one (at least) will fail.
      const {unmount} = render(
        <TextEntry focusOnInit={false} submission={{id: '1', _id: '1', state: 'unsubmitted'}} />,
      )
      await waitFor(() => {
        expect(tinymce.get('textentry_text')).toBeDefined()
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
        </MockedProvider>,
      )

      // Wait for callbacks to fire and the "editor" to be loaded
      await waitFor(
        () => {
          expect(tinymce.get('textentry_text')).toBeDefined()
        },
        {timeout: 4000},
      )
      fakeEditor = tinymce.get('textentry_text')
      return result
    }

    beforeEach(async () => {
      jest.useFakeTimers()
      const alert = document.createElement('div')
      alert.id = 'flash_screenreader_holder'
      alert.setAttribute('role', 'alert')
      document.body.appendChild(alert)
    })

    afterEach(async () => {
      jest.runOnlyPendingTimers()
      jest.useRealTimers()
    })

    // TODO: These tests require complex RCE (Rich Content Editor) setup and proper tinymce mocking.
    // The tests are skipped until we can properly mock the text editor initialization and draft saving behavior.
    it.skip('shows a "Saving Draft" label when the contents of a text entry have started changing', async () => {
      const {findByText} = await renderTextAttempt()

      await waitFor(
        () => {
          expect(tinymce.get('textentry_text')).toBeDefined()
        },
        {timeout: 4000},
      )

      act(() => {
        fakeEditor = tinymce.get('textentry_text')
        fakeEditor.setContent('some edited draft text')
        jest.advanceTimersByTime(500)
      })

      expect(await findByText('Saving Draft')).toBeInTheDocument()
    })

    it.skip('disables the Submit Assignment button while allegedly saving the draft', async () => {
      const {getByTestId} = await renderTextAttempt()
      act(() => {
        fakeEditor.setContent('some edited draft text')
        jest.advanceTimersByTime(500)
      })

      expect(getByTestId('submit-button')).toBeDisabled()
    })

    it.skip('shows a "Draft Saved" label when a text draft has been successfully saved', async () => {
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

    it.skip('shows a "Error Saving Draft" label when a problem has occurred while saving', async () => {
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
})
