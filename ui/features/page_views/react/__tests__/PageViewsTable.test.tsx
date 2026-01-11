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
import {cleanup, render, screen, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {PageViewsTable, type PageViewsTableProps} from '../PageViewsTable'
import {type APIPageView} from '../utils'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

const server = setupServer()
const queryClient = new QueryClient()

afterEach(() => {
  cleanup()
})

// Helper function to create reusable pagination mock
function createPaginationMock(
  userId: string,
  options: {
    maxPages?: number
    onRequest?: (requestCount: number, url: URL) => void
  } = {},
) {
  const {maxPages = 3, onRequest} = options
  const capturedUrls: string[] = []
  let requestCount = 0

  const resolver = http.get(`/api/v1/users/:userId/page_views`, ({params, request}) => {
    if (params.userId !== userId) return // Only handle requests for this userId

    requestCount++
    capturedUrls.push(request.url)

    const url = new URL(request.url)
    const perPage = Number(url.searchParams.get('per_page'))

    // Allow tests to inspect request details
    onRequest?.(requestCount, url)

    let nextLinkHeader = {}
    if (requestCount < maxPages) {
      const nextPageBookmark = btoa(`bookmark:${requestCount + 1}`)
      nextLinkHeader = {
        Link: `<${url.origin}${url.pathname}?page=${nextPageBookmark}>; rel="next"`,
      }
    }

    return HttpResponse.json(generatePageViews(perPage), {headers: nextLinkHeader})
  })

  return {resolver, capturedUrls, getRequestCount: () => requestCount}
}

// As of this writing, JS-DOM does not implement Intl.DurationFormat, so we will
// expect the component under test to fall back to its manual formatting. Putting
// this check in so that tests don't later fail if/when JS-DOM implements it.
const INTERACTION_TIME = 249 // 4 minutes 9 seconds
const FORMATTED_TIME = typeof Intl.DurationFormat === 'function' ? '4m 9s' : '4:09'

function Subject(props: PageViewsTableProps): React.JSX.Element {
  return (
    <QueryClientProvider client={queryClient}>
      <PageViewsTable {...props} />
    </QueryClientProvider>
  )
}

function generatePageViews(count: number): APIPageView[] {
  const views: APIPageView[] = []
  for (let i = 0; i < count; i++) {
    views.push({
      id: crypto.randomUUID(),
      app_name: null,
      http_method: 'get',
      created_at: new Date(Date.now() - i * Math.random() * 60000).toISOString(),
      participated: Math.random() < 0.5,
      interaction_seconds: Math.floor(Math.random() * 300),
      user_agent:
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      url: `http://example.com/page${i}`,
    })
  }
  return views
}

const sample1: APIPageView[] = [
  {
    id: '1',
    app_name: null,
    http_method: 'get',
    created_at: '2024-01-01T12:00:00Z',
    participated: false,
    interaction_seconds: 5,
    user_agent:
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    url: 'http://example.com',
  },
]

const sample2: APIPageView[] = [
  {
    id: '1',
    app_name: null,
    http_method: 'get',
    created_at: '2024-01-01T12:00:00Z',
    participated: false,
    interaction_seconds: INTERACTION_TIME,
    user_agent:
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    url: 'http://example.com',
  },
]

describe('PageViewsTable', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  it('renders the spinner while waiting for the API return', () => {
    const id = '122'
    server.use(http.get(`/api/v1/users/${id}/page_views`, () => HttpResponse.json(sample1)))
    const {getByLabelText} = render(<Subject userId={id} />)
    const spinner = getByLabelText('Loading')
    expect(spinner).toBeInTheDocument()
  })

  it('renders a table from the API data', async () => {
    const id = '123'
    server.use(http.get(`/api/v1/users/${id}/page_views`, () => HttpResponse.json(sample1)))
    const {findByTestId, getByTestId} = render(<Subject userId={id} />)
    expect(await findByTestId('page-views-table-body')).toBeInTheDocument()
    const cells = getByTestId('page-view-row').querySelectorAll('td')
    expect(cells[0]).toHaveTextContent('http://example.com')
    expect(cells[1]).toHaveTextContent('Jan 1,')
    expect(cells[3]).toHaveTextContent('—')
    expect(cells[4]).toHaveTextContent('Chrome 131.0')
  })

  it('properly formats the interaction time', async () => {
    const id = '124'
    server.use(http.get(`/api/v1/users/${id}/page_views`, () => HttpResponse.json(sample2)))
    const {findByTestId, getByTestId} = render(<Subject userId={id} />)
    expect(await findByTestId('page-views-table-body')).toBeInTheDocument()
    const time = getByTestId('page-view-row').querySelector('td:nth-child(4)')
    expect(time).toHaveTextContent(FORMATTED_TIME)
  })

  it('shows the full user agent string in a tooltip', async () => {
    const id = '125'
    server.use(http.get(`/api/v1/users/${id}/page_views`, () => HttpResponse.json(sample1)))
    const {findByTestId, getByTestId} = render(<Subject userId={id} />)
    expect(await findByTestId('page-views-table-body')).toBeInTheDocument()
    const agentTip = screen.getByText(sample1[0].user_agent)
    const agent = getByTestId('page-view-row').querySelector('td:nth-child(5)')
    await waitFor(() => expect(agent).toBeInTheDocument())
    expect(agentTip).toBeInTheDocument()
  })

  it('passes along the date range to the API when one is provided', async () => {
    const id = '126'
    let capturedUrl = ''
    server.use(
      http.get(`/api/v1/users/${id}/page_views`, ({request}) => {
        capturedUrl = request.url
        return HttpResponse.json(sample1)
      }),
    )
    render(
      <Subject userId={id} startDate={new Date('2024-01-01')} endDate={new Date('2024-01-02')} />,
    )
    await waitFor(() => expect(capturedUrl).toBeTruthy())
    expect(capturedUrl).toMatch(/start_time=2024-01-01/)
    expect(capturedUrl).toMatch(/end_time=2024-01-02/)
  })

  describe('pagination', () => {
    it('renders pagination component with correct buttons', async () => {
      // arrange
      const id = '127'
      const {resolver} = createPaginationMock(id, {maxPages: 2})
      server.use(resolver)

      // act
      const {findByTestId, findByText} = render(<Subject userId={id} pageSize={100} />)

      // assert - pagination renders with correct buttons
      await findByTestId('page-views-table-body')
      await waitFor(async () => {
        expect(await findByText('1')).toBeInTheDocument() // Current page
        expect(await findByText('2+')).toBeInTheDocument() // Next page indicator
      })
    })

    it('navigates to next page when pagination button is clicked', async () => {
      // arrange
      const id = '128'
      const {resolver} = createPaginationMock(id, {maxPages: 3})
      server.use(resolver)

      // act
      const {findByTestId, findByText, queryByText} = render(<Subject userId={id} pageSize={100} />)

      // assert - wait for first page to load
      await findByTestId('page-views-table-body')
      await waitFor(async () => {
        expect(await findByText('1')).toBeInTheDocument() // Page 1 button
        expect(await findByText('2+')).toBeInTheDocument() // Page 2+ indicator
      })

      // act - click page 2 button
      const page2Button = await findByText('2+')
      page2Button.click()

      // assert - should navigate to page 2 (component integration test)
      await waitFor(async () => {
        expect(queryByText('2+')).not.toBeInTheDocument() // 2+ indicator should be gone
        expect(await findByText('2')).toBeInTheDocument() // Now showing page 2 as current
      })
    })

    it('shows empty state when API returns no data', async () => {
      // arrange
      const id = '130'
      const onEmpty = vi.fn()
      server.use(
        http.get(`/api/v1/users/:userId/page_views`, ({params}) => {
          if (params.userId !== id) return
          return HttpResponse.json([]) // Return empty array (no page views)
        }),
      )

      // act
      const {findByTestId} = render(<Subject userId={id} pageSize={100} onEmpty={onEmpty} />)

      // assert - should show empty state UI
      await findByTestId('page-views-empty-state')
      expect(onEmpty).toHaveBeenCalledTimes(1)
    })
  })
})
