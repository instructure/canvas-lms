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
import {fireEvent, render, waitForElement} from '@testing-library/react'
import {mockAssignmentAndSubmission} from '../../mocks'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {SubmissionMocks} from '../../graphqlData/Submission'

describe('ContentTabs', () => {
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
      expect(await waitForElement(() => getByTestId('upload-pane'))).toBeInTheDocument()
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
          Assignment: {submissionTypes: ['online_text_entry']}
        })

        const {findByTestId} = render(<AttemptTab {...props} />)
        expect(await findByTestId('text-entry')).toBeInTheDocument()
      })
    })
  })

  describe('there are multiple submission types', () => {
    it('renders the attempt selection page if there is no active submission type', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
      })
      const {getByText} = render(<AttemptTab {...props} />)

      expect(getByText('Choose One Submission Type')).toBeInTheDocument()
    })

    it('shows the correct submission types in the selector', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
      })
      const {container, getByText} = render(<AttemptTab {...props} />)

      const selector = container.querySelector('select')
      expect(selector).toContainElement(getByText('Choose One'))
      expect(selector).toContainElement(getByText('Text Entry'))
      expect(selector).toContainElement(getByText('File'))
    })

    it('updates the active type after selecting a type', async () => {
      const mockedUpdateActiveSubmissionType = jest.fn()
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
      })
      const {container} = render(
        <AttemptTab {...props} updateActiveSubmissionType={mockedUpdateActiveSubmissionType} />
      )

      const selector = container.querySelector('select')
      fireEvent.change(selector, {target: {value: 'online_text_entry'}})

      expect(mockedUpdateActiveSubmissionType).toHaveBeenCalledWith('online_text_entry')
    })

    it('renders the active submission type if available', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']}
      })
      const {getByTestId} = render(
        <AttemptTab {...props} activeSubmissionType="online_text_entry" />
      )

      expect(await getByTestId('text-entry')).toBeInTheDocument()
    })

    it('does not render the selector if the submission state is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        Submission: {
          state: 'submitted'
        }
      })
      const {container} = render(<AttemptTab {...props} />)

      expect(container.querySelector('select')).not.toBeInTheDocument()
    })

    it('does not render the selector if the submission state is graded', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: {submissionTypes: ['online_text_entry', 'online_upload']},
        Submission: {
          state: 'graded'
        }
      })
      const {container} = render(<AttemptTab {...props} />)

      expect(container.querySelector('select')).not.toBeInTheDocument()
    })
  })
})
