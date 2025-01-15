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
import {render, screen, waitFor} from '@testing-library/react'
import FilesApp from '../FilesApp'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {QueryClient} from '@tanstack/react-query'
import fetchMock from 'fetch-mock'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import {setupFilesEnv} from '../../../fixtures/fakeFilesEnv'
import {createMemoryRouter, RouterProvider} from 'react-router-dom'
import {FAKE_FOLDERS} from '../../../fixtures/fakeData'

describe('FilesApp', () => {
  beforeEach(() => {
    setupFilesEnv()
    fetchMock.get(/.*\/by_path/, [FAKE_FOLDERS[0]], {overwriteRoutes: true})
    fetchMock.get(/.*\/all/, [], {overwriteRoutes: true})
    fetchMock.get(/.*\/files\/quota/, {quota_used: 500, quota: 1000}, {overwriteRoutes: true})
    filesEnv.userHasPermission = jest.fn().mockReturnValue(true)
  })

  afterEach(() => {
    fetchMock.resetHistory()
  })

  const renderComponent = (contextAssetString: string) => {
    const queryClient = new QueryClient()
    const router = createMemoryRouter(
      [
        {
          path: '/',
          element: <FilesApp contextAssetString={contextAssetString} />,
          loader: async () => {
            return [{id: 1, context_id: 1, context_type: 'course'}]
          },
        },
      ],
      {initialEntries: ['/']}
    )
    return render(
      <MockedQueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </MockedQueryClientProvider>
    )
  }

  it('renders "Files" when contextAssetString starts with "course_"', async () => {
    renderComponent('course_12345')

    const headingElement = await screen.findByText('Files', {exact: true})
    expect(headingElement).toBeInTheDocument()
  })

  it('renders "All My Files" when contextAssetString starts with "user_"', async () => {
    renderComponent('user_67890')

    const headingElement = await screen.findByText(/All My Files/i)
    expect(headingElement).toBeInTheDocument()
  })

  it('does not render progress bar without permission', async () => {
    filesEnv.userHasPermission = jest.fn().mockReturnValue(false)
    renderComponent('course_12345')

    await waitFor(() => {
      expect(fetchMock.calls().length).toBe(1)
      expect(fetchMock.calls()[0][0]).not.toContain('/files/quota')
    })
  })
})
