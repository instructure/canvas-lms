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
import {render, act, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import {AccountTree} from '../AccountTree'
import {RESPONSE_ACCOUNT_1, RESPONSE_ACCOUNT_4} from './fixtures'

const server = setupServer()

// Track API calls for tests that need to verify call counts
let apiCallTracker: {url: string}[] = []

const defaultProps = {
  originAccountId: 1,
  visibilityChanges: [],
  onAccountToggled: vi.fn(),
  showSpinner: false,
  subscriptionChanges: [],
  onAccountSubscriptionToggled: vi.fn(),
  onAccountExpandedToggled: () => {},
  expandedAccounts: [1],
}

beforeAll(() => server.listen())
afterAll(() => server.close())

beforeEach(() => {
  apiCallTracker = []
  server.use(
    http.get('/api/v1/accounts/:accountId/account_calendars', ({params, request}) => {
      apiCallTracker.push({url: request.url})
      const accountId = params.accountId
      if (accountId === '1') {
        return HttpResponse.json(RESPONSE_ACCOUNT_1)
      }
      if (accountId === '4') {
        return HttpResponse.json(RESPONSE_ACCOUNT_4)
      }
      return HttpResponse.json([])
    }),
  )
})

afterEach(() => {
  server.resetHandlers()
})

describe('AccountTree', () => {
  it('loads and displays an account tree', async () => {
    const {findByText, getByText} = render(<AccountTree {...defaultProps} />)
    expect(await findByText('University, 5 accounts')).toBeInTheDocument()
    expect(getByText('University')).toBeInTheDocument()
    expect(getByText('Manually-Created Courses')).toBeInTheDocument()
    expect(getByText('Big Account, 16 accounts')).toBeInTheDocument()
    expect(getByText('CPMS, 2 accounts')).toBeInTheDocument()
    expect(getByText('Elementary, 2 accounts')).toBeInTheDocument()
  })

  it('checks accounts only where calendar is visible', async () => {
    const {findByRole, getByRole} = render(<AccountTree {...defaultProps} />)
    expect(await findByRole('button', {name: 'University, 5 accounts'})).toBeInTheDocument()
    const universityCheckbox = getByRole('checkbox', {name: 'Show account calendar for University'})
    const mccCheckbox = getByRole('checkbox', {
      name: 'Show account calendar for Manually-Created Courses',
    })
    expect(universityCheckbox).toBeInTheDocument()
    expect(mccCheckbox).toBeInTheDocument()
    expect(universityCheckbox).toBeChecked()
    expect(mccCheckbox).not.toBeChecked()
  })

  it('calls onAccountToggled when a checkbox is toggled', async () => {
    const onAccountToggled = vi.fn()
    const {findByRole, getByRole} = render(
      <AccountTree {...defaultProps} onAccountToggled={onAccountToggled} />,
    )
    expect(await findByRole('button', {name: 'University, 5 accounts'})).toBeInTheDocument()
    const universityCheckbox = getByRole('checkbox', {name: 'Show account calendar for University'})
    expect(onAccountToggled).not.toHaveBeenCalled()
    act(() => universityCheckbox.click())
    expect(onAccountToggled).toHaveBeenCalledWith(1, false)
  })

  it('shows a spinner while loading', () => {
    const {getByText} = render(<AccountTree {...defaultProps} />)
    expect(getByText('Loading accounts')).toBeInTheDocument()
  })

  it('asks to expand tree when a parent account is selected', async () => {
    const onAccountExpandedToggled = vi.fn()
    const {findByRole} = render(
      <AccountTree {...defaultProps} onAccountExpandedToggled={onAccountExpandedToggled} />,
    )
    const cpmsButton = await findByRole('button', {name: 'CPMS, 2 accounts'})
    act(() => cpmsButton.click())
    expect(onAccountExpandedToggled).toHaveBeenCalledWith(4, true)
  })

  it('fetches only origin account on mount', async () => {
    const {findByRole, findByText} = render(
      <AccountTree {...defaultProps} expandedAccounts={[1]} />,
    )
    // On mount, only the origin account should be fetched (not all accounts in expandedAccounts)
    await waitFor(() => {
      expect(apiCallTracker).toHaveLength(1)
    })
    expect(apiCallTracker[0].url).toContain('/accounts/1/account_calendars')

    // Wait for the parent account to be rendered
    expect(await findByRole('button', {name: 'University, 5 accounts'})).toBeInTheDocument()
    // Verify direct child accounts are visible (from the first fetch)
    expect(await findByText('CPMS, 2 accounts')).toBeInTheDocument()
  })

  it('fetches account children on user expansion', async () => {
    const onAccountExpandedToggled = vi.fn()
    const {findByRole} = render(
      <AccountTree {...defaultProps} onAccountExpandedToggled={onAccountExpandedToggled} />,
    )
    await waitFor(() => {
      expect(apiCallTracker).toHaveLength(1)
    })

    // Expand CPMS by clicking its toggle button
    const cpmsButton = await findByRole('button', {name: 'CPMS, 2 accounts'})
    act(() => cpmsButton.click())

    // Verify that expansion callback was called
    expect(onAccountExpandedToggled).toHaveBeenCalledWith(4, true)
    // Verify that a second fetch was triggered for CPMS's children
    await waitFor(() => {
      expect(apiCallTracker).toHaveLength(2)
    })
    expect(apiCallTracker[1].url).toContain('/accounts/4/account_calendars')
  })

  it('loads multiple pages properly if needed', async () => {
    let page1Called = false
    server.use(
      http.get('/api/v1/accounts/1/account_calendars', ({request}) => {
        const url = new URL(request.url)
        const page = url.searchParams.get('page')
        if (page === '2') {
          return HttpResponse.json(RESPONSE_ACCOUNT_1.slice(3, 5))
        }
        page1Called = true
        return HttpResponse.json(RESPONSE_ACCOUNT_1.slice(0, 3), {
          headers: {
            Link: '</api/v1/accounts/1/account_calendars?page=2&per_page=100>; rel="next"',
          },
        })
      }),
    )
    const {findByRole, getByRole} = render(<AccountTree {...defaultProps} />)
    expect(await findByRole('button', {name: 'University, 5 accounts'})).toBeInTheDocument()
    expect(getByRole('button', {name: 'Elementary, 2 accounts'})).toBeInTheDocument()
  })

  it('shows subscription dropdown', async () => {
    const {findByRole, queryAllByTestId} = render(<AccountTree {...defaultProps} />)
    expect(await findByRole('button', {name: 'University, 5 accounts'})).toBeInTheDocument()
    expect(queryAllByTestId('subscription-dropdown')[0]).toBeInTheDocument()
  })
})
