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
import {act, fireEvent, render, waitFor} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import StudentViewContext from '../Context'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

jest.mock('@canvas/rce/RichContentEditor')

describe('ContentTabs', () => {
  beforeEach(() => {
    window.ENV.use_rce_enhancements = true
  })

  describe('the assignment is locked aka passed the until date', () => {
    it('renders the availability dates if the submission is unsubmitted', async () => {
      const props = await mockAssignmentAndSubmission({
        LockInfo: {isLocked: true}
      })
      const {findByText} = render(
        <MockedProvider>
          <AttemptTab {...props} />
        </MockedProvider>
      )
      expect(await findByText('Availability Dates')).toBeInTheDocument()
    })

    it('renders the last submission if the assignment was submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {lockInfo: {isLocked: true}},
        Submission: {
          ...SubmissionMocks.submitted,
          attachments: [{displayName: 'test.jpg'}]
        }
      })
      const {findByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} />
        </MockedProvider>
      )
      expect(await findByTestId('assignments_2_submission_preview')).toBeInTheDocument()
    })
  })

  describe('the submission type is online_upload', () => {
    it('renders the file upload tab when the submission is unsubmitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_upload']}
      })

      const {getByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} />
        </MockedProvider>
      )
      expect(await waitFor(() => getByTestId('upload-pane'))).toBeInTheDocument()
    })

    it('renders the file preview tab when the submission is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_upload']},
        Submission: {
          ...SubmissionMocks.submitted,
          attachments: [{}]
        }
      })

      const {findByTestId} = render(<AttemptTab {...props} />)
      expect(await findByTestId('assignments_2_submission_preview')).toBeInTheDocument()
    })

    describe('Uploading a file', () => {
      beforeAll(() => {
        $('body').append('<div role="alert" id="flash_screenreader_holder" />')
        uploadFileModule.uploadFiles = jest.fn()
        window.URL.createObjectURL = jest.fn()
      })

      it('shows a file preview for an uploaded file', async () => {
        const props = await mockAssignmentAndSubmission({
          Submission: {
            submissionDraft: {
              attachments: [{displayName: 'test.jpg'}]
            }
          }
        })

        const {getAllByText} = render(
          <MockedProvider>
            <AttemptTab {...props} />
          </MockedProvider>
        )
        expect(await waitFor(() => getAllByText('test.jpg')[0])).toBeInTheDocument()
      })
    })
  })

  describe('the submission type is online_text_entry', () => {
    beforeAll(() => {
      $('body').append('<div role="alert" id="flash_screenreader_holder" />')
      uploadFileModule.uploadFiles = jest.fn()
      window.URL.createObjectURL = jest.fn()
    })

    describe('uploading a text draft', () => {
      it('renders the text entry tab', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry']}
        })

        const {findByTestId} = render(<AttemptTab {...props} />)
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
              state: 'submitted'
            }
          })

          const {findByRole} = render(<AttemptTab {...props} />)
          const textarea = await findByRole('textbox')
          expect(textarea).toHaveAttribute('readonly')
        })

        it('renders as read-only if the submission has been graded', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'graded'
            }
          })

          const {findByRole} = render(<AttemptTab {...props} />)
          const textarea = await findByRole('textbox')
          expect(textarea).toHaveAttribute('readonly')
        })

        it('renders as read-only if changes are not allowed to the submission', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'unsubmitted'
            }
          })

          const {findByRole} = render(
            <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
              <AttemptTab {...props} />
            </StudentViewContext.Provider>
          )
          const textarea = await findByRole('textbox')
          expect(textarea).toHaveAttribute('readonly')
        })

        it('does not render as read-only if changes are allowed and the submission is not submitted', async () => {
          const props = await mockAssignmentAndSubmission({
            Assignment: {submissionTypes: ['online_text_entry']},
            Submission: {
              state: 'unsubmitted'
            }
          })

          const {findByRole} = render(<AttemptTab {...props} />)
          const textarea = await findByRole('textbox')
          expect(textarea).not.toHaveAttribute('readonly')
        })
      })
    })
  })

  describe('there are multiple submission types', () => {
    describe('when no submission type is selected', () => {
      it('renders the submission type selector if the submission can be modified', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
        })
        const {getByTestId} = render(<AttemptTab {...props} />)

        expect(getByTestId('submission-type-selector')).toBeInTheDocument()
      })

      it('shows buttons for the available submission types', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
        })
        const {getAllByRole} = render(<AttemptTab {...props} />)

        const buttons = getAllByRole('button')
        expect(buttons).toHaveLength(2)
        expect(buttons[0]).toHaveTextContent('Text')
        expect(buttons[1]).toHaveTextContent('Upload')
      })

      it('does not render the submission type selector if the submission cannot be modified', async () => {
        const props = await mockAssignmentAndSubmission({
          Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
        })
        const {queryByTestId} = render(
          <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
            <AttemptTab {...props} />
          </StudentViewContext.Provider>
        )

        expect(queryByTestId('submission-type-selector')).not.toBeInTheDocument()
      })
    })

    it('updates the active type after selecting a type', async () => {
      const mockedUpdateActiveSubmissionType = jest.fn()
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
      })
      const {getByRole} = render(
        <AttemptTab {...props} updateActiveSubmissionType={mockedUpdateActiveSubmissionType} />
      )

      const textButton = getByRole('button', {name: /Text/})
      act(() => {
        fireEvent.click(textButton)
      })

      expect(mockedUpdateActiveSubmissionType).toHaveBeenCalledWith('online_text_entry')
    })

    it('renders the active submission type if available', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_url']}
      })
      const {findByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} activeSubmissionType="online_url" />
        </MockedProvider>
      )

      expect(await findByTestId('url-entry')).toBeInTheDocument()
    })

    it('does not render the selector if the submission state is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        Submission: {
          state: 'submitted'
        }
      })
      const {queryByTestId} = render(<AttemptTab {...props} />)

      expect(queryByTestId('submission-type-selector')).not.toBeInTheDocument()
    })

    it('does not render the selector if the submission state is graded', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        Submission: {
          state: 'graded'
        }
      })
      const {queryByTestId} = render(<AttemptTab {...props} />)

      expect(queryByTestId('submission-type-selector')).not.toBeInTheDocument()
    })

    it('does not render the selector if the context indicates the submission cannot be modified', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
      })

      const {queryByTestId} = render(
        <StudentViewContext.Provider value={{allowChangesToSubmission: false}}>
          <AttemptTab {...props} />
        </StudentViewContext.Provider>
      )

      expect(queryByTestId('submission-type-selector')).not.toBeInTheDocument()
    })
  })
})
