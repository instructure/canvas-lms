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
import {act, render, fireEvent, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import MockDate from 'mockdate'
import {
  accountCalendarsAPIPage1Response,
  accountCalendarsAPIPage2Response,
  allAccountCalendarsResponse,
  emptyResponse,
  accountCalendarsAPISearchResponse,
} from './mocks'
import AccountCalendarsModal, {
  SEARCH_ENDPOINT,
  SAVE_PREFERENCES_ENDPOINT,
} from '../AccountCalendarsModal'
import {alertForMatchingAccounts} from '@canvas/calendar/AccountCalendarsUtils'

jest.mock('@canvas/calendar/AccountCalendarsUtils', () => {
  return {
    alertForMatchingAccounts: jest.fn(),
  }
})

describe('Other Calendars modal ', () => {
  const page1Results = accountCalendarsAPIPage1Response.account_calendars
  const page2Results = accountCalendarsAPIPage2Response.account_calendars
  const searchResult = accountCalendarsAPISearchResponse.account_calendars
  const totalCalendars = allAccountCalendarsResponse.total_results
  const getSearchUrl = searchTerm => SEARCH_ENDPOINT.concat(`?per_page=2&search_term=${searchTerm}`)
  const markAsSeenUrl = encodeURI(SAVE_PREFERENCES_ENDPOINT.concat(`?mark_feature_as_seen=true`))

  beforeAll(() => {
    jest.useFakeTimers()
  })

  beforeEach(() => {
    fetchMock.get(SEARCH_ENDPOINT.concat('?per_page=2'), {
      body: JSON.stringify(accountCalendarsAPIPage1Response),
      headers: {
        Link: '</api/v1/account_calendars?&per_page=2&page=2>; rel="next"',
      },
    })
    fetchMock.get(
      SEARCH_ENDPOINT.concat('?per_page=5'),
      JSON.stringify(allAccountCalendarsResponse)
    )
    fetchMock.get(
      SEARCH_ENDPOINT.concat('?per_page=2&page=2'),
      JSON.stringify(accountCalendarsAPIPage2Response)
    )
    fetchMock.get(getSearchUrl('Test'), JSON.stringify(accountCalendarsAPISearchResponse))
    fetchMock.get(getSearchUrl('Test2'), JSON.stringify(emptyResponse))
    fetchMock.get(getSearchUrl('T'), JSON.stringify(emptyResponse))
    fetchMock.post(markAsSeenUrl, JSON.stringify({status: 'ok'}))
    jest.clearAllMocks()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  const getProps = (overrides = {}) => ({
    getSelectedOtherCalendars: () => [page1Results[0]],
    onSave: jest.fn(),
    calendarsPerRequest: 2,
    featureSeen: true,
    ...overrides,
  })

  const openModal = async addCalendarButton => {
    expect(addCalendarButton).toBeInTheDocument()
    await userEvent.setup({delay: null}).click(addCalendarButton)
  }

  const advance = ms => {
    act(() => {
      const now = Date.now()
      MockDate.set(now + ms)
      jest.advanceTimersByTime(ms)
    })
  }

  it('renders "calendarsPerRequest" number of account calendars when open', async () => {
    const {getByText, queryByText, getByTestId, findByText} = render(
      <AccountCalendarsModal {...getProps()} />
    )
    const addCalendarButton = getByTestId('add-other-calendars-button')
    await openModal(addCalendarButton)
    expect(await findByText(page1Results[0].name)).toBeInTheDocument()
    expect(getByText(page1Results[1].name)).toBeInTheDocument()
    expect(queryByText(page2Results[0].name)).not.toBeInTheDocument()
  })

  it('shows the calendars already enabled', async () => {
    const {getByTestId, findByTestId} = render(<AccountCalendarsModal {...getProps()} />)
    const addCalendarButton = getByTestId('add-other-calendars-button')
    await openModal(addCalendarButton)
    expect((await findByTestId(`account-${page1Results[0].id}-checkbox`)).checked).toBe(true)
    expect(getByTestId(`account-${page1Results[1].id}-checkbox`).checked).toBe(false)
  })

  it('saves the new enabled calendars state', async () => {
    const user = userEvent.setup({delay: null})
    const onSaveUrl = encodeURI(
      SAVE_PREFERENCES_ENDPOINT.concat(
        `?enabled_account_calendars[]=${page1Results[0].id}&enabled_account_calendars[]=${page1Results[1].id}`
      )
    )
    fetchMock.post(onSaveUrl, JSON.stringify({status: 'ok'}))
    const {findByTestId, getByTestId} = render(<AccountCalendarsModal {...getProps()} />)
    const addCalendarButton = getByTestId('add-other-calendars-button')
    await openModal(addCalendarButton)
    const calendarToEnable = await findByTestId(`account-${page1Results[1].id}-checkbox`)
    const saveButton = getByTestId('save-calendars-button')
    await user.click(calendarToEnable)
    await user.click(saveButton)
    advance(500)
    expect(fetchMock.called(onSaveUrl)).toBe(true)
  })

  it('renders the "Show more" option when there are more calendars to fetch', async () => {
    const user = userEvent.setup({delay: null})
    const showMoreUrl = SEARCH_ENDPOINT.concat('?per_page=2&page=2')
    const {findByText, getByTestId} = render(<AccountCalendarsModal {...getProps()} />)
    const addCalendarButton = getByTestId('add-other-calendars-button')
    await openModal(addCalendarButton)
    const showMoreLink = await findByText('Show more')
    await user.click(showMoreLink)
    expect(fetchMock.called(showMoreUrl)).toBe(true)
  })

  it('does not render the "Show more" option when all the calendars have been fetched', async () => {
    const {queryByText, getByTestId, findByTestId} = render(
      <AccountCalendarsModal {...getProps({calendarsPerRequest: 5})} />
    )
    const addCalendarButton = getByTestId('add-other-calendars-button')
    await openModal(addCalendarButton)
    await findByTestId(`account-${page1Results[1].id}-checkbox`)
    expect(queryByText('Show more')).not.toBeInTheDocument()
  })

  it('mark feature as seen when the modal is opened for the first time', async () => {
    const user = userEvent.setup({delay: null})
    const {getByTestId} = render(<AccountCalendarsModal {...getProps({featureSeen: null})} />)
    const addCalendarButton = getByTestId('add-other-calendars-button')
    await openModal(addCalendarButton)
    advance(500)
    expect(fetchMock.called(markAsSeenUrl)).toBe(true)
    expect(fetchMock.calls(markAsSeenUrl)).toHaveLength(1)
    const closeButton = getByTestId('footer-close-button')
    await user.click(closeButton)
    // wait for the modal to be closed
    await waitFor(() => expect(closeButton).not.toBeInTheDocument())
    await openModal(addCalendarButton)
    advance(500)
    // doesn't call the API if the modal is opened again
    expect(fetchMock.calls(markAsSeenUrl)).toHaveLength(1)
  })

  it('does not try to mark the feature as seen if it is already seen', async() => {
    const {getByTestId} = render(<AccountCalendarsModal {...getProps({featureSeen: true})} />)
    const addCalendarButton = getByTestId('add-other-calendars-button')
    await openModal(addCalendarButton)
    advance(500)
    expect(fetchMock.called(markAsSeenUrl)).toBe(false)
    expect(fetchMock.calls(markAsSeenUrl)).toHaveLength(0)
  })

  it('disables the save button if the user has not made any change', async () => {
    const user = userEvent.setup({delay: null})
    const {getByTestId, findByTestId} = render(<AccountCalendarsModal {...getProps()} />)
    const addCalendarButton = getByTestId('add-other-calendars-button')
    await openModal(addCalendarButton)
    const saveButton = getByTestId('save-calendars-button')
    expect(saveButton).toHaveAttribute('disabled')
    const calendarToEnable = await findByTestId(`account-${page1Results[1].id}-checkbox`)
    await user.click(calendarToEnable)
    expect(saveButton).not.toHaveAttribute('disabled')
  })

  describe('auto subscribe', () => {
    it('shows auto-subscribed calendars as disabled', async () => {
      const searchResponse = structuredClone(accountCalendarsAPIPage1Response)
      searchResponse.account_calendars[1].auto_subscribe = true
      fetchMock.get(
        SEARCH_ENDPOINT.concat('?per_page=2'),
        {
          body: searchResponse,
          headers: {
            Link: '</api/v1/account_calendars?&per_page=2&page=2>; rel="next"',
          },
        },
        {overwriteRoutes: true}
      )
      const {getByTestId, findByTestId} = render(
        <AccountCalendarsModal
          {...getProps({
            getSelectedOtherCalendars: () => searchResponse.account_calendars,
          })}
        />
      )
      const addCalendarButton = getByTestId('add-other-calendars-button')
      await openModal(addCalendarButton)
      expect((await findByTestId(`account-${page1Results[0].id}-checkbox`)).checked).toBe(true)
      expect(getByTestId(`account-${page1Results[1].id}-checkbox`).checked).toBe(true)
      expect(getByTestId(`account-${page1Results[1].id}-checkbox`).disabled).toBe(true)
    })

    it('includes a tooltip for auto-subscribed calendars', async () => {
      const user = userEvent.setup({delay: null})
      const searchResponse = structuredClone(accountCalendarsAPIPage1Response)
      searchResponse.account_calendars[1].auto_subscribe = true
      fetchMock.get(
        SEARCH_ENDPOINT.concat('?per_page=2'),
        {
          body: searchResponse,
          headers: {
            Link: '</api/v1/account_calendars?&per_page=2&page=2>; rel="next"',
          },
        },
        {overwriteRoutes: true}
      )
      const {getByTestId, getByText, findByText} = render(
        <AccountCalendarsModal
          {...getProps({
            getSelectedOtherCalendars: () => searchResponse.account_calendars,
          })}
        />
      )
      const addCalendarButton = getByTestId('add-other-calendars-button')
      await openModal(addCalendarButton)
      // assert the modal is open
      expect(await findByText('Select Calendars')).toBeInTheDocument()
      const helpButton = getByText('help').closest('button')
      expect(helpButton).toBeInTheDocument()
      await user.click(helpButton)
      expect(getByText('Calendars added by the admin cannot be removed')).toBeInTheDocument()
    })
  })

  describe('Search bar ', () => {
    it('shows the total number of available calendars to search through', async () => {
      const {findByPlaceholderText, getByTestId} = render(<AccountCalendarsModal {...getProps()} />)
      const addCalendarButton = getByTestId('add-other-calendars-button')
      await openModal(addCalendarButton)
      expect(await findByPlaceholderText(`Search ${totalCalendars} calendars`)).toBeInTheDocument()
    })

    it('fetches calendars that match with the input value', async () => {
      const {getByTestId, findByTestId} = render(<AccountCalendarsModal {...getProps()} />)
      const addCalendarButton = getByTestId('add-other-calendars-button')
      await openModal(addCalendarButton)
      const searchBar = await findByTestId('search-input')
      fireEvent.change(searchBar, {target: {value: 'Test'}})
      advance(500)
      expect(fetchMock.called(getSearchUrl('Test'))).toBe(true)
    })

    it('does not trigger search requests if the user has not typed at least 2 characters', async () => {
      const {findByTestId, getByTestId} = render(<AccountCalendarsModal {...getProps()} />)
      const addCalendarButton = getByTestId('add-other-calendars-button')
      await openModal(addCalendarButton)
      const searchBar = await findByTestId('search-input')
      fireEvent.change(searchBar, {target: {value: 'T'}})
      advance(500)
      expect(fetchMock.called(getSearchUrl('T'))).toBe(false)
    })

    it('shows an empty state if no calendar was found', async () => {
      const {findByTestId, findByText, getByTestId} = render(
        <AccountCalendarsModal {...getProps()} />
      )
      const addCalendarButton = getByTestId('add-other-calendars-button')
      await openModal(addCalendarButton)
      const searchBar = await findByTestId('search-input')
      fireEvent.change(searchBar, {target: {value: 'Test2'}})
      advance(500)
      expect(await findByText('Hmm, we can’t find any matching calendars.')).toBeInTheDocument()
      expect(await findByTestId('account-calendars-empty-state')).toBeInTheDocument()
    })

    it('announces search results for screen readers', async () => {
      const {findByTestId, getByTestId} = render(<AccountCalendarsModal {...getProps()} />)
      const addCalendarButton = getByTestId('add-other-calendars-button')
      await openModal(addCalendarButton)
      const searchBar = await findByTestId('search-input')
      fireEvent.change(searchBar, {target: {value: 'Test'}})
      advance(500)
      await findByTestId(`account-${searchResult[0].id}-checkbox`)
      expect(alertForMatchingAccounts).toHaveBeenCalledWith(1, false)
    })
  })
})
