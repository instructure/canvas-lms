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
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import userEvent from '@testing-library/user-event'
import {AccountWithCounts} from '../types'

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
  indent: 0,
  isTopAccount: false,
}

const SUBACCOUNT_FETCH = (account: AccountWithCounts) => {
  return encodeURI(
    `/api/v1/accounts/${account.id}/sub_accounts?per_page=100&page=1&include[]=course_count&include[]=sub_account_count`,
  )
}

describe('SubaccountTree', () => {
  beforeEach(() => {
    fetchMock.restore()
    jest.clearAllMocks()
  })

  it('renders only root initially', async () => {
    fetchMock.get(SUBACCOUNT_FETCH(rootAccount), subAccounts)
    const {getByText, queryByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubaccountTree {...props} />
      </MockedQueryClientProvider>,
    )

    await waitFor(() => {
      expect(fetchMock.called(SUBACCOUNT_FETCH(rootAccount), 'GET')).toBe(false)
      expect(getByText('Root Account')).toBeInTheDocument()
      expect(queryByText('Child 1')).toBeNull()
      expect(queryByText('Child 2')).toBeNull()
    })
  })

  it('does not fetch more subaccounts if subaccount count is 0', async () => {
    const account = {...rootAccount, sub_account_count: 0}
    fetchMock.get(SUBACCOUNT_FETCH(rootAccount), subAccounts)
    const {getByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubaccountTree {...props} rootAccount={account} />
      </MockedQueryClientProvider>,
    )

    await waitFor(() => {
      expect(fetchMock.called(SUBACCOUNT_FETCH(rootAccount), 'GET')).toBe(false)
      expect(getByText('Root Account')).toBeInTheDocument()
    })
  })

  it('expands and collapses subaccounts', async () => {
    const user = userEvent.setup()
    fetchMock.get(SUBACCOUNT_FETCH(rootAccount), subAccounts)
    const {getByTestId, getByText, queryByText} = render(
      <MockedQueryClientProvider client={queryClient}>
        <SubaccountTree {...props} />
      </MockedQueryClientProvider>,
    )

    // expand
    await user.click(getByTestId(`expand-${rootAccount.id}`))
    await waitFor(() => {
      expect(fetchMock.called(SUBACCOUNT_FETCH(rootAccount), 'GET')).toBe(true)
      expect(getByText('Child 1')).toBeInTheDocument()
      expect(getByText('Child 2')).toBeInTheDocument()
    })

    // collapse
    await user.click(getByTestId(`collapse-${rootAccount.id}`))
    expect(queryByText('Child 1')).toBeNull()
    expect(queryByText('Child 2')).toBeNull()
  })
})
