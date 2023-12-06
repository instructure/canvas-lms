// @ts-nocheck
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
import {RESPONSE_ACCOUNT_3, RESPONSE_ACCOUNT_4} from './fixtures'
import {alertForMatchingAccounts} from '@canvas/calendar/AccountCalendarsUtils'

jest.mock('@canvas/calendar/AccountCalendarsUtils', () => {
  return {
    alertForMatchingAccounts: jest.fn(),
  }
})

const defaultProps = {
  originAccountId: 1,
  searchValue: 'elemen',
  filterValue: FilterType.SHOW_ALL,
  visibilityChanges: [],
  onAccountToggled: jest.fn(),
}

const accountListUrl = (searchTerm = '', filter = '') =>
  `/api/v1/accounts/1/account_calendars?search_term=${searchTerm}&filter=${filter}&per_page=${
    searchTerm ? 20 : 100
  }`

beforeEach(() => {
  fetchMock.get(accountListUrl(), [])
  jest.clearAllMocks()
})

afterEach(() => {
  fetchMock.restore()
})

describe('AccountList', () => {
  it('shows a no results page', async () => {
    fetchMock.get(accountListUrl('elemen'), [])
    const {getByText} = render(<AccountList {...defaultProps} />)
    await waitFor(async () => {
      expect(getByText('No results found')).toBeInTheDocument()
    })
    expect(
      getByText('Please try another search term, filter, or search with fewer characters')
    ).toBeInTheDocument()
  })

  it('shows a loading indicator only when search results are pending', async () => {
    fetchMock.get(accountListUrl('elemen'), [])
    fetchMock.get(accountListUrl('elementary'), [])
    const {findByText, getByText, rerender, queryByText} = render(<AccountList {...defaultProps} />)
    await findByText('No results found')
    rerender(<AccountList {...defaultProps} searchValue="elementary" />)
    expect(getByText('Loading accounts')).toBeInTheDocument()
    await waitFor(() => expect(queryByText('Loading accounts')).not.toBeInTheDocument())
  })

  it('shows a list of accounts respecting the current search filter', async () => {
    fetchMock.get(accountListUrl('elemen'), RESPONSE_ACCOUNT_4)
    const {findByText, getByText} = render(<AccountList {...defaultProps} />)
    expect(await findByText('CPMS')).toBeInTheDocument()
    expect(getByText('CS')).toBeInTheDocument()
  })

  it('shows a list of accounts respecting the current visibility filter', async () => {
    fetchMock.get(accountListUrl('', FilterType.SHOW_VISIBLE), RESPONSE_ACCOUNT_3)
    const {findByText} = render(
      <AccountList {...defaultProps} searchValue="" filterValue={FilterType.SHOW_VISIBLE} />
    )
    expect(await findByText('Manually-Created Courses')).toBeInTheDocument()
  })

  it('shows a list of accounts respecting both search and visibility filters', async () => {
    fetchMock.get(accountListUrl('', FilterType.SHOW_HIDDEN), [])
    const response = [...RESPONSE_ACCOUNT_3]
    response[0].visible = false
    fetchMock.get(accountListUrl('manually', FilterType.SHOW_HIDDEN), response)
    const {findByText} = render(
      <AccountList {...defaultProps} searchValue="manually" filterValue={FilterType.SHOW_HIDDEN} />
    )
    expect(await findByText('Manually-Created Courses')).toBeInTheDocument()
  })

  it('calls onAccountToggled when toggling a checkbox', async () => {
    const onAccountToggled = jest.fn()
    fetchMock.get(accountListUrl('elemen'), RESPONSE_ACCOUNT_4)
    const {findByText, getByRole} = render(
      <AccountList {...defaultProps} onAccountToggled={onAccountToggled} />
    )
    await findByText('CPMS')
    const cpmsCheckbox = getByRole('checkbox', {name: 'Show account calendar for CPMS'})
    expect(onAccountToggled).not.toHaveBeenCalled()
    act(() => cpmsCheckbox.click())
    expect(onAccountToggled).toHaveBeenCalledWith(4, false)
  })

  it('announces search results for screen readers', async () => {
    fetchMock.get(accountListUrl('elemen'), RESPONSE_ACCOUNT_4)
    const {findByText} = render(<AccountList {...defaultProps} />)
    await findByText('CPMS')
    expect(alertForMatchingAccounts).toHaveBeenCalledWith(2, false)
  })

  it('shows subscription dropdown', async () => {
    fetchMock.get(accountListUrl('', FilterType.SHOW_VISIBLE), RESPONSE_ACCOUNT_3)
    const {findByText, queryAllByTestId} = render(
      <AccountList {...defaultProps} searchValue="" filterValue={FilterType.SHOW_VISIBLE} />
    )
    expect(await findByText('Manually-Created Courses')).toBeInTheDocument()
    expect(queryAllByTestId('subscription-dropdown')[0]).toBeInTheDocument()
  })
})
