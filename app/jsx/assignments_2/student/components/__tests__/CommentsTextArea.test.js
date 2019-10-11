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

import * as uploadFileModule from '../../../../shared/upload_file'
import $ from 'jquery'
import {AlertManagerContext} from '../../../../shared/components/AlertManager'
import {fireEvent, render, wait, waitForElement} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'

import CommentsTab from '../CommentsTab'
import CommentTextArea from '../CommentsTab/CommentTextArea'
import {CREATE_SUBMISSION_COMMENT} from '../../graphqlData/Mutations'
import {mockQuery, mockAssignmentAndSubmission} from '../../mocks'
import {SUBMISSION_COMMENT_QUERY} from '../../graphqlData/Queries'

jest.setTimeout(10000)

async function mockSubmissionCommentQuery() {
  const variables = {submissionAttempt: 0, submissionId: '1'}
  const overrides = {
    Node: {__typename: 'Submission'},
    SubmissionCommentConnection: {
      nodes: [{}]
    }
  }
  const result = await mockQuery(SUBMISSION_COMMENT_QUERY, overrides, variables)
  return {
    request: {
      query: SUBMISSION_COMMENT_QUERY,
      variables
    },
    result
  }
}

async function mockCreateSubmissionComment(variables = {}) {
  const result = await mockQuery(CREATE_SUBMISSION_COMMENT, [], variables)
  return {
    request: {
      query: CREATE_SUBMISSION_COMMENT,
      variables
    },
    result
  }
}

let mockedSetOnFailure = null
let mockedSetOnSuccess = null

function mockContext(children) {
  return (
    <AlertManagerContext.Provider
      value={{
        setOnFailure: mockedSetOnFailure,
        setOnSuccess: mockedSetOnSuccess
      }}
    >
      {children}
    </AlertManagerContext.Provider>
  )
}

