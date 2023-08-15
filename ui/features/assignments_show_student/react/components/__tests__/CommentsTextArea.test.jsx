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

import * as uploadFileModule from '@canvas/upload-file'
import $ from 'jquery'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'

import CommentsTray from '../CommentsTray/index'
import CommentTextArea from '../CommentsTray/CommentTextArea'
import {CREATE_SUBMISSION_COMMENT} from '@canvas/assignments/graphql/student/Mutations'
import {mockQuery, mockAssignmentAndSubmission} from '@canvas/assignments/graphql/studentMocks'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'

async function mockSubmissionCommentQuery() {
  const variables = {submissionAttempt: 0, submissionId: '1'}
  const overrides = {
    Node: {__typename: 'Submission'},
    SubmissionCommentConnection: {
      nodes: [{}],
    },
  }
  const result = await mockQuery(SUBMISSION_COMMENT_QUERY, overrides, variables)
  return {
    request: {
      query: SUBMISSION_COMMENT_QUERY,
      variables,
    },
    result,
  }
}

async function mockCreateSubmissionComment(variables = {}) {
  const result = await mockQuery(CREATE_SUBMISSION_COMMENT, [], variables)
  return {
    request: {
      query: CREATE_SUBMISSION_COMMENT,
      variables,
    },
    result,
  }
}

let mockedSetOnFailure = null
let mockedSetOnSuccess = null

function mockContext(children) {
  return (
    <AlertManagerContext.Provider
      value={{
        setOnFailure: mockedSetOnFailure,
        setOnSuccess: mockedSetOnSuccess,
      }}
    >
      {children}
    </AlertManagerContext.Provider>
  )
}

