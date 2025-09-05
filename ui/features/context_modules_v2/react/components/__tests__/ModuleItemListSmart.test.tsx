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
import {render, screen, waitFor, waitForElementToBeRemoved} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import ModuleItemListSmart, {ModuleItemListSmartProps} from '../ModuleItemListSmart'
import type {ModuleItem} from '../../utils/types'
import {PAGE_SIZE, MODULE_ITEMS, MODULES, SHOW_ALL_PAGE_SIZE} from '../../utils/constants'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

const server = setupServer(
  http.post('/api/graphql', () => {
    return HttpResponse.json({
      data: {
        legacyNode: {
          moduleItemsConnection: {
            edges: [],
            pageInfo: {
              hasNextPage: false,
              endCursor: null,
            },
          },
        },
      },
    })
  }),
)

const generateItems = (count: number): ModuleItem[] =>
  Array.from({length: count}, (_, i) => ({
    _id: `mod-item-${i}`,
    id: `item-${i}`,
    url: `/modules/items/${i}`,
    moduleItemUrl: 'https://example.com',
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

const renderList = ({moduleItems}: {moduleItems: ModuleItem[]}) => (
  <ul data-testid="item-list">
    {moduleItems.map(item => (
      <li key={item.id}>{item.content?.title}</li>
    ))}
  </ul>
)

const defaultProps = (): Omit<ModuleItemListSmartProps, 'renderList'> => ({
  moduleId: 'mod123',
  isExpanded: true,
  view: 'teacher',
  isPaginated: true,
})

const createModulePage = (itemCount: number = 25) => ({
  pageInfo: {
    hasNextPage: false,
    endCursor: null,
  },
  modules: [
    {
      _id: 'mod123',
      moduleItemsTotalCount: itemCount,
    },
  ],
  getModuleItemsTotalCount: (moduleId: string) => (moduleId === 'mod123' ? itemCount : 0),
  isFetching: false,
})

const renderWithClient = (
  ui: React.ReactElement,
  itemCount: number = 25,
  cursor: string | null = null,
) => {
  const client = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: Infinity,
      },
    },
  })

  client.setQueryData([MODULE_ITEMS, 'mod123', cursor], {
    moduleItems: generateItems(PAGE_SIZE),
  })

  const modulePage = createModulePage(itemCount)

  const modulesData = {
    pages: [modulePage],
    pageParams: [null],
    getModuleItemsTotalCount: modulePage.getModuleItemsTotalCount,
    isFetching: false,
  }

  client.setQueryData([MODULES, 'course123'], modulesData)

  return render(
    <QueryClientProvider client={client}>
      <ContextModuleProvider {...contextModuleDefaultProps} courseId="course123">
        {ui}
      </ContextModuleProvider>
    </QueryClientProvider>,
  )
}