describe('CommentTextArea', () => {
  beforeAll(() => {
    window.URL.createObjectURL = jest.fn()
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  beforeEach(() => {
    mockedSetOnFailure = jest.fn().mockResolvedValue({})
    mockedSetOnSuccess = jest.fn().mockResolvedValue({})
  })

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  it('renders the CommentTextArea by default', async () => {
    const props = await mockAssignmentAndSubmission()
    const {getByText} = render(
      <MockedProvider>
        <CommentTextArea {...props} />
      </MockedProvider>
    )
    expect(getByText('Attach a File')).toBeInTheDocument()
  })

  it('renders the input for controlling file inputs', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container} = render(
      <MockedProvider>
        <CommentTextArea {...props} />
      </MockedProvider>
    )
    expect(container.querySelector('input[id="attachmentFile"]')).toBeInTheDocument()
  })

  it('renders the same number of attachments as files', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea {...props} />
      </MockedProvider>
    )
    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="attachmentFile"]')
    )
    const files = [
      new File(['foo'], 'awesome-test-image.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'})
    ]

    uploadFiles(fileInput, files)
    files.forEach(file => expect(getByText(file.name)).toBeInTheDocument())
  })

  it('concats to previously uploaded files', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea {...props} />
      </MockedProvider>
    )
    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="attachmentFile"]')
    )
    const files = [
      new File(['foo'], 'awesome-test-image.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image4.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image5.png', {type: 'image/png'})
    ]

    uploadFiles(fileInput, files.slice(0, 1))
    expect(getByText(files[0].name)).toBeInTheDocument()

    uploadFiles(fileInput, files.slice(1, 4))
    files.slice(1, 4).forEach(file => expect(getByText(file.name)).toBeInTheDocument())

    uploadFiles(fileInput, files.slice(4))
    files.slice(4).forEach(file => expect(getByText(file.name)).toBeInTheDocument())
  })

  it('can remove uploaded files', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container, getByText, queryByText} = render(
      <MockedProvider>
        <CommentTextArea {...props} />
      </MockedProvider>
    )
    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="attachmentFile"]')
    )
    const files = [
      new File(['foo'], 'awesome-test-image.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'})
    ]

    uploadFiles(fileInput, files)
    files.forEach(file => expect(getByText(file.name)).toBeInTheDocument())

    files.slice(0, 3).forEach(file => {
      const button = container.querySelector(`button[id="${file.id}"]`)
      expect(button).toContainElement(getByText(`Remove ${file.name}`))
      fireEvent.click(button)
    })

    files.slice(0, 3).forEach(file => expect(queryByText(file.name)).not.toBeInTheDocument())
    files.slice(3).forEach(file => expect(getByText(file.name)).toBeInTheDocument())
  })

  it('sets focus to the attachment file button after removing all attachments', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea {...props} />
      </MockedProvider>
    )
    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="attachmentFile"]')
    )
    const file = new File(['foo'], 'awesome-test-image.png', {type: 'image/png'})

    uploadFiles(fileInput, [file])

    const uploadButton = container.querySelector('button[id="attachmentFileButton"]')
    jest.spyOn(uploadButton, 'focus')

    const button = container.querySelector(`button[id="${file.id}"]`)
    expect(button).toContainElement(getByText(`Remove ${file.name}`))
    fireEvent.click(button)

    expect(uploadButton.focus).toHaveBeenCalled()
  })

  it('sets focus to the next file in the list if the first file is removed', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea {...props} />
      </MockedProvider>
    )
    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="attachmentFile"]')
    )
    const files = [
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'})
    ]

    uploadFiles(fileInput, files)

    const nextFile = container.querySelector(`button[id="${files[1].id}"]`)
    jest.spyOn(nextFile, 'focus')

    const firstFile = container.querySelector(`button[id="${files[0].id}"]`)
    expect(firstFile).toContainElement(getByText(`Remove ${files[0].name}`))
    fireEvent.click(firstFile)

    expect(nextFile.focus).toHaveBeenCalled()
  })

  it('sets focus to the previous file in the list if any other file is removed', async () => {
    const props = await mockAssignmentAndSubmission()
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea {...props} />
      </MockedProvider>
    )
    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="attachmentFile"]')
    )
    const files = [
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'})
    ]

    uploadFiles(fileInput, files)

    const prevFile = container.querySelector(`button[id="${files[0].id}"]`)
    jest.spyOn(prevFile, 'focus')

    const currFile = container.querySelector(`button[id="${files[1].id}"]`)
    expect(currFile).toContainElement(getByText(`Remove ${files[1].name}`))
    fireEvent.click(currFile)

    expect(prevFile.focus).toHaveBeenCalled()
  })

  it('notifies users when a submission comments with files is sent', async () => {
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => [
      {id: '1', name: 'awesome-test-image1.png'},
      {id: '2', name: 'awesome-test-image2.png'},
      {id: '3', name: 'awesome-test-image3.png'}
    ]

    const variables = {
      submissionAttempt: 0,
      id: '1',
      comment: 'lion',
      fileIds: ['1', '2', '3'],
      mediaObjectId: null
    }
    const mocks = await Promise.all([
      mockSubmissionCommentQuery(),
      mockCreateSubmissionComment(variables)
    ])
    const props = await mockAssignmentAndSubmission()
    const {container, findByPlaceholderText, findByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )
    const textArea = await findByPlaceholderText('Submit a Comment')
    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="attachmentFile"]')
    )

    const file1 = new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'})
    const file2 = new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'})
    const file3 = new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'})

    uploadFiles(fileInput, [file1, file2, file3])

    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(await findByText('Send Comment'))

    uploadFileModule.submissionCommentAttachmentsUpload = mockedFunctionPlacedholder
    await wait(() => expect(mockedSetOnSuccess).toHaveBeenCalledWith('Submission comment sent'))
  })

  it('users cannot send submission comments with not files or text', async () => {
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => [
      {id: '1', name: 'awesome-test-image1.png'},
      {id: '2', name: 'awesome-test-image2.png'},
      {id: '3', name: 'awesome-test-image3.png'}
    ]

    const variables = {submissionAttempt: 0, id: '1', comment: '', fileIds: ['1', '2', '3']}
    const mocks = await Promise.all([
      mockSubmissionCommentQuery(),
      mockCreateSubmissionComment(variables)
    ])
    const props = await mockAssignmentAndSubmission()
    const {getByPlaceholderText, getByText, queryAllByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTab {...props} />
      </MockedProvider>
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: ''}})
    fireEvent.click(getByText('Send Comment'))

    uploadFileModule.submissionCommentAttachmentsUpload = mockedFunctionPlacedholder
    expect(await waitForElement(() => queryAllByText('Submission comment sent'))).toHaveLength(0)
  })

  it('notifies users of error when file fails to upload', async () => {
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => {
      throw new Error('Error uploading file to canvas API')
    }

    const variables = {submissionAttempt: 0, id: '1', comment: 'lion', fileIds: ['1', '2', '3']}
    const mocks = await Promise.all([
      mockSubmissionCommentQuery(),
      mockCreateSubmissionComment(variables)
    ])
    const props = await mockAssignmentAndSubmission()
    const {container, getByPlaceholderText, getByText, queryAllByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTab {...props} />
        </MockedProvider>
      )
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="attachmentFile"]')
    )

    const file1 = new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'})
    const file2 = new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'})
    const file3 = new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'})
    uploadFiles(fileInput, [file1, file2, file3])

    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))
    uploadFileModule.submissionCommentAttachmentsUpload = mockedFunctionPlacedholder

    expect(mockedSetOnFailure).toHaveBeenCalledWith('Error sending submission comment')

    // Should not allow user to submit again if comments have error
    expect(await waitForElement(() => queryAllByText('Send Comment'))).toHaveLength(0)
  })
})
