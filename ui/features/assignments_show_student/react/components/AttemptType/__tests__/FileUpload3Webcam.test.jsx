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

describe('FileUpload - Webcam photo upload', () => {
  beforeAll(() => {
    $('body').append('<div role="alert" id="flash_screenreader_holder" />')
  })

  it('is available when the assignment has no file extension restrictions', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps()

    const {findByRole} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    fireEvent.click(await findByRole('button', {name: /Canvas Files/}))
    expect(await findByRole('button', {name: /Webcam/})).toBeInTheDocument()
  })

  it('is available when the assignment allows PNG files', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Assignment: {allowedExtensions: ['jpg', 'png']},
    })

    const {findByRole} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    fireEvent.click(await findByRole('button', {name: /Canvas Files/}))
    expect(await findByRole('button', {name: /Webcam/})).toBeInTheDocument()
  })

  it('is not available when the assignment does not allow PNG files', async () => {
    const mocks = await createGraphqlMocks()
    const props = await makeProps({
      Assignment: {allowedExtensions: ['xls']},
    })

    const {findByRole, queryByRole} = render(
      <MockedProvider mocks={mocks}>
        <FileUpload {...props} />
      </MockedProvider>,
    )
    fireEvent.click(await findByRole('button', {name: /Canvas Files/}))
    expect(queryByRole('button', {name: /Webcam/})).not.toBeInTheDocument()
  })
})
