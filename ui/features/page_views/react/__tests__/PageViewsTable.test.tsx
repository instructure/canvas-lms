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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {PageViewsTable, type PageViewsTableProps} from '../PageViewsTable'
import {type APIPageView} from '../utils'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

const server = setupServer()
const queryClient = new QueryClient()

// As of this writing, JS-DOM does not implement Intl.DurationFormat, so we will
// expect the component under test to fall back to its manual formatting. Putting
// this check in so that tests don't later fail if/when JS-DOM implements it.
const INTERACTION_TIME = 249 // 4 minutes 9 seconds
// @ts-expect-error
const FORMATTED_TIME = typeof Intl.DurationFormat === 'function' ? '4m 9s' : '4:09'

function Subject(props: PageViewsTableProps): React.JSX.Element {
  return (
    <QueryClientProvider client={queryClient}>
      <PageViewsTable {...props} />
    </QueryClientProvider>
  )
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
})