describe('CommentTextArea', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  beforeEach(() => {
    mockedSetOnFailure = jest.fn().mockResolvedValue({})
    mockedSetOnSuccess = jest.fn().mockResolvedValue({})
  })

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files,
      },
    })
  }

  describe('Media Uploads', () => {
    let createSubmissionComment
    let mediaObject

    beforeEach(() => {
      createSubmissionComment = jest.fn()
      mediaObject = {
        id: 1,
        name: 'Never Gonna Give You Up',
        type: 'video/mp4',
      }
    })

    function renderCommentTextArea(props) {
      const ref = React.createRef()
      render(
        mockContext(
          <MockedProvider>
            <CommentTextArea {...props} ref={ref} />
          </MockedProvider>
        )
      )
      return ref.current
    }

    it('creates a media comment on successful upload', async () => {
      const props = await mockAssignmentAndSubmission()
      const componentRef = renderCommentTextArea(props)
      componentRef.handleMediaUpload(null, mediaObject, createSubmissionComment)
      expect(createSubmissionComment).toHaveBeenCalled()
    })

    it('shows an error message if the upload fails', async () => {
      const props = await mockAssignmentAndSubmission()
      const componentRef = renderCommentTextArea(props)
      const error = {file: {size: 100}, maxFileSize: 250}
      componentRef.handleMediaUpload(error, mediaObject, createSubmissionComment)
      await waitFor(() =>
        expect(mockedSetOnFailure).toHaveBeenCalledWith('Error uploading video/audio recording')
      )
    })

    it('shows a specific file size error message if the upload fails due to size limits', async () => {
      const props = await mockAssignmentAndSubmission()
      const componentRef = renderCommentTextArea(props)
      const error = {file: {size: 262144010}, maxFileSize: 250}
      componentRef.handleMediaUpload(error, mediaObject, createSubmissionComment)
      await waitFor(() =>
        expect(mockedSetOnFailure).toHaveBeenCalledWith('File size exceeds the maximum of 250 MB')
      )
    })
  })

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
    const fileInput = await waitFor(() => container.querySelector('input[id="attachmentFile"]'))
    const files = [
      new File(['foo'], 'awesome-test-image.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'}),
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
    const fileInput = await waitFor(() => container.querySelector('input[id="attachmentFile"]'))
    const files = [
      new File(['foo'], 'awesome-test-image.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image4.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image5.png', {type: 'image/png'}),
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
    const fileInput = await waitFor(() => container.querySelector('input[id="attachmentFile"]'))
    const files = [
      new File(['foo'], 'awesome-test-image.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'}),
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
    const fileInput = await waitFor(() => container.querySelector('input[id="attachmentFile"]'))
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
    const fileInput = await waitFor(() => container.querySelector('input[id="attachmentFile"]'))
    const files = [
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'}),
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
    const fileInput = await waitFor(() => container.querySelector('input[id="attachmentFile"]'))
    const files = [
      new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'}),
      new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'}),
    ]

    uploadFiles(fileInput, files)

    const prevFile = container.querySelector(`button[id="${files[0].id}"]`)
    jest.spyOn(prevFile, 'focus')

    const currFile = container.querySelector(`button[id="${files[1].id}"]`)
    expect(currFile).toContainElement(getByText(`Remove ${files[1].name}`))
    fireEvent.click(currFile)

    expect(prevFile.focus).toHaveBeenCalled()
  })

  // LS-1339 created to figure out why this is failing
  // since updating @instructure/ui-media-player to v7

  it.skip('notifies users when a submission comments with files is sent', async () => {
    // unskip in EVAL-2482
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => [
      {id: '1', name: 'awesome-test-image1.png'},
      {id: '2', name: 'awesome-test-image2.png'},
      {id: '3', name: 'awesome-test-image3.png'},
    ]

    const variables = {
      submissionAttempt: 0,
      id: '1',
      comment: 'lion',
      fileIds: ['1', '2', '3'],
      mediaObjectId: null,
    }
    const mocks = await Promise.all([
      mockSubmissionCommentQuery(),
      mockCreateSubmissionComment(variables),
    ])
    const props = await mockAssignmentAndSubmission()
    const {container, findByPlaceholderText, findByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTray {...props} />
        </MockedProvider>
      )
    )
    const textArea = await findByPlaceholderText('Submit a Comment')
    const fileInput = await waitFor(() => container.querySelector('input[id="attachmentFile"]'))

    const file1 = new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'})
    const file2 = new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'})
    const file3 = new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'})

    uploadFiles(fileInput, [file1, file2, file3])

    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(await findByText('Send Comment'))

    uploadFileModule.submissionCommentAttachmentsUpload = mockedFunctionPlacedholder
    await waitFor(() => expect(mockedSetOnSuccess).toHaveBeenCalledWith('Submission comment sent'))
  })

  // LS-1339 created to figure out why this is failing
  // since updating @instructure/ui-media-player to v7

  it.skip('users cannot send submission comments with not files or text', async () => {
    // unskip in EVAL-2482
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => [
      {id: '1', name: 'awesome-test-image1.png'},
      {id: '2', name: 'awesome-test-image2.png'},
      {id: '3', name: 'awesome-test-image3.png'},
    ]

    const variables = {submissionAttempt: 0, id: '1', comment: '', fileIds: ['1', '2', '3']}
    const mocks = await Promise.all([
      mockSubmissionCommentQuery(),
      mockCreateSubmissionComment(variables),
    ])
    const props = await mockAssignmentAndSubmission()
    const {getByPlaceholderText, getByText, queryAllByText} = render(
      <MockedProvider mocks={mocks}>
        <CommentsTray {...props} />
      </MockedProvider>
    )
    const textArea = await waitFor(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: ''}})
    fireEvent.click(getByText('Send Comment'))

    uploadFileModule.submissionCommentAttachmentsUpload = mockedFunctionPlacedholder
    expect(await waitFor(() => queryAllByText('Submission comment sent'))).toHaveLength(0)
  })

  // LS-1339 created to figure out why this is failing
  // since updating @instructure/ui-media-player to v7

  it.skip('notifies users of error when file fails to upload', async () => {
    // unskip in EVAL-2482
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => {
      throw new Error('Error uploading file to canvas API')
    }

    const variables = {submissionAttempt: 0, id: '1', comment: 'lion', fileIds: ['1', '2', '3']}
    const mocks = await Promise.all([
      mockSubmissionCommentQuery(),
      mockCreateSubmissionComment(variables),
    ])
    const props = await mockAssignmentAndSubmission()
    const {container, getByPlaceholderText, getByText, queryAllByText} = render(
      mockContext(
        <MockedProvider mocks={mocks}>
          <CommentsTray {...props} />
        </MockedProvider>
      )
    )
    const textArea = await waitFor(() => getByPlaceholderText('Submit a Comment'))
    const fileInput = await waitFor(() => container.querySelector('input[id="attachmentFile"]'))

    const file1 = new File(['foo'], 'awesome-test-image1.png', {type: 'image/png'})
    const file2 = new File(['foo'], 'awesome-test-image2.png', {type: 'image/png'})
    const file3 = new File(['foo'], 'awesome-test-image3.png', {type: 'image/png'})
    uploadFiles(fileInput, [file1, file2, file3])

    fireEvent.change(textArea, {target: {value: 'lion'}})
    fireEvent.click(getByText('Send Comment'))
    uploadFileModule.submissionCommentAttachmentsUpload = mockedFunctionPlacedholder

    expect(mockedSetOnFailure).toHaveBeenCalledWith('Error sending submission comment')

    // Should not allow user to submit again if comments have error
    expect(await waitFor(() => queryAllByText('Send Comment'))).toHaveLength(0)
  })
})
