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
import {render, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import ModuleItemListSmart, {ModuleItemListSmartProps} from '../ModuleItemListSmart'
import type {ModuleItem} from '../../utils/types'
import {PAGE_SIZE, SHOW_ALL_PAGE_SIZE, MODULE_ITEMS} from '../../utils/constants'

const generateItems = (count: number): ModuleItem[] =>
  Array.from({length: count}, (_, i) => ({
    _id: `mod-item-${i}`,
    id: `item-${i}`,
    url: `/modules/items/${i}`,
    moduleItemUrl: null,
    indent: 0,
    position: i + 1,
    title: `Content ${i}`,
    content: {
      __typename: 'Assignment',
      id: `content-${i}`,
      title: `Content ${i}`,
    },
    masterCourseRestrictions: {
      all: false,
      availabilityDates: false,
      content: false,
      dueDates: false,
      lockDates: false,
      points: false,
      settings: false,
    },
  }))

// Mock the context providers and hooks that the component depends on
const mockContextModule = {
  courseId: 'test-course-id',
  pageSize: 10,
  setModuleCursorState: vi.fn(),
}

const mockModules = {
  getModuleItemsTotalCount: vi.fn((moduleId: string) => {
    if (moduleId === 'mod123') return 50
    if (moduleId === 'mod456') return 150
    return 0
  }),
}

const mockPageState = [1, vi.fn()]

// Mock the hooks
vi.mock('../../hooks/useModuleContext', () => ({
  useContextModule: () => mockContextModule,
}))

vi.mock('../../hooks/queries/useModules', () => ({
  useModules: () => mockModules,
}))

vi.mock('../../hooks/usePageState', () => ({
  usePageState: () => mockPageState,
}))

// Mock the useModuleItems hook
const mockUseModuleItems = vi.fn()
const mockGetModuleItems = vi.fn()
vi.mock('../../hooks/queries/useModuleItems', () => ({
  useModuleItems: (...args: any[]) => mockUseModuleItems(...args),
  getModuleItems: (...args: any[]) => mockGetModuleItems(...args),
}))

// MSW Server setup for mocking GraphQL requests
const server = setupServer(
  // Mock GetModulesQuery to avoid unhandled requests
  graphql.query('GetModulesQuery', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          modulesConnection: {
            edges: [],
            pageInfo: {hasNextPage: false, endCursor: null},
          },
        },
      },
    })
  }),
)

const renderList = ({moduleItems}: {moduleItems: ModuleItem[]}) => (
  <ul data-testid="item-list">
    {moduleItems.map(item => (
      <li key={item.id}>{item.content?.title}</li>
    ))}
  </ul>
)

const buildDefaultProps = (
  overrides: Partial<Omit<ModuleItemListSmartProps, 'renderList'>> = {},
): Omit<ModuleItemListSmartProps, 'renderList'> => ({
  moduleId: 'mod123',
  isExpanded: true,
  view: 'teacher',
  isPaginated: false, // This is the key - Show All mode
  ...overrides,
})

const setup = (
  props: Partial<Omit<ModuleItemListSmartProps, 'renderList'>> = {},
  itemCount = 50,
) => {
  const client = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: Infinity,
      },
    },
  })

  const defaultProps = buildDefaultProps(props)

  // Pre-populate query cache with module item count
  client.setQueryData([MODULE_ITEMS, defaultProps.moduleId], itemCount)

  return render(
    <QueryClientProvider client={client}>
      <ModuleItemListSmart {...defaultProps} renderList={renderList} />
    </QueryClientProvider>,
  )
}

// Helper to create GraphQL response for module items
const createModuleItemsResponse = (
  items: ModuleItem[],
  hasNextPage = false,
  endCursor: string | null = null,
) => ({
  data: {
    legacyNode: {
      moduleItemsConnection: {
        edges: items.map(item => ({node: item})),
        pageInfo: {
          hasNextPage,
          endCursor,
        },
      },
    },
  },
})

describe('ModuleItemListSmart Show All optimization', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'warn'})
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })

  afterAll(() => {
    server.close()
  })

  it.skip('uses larger page size (100) when fetching all items in show-all mode', async () => {
    // Mock getModuleItems to capture call arguments
    mockGetModuleItems.mockResolvedValue({
      moduleItems: generateItems(50),
      pageInfo: {hasNextPage: false, endCursor: null},
    })

    // Mock useModuleItems to return loading initially, then success
    mockUseModuleItems.mockReturnValue({
      data: null,
      isLoading: true,
      error: null,
    })

    const {rerender} = setup()

    // Component should trigger a React Query for all items since isPaginated = false
    await waitFor(() => {
      expect(mockGetModuleItems).toHaveBeenCalled()
    })

    // Verify that getModuleItems was called with the larger page size (100)
    expect(mockGetModuleItems).toHaveBeenCalledWith('mod123', null, 'teacher', SHOW_ALL_PAGE_SIZE)
  })

  it.skip('makes fewer requests when using larger page size with pagination', async () => {
    // Mock multiple calls for pagination scenario
    // First call returns 100 items with more pages
    mockGetModuleItems
      .mockResolvedValueOnce({
        moduleItems: generateItems(100),
        pageInfo: {hasNextPage: true, endCursor: 'cursor1'},
      })
      // Second call returns remaining 50 items
      .mockResolvedValueOnce({
        moduleItems: generateItems(50).map((item, i) => ({
          ...item,
          _id: `mod-item-${i + 100}`,
          id: `item-${i + 100}`,
        })),
        pageInfo: {hasNextPage: false, endCursor: null},
      })

    // Mock for non-paginated mode, total count = 150
    mockModules.getModuleItemsTotalCount.mockReturnValue(150)
    mockUseModuleItems.mockReturnValue({
      data: null,
      isLoading: true,
      error: null,
    })

    setup()

    // Wait for queries to complete
    await waitFor(
      () => {
        expect(mockGetModuleItems).toHaveBeenCalledTimes(2)
      },
      {timeout: 3000},
    )

    // First call should use SHOW_ALL_PAGE_SIZE
    expect(mockGetModuleItems).toHaveBeenNthCalledWith(
      1,
      'mod123',
      null,
      'teacher',
      SHOW_ALL_PAGE_SIZE,
    )

    // Second call should also use SHOW_ALL_PAGE_SIZE with cursor
    expect(mockGetModuleItems).toHaveBeenNthCalledWith(
      2,
      'mod123',
      'cursor1',
      'teacher',
      SHOW_ALL_PAGE_SIZE,
    )
  })
})
