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
import * as uploadFileModule from '../../../../shared/upload_file'
import AttemptTab from '../AttemptTab'
import {mockAssignmentAndSubmission} from '../../mocks'
import React from 'react'
import {render, waitForElement} from '@testing-library/react'
import {SubmissionMocks} from '../../graphqlData/Submission'

describe('ContentTabs', () => {
  describe('the submission type is online_upload', () => {
    it('renders the file upload tab when the submission is unsubmitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: () => ({submissionTypes: ['online_upload']})
      })

      const {getByTestId} = render(<AttemptTab {...props} />)
      expect(await waitForElement(() => getByTestId('upload-pane'))).toBeInTheDocument()
    })

    it('renders the file preview tab when the submission is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: () => ({submissionTypes: ['online_upload']}),
        Submission: () => ({
          ...SubmissionMocks.submitted,
          attachments: [{}]
        })
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
          Submission: () => ({
            submissionDraft: {
              attachments: [{displayName: 'test.jpg'}]
            }
          })
        })

        const {getAllByText} = render(<AttemptTab {...props} />)
        expect(await waitForElement(() => getAllByText('test.jpg')[0])).toBeInTheDocument()
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
          Assignment: () => ({submissionTypes: ['online_text_entry']})
        })

        const {findByTestId} = render(<AttemptTab {...props} />)
        expect(await findByTestId('text-entry')).toBeInTheDocument()
      })
    })
  })
})
