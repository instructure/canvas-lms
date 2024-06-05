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
import {render, screen, act, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import {MockedProvider} from '@apollo/react-testing'
import {mockQuery} from '@canvas/assignments/graphql/studentMocks'
import MoreOptions from '../MoreOptions/index'
import React from 'react'

const createGraphqlMocks = async (overrides = {}) => {
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
const defaultProps = (props = {}) => ({
  assignmentID: '1',
  courseID: '1',
  userID: '1',
  ...props,
})
const renderTestComponent = async (props = {}) => {
  const mocks = await createGraphqlMocks()
  const TestComponent = () => (
    <MockedProvider mocks={mocks}>
      <MoreOptions {...defaultProps(props)} />
    </MockedProvider>
  )

  return {
    ...render(<TestComponent />),
    mocks,
    TestComponent,
  }
}

describe('MoreOptions', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
    jest.clearAllMocks()

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

  it('renders a button for selecting Canvas files when handleCanvasFiles is not null', async () => {
    await renderTestComponent({
      handleCanvasFiles: jest.fn(),
    })

    expect(await screen.findByRole('button', {name: /Files/})).toBeInTheDocument()
  })

  it('does not render a button for selecting Canvas files when handleCanvasFiles is null', async () => {
    await renderTestComponent()

    expect(screen.queryByRole('button', {name: /Files/})).not.toBeInTheDocument()
  })

  describe('Canvas Files', () => {
    let selectedCanvasFiles

    const handleCanvasFiles = fileID => {
      selectedCanvasFiles.push(fileID)
    }
    const renderAndClickMyFiles = async (props = {}) => {
      const wrapper = await renderTestComponent(props)

      const user = userEvent.setup({delay: null})
      const canvasFilesButton = await screen.findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      const myFilesButton = (await screen.findAllByText('my files'))[0]
      await user.click(myFilesButton)

      return {
        ...wrapper,
        user,
      }
    }

    beforeEach(() => {
      selectedCanvasFiles = []
    })

    it('renders user and group folders', async () => {
      const {mocks} = await renderTestComponent({
        handleCanvasFiles,
      })

      const user = userEvent.setup({delay: null})
      const canvasFilesButton = await screen.findByRole('button', {name: /Files/})
      await user.click(canvasFilesButton)

      expect((await screen.findAllByText('my files'))[0]).toBeInTheDocument()
      expect(
        (await screen.findAllByText(mocks[0].result.data.legacyNode.groups[0].name))[0]
      ).toBeInTheDocument()
    })

    it('renders the folder contents when a folder is selected', async () => {
      await renderAndClickMyFiles({
        handleCanvasFiles,
      })

      const fileSelect = await screen.findByTestId('upload-file-modal')
      expect(fileSelect).toContainElement((await screen.findAllByText('dank memes'))[0])
      expect(fileSelect).toContainElement(
        (await screen.findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      )
    })

    it('filters out files with disallowed extensions when allowedExtensions is provided', async () => {
      await renderAndClickMyFiles({
        handleCanvasFiles,
        allowedExtensions: ['doc'],
      })

      const fileSelect = await screen.findByTestId('upload-file-modal')
      expect(fileSelect).not.toContainElement(
        screen.queryByText('www.creedthoughts.gov.www/creedthoughts')
      )
    })

    it('includes files with allowed extensions when allowedExtensions is provided', async () => {
      await renderAndClickMyFiles({
        handleCanvasFiles,
        allowedExtensions: ['png'],
      })

      const fileSelect = await screen.findByTestId('upload-file-modal')
      expect(fileSelect).toContainElement(
        (await screen.findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      )
    })

    it('allows folder navigation through breadcrumbs', async () => {
      const {user, mocks} = await renderAndClickMyFiles({
        handleCanvasFiles,
      })

      const fileSelect = await screen.findByTestId('upload-file-modal')
      expect(fileSelect).toContainElement((await screen.findAllByText('dank memes'))[0])

      const rootFolderBreadcrumbLink = (await screen.findAllByText('Root'))[0]
      await user.click(rootFolderBreadcrumbLink)

      expect((await screen.findAllByText('my files'))[0]).toBeInTheDocument()
      expect(
        (await screen.findAllByText(mocks[0].result.data.legacyNode.groups[0].name))[0]
      ).toBeInTheDocument()
    })

    it('hides the upload button until a file has been selected', async () => {
      const {user} = await renderAndClickMyFiles({
        handleCanvasFiles,
      })

      const file = (await screen.findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      expect(file).toBeInTheDocument()

      expect(screen.queryByText('Upload')).not.toBeInTheDocument()

      await user.click(file)
      expect(await screen.findByText('Upload')).toBeInTheDocument()
    })

    it('calls the handleCanvasFiles prop function when the upload button is clicked', async () => {
      const {user} = await renderAndClickMyFiles({
        handleCanvasFiles,
      })

      const file = (await screen.findAllByText('www.creedthoughts.gov.www/creedthoughts'))[0]
      await user.click(file)

      const uploadButton = await screen.findByRole('button', {name: 'Upload'})
      await user.click(uploadButton)

      expect(selectedCanvasFiles).toEqual(['11'])
    })
  })

  describe('Webcam photo capture', () => {
    let handleWebcamPhotoUpload

    const renderComponent = async () => {
      const user = userEvent.setup({delay: null})
      const component = await renderTestComponent({
        handleWebcamPhotoUpload,
      })

      return {
        ...component,
        user,
      }
    }

    beforeEach(() => {
      handleWebcamPhotoUpload = jest.fn()
      jest.useFakeTimers()

      navigator.mediaDevices = {getUserMedia: jest.fn()}
      navigator.mediaDevices.getUserMedia.mockResolvedValue({
        getTracks: () => ({forEach: jest.fn()}),
        clientWidth: 640,
        clientHeight: 480,
      })
      HTMLCanvasElement.prototype.getContext = () => ({
        drawImage: jest.fn(),
      })
      HTMLCanvasElement.prototype.toDataURL = jest.fn().mockReturnValue('data:image/png;base64,')
      HTMLCanvasElement.prototype.toBlob = jest.fn().mockImplementation(cb => cb(new Blob()))
    })

    afterEach(() => {
      jest.runAllTimers()
      delete navigator.mediaDevices
    })

    it('renders a webcam capture button if the handleWebcamPhotoUpload prop is defined', async () => {
      await renderComponent()

      expect(await screen.findByRole('button', {name: /Webcam/})).toBeInTheDocument()
    })

    it('shows the webcam capture view when the user clicks the button', async () => {
      const {user} = await renderComponent()

      const webcamButton = await screen.findByRole('button', {name: /Webcam/})
      await user.click(webcamButton)

      const modal = await screen.findByRole('dialog')
      expect(modal).toContainHTML('Take a Photo via Webcam')
    })

    it('calls the handleWebcamPhotoUpload when the user has taken a photo and saved it', async () => {
      const {user, rerender, TestComponent} = await renderComponent()

      const webcamButton = await screen.findByRole('button', {name: /Webcam/})
      await user.click(webcamButton)

      const recordButton = await screen.findByRole('button', {name: 'Take Photo'})
      await user.click(recordButton)

      await act(async () => {
        jest.advanceTimersByTime(3000)
        await waitFor(() => rerender(<TestComponent />))
        jest.advanceTimersByTime(2000)
        await waitFor(() => rerender(<TestComponent />))
        jest.advanceTimersByTime(1000)
        await waitFor(() => rerender(<TestComponent />))
        jest.advanceTimersByTime(500)
        await waitFor(() => rerender(<TestComponent />))
        await screen.findByAltText('Captured Image')
      })

      const saveButton = await screen.findByRole('button', {name: 'Save'})
      await user.click(saveButton)

      expect(handleWebcamPhotoUpload).toHaveBeenCalledTimes(1)
    })

    it('does not render a webcam capture button if the handleWebcamPhotoUpload prop is not set', async () => {
      handleWebcamPhotoUpload = null

      await renderComponent()

      expect(screen.queryByRole('button', {name: /Webcam/})).not.toBeInTheDocument()
    })
  })
})