describe('ModuleItemListSmart', () => {
  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    localStorage.clear()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('renders paginated items and shows pagination UI when needed', async () => {
    const itemCount = 25 // PAGE_SIZE = 10, so this gives 3 pages
    renderWithClient(<ModuleItemListSmart {...defaultProps()} renderList={renderList} />, itemCount)

    await screen.findByTestId('item-list')
    if (screen.queryByTestId('loading')) {
      await waitForElementToBeRemoved(() => screen.getByTestId('loading'))
    }

    const summary = await screen.findByTestId('pagination-info-text')
    expect(summary).toHaveTextContent(`Showing 1-10 of ${itemCount} items`)

    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent(/all module items loaded/i)
  })

  it('navigates to the next page and updates visible items', async () => {
    const itemCount = PAGE_SIZE * 2
    const firstPageItems = generateItems(PAGE_SIZE)
    const secondPageItems = generateItems(PAGE_SIZE).map((item, i) => ({
      ...item,
      id: `item-${i + PAGE_SIZE}`,
      content: {
        ...item.content,
        title: `Content ${i + PAGE_SIZE}`,
      },
    }))

    const client = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          staleTime: Infinity,
        },
      },
    })
    const user = userEvent.setup()

    // Set up module items for both pages
    client.setQueryData([MODULE_ITEMS, 'mod123', null], {
      moduleItems: firstPageItems,
    })
    client.setQueryData([MODULE_ITEMS, 'mod123', btoa(String(PAGE_SIZE))], {
      moduleItems: secondPageItems,
    })

    const modulePage = createModulePage(itemCount)

    client.setQueryData([MODULES, 'course123'], {
      pages: [modulePage],
      pageParams: [null],
      getModuleItemsTotalCount: modulePage.getModuleItemsTotalCount,
      isFetching: false,
    })

    render(
      <QueryClientProvider client={client}>
        <ContextModuleProvider {...contextModuleDefaultProps} courseId="course123">
          <ModuleItemListSmart {...defaultProps()} isPaginated={true} renderList={renderList} />
        </ContextModuleProvider>
      </QueryClientProvider>,
    )

    expect(await screen.findByText('Content 0')).toBeInTheDocument()
    expect(
      await screen.findByText(`Showing 1-${PAGE_SIZE} of ${itemCount} items`),
    ).toBeInTheDocument()

    const pageTwoButton = screen.queryByText('2')?.closest('button')
    expect(pageTwoButton).toBeInTheDocument()
    await user.click(pageTwoButton!)

    await waitFor(() => {
      expect(screen.getByText(`Content ${PAGE_SIZE}`)).toBeInTheDocument()
      expect(
        screen.getByText(`Showing ${PAGE_SIZE + 1}-${PAGE_SIZE * 2} of ${itemCount} items`),
      ).toBeInTheDocument()
    })
  })

  it('renders all items when pagination is not needed', async () => {
    const client = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          staleTime: Infinity,
        },
      },
    })

    // Set up data for the non-paginated query
    client.setQueryData(['MODULE_ITEMS_ALL', 'mod123', 'teacher', SHOW_ALL_PAGE_SIZE], {
      moduleItems: generateItems(PAGE_SIZE),
      pageInfo: {hasNextPage: false, endCursor: null},
    })

    const modulePage = createModulePage(PAGE_SIZE)

    const modulesData = {
      pages: [modulePage],
      pageParams: [null],
      getModuleItemsTotalCount: modulePage.getModuleItemsTotalCount,
      isFetching: false,
    }

    client.setQueryData([MODULES, 'course123'], modulesData)

    render(
      <QueryClientProvider client={client}>
        <ContextModuleProvider {...contextModuleDefaultProps} courseId="course123">
          <ModuleItemListSmart {...defaultProps()} isPaginated={false} renderList={renderList} />
        </ContextModuleProvider>
      </QueryClientProvider>,
    )

    const list = await screen.findByTestId('item-list')
    expect(list.children).toHaveLength(PAGE_SIZE)
    expect(screen.queryByTestId('pagination-info-text')).not.toBeInTheDocument()
  })

  describe('Error handling', () => {
    // this supresses the error message React emits to the console when BadList throws the exception
    let errorListener: (event: ErrorEvent) => void
    let originalError: any
    beforeEach(() => {
      originalError = window.onerror
      window.onerror = () => {
        return true
      }

      errorListener = event => {
        event.preventDefault()
      }
      window.addEventListener('error', errorListener)
    })

    afterEach(() => {
      window.onerror = originalError
      window.removeEventListener('error', errorListener)
    })

    it('renders error fallback if renderList throws', async () => {
      const BadList: React.FC<{moduleItems: ModuleItem[]}> = () => {
        throw new Error('render failure')
      }
      const renderListThatThrows = ({moduleItems}: {moduleItems: ModuleItem[]}) => {
        return <BadList moduleItems={moduleItems} />
      }
      renderWithClient(
        <ModuleItemListSmart {...defaultProps()} renderList={renderListThatThrows} />,
        PAGE_SIZE,
      )
      const alertText = await screen.findByText('An unexpected error occurred.')
      expect(alertText).toBeInTheDocument()
    })
  })

  it('shows loading spinner when data is loading', async () => {
    const client = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
          staleTime: 0,
        },
      },
    })

    const delayedResolve = <T,>(value: T) =>
      new Promise<T>(resolve => setTimeout(() => resolve(value), 50))

    // Set up modules data
    const modulePage = createModulePage(25)

    client.setQueryData([MODULES, 'course123'], {
      pages: [modulePage],
      pageParams: [null],
      getModuleItemsTotalCount: modulePage.getModuleItemsTotalCount,
      isFetching: false,
    })

    client.setQueryDefaults([MODULE_ITEMS, 'mod123', null], {
      queryFn: () =>
        delayedResolve({
          moduleItems: generateItems(PAGE_SIZE),
        }),
    })

    render(
      <QueryClientProvider client={client}>
        <ContextModuleProvider {...contextModuleDefaultProps} courseId="course123">
          <ModuleItemListSmart {...defaultProps()} renderList={renderList} />
        </ContextModuleProvider>
      </QueryClientProvider>,
    )

    await waitFor(() => {
      expect(screen.getByText(/Loading module items/i)).toBeInTheDocument()
    })
  })
})
