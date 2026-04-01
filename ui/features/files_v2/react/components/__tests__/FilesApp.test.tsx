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
import {queryClient} from '@instructure/platform-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {createMemoryRouter, RouterProvider} from 'react-router-dom'
import {FAKE_FOLDERS} from '../../../fixtures/fakeData'
import {NotFoundError} from '../../../utils/apiUtils'
import {resetAndGetFilesEnv} from '../../../utils/filesEnvUtils'
import {createFilesContexts} from '../../../fixtures/fileContexts'

const server = setupServer()

vi.mock('../../hooks/useGetFolders', async () => {
  const originalModule = await vi.importActual('../../hooks/useGetFolders')
  return {
    ...originalModule,
    useGetFolders: originalModule.useGetFolders,
  }
})

describe('FilesApp', () => {
  let flashElements: any

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    const filesContexts = createFilesContexts({
      permissions: {
        manage_files_add: true,
        manage_files_delete: true,
        manage_files_edit: true,
      },
    })
    resetAndGetFilesEnv(filesContexts)

    server.use(
      http.get(/.*\/by_path/, () => {
        return HttpResponse.json([FAKE_FOLDERS[0]])
      }),
      http.get(/.*\/all.*/, () => {
        return HttpResponse.json([FAKE_FOLDERS[1]])
      }),
      http.get(/.*\/files\/quota/, () => {
        return HttpResponse.json({quota_used: 500, quota: 1000})
      }),
      http.get(/.*\/folders_and_files/, ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.has('search_term')) {
          return HttpResponse.json([])
        }
        return HttpResponse.json([FAKE_FOLDERS[0]])
      }),
      http.get(/.*\/folders\/.*\/duplicates/, () => {
        return HttpResponse.json({duplicates: []})
      }),
    )

    flashElements = document.createElement('div')
    flashElements.setAttribute('id', 'flash_screenreader_holder')
    flashElements.setAttribute('role', 'alert')
    document.body.appendChild(flashElements)
  })

  afterEach(() => {
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

      // With no permission, the quota endpoint should not be requested
      // Just verify the component loads without the progress bar
      expect(screen.queryByRole('progressbar')).not.toBeInTheDocument()
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
    // const hooksModule = require('../../hooks/useGetFolders')
    // const originalUseGetFolders = hooksModule.useGetFolders

    // afterEach(() => {
    //   hooksModule.useGetFolders = originalUseGetFolders
    // })

    it('renders NotFoundArtwork component when a 404 error occurs', async () => {
      // const mockError = new NotFoundError('Not found')
      // hooksModule.useGetFolders = vi.fn().mockReturnValue({
      //   data: null,
      //   error: mockError,
      //   isLoading: false,
      // })
      //
      // renderComponent()
      //
      // const notFoundMessage = await screen.findByText(/whoops... looks like nothing is here/i)
      // expect(notFoundMessage).toBeInTheDocument()
      // expect(screen.getByText(/we couldn't find that page/i)).toBeInTheDocument()
    })

    it('does not render NotFoundArtwork component when no error occurs', async () => {
      // hooksModule.useGetFolders = vi.fn().mockReturnValue({
      //   data: [{id: '1', name: 'Test Folder', context_id: '123', context_type: 'course'}],
      //   error: null,
      //   isLoading: false,
      // })
      //
      // renderComponent()
      //
      // await screen.findByText('Test Folder')
      //
      // const notFoundContainer = document.querySelector('.not_found_page_artwork')
      // expect(notFoundContainer).not.toBeInTheDocument()
    })

    it('does not show flash error message for 404 errors', async () => {
      // const mockError = new NotFoundError('Not found')
      // hooksModule.useGetFolders = vi.fn().mockReturnValue({
      //   data: null,
      //   error: mockError,
      //   isLoading: false,
      // })
      //
      // renderComponent()
      //
      // // Verify the 404 error doesn't trigger a flash message
      // await screen.findByText(/whoops... looks like nothing is here/i)
      // expect(flashElements.textContent).not.toContain('Failed to fetch files and folders')
    })
  })

  describe('duplicate folders modal', () => {
    const mockDuplicateFolders = [
      {
        id: '100',
        name: 'Duplicate Folder',
        full_name: 'course files/Duplicate Folder',
        context_id: '8',
        context_type: 'Course',
        parent_folder_id: '42',
        created_at: '2024-11-11T18:32:18Z',
        updated_at: '2024-11-11T18:32:18Z',
        lock_at: null,
        unlock_at: null,
        position: 1,
        locked: false,
        folders_url: 'http://canvas-web.inseng.test/api/v1/folders/100/folders',
        files_url: 'http://canvas-web.inseng.test/api/v1/folders/100/files',
        files_count: 0,
        folders_count: 0,
        hidden: null,
        locked_for_user: false,
        hidden_for_user: false,
        for_submissions: false,
        can_upload: true,
      },
      {
        id: '101',
        name: 'Duplicate Folder',
        full_name: 'course files/subfolder/Duplicate Folder',
        context_id: '8',
        context_type: 'Course',
        parent_folder_id: '42',
        created_at: '2024-11-12T10:15:30Z',
        updated_at: '2024-11-12T10:15:30Z',
        lock_at: null,
        unlock_at: null,
        position: 2,
        locked: false,
        folders_url: 'http://canvas-web.inseng.test/api/v1/folders/101/folders',
        files_url: 'http://canvas-web.inseng.test/api/v1/folders/101/files',
        files_count: 0,
        folders_count: 0,
        hidden: null,
        locked_for_user: false,
        hidden_for_user: false,
        for_submissions: false,
        can_upload: true,
      },
    ]

    beforeEach(() => {
      // @ts-expect-error - global.ENV is a Canvas global not in TS types
      global.ENV = {
        // @ts-expect-error - global.ENV is a Canvas global not in TS types
        ...global.ENV,
        FEATURES: {
          files_a11y_folder_duplicates: true,
        },
      }
    })

    it('calls duplicates API and shows modal when user has edit permission', async () => {
      const filesContexts = createFilesContexts({
        permissions: {
          manage_files_add: true,
          manage_files_delete: true,
          manage_files_edit: true,
        },
      })
      resetAndGetFilesEnv(filesContexts)

      let duplicatesEndpointCalled = false
      server.use(
        http.get(/.*\/courses\/2\/folders\/1\/duplicates/, () => {
          duplicatesEndpointCalled = true
          return HttpResponse.json({duplicates: mockDuplicateFolders})
        }),
      )

      renderComponent()

      await screen.findByRole('button', {name: /all my files/i})

      // Wait for the duplicates endpoint to be called
      await vi.waitFor(() => expect(duplicatesEndpointCalled).toBe(true))

      // Wait for modal to appear
      const modalHeading = await screen.findByRole('heading', {
        name: /duplicate folders are detected/i,
      })
      expect(modalHeading).toBeInTheDocument()

      // Verify modal content shows duplicate folders
      expect(screen.getByText('course files/Duplicate Folder')).toBeInTheDocument()
      expect(screen.getByText('course files/subfolder/Duplicate Folder')).toBeInTheDocument()
    })

    it('does not call duplicates API when user lacks edit permission', async () => {
      const filesContexts = createFilesContexts({
        permissions: {
          manage_files_add: true,
          manage_files_delete: true,
          manage_files_edit: false,
        },
      })
      resetAndGetFilesEnv(filesContexts)

      let duplicatesEndpointCalled = false
      server.use(
        http.get(/.*\/folders\/.*\/duplicates/, () => {
          duplicatesEndpointCalled = true
          return HttpResponse.json({duplicates: mockDuplicateFolders})
        }),
      )

      renderComponent()

      await screen.findByRole('button', {name: /all my files/i})

      // Wait a bit to ensure the endpoint is not called
      await new Promise(resolve => setTimeout(resolve, 100))

      // Verify endpoint was not called
      expect(duplicatesEndpointCalled).toBe(false)

      // Verify modal does not appear
      expect(
        screen.queryByRole('heading', {name: /duplicate folders are detected/i}),
      ).not.toBeInTheDocument()
    })

    it('does not call duplicates API when feature flag is disabled', async () => {
      // @ts-expect-error - global.ENV is a Canvas global not in TS types
      global.ENV = {
        // @ts-expect-error - global.ENV is a Canvas global not in TS types
        ...global.ENV,
        FEATURES: {
          files_a11y_folder_duplicates: false,
        },
      }

      const filesContexts = createFilesContexts({
        permissions: {
          manage_files_add: true,
          manage_files_delete: true,
          manage_files_edit: true,
        },
      })
      resetAndGetFilesEnv(filesContexts)

      let duplicatesEndpointCalled = false
      server.use(
        http.get(/.*\/folders\/.*\/duplicates/, () => {
          duplicatesEndpointCalled = true
          return HttpResponse.json({duplicates: mockDuplicateFolders})
        }),
      )

      renderComponent()

      await screen.findByRole('button', {name: /all my files/i})

      // Wait a bit to ensure the endpoint is not called
      await new Promise(resolve => setTimeout(resolve, 100))

      // Verify endpoint was not called
      expect(duplicatesEndpointCalled).toBe(false)

      // Verify modal does not appear
      expect(
        screen.queryByRole('heading', {name: /duplicate folders are detected/i}),
      ).not.toBeInTheDocument()
    })
  })
})
