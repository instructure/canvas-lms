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
import {CREATE_SUBMISSION, CREATE_SUBMISSION_DRAFT} from '../../graphqlData/Mutations'
import {createCache} from '../../../../canvas-apollo'
import {fireEvent, render, wait, waitForElement} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '../../mocks'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'
import {STUDENT_VIEW_QUERY} from '../../graphqlData/Queries'
import {SubmissionMocks} from '../../graphqlData/Submission'

async function preloadCache() {
  const variables = {assignmentLid: '1', submissionID: '1'}
  const result = await mockQuery(STUDENT_VIEW_QUERY, {}, variables)
  const cache = createCache()
  cache.writeQuery({
    query: STUDENT_VIEW_QUERY,
    variables,
    data: result.data
  })
  return cache
}

describe('ContentTabs', () => {
  describe('the submission type is online_upload', () => {
    it('renders the file upload tab when the submission is unsubmitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: () => ({submissionTypes: ['online_upload']})
      })

      const {getByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} />
        </MockedProvider>
      )
      expect(getByTestId('upload-pane')).toBeInTheDocument()
    })

    it('renders the file preview tab when the submission is submitted', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: () => ({submissionTypes: ['online_upload']}),
        Submission: () => ({
          ...SubmissionMocks.submitted,
          attachments: [{}]
        })
      })

      const {getByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} />
        </MockedProvider>
      )
      expect(getByTestId('assignments_2_submission_preview')).toBeInTheDocument()
    })
  })

  describe('the submission type is online_text_entry', () => {
    it('renders the text entry tab', async () => {
      const props = await mockAssignmentAndSubmission({
        Assignment: () => ({submissionTypes: ['online_text_entry']})
      })

      const {getByTestId} = render(
        <MockedProvider>
          <AttemptTab {...props} />
        </MockedProvider>
      )

      expect(getByTestId('text-entry')).toBeInTheDocument()
    })
  })
})

describe('Submitting an assignment', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  const createGraphqlMocks = async () => {
    const variables = {
      assignmentLid: '1',
      fileIds: ['1'],
      submissionID: '1',
      type: 'online_upload'
    }

    const mockedResults = await mockQuery(CREATE_SUBMISSION, {}, variables)
    return [
      {
        request: {
          query: CREATE_SUBMISSION,
          variables
        },
        result: mockedResults
      }
    ]
  }

  it('notifies SR users when an assignment is submitted', async () => {
    const mocks = await createGraphqlMocks()
    const props = await mockAssignmentAndSubmission({
      Submission: () => SubmissionMocks.draftWithAttachment,
      File: () => ({_id: '1'})
    })
    const {getByTestId, getByText} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <AttemptTab {...props} />
      </MockedProvider>
    )

    const submitButton = getByTestId('submit-button')
    fireEvent.click(submitButton)
    await wait(() => {
      expect(getByText('Submission sent')).toBeInTheDocument()
    })
  })

  it('shows an error when an assignment fails to be submitted', async () => {
    const mocks = await createGraphqlMocks()
    const props = await mockAssignmentAndSubmission({
      Submission: () => SubmissionMocks.draftWithAttachment,
      File: () => ({_id: '1'})
    })
    mocks[0].error = new Error('aw shucks')
    const {getByTestId, getAllByText} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <AttemptTab {...props} />
      </MockedProvider>
    )

    const submitButton = getByTestId('submit-button')
    fireEvent.click(submitButton)
    await wait(() => {
      expect(getAllByText('Error sending submission')[0]).toBeInTheDocument()
    })
  })
})

describe('Uploading a file', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
    uploadFileModule.uploadFiles = jest.fn()
    window.URL.createObjectURL = jest.fn()
  })

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  const createGraphqlMocks = async () => {
    const variables = {id: '1', attempt: 1, fileIds: ['1']}
    const mockedResults = await mockQuery(CREATE_SUBMISSION_DRAFT, {}, variables)
    return [
      {
        request: {
          query: CREATE_SUBMISSION_DRAFT,
          variables
        },
        result: mockedResults
      }
    ]
  }

  it('shows an error when creating a new SubmissionDraft fails', async () => {
    const props = await mockAssignmentAndSubmission()
    const mocks = await createGraphqlMocks()
    mocks[0].error = new Error('aw shucks')
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    const {getByTestId, getAllByText} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <AttemptTab {...props} />
      </MockedProvider>
    )

    const fileInput = getByTestId('input-file-drop')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(getAllByText('Error updating submission draft')[0]).toBeInTheDocument()
    })
  })

  it('shows an error when uploading a file fails', async () => {
    const props = await mockAssignmentAndSubmission()
    const mocks = await createGraphqlMocks()
    uploadFileModule.uploadFiles.mock.results = [
      {type: 'throw', value: 'Error uploading file to Canvas API'}
    ]

    const {getByTestId, getAllByText} = render(
      <MockedProvider mocks={mocks} cache={createCache()}>
        <AttemptTab {...props} />
      </MockedProvider>
    )

    const fileInput = getByTestId('input-file-drop')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(getAllByText('Error updating submission draft')[0]).toBeInTheDocument()
    })
  })

  it('notifies SR users when a submission draft has been saved', async () => {
    const cache = await preloadCache()
    const props = await mockAssignmentAndSubmission()
    const mocks = await createGraphqlMocks()
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    const {getByTestId, getByText} = render(
      <MockedProvider mocks={mocks} cache={cache}>
        <AttemptTab {...props} />
      </MockedProvider>
    )

    const fileInput = getByTestId('input-file-drop')
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(getByText('Submission draft updated')).toBeInTheDocument()
    })
  })

  it('shows a file preview for an uploaded file', async () => {
    const props = await mockAssignmentAndSubmission({
      Submission: () => ({
        submissionDraft: {
          attachments: [{displayName: 'test.jpg'}]
        }
      })
    })
    const {getAllByText} = render(
      <MockedProvider cache={createCache()}>
        <AttemptTab {...props} />
      </MockedProvider>
    )
    expect(await waitForElement(() => getAllByText('test.jpg')[0])).toBeInTheDocument()
  })
})
