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
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import FileUpload from '../FileUpload'
import {fireEvent, render, waitFor} from '@testing-library/react'
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

describe('FileUpload - Upload and LTI', () => {
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

  // TODO: vi->vitest - File upload callback not triggering, timing issue
  it.skip('allows uploading multiple files at a time', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = vi.fn()
    const props = await makeProps()
    uploadFileModule.uploadFile
      .mockResolvedValueOnce({id: '1', name: 'file1.jpg'})
      .mockResolvedValueOnce({id: '2', name: 'file2.jpg'})

    const {container} = render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new Blob(['foo'], {type: 'application/pdf'})
    file.name = 'file1.pdf'
    const file2 = new Blob(['foo'], {type: 'application/pdf'})
    file2.name = 'file2.pdf'

    uploadFiles(fileInput, [file, file2])

    await waitFor(() => {
      expect(props.onUploadRequested).toHaveBeenCalledWith(
        expect.objectContaining({
          files: [
            expect.objectContaining({preview: expect.stringMatching(/^blob:/)}),
            expect.objectContaining({preview: expect.stringMatching(/^blob:/)}),
          ],
        }),
      )
    })
  })

  it('creates an error alert when the API fails to upload files', async () => {
    const mocks = await createGraphqlMocks()
    const setOnFailure = vi.fn()
    const setOnSuccess = vi.fn()
    const props = await makeProps()
    props.onUploadRequested.mockImplementation(({onError}) => {
      onError(new Error('no'))
    })

    const {container} = render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
    const fileInput = container.querySelector('input[type="file"]')
    const file = new Blob(['foo'], {type: 'application/pdf'})
    file.name = 'file1.pdf'

    uploadFiles(fileInput, [file])
    await waitFor(() => {
      expect(setOnFailure).toHaveBeenCalledWith('Error updating submission draft')
    })
  })

  it('uploads files received through the LtiDeepLinkingResponse message event', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = vi.fn()
    const props = await makeProps({
      Submission: {attempt: 0},
    })
    uploadFileModule.uploadFile.mockResolvedValueOnce({id: '1', name: 'LemonRules.jpg'})

    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'LtiDeepLinkingResponse',
          content_items: [
            {
              url: 'http://lemon.com',
              title: 'LemonRules.txt',
              mediaType: 'plain/txt',
            },
          ],
        },
      }),
    )

    await waitFor(() => {
      expect(props.onUploadRequested).toHaveBeenCalledWith(
        expect.objectContaining({
          files: [
            {
              mediaType: 'plain/txt',
              title: 'LemonRules.txt',
              url: 'http://lemon.com',
            },
          ],
        }),
      )
    })
  })

  it('clears mediaType on files received through the A2ExternalContentReady message event', async () => {
    const mocks = await createGraphqlMocks()
    const setOnSuccess = vi.fn()
    const props = await makeProps({
      Submission: {attempt: 0},
    })
    uploadFileModule.uploadFile.mockResolvedValueOnce({id: '1', name: 'LemonRules.jpg'})

    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnSuccess}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'A2ExternalContentReady',
          content_items: [
            {
              url: 'http://lemon.com',
              title: 'LemonRules.txt',
              mediaType: 'application/octet-stream',
            },
          ],
        },
      }),
    )

    await waitFor(() => {
      expect(props.onUploadRequested).toHaveBeenCalledWith(
        expect.objectContaining({
          files: [
            {
              mediaType: '',
              title: 'LemonRules.txt',
              url: 'http://lemon.com',
            },
          ],
        }),
      )
    })
  })

  it('creates an error alert when given no file id through the Lti response', async () => {
    const mocks = await createGraphqlMocks()
    const setOnFailure = vi.fn()
    const props = await makeProps()
    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'A2ExternalContentReady',
          content_items: [],
        },
      }),
    )

    expect(setOnFailure).toHaveBeenCalledWith('Error adding files to submission draft')
  })

  it('creates an error alert when an error message is present in the Lti response', async () => {
    const mocks = await createGraphqlMocks()
    const setOnFailure = vi.fn()
    const props = await makeProps()
    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )

    const errormsg = 'oooh eeee this is an error message'
    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'LtiDeepLinkingResponse',
          errormsg,
        },
      }),
    )

    expect(setOnFailure).toHaveBeenCalledWith(errormsg)
  })

  it('does not call onUploadRequested when there is an error message present in the Lti response', async () => {
    const mocks = await createGraphqlMocks()
    const setOnFailure = vi.fn()
    const props = await makeProps()
    render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure}}>
          <FileUpload {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )

    const errormsg = 'oooh eeee this is an error message'
    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'LtiDeepLinkingResponse',
          content_items: [
            {
              url: 'http://lemon.com',
              title: 'LemonRules.txt',
              mediaType: 'plain/txt',
            },
          ],
          errormsg,
        },
      }),
    )

    expect(props.onUploadRequested).not.toHaveBeenCalled()
  })
})
