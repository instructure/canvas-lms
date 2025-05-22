/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import {render, waitFor, screen} from '@testing-library/react'
import FilesApp from '../FilesApp'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import fetchMock from 'fetch-mock'
import {createMemoryRouter, RouterProvider} from 'react-router-dom'
import {FAKE_FOLDERS} from '../../../fixtures/fakeData'
import {NotFoundError} from '../../../utils/apiUtils'
import {resetAndGetFilesEnv} from '../../../utils/filesEnvUtils'
import {createFilesContexts} from '../../../fixtures/fileContexts'

// Mock the useGetFolders module, but provide the real implementation by default
jest.mock('../../hooks/useGetFolders', () => {
  const originalModule = jest.requireActual('../../hooks/useGetFolders')
  return {
    ...originalModule,
    useGetFolders: originalModule.useGetFolders,
  }
})

describe('FilesApp', () => {
  let flashElements: any

  beforeEach(() => {
    const filesContexts = createFilesContexts({
      permissions: {
        manage_files_add: true,
        manage_files_delete: true,
        manage_files_edit: true,
      },
    })
    resetAndGetFilesEnv(filesContexts)

    fetchMock.get(/.*\/by_path/, [FAKE_FOLDERS[0]], {overwriteRoutes: true})
    fetchMock.get(/.*\/all.*/, [FAKE_FOLDERS[1]], {
      overwriteRoutes: true,
    })
    fetchMock.get(/.*\/files\/quota/, {quota_used: 500, quota: 1000}, {overwriteRoutes: true})
    fetchMock.get(/.*\/files\?search_term.*/, [], {overwriteRoutes: true})

    flashElements = document.createElement('div')
    flashElements.setAttribute('id', 'flash_screenreader_holder')
    flashElements.setAttribute('role', 'alert')
    document.body.appendChild(flashElements)
  })

  afterEach(() => {
    fetchMock.resetHistory()

    document.body.removeChild(flashElements)
    flashElements = undefined
  })

  const renderComponent = (overrideEntries?: string[]) => {
    const entries = overrideEntries || ['/']
    const router = createMemoryRouter(
      [
        {
          path: '/',
          Component: FilesApp,
        },
      ],
      {initialEntries: entries},
    )
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </MockedQueryClientProvider>,
    )
  }

  describe('without permissions', () => {
    beforeEach(() => {
      const filesContexts = createFilesContexts({
        permissions: {
          manage_files_add: false,
          manage_files_delete: false,
          manage_files_edit: false,
        },
      })
      resetAndGetFilesEnv(filesContexts)
    })

    it('does not render progress bar without permission', async () => {
      renderComponent()

      await waitFor(() => {
        expect(fetchMock.calls()).toHaveLength(1)
        expect(fetchMock.calls()[0][0]).not.toContain('/files/quota')
      })
    })

    it('does not render Upload File or Create Folder buttons when user does not have permission', async () => {
      renderComponent()
      // necessary to prevent false positives
      const allMyFilesButton = await screen.findByRole('button', {name: /all my files/i})
      const uploadButton = screen.queryByRole('button', {name: 'Upload'})
      const createFolderButton = screen.queryByRole('button', {name: 'Folder'})
      expect(allMyFilesButton).toBeInTheDocument()
      expect(uploadButton).not.toBeInTheDocument()
      expect(createFolderButton).not.toBeInTheDocument()
    })
  })

  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('renders next page button when header', async () => {
    // this intermittently timedout in jenkins, even though it runs just fine locally
    fetchMock.get(
      /.*\/all.*/,
      {
        body: [],
        headers: {
          Link: '</next-page>; rel="next"',
        },
      },
      {
        overwriteRoutes: true,
      },
    )
    renderComponent()
    const nextPageButton = await screen.findByRole('button', {name: '2'})
    expect(nextPageButton).toBeInTheDocument()
  })

  it('does not render page buttons when no header', async () => {
    renderComponent()
    // necessary to make sure table has finished loading
    // otherwise test is false positive because button would never be rendered
    const folderName = await screen.findByText(FAKE_FOLDERS[1].name)
    expect(folderName).toBeInTheDocument()
    const nextPageButton = screen.queryByRole('button', {name: '1'})
    expect(nextPageButton).not.toBeInTheDocument()
  })

  it('does render Upload File or Create Folder buttons when user has permission', async () => {
    renderComponent()
    const uploadButton = await screen.findByRole('button', {name: 'Upload'})
    const createFolderButton = await screen.findByRole('button', {name: /add folder/i})
    expect(uploadButton).toBeInTheDocument()
    expect(createFolderButton).toBeInTheDocument()
  })

  it('does not render Upload File or Create Folder buttons when searching', async () => {
    renderComponent(['?search_term=foo'])
    const allMyFilesButton = await screen.findByRole('button', {name: /all my files/i})
    const uploadButton = screen.queryByRole('button', {name: 'Upload'})
    const createFolderButton = screen.queryByRole('button', {name: 'Folder'})
    expect(allMyFilesButton).toBeInTheDocument()
    expect(uploadButton).not.toBeInTheDocument()
    expect(createFolderButton).not.toBeInTheDocument()
  })

  describe('404 error handling', () => {
    const hooksModule = require('../../hooks/useGetFolders')
    const originalUseGetFolders = hooksModule.useGetFolders

    afterEach(() => {
      hooksModule.useGetFolders = originalUseGetFolders
    })

    it('renders NotFoundArtwork component when a 404 error occurs', async () => {
      const mockError = new NotFoundError('Not found')
      hooksModule.useGetFolders = jest.fn().mockReturnValue({
        data: null,
        error: mockError,
        isLoading: false,
      })
      renderComponent()
      await waitFor(() => {
        expect(screen.getByText(/whoops... looks like nothing is here/i)).toBeInTheDocument()
        expect(screen.getByText(/we couldn't find that page/i)).toBeInTheDocument()
      })
    })

    it('does not render NotFoundArtwork component when no error occurs', async () => {
      hooksModule.useGetFolders = jest.fn().mockReturnValue({
        data: [{id: '1', name: 'Test Folder', context_id: '123', context_type: 'course'}],
        error: null,
        isLoading: false,
      })
      renderComponent()
      await waitFor(() => {
        const notFoundContainer = document.querySelector('.not_found_page_artwork')
        expect(notFoundContainer).not.toBeInTheDocument()
      })
    })

    it('does not show flash error message for 404 errors', async () => {
      const mockError = new NotFoundError('Not found')
      hooksModule.useGetFolders = jest.fn().mockReturnValue({
        data: null,
        error: mockError,
        isLoading: false,
      })
      renderComponent()
      expect(flashElements.textContent).not.toContain('Failed to fetch files and folders')
    })
  })
})
