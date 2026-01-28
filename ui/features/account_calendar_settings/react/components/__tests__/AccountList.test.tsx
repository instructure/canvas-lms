/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act, render, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import {AccountList, type ComponentProps} from '../AccountList'
import {FilterType} from '../FilterControls'
import {RESPONSE_ACCOUNT_3, RESPONSE_ACCOUNT_4} from './fixtures'
import {alertForMatchingAccounts} from '@canvas/calendar/AccountCalendarsUtils'

vi.mock('@canvas/calendar/AccountCalendarsUtils', () => {
  return {
    alertForMatchingAccounts: vi.fn(),
  }
})

const server = setupServer()

const defaultProps: ComponentProps = {
  originAccountId: 1,
  searchValue: 'elemen',
  filterValue: FilterType.SHOW_ALL,
  visibilityChanges: [],
  onAccountToggled: vi.fn(),
  onAccountSubscriptionToggled: vi.fn(),
  subscriptionChanges: [],
}

beforeAll(() => server.listen())
afterAll(() => server.close())

beforeEach(() => {
  server.use(
    http.get('/api/v1/accounts/1/account_calendars', ({request}) => {
      const url = new URL(request.url)
      const searchTerm = url.searchParams.get('search_term') || ''
      const filter = url.searchParams.get('filter') || ''

      if (searchTerm === 'elemen') {
        return HttpResponse.json(RESPONSE_ACCOUNT_4)
      }
      if (searchTerm === 'elementary') {
        return HttpResponse.json([])
      }
      if (filter === FilterType.SHOW_VISIBLE && !searchTerm) {
        return HttpResponse.json(RESPONSE_ACCOUNT_3)
      }
      if (filter === FilterType.SHOW_HIDDEN && !searchTerm) {
        return HttpResponse.json([])
      }
      if (searchTerm === 'manually' && filter === FilterType.SHOW_HIDDEN) {
        const response = [...RESPONSE_ACCOUNT_3]
        response[0] = {...response[0], visible: false}
        return HttpResponse.json(response)
      }
      return HttpResponse.json([])
    }),
  )
  vi.clearAllMocks()
})

afterEach(() => {
  server.resetHandlers()
})

describe('AccountList', () => {
  it('shows a no results page', async () => {
    // Override for this test to return empty results
    server.use(
      http.get('/api/v1/accounts/1/account_calendars', () => {
        return HttpResponse.json([])
      }),
    )
    const {getByText} = render(<AccountList {...defaultProps} />)
    await waitFor(async () => {
      expect(getByText('No results found')).toBeInTheDocument()
    })
    expect(
      getByText('Please try another search term, filter, or search with fewer characters'),
    ).toBeInTheDocument()
  })

  it('shows a loading indicator only when search results are pending', async () => {
    // Uses the handler from beforeEach
    const {findByText, getByText, rerender, queryByText} = render(<AccountList {...defaultProps} />)
    await findByText('CPMS')
    rerender(<AccountList {...defaultProps} searchValue="elementary" />)
    expect(getByText('Loading accounts')).toBeInTheDocument()
    await waitFor(() => expect(queryByText('Loading accounts')).not.toBeInTheDocument())
  })

  it('shows a list of accounts respecting the current search filter', async () => {
    // Uses the handler from beforeEach for 'elemen' search
    const {findByText, getByText} = render(<AccountList {...defaultProps} />)
    expect(await findByText('CPMS')).toBeInTheDocument()
    expect(getByText('CS')).toBeInTheDocument()
  })

  it('shows a list of accounts respecting the current visibility filter', async () => {
    // Uses the handler from beforeEach for SHOW_VISIBLE filter
    const {findByText} = render(
      <AccountList {...defaultProps} searchValue="" filterValue={FilterType.SHOW_VISIBLE} />,
    )
    expect(await findByText('Manually-Created Courses')).toBeInTheDocument()
  })

  it('shows a list of accounts respecting both search and visibility filters', async () => {
    // Uses the handler from beforeEach for 'manually' + SHOW_HIDDEN
    const {findByText} = render(
      <AccountList {...defaultProps} searchValue="manually" filterValue={FilterType.SHOW_HIDDEN} />,
    )
    expect(await findByText('Manually-Created Courses')).toBeInTheDocument()
  })

  it('calls onAccountToggled when toggling a checkbox', async () => {
    const onAccountToggled = vi.fn()
    // Uses the handler from beforeEach for 'elemen' search
    const {findByText, getByRole} = render(
      <AccountList {...defaultProps} onAccountToggled={onAccountToggled} />,
    )
    await findByText('CPMS')
    const cpmsCheckbox = getByRole('checkbox', {name: 'Show account calendar for CPMS'})
    expect(onAccountToggled).not.toHaveBeenCalled()
    act(() => cpmsCheckbox.click())
    expect(onAccountToggled).toHaveBeenCalledWith(4, false)
  })

  it('announces search results for screen readers', async () => {
    // Uses the handler from beforeEach for 'elemen' search
    const {findByText} = render(<AccountList {...defaultProps} />)
    await findByText('CPMS')
    expect(alertForMatchingAccounts).toHaveBeenCalledWith(2, false)
  })

  it('shows subscription dropdown', async () => {
    // Uses the handler from beforeEach for SHOW_VISIBLE filter
    const {findByText, queryAllByTestId} = render(
      <AccountList {...defaultProps} searchValue="" filterValue={FilterType.SHOW_VISIBLE} />,
    )
    expect(await findByText('Manually-Created Courses')).toBeInTheDocument()
    expect(queryAllByTestId('subscription-dropdown')[0]).toBeInTheDocument()
  })
})
