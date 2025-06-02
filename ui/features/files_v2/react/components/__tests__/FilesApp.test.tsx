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
import {render, screen} from '@testing-library/react'
import FilesApp from '../FilesApp'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import fetchMock from 'fetch-mock'
import {createMemoryRouter, RouterProvider} from 'react-router-dom'
import {FAKE_FOLDERS} from '../../../fixtures/fakeData'
import {NotFoundError} from '../../../utils/apiUtils'
import {resetAndGetFilesEnv} from '../../../utils/filesEnvUtils'
import {createFilesContexts} from '../../../fixtures/fileContexts'

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
    queryClient.clear()

    document.body.removeChild(flashElements)
    flashElements = undefined
  })

  const renderComponent = (overrideEntries?: string[]) => {
    const entries = overrideEntries || ['/']
    const router = createMemoryRouter(
      [
        {
          path: '*',
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

      await screen.findByRole('button', {name: /all my files/i})

      expect(fetchMock.calls()).toHaveLength(1)
      expect(fetchMock.calls()[0][0]).not.toContain('/files/quota')
    })

    it('does not render Upload File or Create Folder buttons when user does not have permission', async () => {
      renderComponent()

      const allMyFilesButton = await screen.findByRole('button', {name: /all my files/i})
      expect(allMyFilesButton).toBeInTheDocument()

      const uploadButton = screen.queryByRole('button', {name: 'Upload'})
      const createFolderButton = screen.queryByRole('button', {name: 'Folder'})

      expect(uploadButton).not.toBeInTheDocument()
      expect(createFolderButton).not.toBeInTheDocument()
    })
  })

  // fickle
  it.skip('renders next page button when pagination headers are present', async () => {
    fetchMock.get(
      /.*\/all.*/,
      {
        body: FAKE_FOLDERS,
        headers: {
          Link: '</api/v1/folders/1/files?page=2>; rel="next"',
          'X-Total-Pages': '2',
        },
      },
      {
        overwriteRoutes: true,
      },
    )

    renderComponent(['/all'])

    await screen.findByRole('button', {name: /all my files/i})

    await screen.findByTestId('pagination-announcement')

    const pagination = await screen.findByTestId('files-pagination')
    expect(pagination).toBeInTheDocument()

    const nextPageButton = await screen.findByRole('button', {name: '2'})
    expect(nextPageButton).toBeInTheDocument()
  })

  it('verifies fetch is called with correct pagination headers', async () => {
    const mockResponse = {
      body: FAKE_FOLDERS,
      headers: {
        Link: '</api/v1/folders/1/files?page=2>; rel="next"',
        'X-Total-Pages': '2',
      },
    }

    fetchMock.get(/.*\/all.*/, mockResponse, {overwriteRoutes: true})

    renderComponent(['/all'])

    await screen.findByRole('button', {name: /all my files/i})

    expect(fetchMock.called(/.*\/all.*/)).toBe(true)

    const calls = fetchMock.calls(/.*\/all.*/)
    expect(calls.length).toBeGreaterThan(0)

    const lastCallResponse = fetchMock.lastResponse(/.*\/all.*/)
    expect(lastCallResponse).not.toBeUndefined()

    if (lastCallResponse) {
      expect(lastCallResponse.headers.get('Link')).toContain('rel="next"')
      expect(lastCallResponse.headers.get('X-Total-Pages')).toBe('2')
    }
  })

  it('does not render pagination when only one page exists', async () => {
    fetchMock.get(/.*\/all.*/, FAKE_FOLDERS, {overwriteRoutes: true})

    renderComponent(['/all'])

    await screen.findByRole('button', {name: /all my files/i})

    const pagination = screen.queryByTestId('files-pagination')
    expect(pagination).not.toBeInTheDocument()
  })

  it('renders Upload File and Create Folder buttons when user has permission', async () => {
    renderComponent()

    await screen.findByRole('button', {name: /all my files/i})

    const uploadButton = await screen.findByRole('button', {name: 'Upload'})
    const createFolderButton = await screen.findByRole('button', {name: /add folder/i})

    expect(uploadButton).toBeInTheDocument()
    expect(createFolderButton).toBeInTheDocument()
  })

  it('hides Upload File and Create Folder buttons when searching', async () => {
    renderComponent(['?search_term=foo'])

    const allMyFilesButton = await screen.findByRole('button', {name: /all my files/i})
    expect(allMyFilesButton).toBeInTheDocument()

    const uploadButton = screen.queryByRole('button', {name: 'Upload'})
    const createFolderButton = screen.queryByRole('button', {name: 'Folder'})

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

      const notFoundMessage = await screen.findByText(/whoops... looks like nothing is here/i)
      expect(notFoundMessage).toBeInTheDocument()
      expect(screen.getByText(/we couldn't find that page/i)).toBeInTheDocument()
    })

    it('does not render NotFoundArtwork component when no error occurs', async () => {
      hooksModule.useGetFolders = jest.fn().mockReturnValue({
        data: [{id: '1', name: 'Test Folder', context_id: '123', context_type: 'course'}],
        error: null,
        isLoading: false,
      })

      renderComponent()

      await screen.findByText('Test Folder')

      const notFoundContainer = document.querySelector('.not_found_page_artwork')
      expect(notFoundContainer).not.toBeInTheDocument()
    })

    it('does not show flash error message for 404 errors', async () => {
      const mockError = new NotFoundError('Not found')
      hooksModule.useGetFolders = jest.fn().mockReturnValue({
        data: null,
        error: mockError,
        isLoading: false,
      })

      renderComponent()

      // Verify the 404 error doesn't trigger a flash message
      await screen.findByText(/whoops... looks like nothing is here/i)
      expect(flashElements.textContent).not.toContain('Failed to fetch files and folders')
    })
  })
})
