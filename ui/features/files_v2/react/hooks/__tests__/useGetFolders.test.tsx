/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {renderHook} from '@testing-library/react-hooks'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {useGetFolders} from '../useGetFolders'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {resetAndGetFilesEnv} from '../../../utils/filesEnvUtils'
import {FileContext} from '@canvas/files_v2/react/modules/filesEnvFactory.types'
import {useParams} from 'react-router-dom'

const server = setupServer()

// Mock the useParams hook
vi.mock('react-router-dom', async () => ({
  ...(await vi.importActual('react-router-dom')),
  useParams: vi.fn().mockReturnValue({
    context: '',
    '*': '',
  }),
}))

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
})

const wrapper = ({children}: {children: React.ReactNode}) => (
  <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
)

const USER_FILES_CONTEXT: FileContext[] = [
  {
    contextType: 'users',
    contextId: '1',
    root_folder_id: '2',
    asset_string: 'user_1',
    permissions: {},
    name: 'My Files',
  },
]
const mockFolders = [{id: 2, name: 'Folder 1', context_id: 1, context_type: 'User'}]
const mockSubfolders = [
  {id: 2, name: 'Folder 1', context_id: 1, context_type: 'User'},
  {id: 3, name: 'profile pictrues', context_id: 1, context_type: 'User'},
]

describe('useGetFolders', () => {
  let requestMade = false

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    requestMade = false
    server.use(
      http.get(/\/folders\/by_path/, () => {
        requestMade = true
        return HttpResponse.json(mockFolders)
      }),
    )
    resetAndGetFilesEnv(USER_FILES_CONTEXT)
    ;(useParams as any).mockReturnValue({
      context: 'users_1',
      '*': '',
    })
  })

  afterEach(() => {
    server.resetHandlers()
    requestMade = false
  })

  it('returns root folder without fetching', async () => {
    const {result, waitForNextUpdate} = renderHook(() => useGetFolders(), {
      wrapper,
    })
    await waitForNextUpdate()

    expect(requestMade).toBe(false)
    expect(result.current.data).toHaveLength(1)
    expect(result.current.data?.[0]).toMatchObject({
      id: '2',
      context_id: '1',
      context_type: 'user',
    })
  })

  it('fetches root folder when there is no root_context_id in files context', async () => {
    const ROOTLESS_CONTEXT: FileContext = {...USER_FILES_CONTEXT[0]}
    ROOTLESS_CONTEXT.root_folder_id = ''
    resetAndGetFilesEnv([ROOTLESS_CONTEXT])

    const {result, waitForNextUpdate} = renderHook(() => useGetFolders(), {
      wrapper,
    })
    await waitForNextUpdate()

    expect(requestMade).toBe(true)
    expect(result.current.data).toHaveLength(1)
    expect(result.current.data).toMatchObject(mockFolders)
  })

  describe('in a subfolder', () => {
    beforeEach(() => {
      server.use(
        http.get(/\/folders\/by_path/, () => {
          requestMade = true
          return HttpResponse.json(mockSubfolders)
        }),
      )
      ;(useParams as any).mockReturnValue({
        context: 'users_1',
        '*': 'profile pictures',
      })
    })

    it('fetches folders', async () => {
      const {result, waitForNextUpdate} = renderHook(() => useGetFolders(), {
        wrapper,
      })
      await waitForNextUpdate()

      expect(requestMade).toBe(true)
      expect(result.current.data).toHaveLength(2)
      expect(result.current.data).toMatchObject(mockSubfolders)
    })
  })
})
