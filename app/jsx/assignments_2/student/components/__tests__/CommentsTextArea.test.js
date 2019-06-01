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
import {
  commentGraphqlMock,
  mockAssignment,
  mockComments,
  mockMultipleAttachments
} from '../../test-utils'
import {fireEvent, render, waitForElement} from 'react-testing-library'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'

import CommentTextArea from '../Comments/CommentTextArea'
import Comments from '../Comments'
import * as uploadFileModule from '../../../../shared/upload_file'

describe('CommentTextArea', () => {
  beforeAll(() => {
    window.URL.createObjectURL = jest.fn()
  })

  beforeEach(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  it('renders the CommentTextArea by default', async () => {
    const {getByText} = render(
      <MockedProvider>
        <CommentTextArea assignment={mockAssignment()} />
      </MockedProvider>
    )
    expect(getByText('Attach a File')).toBeInTheDocument()
  })

  it('renders the input for controlling file inputs', async () => {
    const {container} = render(
      <MockedProvider>
        <CommentTextArea assignment={mockAssignment()} />
      </MockedProvider>
    )
    expect(container.querySelector('input[id="attachmentFile"]')).toBeInTheDocument()
  })

  it('renders the same number of attachments as files', async () => {
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea assignment={mockAssignment()} />
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
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea assignment={mockAssignment()} />
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
    const {container, getByText, queryByText} = render(
      <MockedProvider>
        <CommentTextArea assignment={mockAssignment()} />
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
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea assignment={mockAssignment()} />
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
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea assignment={mockAssignment()} />
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
    const {container, getByText} = render(
      <MockedProvider>
        <CommentTextArea assignment={mockAssignment()} />
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
    const mockedComments = mockComments()
    mockedComments.attachments = mockMultipleAttachments()
    const basicMock = commentGraphqlMock(mockedComments)
    const {container, getByPlaceholderText, getByText} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
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
    expect(await waitForElement(() => getByText('Submission comment sent'))).toBeInTheDocument()
  })

  it('users cannot send submission comments with not files or text', async () => {
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => [
      {id: '1', name: 'awesome-test-image1.png'},
      {id: '2', name: 'awesome-test-image2.png'},
      {id: '3', name: 'awesome-test-image3.png'}
    ]
    const mockedComments = mockComments()
    mockedComments.attachments = mockMultipleAttachments()
    const basicMock = commentGraphqlMock(mockedComments)
    const {getByPlaceholderText, getByText, queryAllByText} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
    )
    const textArea = await waitForElement(() => getByPlaceholderText('Submit a Comment'))
    fireEvent.change(textArea, {target: {value: ''}})
    fireEvent.click(getByText('Send Comment'))

    uploadFileModule.submissionCommentAttachmentsUpload = mockedFunctionPlacedholder
    expect(await waitForElement(() => queryAllByText('Submission comment sent'))).toHaveLength(0)
  })

  it('notifies users when a submission comments with files is not sent', async () => {
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => [
      {id: '1', name: 'awesome-test-image1.png'},
      {id: '2', name: 'awesome-test-image2.png'},
      {id: '3', name: 'awesome-test-image3.png'}
    ]
    const mockedComments = mockComments()
    mockedComments.attachments = mockMultipleAttachments()
    const errorMock = commentGraphqlMock(mockedComments)
    errorMock[2].result = {errors: [{message: 'Error!'}]}

    const {container, getByPlaceholderText, getByText} = render(
      <MockedProvider defaultOptions={{mutate: {errorPolicy: 'all'}}} mocks={errorMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
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

    expect(
      await waitForElement(() => getByText('Error sending submission comment'))
    ).toBeInTheDocument()
  })

  it('notifies users of error when file fails to upload', async () => {
    const mockedFunctionPlacedholder = uploadFileModule.submissionCommentAttachmentsUpload
    uploadFileModule.submissionCommentAttachmentsUpload = () => {
      throw new Error('Error uploading file to canvas API')
    }
    const mockedComments = mockComments()
    mockedComments.attachments = mockMultipleAttachments()
    const basicMock = commentGraphqlMock(mockedComments)
    const {container, getByPlaceholderText, getByText, queryAllByText} = render(
      <MockedProvider mocks={basicMock} addTypename>
        <Comments assignment={mockAssignment()} />
      </MockedProvider>
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

    expect(
      await waitForElement(() => getByText('Error sending submission comment'))
    ).toBeInTheDocument()

    // Should not allow user to submit again if comments have error
    expect(await waitForElement(() => queryAllByText('Send Comment'))).toHaveLength(0)
  })
})
