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
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import FileUpload from '../FileUpload'
import {fireEvent, render} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import React, {createRef} from 'react'

vi.mock('@canvas/upload-file', () => ({
  uploadFile: vi.fn().mockImplementation(file => {
    return Promise.resolve({id: 'mock-id', name: file.name})
  }),
}))

async function createGraphqlMocks(overrides = {}) {
  const userGroupOverrides = [{Node: () => ({__typename: 'User'})}]
  userGroupOverrides.push(overrides)

  const externalToolsResult = await mockQuery(EXTERNAL_TOOLS_QUERY, overrides, {courseID: '1'})
  const userGroupsResult = await mockQuery(USER_GROUPS_QUERY, userGroupOverrides, {userID: '1'})
  return [
    {
      request: {
        query: EXTERNAL_TOOLS_QUERY,
        variables: {courseID: '1'},
      },
      result: externalToolsResult,
    },
    {
      request: {
        query: EXTERNAL_TOOLS_QUERY,
        variables: {courseID: '1'},
      },
      result: externalToolsResult,
    },
    {
      request: {
        query: USER_GROUPS_QUERY,
        variables: {userID: '1'},
      },
      result: userGroupsResult,
    },
  ]
}

async function makeProps(overrides) {
  const assignmentAndSubmission = await mockAssignmentAndSubmission(overrides)
  const props = {
    ...assignmentAndSubmission,

    // Make these return a promise that will resolve
    onCanvasFileRequested: vi.fn(),
    onUploadRequested: vi.fn(),
    filesToUpload: [],
    uploadingFiles: false,
    focusOnInit: false,
    submitButtonRef: createRef(),
  }
  return props
}

describe('FileUpload - Extensions and Validation', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  const uploadFiles = (element, files) => {
    fireEvent.change(element, {
      target: {
        files,
      },
    })
  }

  it('displays allowed extensions in the upload box', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg, png']},
    })
    const {getByTestId, getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(getByText('File permitted: JPG, PNG'))
  })

  it('does not display any allowed extensions if there are none', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId, queryByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).not.toContainElement(queryByText('File permitted'))
  })

  it('renders an error when adding a file that is not an allowed extension', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg']},
    })
    const {container, getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new Blob(['foo'], {type: 'application/pdf'})
    file.name = 'file1.pdf'

    uploadFiles(fileInput, [file])

    expect(getByText('Invalid file type')).toBeInTheDocument()
  })

  it('does not render an error when adding a file that is an allowed extension', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = vi.fn()
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg']},
    })
    const {container, queryByText} = render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
    const fileInput = container.querySelector('input[id="inputFileDrop"]')
    const file = new Blob(['foo'], {type: 'application/jpg'})
    file.name = 'file1.jpg'

    uploadFiles(fileInput, [file])

    expect(queryByText('Invalid file type')).toBeNull()
  })

  it('renders an error when attempting to submit the assignment with no files', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({Submission: {submissionDraft: {meetsUploadCriteria: false}}})
    const submitButton = document.createElement('button')
    props.submitButtonRef.current = submitButton
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    fireEvent.click(props.submitButtonRef.current)
    expect(getByText('At least one submission type is required')).toBeInTheDocument()
  })

  it('clears error when clicking the FileDrop component', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({Submission: {submissionDraft: {meetsUploadCriteria: false}}})
    const submitButton = document.createElement('button')
    props.submitButtonRef.current = submitButton
    const {getByText, queryByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    fireEvent.click(props.submitButtonRef.current)
    expect(getByText('At least one submission type is required')).toBeInTheDocument()
    fireEvent.click(document.getElementById('inputFileDrop'))
    expect(queryByText('At least one submission type is required')).not.toBeInTheDocument()
  })
})
