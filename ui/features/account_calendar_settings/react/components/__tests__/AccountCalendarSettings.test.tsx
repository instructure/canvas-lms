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
import {RESPONSE_ACCOUNT_1, RESPONSE_ACCOUNT_5, RESPONSE_ACCOUNT_6} from './fixtures'

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

  // FOO-3934 skipped because of a timeout (> 5 seconds causing build to fail)
  it.skip('saves changes when clicking apply', async () => {
    fetchMock.put(/\/api\/v1\/accounts\/1\/account_calendars/, {message: 'Updated 1 account'})
    const {findByText, getByText, findAllByText, getByTestId, findAllByTestId} = render(
      <AccountCalendarSettings {...defaultProps} />
    )
    expect(await findByText('University (5)')).toBeInTheDocument()
    const universityCheckbox = (await findAllByTestId('account-calendar-checkbox-University'))[0]
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
    await findByText('University (5)')
    expect(getByTestId('account-tree')).toBeInTheDocument()
  })

  it('renders account list when filters are applied', async () => {
    const {findByText, queryByTestId, getByPlaceholderText} = render(
      <AccountCalendarSettings {...defaultProps} />
    )
    await findByText('University (5)')
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

  describe('auto subscription settings', () => {
    beforeEach(() => {
      fetchMock.restore()
      fetchMock.get(/\/api\/v1\/accounts\/1\/visible_calendars_count.*/, RESPONSE_ACCOUNT_5.length)
      fetchMock.get(/\/api\/v1\/accounts\/1\/account_calendars.*/, RESPONSE_ACCOUNT_5)
      fetchMock.put(/\/api\/v1\/accounts\/1\/account_calendars/, {message: 'Updated 1 account'})
      jest.useFakeTimers()
      jest.clearAllMocks()
    })

    it('saves subscription type changes', async () => {
      const {findByText, getByText, getByTestId, getAllByTestId} = render(
        <AccountCalendarSettings {...defaultProps} />
      )
      expect(await findByText('Manually-Created Courses (2)')).toBeInTheDocument()

      act(() => getAllByTestId('subscription-dropdown')[0].click())
      act(() => getByText('Auto subscribe').click())
      act(() => getByTestId('save-button').click())
      act(() => getByTestId('confirm-button').click())
      const request = fetchMock.lastOptions(/\/api\/v1\/accounts\/1\/account_calendars.*/)
      const requestBody = JSON.parse(request?.body?.toString() || '{}')
      expect(requestBody).toEqual([{id: RESPONSE_ACCOUNT_5[0].id, auto_subscribe: true}])
    })

    it('shows the confirmation modal if switching from manual to auto subscription', async () => {
      const {getByRole, getByText, findByText, getByTestId, getAllByTestId} = render(
        <AccountCalendarSettings {...defaultProps} />
      )
      expect(await findByText('Manually-Created Courses (2)')).toBeInTheDocument()

      act(() => getAllByTestId('subscription-dropdown')[0].click())
      act(() => getByText('Auto subscribe').click())
      act(() => getByTestId('save-button').click())
      const modalTitle = getByRole('heading', {name: 'Apply Changes'})
      expect(modalTitle).toBeInTheDocument()
    })

    it('does not show the confirmation modal if switching from auto to manual subscription', async () => {
      fetchMock.restore()
      fetchMock.get(/\/api\/v1\/accounts\/1\/account_calendars.*/, RESPONSE_ACCOUNT_6)
      fetchMock.get(/\/api\/v1\/accounts\/1\/visible_calendars_count.*/, RESPONSE_ACCOUNT_6.length)
      fetchMock.put(/\/api\/v1\/accounts\/1\/account_calendars/, {message: 'Updated 1 account'})

      const {queryByRole, getByText, findByText, getByTestId} = render(
        <AccountCalendarSettings {...defaultProps} />
      )
      expect(await findByText('Manually-Created Courses')).toBeInTheDocument()
      const applyButton = getByTestId('save-button')

      expect(applyButton).toBeDisabled()
      act(() => getByTestId('subscription-dropdown').click())
      act(() => getByText('Manual subscribe').click())
      expect(applyButton).toBeEnabled()
      act(() => applyButton.click())
      const modalTitle = queryByRole('heading', {name: 'Apply Changes'})
      expect(modalTitle).not.toBeInTheDocument()
    })

    // LF-1202
    it.skip('does not show the confirmation modal if changing only the account visibility', async () => {
      const {queryByRole, getByRole, getByTestId, findByText} = render(
        <AccountCalendarSettings {...defaultProps} />
      )
      expect(await findByText('Manually-Created Courses (2)')).toBeInTheDocument()

      const visibilityCheckbox = getByRole('checkbox', {
        name: 'Show account calendar for Manually-Created Courses',
      })
      const applyButton = getByTestId('save-button')
      expect(applyButton).toBeDisabled()
      act(() => visibilityCheckbox.click())
      expect(applyButton).toBeEnabled()
      act(() => applyButton.click())
      const modalTitle = queryByRole('heading', {name: 'Apply Changes'})
      expect(modalTitle).not.toBeInTheDocument()
    })

    describe('fires confirmation dialog when', () => {
      beforeEach(() => {
        fetchMock.restore()
        fetchMock.get(/\/api\/v1\/accounts\/1\/account_calendars.*/, RESPONSE_ACCOUNT_1)
        fetchMock.get(
          /\/api\/v1\/accounts\/1\/visible_calendars_count.*/,
          RESPONSE_ACCOUNT_1.length
        )
      })

      it.skip('calendar visibility changes (flaky)', async () => {
        const getUniversityCheckbox = () =>
          getByRole('checkbox', {
            name: 'Show account calendar for University',
          })

        const {findByText, getByRole} = render(<AccountCalendarSettings {...defaultProps} />)
        expect(await findByText('University (5)')).toBeInTheDocument()

        act(() => getUniversityCheckbox().click())

        const event = new Event('beforeunload')
        event.preventDefault = jest.fn()
        window.dispatchEvent(event)
        expect(event.preventDefault).toHaveBeenCalled()

        act(() => getUniversityCheckbox().click())

        event.preventDefault = jest.fn()
        window.dispatchEvent(event)
        expect(event.preventDefault).not.toHaveBeenCalled()
      })

      it('calendar subscription type changes', async () => {
        const {findByText, getByText, getAllByTestId} = render(
          <AccountCalendarSettings {...defaultProps} />
        )
        expect(await findByText('University (5)')).toBeInTheDocument()

        act(() => getAllByTestId('subscription-dropdown')[0].click())
        act(() => getByText('Auto subscribe').click())

        const event = new Event('beforeunload')
        event.preventDefault = jest.fn()
        window.dispatchEvent(event)
        expect(event.preventDefault).toHaveBeenCalled()

        act(() => getAllByTestId('subscription-dropdown')[0].click())
        act(() => getByText('Manual subscribe').click())

        event.preventDefault = jest.fn()
        window.dispatchEvent(event)
        expect(event.preventDefault).not.toHaveBeenCalled()
      })
    })
  })
})
