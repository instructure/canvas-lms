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

import {render, waitFor} from '@testing-library/react'
import SubaccountTree from '../SubaccountTree'
import fetchMock from 'fetch-mock'
import userEvent from '@testing-library/user-event'
import type {AccountWithCounts} from '../types'
import {QueryClient} from '@tanstack/react-query'
import {SubaccountProvider} from '../util'

const rootAccount = {
  id: '1',
  name: 'Root Account',
  sub_account_count: 2,
  course_count: 0,
}

const subAccounts = [
  {id: '11', name: 'Child 1', sub_account_count: 0, course_count: 0},
  {id: '12', name: 'Child 2', sub_account_count: 0, course_count: 0},
]

const props = {
  rootAccount,
  depth: 0,
  isTopAccount: false,
  defaultExpanded: true,
}

// Use regex matcher to handle different parameter orderings
const SUBACCOUNT_FETCH_MATCHER = (account: AccountWithCounts) => {
  return new RegExp(`/api/v1/accounts/${account.id}/sub_accounts`)
}

const renderSubaccountTree = (overrides = {}) => {
  const mergedProps = {...props, ...overrides}
  return render(
    <SubaccountProvider>
      <SubaccountTree {...mergedProps} />
    </SubaccountProvider>,
  )
}

describe('SubaccountTree', () => {
  const queryClient = new QueryClient()
  beforeEach(() => {
    fetchMock.restore()
    vi.clearAllMocks()
    queryClient.clear()
    // Clear sessionStorage to avoid cached data interfering with tests
    sessionStorage.clear()
  })

  afterEach(() => {
    queryClient.clear()
    sessionStorage.clear()
  })

  // the only time this doesn't happen automatically is if the subaccount count is over 100
  it('fetches sub-accounts and expands collapses', async () => {
    const user = userEvent.setup()
    fetchMock.get(SUBACCOUNT_FETCH_MATCHER(rootAccount), subAccounts)
    const {getByText, getByTestId, queryByText} = renderSubaccountTree()

    await waitFor(() => {
      expect(fetchMock.called(SUBACCOUNT_FETCH_MATCHER(rootAccount), 'GET')).toBe(true)
      expect(getByText('Root Account')).toBeInTheDocument()
      expect(getByText('Child 1')).toBeInTheDocument()
      expect(getByText('Child 2')).toBeInTheDocument()
    })

    // collapse
    await user.click(getByTestId(`collapse-${rootAccount.id}`))
    expect(queryByText('Child 1')).toBeNull()
    expect(queryByText('Child 2')).toBeNull()

    // expand again
    await user.click(getByTestId(`expand-${rootAccount.id}`))
    expect(getByText('Child 1')).toBeInTheDocument()
    expect(getByText('Child 2')).toBeInTheDocument()
  })

  it('does not fetch more subaccounts if subaccount count is 0', async () => {
    const account = {...rootAccount, sub_account_count: 0}
    fetchMock.get(SUBACCOUNT_FETCH_MATCHER(rootAccount), subAccounts)
    const {getByText} = renderSubaccountTree({rootAccount: account})

    await waitFor(() => {
      expect(fetchMock.called(SUBACCOUNT_FETCH_MATCHER(rootAccount), 'GET')).toBe(false)
      expect(getByText('Root Account')).toBeInTheDocument()
    })
  })
})
