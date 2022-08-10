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
import fetchMock from 'fetch-mock'

import {AccountList} from '../AccountList'
import {FilterType} from '../FilterControls'
import {RESPONSE_ACCOUNT_4} from '../../__tests__/fixtures'

const defaultProps = {
  originAccountId: 1,
  searchValue: 'elemen',
  filterValue: FilterType.SHOW_ALL,
  visibilityChanges: [],
  onAccountToggled: jest.fn()
}

beforeEach(() => {
  fetchMock.get('/api/v1/accounts/1/account_calendars?search_term=', [])
})

afterEach(() => {
  fetchMock.restore()
})

describe('AccountList', () => {
  it('shows a no results page', async () => {
    fetchMock.get('/api/v1/accounts/1/account_calendars?search_term=elemen', [])
    const {findByText, getByText} = render(<AccountList {...defaultProps} />)
    expect(await findByText('No results for "elemen"')).toBeInTheDocument()
    expect(
      getByText('Please try another search term or search with fewer characters')
    ).toBeInTheDocument()
  })

  it('shows a loading indicator only when search results are pending', async () => {
    fetchMock.get('/api/v1/accounts/1/account_calendars?search_term=elemen', [])
    fetchMock.get('/api/v1/accounts/1/account_calendars?search_term=elementary', [])
    const {findByText, getByText, rerender, queryByText} = render(<AccountList {...defaultProps} />)
    await findByText('No results for "elemen"')
    rerender(<AccountList {...defaultProps} searchValue="elementary" />)
    expect(getByText('Loading accounts')).toBeInTheDocument()
    await waitFor(() => expect(queryByText('Loading accounts')).not.toBeInTheDocument())
  })

  it('shows a list of accounts respecting the current filters', async () => {
    fetchMock.get('/api/v1/accounts/1/account_calendars?search_term=elemen', RESPONSE_ACCOUNT_4)
    const {findByText, getByText} = render(<AccountList {...defaultProps} />)
    expect(await findByText('CPMS')).toBeInTheDocument()
    expect(getByText('CS')).toBeInTheDocument()
  })

  it('calls onAccountToggled when toggling a checkbox', async () => {
    const onAccountToggled = jest.fn()
    fetchMock.get('/api/v1/accounts/1/account_calendars?search_term=elemen', RESPONSE_ACCOUNT_4)
    const {findByText, getByRole} = render(
      <AccountList {...defaultProps} onAccountToggled={onAccountToggled} />
    )
    await findByText('CPMS')
    const cpmsCheckbox = getByRole('checkbox', {name: 'Show account calendar for CPMS'})
    expect(onAccountToggled).not.toHaveBeenCalled()
    act(() => cpmsCheckbox.click())
    expect(onAccountToggled).toHaveBeenCalledWith(4, false)
  })
})
