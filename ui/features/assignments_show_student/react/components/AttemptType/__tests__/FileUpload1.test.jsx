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
import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import FileUpload from '../FileUpload'
import {render} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import React, {createRef} from 'react'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'
import StudentViewContext from '@canvas/assignments/react/StudentViewContext'

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

describe('FileUpload - Basic Rendering', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  it('renders the upload file drop', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toHaveTextContent(/choose a file to upload/i)
  })

  it('renders an enabled upload file drop for students', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const fileDrop = getByTestId('input-file-drop')

    expect(fileDrop).not.toBeDisabled()
  })

  it('renders a disabled upload file drop for observers', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <StudentViewContext.Provider value={{allowChangesToSubmission: false, isObserver: true}}>
          <FileUpload {...props} />
        </StudentViewContext.Provider>
      </MockedProvider>,
    )
    const fileDrop = getByTestId('input-file-drop')

    expect(fileDrop).toBeDisabled()
  })

  it('does not move focus to file drop box after render if focusOnInit is false', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const inputFileDrop = getByTestId('input-file-drop')

    expect(inputFileDrop).not.toHaveFocus()
  })

  it('moves focus to file drop box after render if focusOnInit is true', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    props.focusOnInit = true
    const {getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const inputFileDrop = getByTestId('input-file-drop')

    expect(inputFileDrop).toHaveFocus()
  })

  it('renders the submission draft files if there are any', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz'},
    })

    const {getByTestId, getAllByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const uploadRender = getByTestId('upload-pane')
    expect(uploadRender).toContainElement(getAllByText('foobarbaz')[0])
  })

  it('renders in an img tag if the file type is an image', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz', mimeClass: 'image'},
    })
    const {container, getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const uploadRender = getByTestId('upload-pane')
    expect(uploadRender).toContainElement(container.querySelector('img[alt="foobarbaz preview"]'))
  })

  it('renders an icon if a non-image file is uploaded', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'foobarbaz', mimeClass: 'pdf'},
    })

    const {container, getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const uploadRender = getByTestId('upload-pane')

    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconPdf"]'))
    expect(container.querySelector('img[alt="foobarbaz preview"]')).toBeNull()
  })
})
