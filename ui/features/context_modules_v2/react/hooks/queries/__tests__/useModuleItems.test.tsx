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

import {useModuleItems} from '../useModuleItems'
import {renderHook} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'
import {waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import * as alerts from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashError: jest.fn(),
}))

const mockShowFlashError = alerts.showFlashError as jest.Mock

const moduleId = 'mod-123'
const errorMsg = 'Boom'

const node1 = {id: 'item_1'}
const node2 = {id: 'item_2'}

const endPageInfo = {
  hasNextPage: false,
  endCursor: null,
}

const mockGqlSuccessResponse = {
  legacyNode: {
    moduleItemsConnection: {
      edges: [{node: node1}, {node: node2}],
      pageInfo: endPageInfo,
    },
  },
}

const server = setupServer()

const renderUseModuleItems = (moduleId: string, enabled = true) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return renderHook(() => useModuleItems(moduleId, null, enabled), {
    wrapper: ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    ),
  })
}

describe('useModuleItems', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    mockShowFlashError.mockClear()
  })
  afterAll(() => server.close())

  it('fetches and transforms module items', async () => {
    server.use(
      graphql.query('GetModuleItemsQuery', ({variables}) => {
        expect(variables.moduleId).toBe(moduleId)
        return HttpResponse.json({data: {...mockGqlSuccessResponse}})
      }),
    )

    const {result} = renderUseModuleItems(moduleId)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(result.current.isError).toBe(false)
    const data = result.current.data
    expect(data).toBeDefined()
    expect(data?.moduleItems).toHaveLength(2)
    expect(data?.moduleItems[0]).toMatchObject({id: 'item_1', moduleId, index: 0})
    expect(data?.moduleItems[1]).toMatchObject({id: 'item_2', moduleId, index: 1})
    expect(data?.pageInfo).toEqual(endPageInfo)
  })

  it('shows flash error when query fails (network error)', async () => {
    server.use(
      graphql.query('GetModuleItemsQuery', ({variables}) => {
        expect(variables.moduleId).toBe('mod-500')
        return variables.networkError('Failed to connect')
      }),
    )
    const {result} = renderUseModuleItems('mod-500')

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
    })

    expect(mockShowFlashError).toHaveBeenCalledWith(
      expect.stringContaining('Failed to load module items'),
    )
  })

  it('shows flash error when response contains errors', async () => {
    server.use(
      graphql.query('GetModuleItemsQuery', () => {
        return HttpResponse.json({
          errors: [{message: errorMsg}],
        })
      }),
    )

    const {result} = renderUseModuleItems('mod-500')

    await waitFor(() => {
      expect(result.current.isError).toBe(true)
    })

    expect(mockShowFlashError).toHaveBeenCalledWith(
      expect.stringContaining('Failed to load module items'),
    )
  })

  it('does not query if enabled is false', async () => {
    let wasCalled = false
    server.use(
      graphql.query('GetModuleItemsQuery', () => {
        wasCalled = true
        return HttpResponse.json({data: {...mockGqlSuccessResponse}})
      }),
    )

    const {result} = renderUseModuleItems('mod-789', false)

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })

    expect(wasCalled).toBe(false)
    expect(result.current.data).toBeUndefined()
  })
})
