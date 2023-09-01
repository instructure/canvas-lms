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
import fetchMock from 'fetch-mock'

import {AccountTree} from '../AccountTree'
import {RESPONSE_ACCOUNT_1, RESPONSE_ACCOUNT_4} from './fixtures'

const defaultProps = {
  originAccountId: 1,
  visibilityChanges: [],
  onAccountToggled: jest.fn(),
  showSpinner: false,
  subscriptionChanges: [],
  onAccountSubscriptionToggled: jest.fn(),
  onAccountExpandedToggled: () => {},
  expandedAccounts: [1],
}

beforeEach(() => {
  fetchMock.get(/\/api\/v1\/accounts\/1\/account_calendars.*/, RESPONSE_ACCOUNT_1)
  fetchMock.get(/\/api\/v1\/accounts\/4\/account_calendars.*/, RESPONSE_ACCOUNT_4)
})

afterEach(() => {
  fetchMock.restore()
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
    const onAccountToggled = jest.fn()
    const {findByRole, getByRole} = render(
      <AccountTree {...defaultProps} onAccountToggled={onAccountToggled} />
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
    const onAccountExpandedToggled = jest.fn()
    const {findByRole} = render(
      <AccountTree {...defaultProps} onAccountExpandedToggled={onAccountExpandedToggled} />
    )
    const cpmsButton = await findByRole('button', {name: 'CPMS, 2 accounts'})
    act(() => cpmsButton.click())
    expect(onAccountExpandedToggled).toHaveBeenCalledWith(4, true)
  })

  it('expands expanded nodes of the tree', async () => {
    const {getByText} = render(<AccountTree {...defaultProps} expandedAccounts={[1, 4]} />)
    await waitFor(() => {
      expect(fetchMock.calls().length).toBe(2)
    })
    await waitFor(() => {
      expect(getByText('University (5)')).toBeInTheDocument() // this is the parent account
      expect(getByText('CPMS')).toBeInTheDocument() // this is a child account
      expect(getByText('CPMS (2)')).toBeInTheDocument() // this is a child account with children
      expect(getByText('CS')).toBeInTheDocument() // this is a child of CPMS
    })
  })

  it('loads multiple pages properly if needed', async () => {
    fetchMock.restore()
    fetchMock.getOnce(/\/api\/v1\/accounts\/1\/account_calendars.*/, {
      body: RESPONSE_ACCOUNT_1.slice(0, 3),
      headers: {
        Link: '</api/v1/accounts/1/account_calendars?page=2&per_page=100>; rel="next"',
      },
    })
    fetchMock.getOnce(
      '/api/v1/accounts/1/account_calendars?page=2&per_page=100',
      RESPONSE_ACCOUNT_1.slice(3, 5)
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
