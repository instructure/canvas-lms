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
import {render} from '@testing-library/react'
import {mockAssignmentAndSubmission, mockQuery} from '@canvas/assignments/graphql/studentMocks'
import {MockedProvider} from '@apollo/client/testing'
import React, {createRef} from 'react'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

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

describe('FileUpload - File Management', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  it('renders a button to remove the file', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {_id: '1', displayName: 'foobarbaz'},
    })

    const {container, getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const button = container.querySelector('button[id="1"]')

    expect(button).toContainElement(getByText('Remove foobarbaz'))
    expect(button).toContainElement(container.querySelector('svg[name="IconTrash"]'))
  })

  it('renders a remove button for each uploaded file', async () => {
    const mocks = await createGraphqlMocks()
    const attachmentOverrides = [
      {_id: '1', displayName: 'foobarbaz1'},
      {_id: '2', displayName: 'foobarbaz2'},
    ]
    const props = await makeProps({
      Submission: {
        submissionDraft: {attachments: attachmentOverrides},
      },
    })

    const {container, getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )

    attachmentOverrides.forEach(attachment => {
      const button = container.querySelector(`button[id="${attachment._id}"]`)
      expect(button).toContainElement(getByText(`Remove ${attachment.displayName}`))
    })
  })

  it('elides filenames for files greater than 21 characters', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: 'c'.repeat(22)},
    })

    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )

    expect(getByText(/^c+\.{3}c+$/)).toBeInTheDocument()
  })

  it('does not elide filenames for files less than or equal to 21 characters', async () => {
    const mocks = await createGraphqlMocks()
    const filename = 'c'.repeat(21)
    const props = await makeProps({
      Submission: SubmissionMocks.onlineUploadReadyToSubmit,
      File: {displayName: filename},
    })

    const {getAllByText} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )

    expect(getAllByText(filename)[0]).toBeInTheDocument()
  })

  it('displays a button for uploading Canvas files in the upload box', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    const {getByTestId, findByRole} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    const emptyRender = getByTestId('upload-box')

    expect(emptyRender).toContainElement(await findByRole('button', {name: /Files/}))
  })

  it('shows a checkmark icon for uploaded files', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = vi.fn()
    const attachmentOverrides = [{_id: '1', displayName: 'just a file'}]
    const props = await makeProps({
      Submission: {
        submissionDraft: {attachments: attachmentOverrides},
      },
    })

    const {container, getByTestId} = render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
    const uploadRender = getByTestId('upload-pane')
    expect(uploadRender).toContainElement(container.querySelector('svg[name="IconComplete"]'))
  })

  it('renders a loading indicator for each file in the process of uploading', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()
    props.filesToUpload = [
      {id: '1', _id: '1', name: 'file1.pdf', isLoading: true, loaded: 10, total: 100},
      {id: '2', _id: '2', name: 'file2.pdf', isLoading: true, loaded: 50, total: 250},
    ]

    const {getAllByRole} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )

    const progressBars = getAllByRole('progressbar')
    expect(progressBars).toHaveLength(2)

    expect(progressBars[0].value).toBe(10)
    expect(progressBars[0].max).toBe(100)
    expect(progressBars[0]).toHaveAttribute('aria-valuetext', '10 percent')
    expect(progressBars[0]).toHaveAttribute('aria-label', 'Upload progress for file1.pdf')

    expect(progressBars[1].value).toBe(50)
    expect(progressBars[1].max).toBe(250)
    expect(progressBars[1]).toHaveAttribute('aria-valuetext', '20 percent')
    expect(progressBars[1]).toHaveAttribute('aria-label', 'Upload progress for file2.pdf')
  })
})
