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
import {render, screen, waitFor, waitForElementToBeRemoved, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {graphql, HttpResponse} from 'msw'
import ModuleItemListSmart, {ModuleItemListSmartProps} from '../ModuleItemListSmart'
import type {ModuleItem} from '../../utils/types'
import {
  PAGE_SIZE,
  MODULE_ITEMS,
  MODULES,
  SHOW_ALL_PAGE_SIZE,
  MODULE_ITEMS_ALL,
} from '../../utils/constants'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'

const generateItems = (count: number, start: number = 0): ModuleItem[] =>
  Array.from({length: count}, (_, i) => ({
    _id: `mod-item-${i + start}`,
    id: `item-${i + start}`,
    url: `/modules/items/${i + start}`,
    moduleItemUrl: 'https://example.com',
    indent: 0,
    position: i + 1,
    title: `Content ${i + start}`,
    content: {
      __typename: 'Assignment',
      id: `content-${i + start}`,
      title: `Content ${i + start}`,
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
  afterEach(() => {
    localStorage.clear()
  })

  describe('rendering', () => {
    it('renders paginated items and shows pagination UI when needed', async () => {
      const itemCount = 25 // PAGE_SIZE = 10, so this gives 3 pages
      renderWithClient(
        <ModuleItemListSmart {...defaultProps()} renderList={renderList} />,
        itemCount,
      )

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
      const secondPageItems = generateItems(PAGE_SIZE, PAGE_SIZE)

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

      await waitFor(() => {
        expect(screen.getByText('Content 0')).toBeInTheDocument()
        expect(screen.getByText(`Showing 1-${PAGE_SIZE} of ${itemCount} items`)).toBeInTheDocument()
      })

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

      const items1 = generateItems(PAGE_SIZE)
      const items2 = generateItems(PAGE_SIZE, PAGE_SIZE)
      // Set up data for the non-paginated query
      client.setQueryData([MODULE_ITEMS_ALL, 'mod123', 'teacher', SHOW_ALL_PAGE_SIZE], {
        moduleItems: items1.concat(items2),
        pageInfo: {hasNextPage: false, endCursor: null},
      })
      client.setQueryData([MODULE_ITEMS, 'mod123', null], {
        moduleItems: items1,
      })
      client.setQueryData([MODULE_ITEMS, 'mod123', btoa(String(PAGE_SIZE))], {
        moduleItems: items2,
      })

      const modulePage = createModulePage(PAGE_SIZE * 2)

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
      expect(list.children).toHaveLength(PAGE_SIZE * 2)
      expect(screen.queryByTestId('pagination-info-text')).not.toBeInTheDocument()
    })

    describe('loading', () => {
      let server: ReturnType<typeof setupServer>
      beforeAll(() => {
        server = setupServer(
          graphql.query('GetModuleItemsQuery', () => {
            return new Promise(resolve => {
              setTimeout(() => {
                resolve(
                  HttpResponse.json({
                    data: {
                      legacyNode: {
                        moduleItems: [],
                      },
                    },
                  }),
                )
              }, 50)
            })
          }),
        )
        server.listen()
      })

      afterAll(() => {
        server.close()
      })

      it('shows loading spinner when data is loading', async () => {
        // Set up modules data
        const client = new QueryClient({
          defaultOptions: {
            queries: {
              retry: false,
              staleTime: Infinity,
            },
          },
        })
        const modulePage = createModulePage(25)
        client.setQueryData([MODULES, 'course123'], {
          pages: [modulePage],
          pageParams: [null],
          getModuleItemsTotalCount: modulePage.getModuleItemsTotalCount,
          isFetching: false,
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

  describe('Module page navigation events', () => {
    let client: QueryClient
    let itemCount: number

    beforeEach(() => {
      client = new QueryClient({
        defaultOptions: {
          queries: {
            retry: false,
            staleTime: Infinity,
          },
        },
      })

      // Build 2 pages of items
      itemCount = PAGE_SIZE * 2 - 2
      const firstPageItems = generateItems(PAGE_SIZE)
      client.setQueryData([MODULE_ITEMS, 'mod123', null], {
        moduleItems: firstPageItems,
      })

      const secondPageItems = generateItems(PAGE_SIZE, PAGE_SIZE)
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
    })

    it('navigates to page the page specified in the event', async () => {
      render(
        <QueryClientProvider client={client}>
          <ContextModuleProvider {...contextModuleDefaultProps} courseId="course123">
            <ModuleItemListSmart {...defaultProps()} isPaginated={true} renderList={renderList} />
          </ContextModuleProvider>
        </QueryClientProvider>,
      )

      // The first page is rendered
      await waitFor(() => {
        expect(screen.getByText('Content 0')).toBeInTheDocument()
        expect(screen.getByText(`Showing 1-${PAGE_SIZE} of ${itemCount} items`)).toBeInTheDocument()
      })

      // navigate to page 2
      fireEvent(
        document,
        new CustomEvent('module-page-navigation', {
          detail: {
            moduleId: 'mod123',
            pageNumber: 2,
          },
        }),
      )

      // Verify that we navigated to page 2
      await waitFor(() => {
        expect(screen.getByText(`Content ${PAGE_SIZE}`)).toBeInTheDocument()
        expect(
          screen.getByText(`Showing ${PAGE_SIZE + 1}-${itemCount} of ${itemCount} items`),
        ).toBeInTheDocument()
      })
    })

    it('ignores module-page-navigation events for different module IDs', async () => {
      render(
        <QueryClientProvider client={client}>
          <ContextModuleProvider {...contextModuleDefaultProps} courseId="course123">
            <ModuleItemListSmart {...defaultProps()} isPaginated={true} renderList={renderList} />
          </ContextModuleProvider>
        </QueryClientProvider>,
      )

      // Wait for the first page to render
      await waitFor(() => {
        expect(screen.getByText('Content 0')).toBeInTheDocument()
      })

      // Initial page should be page 1
      await waitFor(() => {
        expect(screen.getByText(`Showing 1-${PAGE_SIZE} of ${itemCount} items`)).toBeInTheDocument()
      })

      // Dispatch a custom event for a different module ID
      fireEvent(
        document,
        new CustomEvent('module-page-navigation', {
          detail: {
            moduleId: 'different-module-id',
            pageNumber: 2,
          },
        }),
      )

      // Wait a moment to ensure any async operations would have completed
      await new Promise(resolve => setTimeout(resolve, 50))

      // Verify we're still on page 1 (no change)
      expect(screen.getByText('Content 0')).toBeInTheDocument()
      expect(screen.getByText(`Showing 1-${PAGE_SIZE} of ${itemCount} items`)).toBeInTheDocument()
    })
  })
})
