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
import {render, act, waitFor, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

import {AccountCalendarSettings} from '../AccountCalendarSettings'
import {RESPONSE_ACCOUNT_1} from './fixtures'

jest.mock('@canvas/calendar/AccountCalendarsUtils', () => {
  return {
    alertForMatchingAccounts: jest.fn(),
  }
})

const defaultProps = {
  accountId: 1,
}

beforeEach(() => {
  fetchMock.get(/\/api\/v1\/accounts\/1\/account_calendars.*/, RESPONSE_ACCOUNT_1)
  fetchMock.get(/\/api\/v1\/accounts\/1\/visible_calendars_count.*/, RESPONSE_ACCOUNT_1.length)
  jest.useFakeTimers()
  jest.clearAllMocks()
})

afterEach(() => {
  fetchMock.restore()
  destroyContainer()
})

describe('AccountCalendarSettings', () => {
  it('renders header and subtext', () => {
    const {getByRole, getByText} = render(<AccountCalendarSettings {...defaultProps} />)
    expect(
      getByRole('heading', {name: 'Account Calendar Visibility', level: 1})
    ).toBeInTheDocument()
    expect(
      getByText(
        'Choose which calendars your users can add in the "Other Calendars" section of their Canvas calendar. Users will only be able to add enabled calendars for the accounts they are associated with. By default, all calendars are disabled.'
      )
    ).toBeInTheDocument()
  })

  it('saves changes when clicking apply', async () => {
    fetchMock.put(/\/api\/v1\/accounts\/1\/account_calendars/, {message: 'Updated 1 account'})
    const {findByText, getByText, findAllByText, getByTestId, getByRole} = render(
      <AccountCalendarSettings {...defaultProps} />
    )
    expect(await findByText('University (25)')).toBeInTheDocument()
    const universityCheckbox = getByRole('checkbox', {name: 'Show account calendar for University'})
    const applyButton = getByTestId('save-button')
    expect(applyButton).toBeDisabled()
    act(() => universityCheckbox.click())
    expect(applyButton).toBeEnabled()
    act(() => applyButton.click())
    await waitFor(() => expect(getByText('Loading accounts')).toBeInTheDocument())
    expect((await findAllByText('Updated 1 account'))[0]).toBeInTheDocument()
  })

  it('renders account tree when no filters are applied', async () => {
    const {findByText, getByTestId} = render(<AccountCalendarSettings {...defaultProps} />)
    await findByText('University (25)')
    expect(getByTestId('account-tree')).toBeInTheDocument()
  })

  it('renders account list when filters are applied', async () => {
    const {findByText, queryByTestId, getByPlaceholderText} = render(
      <AccountCalendarSettings {...defaultProps} />
    )
    await findByText('University (25)')
    fetchMock.restore()
    fetchMock.get('/api/v1/accounts/1/account_calendars?search_term=elemen&filter=&per_page=20', [
      {
        id: '134',
        name: 'West Elementary School',
        parent_account_id: '1',
        root_account_id: '0',
        visible: true,
        sub_account_count: 0,
      },
    ])
    const search = getByPlaceholderText('Search Calendars')
    fireEvent.change(search, {target: {value: 'elemen'}})
    expect(await findByText('West Elementary School')).toBeInTheDocument()
    expect(queryByTestId('account-tree')).not.toBeVisible()
  })
})
