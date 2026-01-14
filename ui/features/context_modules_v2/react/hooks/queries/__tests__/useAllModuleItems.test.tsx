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

import {useAllModuleItems, getAllModuleItems} from '../useAllModuleItems'
import * as moduleItemsHook from '../useModuleItems'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {SHOW_ALL_PAGE_SIZE} from '../../../utils/constants'

vi.mock('../useModuleItems', () => ({
  getModuleItems: vi.fn(),
}))
const mockGetModuleItems = moduleItemsHook.getModuleItems as ReturnType<typeof vi.fn>

const moduleId = 'mod-123'
const view = 'teacher'

const node1 = {id: 'item_1'}
const node2 = {id: 'item_2'}
const node3 = {id: 'item_3'}
const node4 = {id: 'item_4'}

const renderUseAllModuleItems = (moduleId: string, enabled = true) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return renderHook(() => useAllModuleItems(moduleId, enabled, view), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    ),
  })
}

describe.skip('useAllModuleItems', () => {
  beforeEach(() => {
    // First page has more items
    mockGetModuleItems.mockResolvedValueOnce({
      moduleItems: [
        {...node1, moduleId, index: 0},
        {...node2, moduleId, index: 1},
      ],
      pageInfo: {
        hasNextPage: true,
        endCursor: 'cursor1',
      },
    })

    // Second page is the last page
    mockGetModuleItems.mockResolvedValueOnce({
      moduleItems: [
        {...node3, moduleId, index: 2},
        {...node4, moduleId, index: 3},
      ],
      pageInfo: {
        hasNextPage: false,
        endCursor: null,
      },
    })
  })
  afterEach(() => {
    mockGetModuleItems.mockReset()
  })

  describe('getAllModuleItems', () => {
    it('fetches all items by paginating through results', async () => {
      const result = await getAllModuleItems(moduleId, view)

      expect(mockGetModuleItems).toHaveBeenCalledTimes(2)
      expect(mockGetModuleItems).toHaveBeenNthCalledWith(
        1,
        moduleId,
        null,
        view,
        SHOW_ALL_PAGE_SIZE,
      )
      expect(mockGetModuleItems).toHaveBeenNthCalledWith(
        2,
        moduleId,
        'cursor1',
        view,
        SHOW_ALL_PAGE_SIZE,
      )

      expect(result.moduleItems).toHaveLength(4)
      expect(result.pageInfo).toEqual({hasNextPage: false, endCursor: null})
    })

    it('handles errors from getModuleItems', async () => {
      const error = new Error('Failed to fetch module items')
      mockGetModuleItems.mockReset()
      mockGetModuleItems.mockRejectedValue(error)

      await expect(getAllModuleItems(moduleId, view)).rejects.toThrow(error)
    })
  })

  describe('the hook', () => {
    afterEach(() => {
      mockGetModuleItems.mockReset()
    })

    it('fetches all module items when enabled', async () => {
      const {result} = renderUseAllModuleItems(moduleId, true)

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(result.current.isError).toBe(false)
      const data = result.current.data
      expect(data).toBeDefined()
      expect(data?.moduleItems).toHaveLength(4)
      expect(data?.pageInfo).toEqual({hasNextPage: false, endCursor: null})
    })

    it('does not query if enabled is false', async () => {
      const {result} = renderUseAllModuleItems(moduleId, false)

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(mockGetModuleItems).not.toHaveBeenCalled()
    })

    it('handles errors properly', async () => {
      mockGetModuleItems.mockReset()
      mockGetModuleItems.mockImplementation(() => {
        throw new Error('Failed to fetch')
      })
      const {result} = renderUseAllModuleItems(moduleId, true)

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      expect(result.current.isError).toBe(true)

      expect(result.current.error).toBeDefined()
    })
  })
})
