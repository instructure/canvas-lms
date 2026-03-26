/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {MemoryRouter} from 'react-router-dom'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {TermFilter} from '../TermFilter'

const server = setupServer()
const accountId = '123'

const PAST_DATE = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
const FUTURE_DATE = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()

const MOCK_TERMS = {
  enrollment_terms: [
    {id: '1', name: 'Spring 2026', start_at: PAST_DATE, end_at: null, used_in_subaccount: true},
    {id: '2', name: 'Fall 2026', start_at: FUTURE_DATE, end_at: null, used_in_subaccount: true},
    {id: '3', name: 'Summer 2025', start_at: null, end_at: PAST_DATE, used_in_subaccount: true},
  ],
}

describe('TermFilter', () => {
  let queryClient: QueryClient

  beforeAll(() => server.listen())

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
      },
    })
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })

  afterAll(() => server.close())

  const renderTermFilter = (props: {value?: string; onChange?: (id: string) => void} = {}) => {
    const onChange = props.onChange ?? vi.fn()
    const value = props.value ?? ''

    return render(
      <MemoryRouter>
        <QueryClientProvider client={queryClient}>
          <TermFilter accountId={accountId} value={value} onChange={onChange} />
        </QueryClientProvider>
      </MemoryRouter>,
    )
  }

  const openDropdown = async (user: ReturnType<typeof userEvent.setup>) => {
    const input = screen.getByRole('combobox')
    await user.click(input)
  }

  it('renders with the placeholder text when no value is selected', () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () =>
        HttpResponse.json({enrollment_terms: []}),
      ),
    )

    renderTermFilter()

    expect(screen.getByPlaceholderText('Filter by term')).toBeInTheDocument()
  })

  it('shows a spinner while terms are loading', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, async () => {
        await new Promise(resolve => setTimeout(resolve, 200))
        return HttpResponse.json(MOCK_TERMS)
      }),
    )

    const user = userEvent.setup()
    renderTermFilter()

    // Open the dropdown while the request is still in-flight
    const input = screen.getByRole('combobox')
    await user.click(input)

    await waitFor(() => {
      expect(screen.getByTitle('Loading terms...')).toBeInTheDocument()
    })
  })

  it('renders the "All terms" option under "Show courses from" group', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () =>
        HttpResponse.json({enrollment_terms: []}),
      ),
    )

    const user = userEvent.setup()
    renderTermFilter()

    await openDropdown(user)

    await waitFor(() => {
      expect(screen.getByText('Show courses from')).toBeInTheDocument()
      expect(screen.getByText('All terms')).toBeInTheDocument()
    })
  })

  it('renders an "Active Terms" group with active terms', async () => {
    server.use(http.get(`/api/v1/accounts/${accountId}/terms`, () => HttpResponse.json(MOCK_TERMS)))

    const user = userEvent.setup()
    renderTermFilter()

    await openDropdown(user)

    await waitFor(() => {
      expect(screen.getByText('Active Terms')).toBeInTheDocument()
      expect(screen.getByText('Spring 2026')).toBeInTheDocument()
    })
  })

  it('renders a "Future Terms" group only when future terms exist', async () => {
    server.use(http.get(`/api/v1/accounts/${accountId}/terms`, () => HttpResponse.json(MOCK_TERMS)))

    const user = userEvent.setup()
    renderTermFilter()

    await openDropdown(user)

    await waitFor(() => {
      expect(screen.getByText('Future Terms')).toBeInTheDocument()
      expect(screen.getByText('Fall 2026')).toBeInTheDocument()
    })
  })

  it('does not render a "Future Terms" group when no future terms exist', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () =>
        HttpResponse.json({
          enrollment_terms: [
            {
              id: '1',
              name: 'Spring 2026',
              start_at: PAST_DATE,
              end_at: null,
              used_in_subaccount: true,
            },
          ],
        }),
      ),
    )

    const user = userEvent.setup()
    renderTermFilter()

    await openDropdown(user)

    await waitFor(() => {
      expect(screen.getByText('Spring 2026')).toBeInTheDocument()
    })

    expect(screen.queryByText('Future Terms')).not.toBeInTheDocument()
  })

  it('renders a "Past Terms" group only when past terms exist', async () => {
    server.use(http.get(`/api/v1/accounts/${accountId}/terms`, () => HttpResponse.json(MOCK_TERMS)))

    const user = userEvent.setup()
    renderTermFilter()

    await openDropdown(user)

    await waitFor(() => {
      expect(screen.getByText('Past Terms')).toBeInTheDocument()
      expect(screen.getByText('Summer 2025')).toBeInTheDocument()
    })
  })

  it('does not render a "Past Terms" group when no past terms exist', async () => {
    server.use(
      http.get(`/api/v1/accounts/${accountId}/terms`, () =>
        HttpResponse.json({
          enrollment_terms: [
            {
              id: '1',
              name: 'Spring 2026',
              start_at: PAST_DATE,
              end_at: null,
              used_in_subaccount: true,
            },
          ],
        }),
      ),
    )

    const user = userEvent.setup()
    renderTermFilter()

    await openDropdown(user)

    await waitFor(() => {
      expect(screen.getByText('Spring 2026')).toBeInTheDocument()
    })

    expect(screen.queryByText('Past Terms')).not.toBeInTheDocument()
  })

  it('calls onChange with the term id when a term is selected', async () => {
    const onChange = vi.fn()

    server.use(http.get(`/api/v1/accounts/${accountId}/terms`, () => HttpResponse.json(MOCK_TERMS)))

    const user = userEvent.setup()
    renderTermFilter({onChange})

    await openDropdown(user)

    const option = await screen.findByText('Spring 2026')
    await user.click(option)

    expect(onChange).toHaveBeenCalledWith('1')
  })

  it('calls onChange with an empty string when "All terms" is selected', async () => {
    const onChange = vi.fn()

    server.use(http.get(`/api/v1/accounts/${accountId}/terms`, () => HttpResponse.json(MOCK_TERMS)))

    const user = userEvent.setup()
    renderTermFilter({onChange})

    await openDropdown(user)

    const allTermsOption = await screen.findByText('All terms')
    await user.click(allTermsOption)

    expect(onChange).toHaveBeenCalledWith('')
  })

  it('filters options to show only matches when the user types', async () => {
    server.use(http.get(`/api/v1/accounts/${accountId}/terms`, () => HttpResponse.json(MOCK_TERMS)))

    const user = userEvent.setup()
    renderTermFilter()

    const input = screen.getByRole('combobox')
    await user.click(input)

    // Wait for all options to be available before filtering
    await screen.findByText('Spring 2026')

    await user.type(input, 'Spring')

    await waitFor(() => {
      expect(screen.getByText('Spring 2026')).toBeInTheDocument()
    })

    expect(screen.queryByText('Fall 2026')).not.toBeInTheDocument()
    expect(screen.queryByText('Summer 2025')).not.toBeInTheDocument()
  })

  it('shows "No matches" when the typed filter matches nothing', async () => {
    server.use(http.get(`/api/v1/accounts/${accountId}/terms`, () => HttpResponse.json(MOCK_TERMS)))

    const user = userEvent.setup()
    renderTermFilter()

    const input = screen.getByRole('combobox')
    await user.click(input)

    // Wait until terms are loaded before typing
    await screen.findByText('Spring 2026')

    await user.type(input, 'xyzzy')

    await waitFor(() => {
      expect(screen.getByText('No matches')).toBeInTheDocument()
    })
  })

  it('updates the displayed value when value prop changes to a different term id', async () => {
    server.use(http.get(`/api/v1/accounts/${accountId}/terms`, () => HttpResponse.json(MOCK_TERMS)))

    const {rerender} = render(
      <MemoryRouter>
        <QueryClientProvider client={queryClient}>
          <TermFilter accountId={accountId} value="1" onChange={vi.fn()} />
        </QueryClientProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      const input = screen.getByRole('combobox') as HTMLInputElement
      expect(input.value).toBe('Spring 2026')
    })

    rerender(
      <MemoryRouter>
        <QueryClientProvider client={queryClient}>
          <TermFilter accountId={accountId} value="3" onChange={vi.fn()} />
        </QueryClientProvider>
      </MemoryRouter>,
    )

    await waitFor(() => {
      const input = screen.getByRole('combobox') as HTMLInputElement
      expect(input.value).toBe('Summer 2025')
    })
  })
})
