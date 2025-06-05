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

import $ from 'jquery'
import * as uploadFileModule from '@canvas/upload-file'
import AttemptTab from '../AttemptTab'
import {EXTERNAL_TOOLS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import TextEntry from '../AttemptType/TextEntry'
import {render, waitFor} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import React, {createRef} from 'react'
import StudentViewContext from '../Context'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/upload-file')
jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
  replaceLocation: jest.fn(),
  reloadWindow: jest.fn(),
  openWindow: jest.fn(),
  forceReload: jest.fn(),
  windowAlert: jest.fn(),
  windowConfirm: jest.fn(() => true),
  windowPathname: jest.fn(() => '/'),
}))

const defaultMocks = (result = {data: {}}) => [
  {
    request: {
      query: EXTERNAL_TOOLS_QUERY,
      variables: {courseID: '1'},
    },
    result,
  },
]
const CUSTOM_TIMEOUT_LIMIT = 1000
describe('ContentTabs', () => {
  beforeAll(() => {
    window.INST = window.INST || {}
    window.INST.editorButtons = []

    // Mock URL.createObjectURL for file handling
    URL.createObjectURL = jest.fn(blob => {
      return `blob:mock-url-${blob.name || 'unnamed'}`
    })

    // Mock Blob.prototype.slice for file handling
    if (!Blob.prototype.slice) {
      Blob.prototype.slice = jest.fn(function (start, end) {
        return this
      })
    }
  })

  beforeEach(() => {
    fakeENV.setup({
      context_asset_string: 'course_1',
      current_user: {id: '1', display_name: 'Test User'},
      enrollment_state: 'active',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  const renderAttemptTab = async props => {
    const retval = render(
      <MockedProvider mocks={defaultMocks()}>
        <AttemptTab {...props} focusAttemptOnInit={false} />
      </MockedProvider>,
    )

    if (props.assignment.submissionTypes.includes('online_text_entry')) {
      await waitFor(
        () => {
          expect(tinymce.get('textentry_text')).toBeDefined()
        },
        {timeout: 4000},
      )
      return retval
    } else {
      return Promise.resolve(retval)
    }
  }

  const createSubmitButtonRef = () => {
    const submitButton = document.createElement('button')
    const ref = createRef()
    ref.current = submitButton
    return ref
  }

  describe('the submission type is student_annotation', () => {
    it('renders the canvadocs iframe', async () => {
      const assignmentAndSubmission = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['student_annotation']},
      })
      const props = {
        ...assignmentAndSubmission,
        createSubmissionDraft: jest.fn().mockResolvedValue({}),
      }
      props.submitButtonRef = createSubmitButtonRef()

      const {getByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} focusAttemptOnInit={false} />
        </MockedProvider>,
      )
      await new Promise(resolve => setTimeout(resolve, CUSTOM_TIMEOUT_LIMIT))
      expect(await waitFor(() => getByTestId('canvadocs-pane'))).toBeInTheDocument()
    })
  })

  describe('the submission type is online_text_entry', () => {
    let submitButtonRef
    beforeAll(async () => {
      $('body').append('<div role="alert" id="flash_screenreader_holder" />')
      uploadFileModule.uploadFiles = jest.fn()
      submitButtonRef = createSubmitButtonRef()

      // This gets the lazy loaded components loaded before our specs.
      // otherwise, the first one (at least) will fail.
      const {unmount} = render(
        <TextEntry
          focusOnInit={false}
          submission={{id: '1', _id: '1', state: 'unsubmitted'}}
          submitButtonRef={submitButtonRef}
        />,
      )
      await waitFor(() => {
        expect(tinymce.get('textentry_text')).toBeDefined()
      })
      unmount()
    })

    describe('uploading a text draft', () => {
      it('renders the text entry tab', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry']},
        })
        props.submitButtonRef = submitButtonRef

        const {findByTestId} = await renderAttemptTab(props)
        expect(await findByTestId('text-editor')).toBeInTheDocument()
      })

      // The following tests don't match how the text editor actually works.
      // The RCE doesn't play nicely with our test environment, so we stub it
      // out and instead test for the read-only property (and possibly others
      // eventually) on the TextEntry component's placeholder text-area. This
      // does not mirror real-world usage but at least lets us verify that our
      // props are being passed through and correctly on the initial render.
      describe('text area', () => {
        it('renders as read-only if the submission has been submitted', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'submitted',
            },
          })
          props.submitButtonRef = submitButtonRef

          const {findByTestId} = await renderAttemptTab(props)
          expect(await findByTestId('read-only-content')).toBeInTheDocument()
        })

        it('does not render as read-only if the submission has been graded pre-submission', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'graded',
              attempt: 0,
            },
          })
          props.submitButtonRef = submitButtonRef

          const {queryByTestId} = await renderAttemptTab(props)
          expect(queryByTestId('read-only-content')).not.toBeInTheDocument()
        })

        it('renders as read-only if the submission has been graded post-submission', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'graded',
              attempt: 1,
            },
          })
          props.submitButtonRef = submitButtonRef

          const {findByTestId} = await renderAttemptTab(props)
          expect(await findByTestId('read-only-content')).toBeInTheDocument()
        })

        it('renders as read-only if changes are not allowed to the submission', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'unsubmitted',
            },
          })
          props.submitButtonRef = submitButtonRef

          // Wrap in MockedProvider to ensure consistent context
          const {findByTestId} = render(
            <MockedProvider mocks={defaultMocks()}>
              <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
                <AttemptTab {...props} focusAttemptOnInit={false} />
              </StudentViewContext.Provider>
            </MockedProvider>,
          )

          // Wait for the component to be fully rendered
          await waitFor(
            () => {
              expect(tinymce.get('textentry_text')).toBeDefined()
            },
            {timeout: 4000},
          )

          // Now check for the read-only content
          expect(await findByTestId('read-only-content')).toBeInTheDocument()
        })

        it('does not render as read-only if changes are allowed and the submission is not submitted', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'unsubmitted',
            },
          })
          props.submitButtonRef = submitButtonRef

          const {queryByTestId} = await renderAttemptTab(props)
          expect(queryByTestId('read-only-content')).not.toBeInTheDocument()
        })
      })
    })
  })
})
