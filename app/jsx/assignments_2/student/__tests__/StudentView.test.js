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
import {fireEvent, render, waitForElement} from 'react-testing-library'
import {GetAssignmentEnvVariables, STUDENT_VIEW_QUERY} from '../assignmentData'
import {mockGraphqlQueryResults, submissionGraphqlMock} from '../test-utils'
import {MockedProvider} from 'react-apollo/test-utils'
import React from 'react'
import StudentView from '../StudentView'
import * as uploadFileModule from '../../../shared/upload_file'

const mocks = [
  {
    request: {
      query: STUDENT_VIEW_QUERY,
      variables: {
        assignmentLid: '7'
      }
    },
    result: {
      data: {
        assignment: mockGraphqlQueryResults()
      }
    }
  }
]

describe('StudentView', () => {
  beforeAll(() => {
    window.URL.createObjectURL = jest.fn()
    uploadFileModule.uploadFiles = jest.fn()
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
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
        <StudentView assignmentLid="7" />
      </MockedProvider>
    )
    expect(
      await waitForElement(() => getByTestId('assignments-2-student-view'))
    ).toBeInTheDocument()
  })

  it('renders default env correctly', async () => {
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
    window.ENV = {
      context_asset_string: 'test_1',
      COURSE_ID: '1',
      current_user: {display_name: 'bob', avatar_url: 'awesome.avatar.url'},
      PREREQS: {}
    }

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
        <StudentView assignmentLid="7" />
      </MockedProvider>
    )

    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  // We have to do all these tests from this root component so that the apollo
  // cache is actually populated for the components that are needed. Not ideal,
  // maybe we could circle back later and find an easier way to handle these.

  it('notifies SR users when a submission has been sent', async () => {
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    const {container, getByText, getByRole} = render(
      <MockedProvider mocks={submissionGraphqlMock()} addTypename>
        <StudentView assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() => container.querySelector('input[type="file"]'))
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    expect(getByText('Submit')).toBeInTheDocument()
    fireEvent.click(getByText('Submit'))

    expect(getByRole('alert')).toContainElement(
      await waitForElement(() => getByText('Submission sent'))
    )
  })

  it('notifies users of error when a submission fails to send', async () => {
    uploadFileModule.uploadFiles.mockReturnValueOnce([{id: '1', name: 'file1.jpg'}])

    const assignmentMocks = submissionGraphqlMock()
    assignmentMocks[0].result = {errors: [{message: 'Error!'}]}
    const {container, getByText} = render(
      <MockedProvider
        defaultOptions={{mutate: {errorPolicy: 'all'}}}
        mocks={assignmentMocks}
        addTypename
      >
        <StudentView assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() => container.querySelector('input[type="file"]'))
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    expect(getByText('Submit')).toBeInTheDocument()
    fireEvent.click(getByText('Submit'))

    expect(await waitForElement(() => getByText('Error sending submission'))).toBeInTheDocument()
  })

  it('notifies users of error when attachments fail to upload', async () => {
    uploadFileModule.uploadFiles.mock.results = [
      {type: 'throw', value: 'Error uploading file to Canvas API'}
    ]

    const {container, getByText} = render(
      <MockedProvider mocks={submissionGraphqlMock()} addTypename>
        <StudentView assignmentLid="22" />
      </MockedProvider>
    )

    const fileInput = await waitForElement(() => container.querySelector('input[type="file"]'))
    const file = new File(['foo'], 'file1.jpg', {type: 'image/jpg'})
    uploadFiles(fileInput, [file])

    expect(getByText('Submit')).toBeInTheDocument()
    fireEvent.click(getByText('Submit'))

    expect(await waitForElement(() => getByText('Error sending submission'))).toBeInTheDocument()
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
      <StudentView assignmentLid="7" />
    </MockedProvider>
  )

  expect(await waitForElement(() => getByText('Sorry, Something Broke'))).toBeInTheDocument()
})
