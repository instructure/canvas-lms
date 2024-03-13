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

import axios from '@canvas/axios'
import {USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {act, render, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import MoreOptions from '../MoreOptions/index'
import React from 'react'

async function createGraphqlMocks(overrides = {}) {
  const userGroupOverrides = [{Node: () => ({__typename: 'User'})}]
  userGroupOverrides.push(overrides)

  const userGroupsResult = await mockQuery(USER_GROUPS_QUERY, userGroupOverrides, {userID: '1'})
  return [
    {
      request: {
        query: USER_GROUPS_QUERY,
        variables: {userID: '1'},
      },
      result: userGroupsResult,
    },
  ]
}

beforeEach(() => {
  jest.spyOn(axios, 'get').mockImplementation(input => {
    const resp = {headers: {}, data: []}
    if (input === '/api/v1/users/self/folders/root') {
      resp.data = {
        context_type: 'user',
        id: '1',
        name: 'my files',
        created_at: '2019-08-13T16:38:42Z',
      }
    } else if (input === '/api/v1/groups/1/folders/root') {
      resp.data = {
        context_type: 'group',
        id: '3',
        name: 'group files',
        created_at: '2019-08-13T16:38:42Z',
      }
    } else if (input === '/api/v1/folders/1/folders?include=user') {
      resp.data = {
        id: '4',
        name: 'dank memes',
        created_at: '2019-08-13T16:38:42Z',
        locked: false,
        parent_folder_id: '1',
      }
    } else if (input === '/api/v1/folders/4/files?include=user') {
      resp.data = {
        id: '10',
        display_name: 'bad_luck_brian.png',
        filename: 'bad_luck_brian.png',
        created_at: '2019-05-14T18:14:05Z',
        updated_at: '2019-08-14T22:26:07Z',
        user: {
          display_name: 'Mr. Norton',
        },
        size: 1122994,
        locked: false,
        folder_id: '4',
      }
    } else if (input === '/api/v1/folders/1/files?include=user') {
      resp.data = {
        id: '11',
        display_name: 'www.creedthoughts.gov.www/creedthoughts',
        filename: 'creedthoughts.png',
        created_at: '2019-05-14T20:00:00Z',
        updated_at: '2019-08-14T22:00:00Z',
        user: {
          display_name: 'Creed Bratton',
        },
        size: 1122994,
        locked: false,
        folder_id: '1',
      }
    }
    return Promise.resolve(resp)
  })
})

describe('MoreOptions', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
    jest.clearAllMocks()
    jest.useRealTimers()
  })

  afterEach(() => {
    cleanup()
  })

  it('renders a button for selecting Canvas files when handleCanvasFiles is not null', async () => {
    const mocks = await createGraphqlMocks()
    const {findByRole} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" userID="1" handleCanvasFiles={() => {}} />
      </MockedProvider>
    )
    expect(await findByRole('button', {name: /Files/})).toBeInTheDocument()
  })

  it('does not render a button for selecting Canvas files when handleCanvasFiles is null', async () => {
    const mocks = await createGraphqlMocks()
    const {queryByRole} = render(
      <MockedProvider mocks={mocks}>
        <MoreOptions assignmentID="1" courseID="1" userID="1" />
      </MockedProvider>
    )
    expect(queryByRole('button', {name: /Files/})).not.toBeInTheDocument()
  })

  describe('Canvas Files', () => {
    let selectedCanvasFiles = []
    const handleCanvasFiles = fileID => {
      selectedCanvasFiles.push(fileID)
    }

    beforeEach(() => {
      selectedCanvasFiles = []
      document.body.innerHTML = ''
      jest.clearAllMocks()
      jest.useRealTimers()
    })

    afterEach(() => {
      cleanup()
    })

    it('renders user and group folders', async () => {
      const user = userEvent.setup({delay: null})
      const mocks = await createGraphqlMocks()
      const {findAllByText, findByRole} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      expect((await findAllByText('my files'))[0]).toBeInTheDocument()
      expect(
        (await findAllByText(mocks[0].result.data.legacyNode.groups[0].name))[0]
      ).toBeInTheDocument()
    })

    it('renders the folder contents when a folder is selected', async () => {
      const user = userEvent.setup({delay: null})
      const mocks = await createGraphqlMocks()
      const {findAllByText, findByRole, findByTestId} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      await user.click(myFilesButton)

      const fileSelect = await findByTestId('upload-file-modal')
      expect(fileSelect).toContainElement((await findAllByText('dank memes'))[0])
      expect(fileSelect).toContainElement(
        (await findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      )
    }, 10000)

    it('filters out files with disallowed extensions when allowedExtensions is provided', async () => {
      const user = userEvent.setup({delay: null})
      const mocks = await createGraphqlMocks()
      const {findAllByText, findByRole, findByTestId, queryByText} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
            allowedExtensions={['doc']}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      await user.click(myFilesButton)

      const fileSelect = await findByTestId('upload-file-modal')
      expect(fileSelect).not.toContainElement(
        queryByText('www.creedthoughts.gov.www/creedthoughts')
      )
    }, 10000)

    it('includes files with allowed extensions when allowedExtensions is provided', async () => {
      const user = userEvent.setup({delay: null})
      const mocks = await createGraphqlMocks()
      const {findAllByText, findByRole, findByTestId} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
            allowedExtensions={['png']}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      await user.click(myFilesButton)

      const fileSelect = await findByTestId('upload-file-modal')
      expect(fileSelect).toContainElement(
        (await findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      )
    }, 10000)

    it('allows folder navigation through breadcrumbs', async () => {
      const user = userEvent.setup({delay: null})
      const mocks = await createGraphqlMocks()
      const {findAllByText, findByRole, findByTestId} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      await user.click(myFilesButton)

      const fileSelect = await findByTestId('upload-file-modal')
      expect(fileSelect).toContainElement((await findAllByText('dank memes'))[0])

      const rootFolderBreadcrumbLink = (await findAllByText('Root'))[0]
      await user.click(rootFolderBreadcrumbLink)

      expect((await findAllByText('my files'))[0]).toBeInTheDocument()
      expect(
        (await findAllByText(mocks[0].result.data.legacyNode.groups[0].name))[0]
      ).toBeInTheDocument()
    })

    it('hides the upload button until a file has been selected', async () => {
      const user = userEvent.setup({delay: null})
      const mocks = await createGraphqlMocks()
      const {findAllByText, findByRole, findByText, queryByText} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      await user.click(myFilesButton)

      const file = (await findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      expect(file).toBeInTheDocument()

      expect(queryByText('Upload')).not.toBeInTheDocument()

      await user.click(file)
      expect(await findByText('Upload')).toBeInTheDocument()
    })

    it('calls the handleCanvasFiles prop function when the upload button is clicked', async () => {
      const user = userEvent.setup({delay: null})
      const mocks = await createGraphqlMocks()
      const {findAllByText, findByRole} = render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            userID="1"
            handleCanvasFiles={handleCanvasFiles}
          />
        </MockedProvider>
      )
      const canvasFilesButton = await findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      const myFilesButton = (await findAllByText('my files'))[0]
      await user.click(myFilesButton)

      const file = (await findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      await user.click(file)

      const uploadButton = await findByRole('button', {name: 'Upload'})
      await user.click(uploadButton)

      expect(selectedCanvasFiles).toEqual(['11'])
    })
  }, 10000)

  describe('Webcam photo capture', () => {
    let handleWebcamPhotoUpload

    const renderComponent = async () => {
      const mocks = await createGraphqlMocks()

      return render(
        <MockedProvider mocks={mocks}>
          <MoreOptions
            assignmentID="1"
            courseID="1"
            handleWebcamPhotoUpload={handleWebcamPhotoUpload}
            userID="1"
          />
        </MockedProvider>
      )
    }

    beforeEach(() => {
      handleWebcamPhotoUpload = jest.fn()
      jest.useFakeTimers()

      navigator.mediaDevices = {
        getUserMedia: jest.fn().mockResolvedValue({
          getTracks: () => [{stop: jest.fn()}],
        }),
      }
    })

    afterEach(() => {
      act(() => {
        jest.runOnlyPendingTimers()
      })
      jest.useRealTimers()
      delete navigator.mediaDevices
    })

    it('renders a webcam capture button if the handleWebcamPhotoUpload prop is defined', async () => {
      const {findByRole} = await renderComponent()

      expect(await findByRole('button', {name: /Webcam/})).toBeInTheDocument()
    })

    it('shows the webcam capture view when the user clicks the button', async () => {
      const user = userEvent.setup({delay: null})
      const {findByRole} = await renderComponent()

      const webcamButton = await findByRole('button', {name: /Webcam/})
      await user.click(webcamButton)

      const modal = await findByRole('dialog')
      expect(modal).toContainHTML('Take a Photo via Webcam')
    })

    it('calls the handleWebcamPhotoUpload when the user has taken a photo and saved it', async () => {
      const user = userEvent.setup({delay: null})
      // unskip in EVAL-2661 (9/27/22)
      const {findByRole} = await renderComponent()

      const webcamButton = await findByRole('button', {name: /Webcam/})
      await user.click(webcamButton)

      const recordButton = await findByRole('button', {name: 'Take Photo'})
      await user.click(recordButton)

      act(() => {
        jest.advanceTimersByTime(10000)
      })

      const saveButton = await findByRole('button', {name: 'Save'})
      await user.click(saveButton)

      expect(handleWebcamPhotoUpload).toHaveBeenCalledTimes(1)
    })

    it('does not render a webcam capture button if the handleWebcamPhotoUpload prop is not set', async () => {
      handleWebcamPhotoUpload = null
      const {queryByRole} = await renderComponent()
      expect(queryByRole('button', {name: /Webcam/})).not.toBeInTheDocument()
    })
  })
})
