/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import * as uploadFileModule from '../../../shared/upload_file'
import {fireEvent, render, wait, waitForElement} from 'react-testing-library'
import {GetAssignmentEnvVariables, STUDENT_VIEW_QUERY} from '../assignmentData'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'
import {singleAttachment, submissionGraphqlMock} from '../test-utils'
import SubmissionIDQuery from '../components/SubmissionIDQuery'

let mocks

describe('SubmissionIDQuery', () => {
  beforeAll(() => {
    window.URL.createObjectURL = jest.fn()
    uploadFileModule.uploadFiles = jest.fn()
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  beforeEach(() => {
    mocks = submissionGraphqlMock()
    mocks[2].result.data.assignment.submissionsConnection.nodes[0].state = 'unsubmitted'

    window.ENV = {
      context_asset_string: 'test_1',
      COURSE_ID: '1',
      current_user: {display_name: 'bob', avatar_url: 'awesome.avatar.url'},
      PREREQS: {}
    }
  })

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files
      }
    })
  }

  it('renders normally', async () => {
    const {getByTestId} = render(
      <MockedProvider mocks={mocks} removeTypename addTypename>
        <SubmissionIDQuery assignmentLid="22" />
      </MockedProvider>
    )
    expect(
      await waitForElement(() => getByTestId('assignments-2-student-view'))
    ).toBeInTheDocument()
  })

  it('renders default env correctly', async () => {
    window.ENV = {}
    const defaultEnv = GetAssignmentEnvVariables()

    expect(defaultEnv).toEqual({
      assignmentUrl: '',
      courseId: null,
      currentUser: null,
      modulePrereq: null,
      moduleUrl: ''
    })
  })

  it('renders with env params set', async () => {
    const env = GetAssignmentEnvVariables()

    expect(env).toEqual({
      assignmentUrl: 'http://localhost/tests/1/assignments',
      courseId: '1',
      currentUser: {display_name: 'bob', avatar_url: 'awesome.avatar.url'},
      modulePrereq: null,
      moduleUrl: 'http://localhost/tests/1/modules'
    })
  })

  it('renders loading', async () => {
    const {getByTitle} = render(
      <MockedProvider mocks={mocks} removeTypename addTypename>
        <SubmissionIDQuery assignmentLid="22" />
      </MockedProvider>
    )

    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  // We have to do all these tests from this root component so that the apollo
  // cache is actually populated for the components that are needed. Not ideal,
  // maybe we could circle back later and find an easier way to handle these.

  it('displays uploaded files', async () => {
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    const {container, getByText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <SubmissionIDQuery assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() =>
      container.querySelector('input[id="inputFileDrop"]')
    )
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    expect(
      await waitForElement(() => getByText(singleAttachment().displayName))
    ).toBeInTheDocument()
  })

  it('notifies SR users when an attachment has been uploaded', async () => {
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    const {getByTestId, getByText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <SubmissionIDQuery assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() => getByTestId('inputFileDrop'))
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(getByText('Submission draft updated')).toBeInTheDocument()
    })
  })

  it('notifies users of error when attachments fail to upload in the API', async () => {
    uploadFileModule.uploadFiles.mock.results = [
      {type: 'throw', value: 'Error uploading file to Canvas API'}
    ]

    const {getByTestId, getByText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <SubmissionIDQuery assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() => getByTestId('inputFileDrop'))
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(getByText('Error updating submission draft')).toBeInTheDocument()
    })
  })

  it('notifies users of error when a submission fails to upload via graphql', async () => {
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    mocks[0].error = new Error('aw shucks')
    const {getByTestId, getByText} = render(
      <MockedProvider defaultOptions={{mutate: {errorPolicy: 'all'}}} mocks={mocks} addTypename>
        <SubmissionIDQuery assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() => getByTestId('inputFileDrop'))
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    await wait(() => {
      expect(getByText('Error updating submission draft')).toBeInTheDocument()
    })
  })

  it('notifies SR users when a submission has been sent', async () => {
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    const {getByTestId, getByText} = render(
      <MockedProvider mocks={mocks} addTypename>
        <SubmissionIDQuery assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() => getByTestId('inputFileDrop'))
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    const submitButton = await waitForElement(() => getByTestId('submit-button'))
    fireEvent.click(submitButton)
    await wait(() => {
      expect(getByText('Submission sent')).toBeInTheDocument()
    })
  })

  it('notifies users of error when a submission fails to send via graphql', async () => {
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    mocks[1].error = new Error('aw shucks')
    const {getByTestId, getByText} = render(
      <MockedProvider defaultOptions={{mutate: {errorPolicy: 'all'}}} mocks={mocks} addTypename>
        <SubmissionIDQuery assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() => getByTestId('inputFileDrop'))
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    const submitButton = await waitForElement(() => getByTestId('submit-button'))
    fireEvent.click(submitButton)
    await wait(() => {
      expect(getByText('Error sending submission')).toBeInTheDocument()
    })
  })

  it('renders error', async () => {
    const errorMock = [
      {
        request: {
          query: STUDENT_VIEW_QUERY,
          variables: {
            assignmentLid: '7'
          }
        },
        error: new Error('aw shucks')
      }
    ]
    const {getByText} = render(
      <MockedProvider mocks={errorMock} removeTypename addTypename>
        <SubmissionIDQuery assignmentLid="7" />
      </MockedProvider>
    )

    expect(await waitForElement(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
  })
})
