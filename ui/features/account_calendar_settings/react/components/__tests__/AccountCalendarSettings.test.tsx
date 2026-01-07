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
import {cleanup, render, act, waitFor, fireEvent} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

import {AccountCalendarSettings} from '../AccountCalendarSettings'
import {RESPONSE_ACCOUNT_1, RESPONSE_ACCOUNT_5, RESPONSE_ACCOUNT_6} from './fixtures'

vi.mock('@canvas/calendar/AccountCalendarsUtils', () => {
  return {
    alertForMatchingAccounts: vi.fn(),
  }
})

const server = setupServer()

// To capture PUT request bodies
let lastPutRequestBody: unknown = null

const defaultProps = {
  accountId: 1,
}

beforeAll(() => server.listen())
afterAll(() => server.close())

beforeEach(() => {
  lastPutRequestBody = null
  server.use(
    http.get('/api/v1/accounts/1/account_calendars', ({request}) => {
      const url = new URL(request.url)
      const searchTerm = url.searchParams.get('search_term') || ''
      if (searchTerm === 'elemen') {
        return HttpResponse.json([
          {
            id: '134',
            name: 'West Elementary School',
            parent_account_id: '1',
            root_account_id: '0',
            visible: true,
            sub_account_count: 0,
          },
        ])
      }
      return HttpResponse.json(RESPONSE_ACCOUNT_1)
    }),
    http.get('/api/v1/accounts/1/visible_calendars_count', () => {
      return HttpResponse.json(RESPONSE_ACCOUNT_1.length)
    }),
    http.put('/api/v1/accounts/1/account_calendars', async ({request}) => {
      lastPutRequestBody = await request.json()
      return HttpResponse.json({message: 'Updated 1 account'})
    }),
  )
  vi.clearAllMocks()
})

afterEach(() => {
  cleanup()
  server.resetHandlers()
  destroyContainer()
  vi.useRealTimers()
})

describe('AccountCalendarSettings', () => {
  it('renders header and subtext', () => {
    const {getByRole, getByText} = render(<AccountCalendarSettings {...defaultProps} />)
    expect(
      getByRole('heading', {name: 'Account Calendar Visibility', level: 1}),
    ).toBeInTheDocument()
    expect(
      getByText(
        'Choose which calendars your users can add in the "Other Calendars" section of their Canvas calendar. Users will only be able to add enabled calendars for the accounts they are associated with. By default, all calendars are disabled.',
      ),
    ).toBeInTheDocument()
  })

  it('saves changes when clicking apply', async () => {
    // PUT handler already set up in beforeEach
    const {findByText, getByText, findAllByText, getByTestId, findAllByTestId} = render(
      <AccountCalendarSettings {...defaultProps} />,
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
      <AccountCalendarSettings {...defaultProps} />,
    )
    await findByText('University (5)')
    // Search handler already set up in beforeEach to return West Elementary School for 'elemen'
    const search = getByPlaceholderText('Search Calendars')
    fireEvent.change(search, {target: {value: 'elemen'}})
    expect(await findByText('West Elementary School')).toBeInTheDocument()
    expect(queryByTestId('account-tree')).not.toBeVisible()
  })

  describe('auto subscription settings', () => {
    beforeEach(() => {
      // Reset and set up fresh handlers for this describe block
      server.resetHandlers(
        http.get('/api/v1/accounts/1/visible_calendars_count', () => {
          return HttpResponse.json(RESPONSE_ACCOUNT_5.length)
        }),
        http.get('/api/v1/accounts/1/account_calendars', () => {
          return HttpResponse.json(RESPONSE_ACCOUNT_5)
        }),
        http.put('/api/v1/accounts/1/account_calendars', async ({request}) => {
          lastPutRequestBody = await request.json()
          return HttpResponse.json({message: 'Updated 1 account'})
        }),
      )
      vi.clearAllMocks()
    })

    it('saves subscription type changes', async () => {
      const {findByText, getByText, getByTestId, getAllByTestId} = render(
        <AccountCalendarSettings {...defaultProps} />,
      )
      expect(await findByText('Manually-Created Courses (2)')).toBeInTheDocument()

      act(() => getAllByTestId('subscription-dropdown')[0].click())
      act(() => getByText('Auto subscribe').click())
      act(() => getByTestId('save-button').click())
      act(() => getByTestId('confirm-button').click())
      await waitFor(() => {
        expect(lastPutRequestBody).toEqual([{id: RESPONSE_ACCOUNT_5[0].id, auto_subscribe: true}])
      })
    })

    it('shows the confirmation modal if switching from manual to auto subscription', async () => {
      const {getByRole, getByText, findByText, getByTestId, getAllByTestId} = render(
        <AccountCalendarSettings {...defaultProps} />,
      )
      expect(await findByText('Manually-Created Courses (2)')).toBeInTheDocument()

      act(() => getAllByTestId('subscription-dropdown')[0].click())
      act(() => getByText('Auto subscribe').click())
      act(() => getByTestId('save-button').click())
      const modalTitle = getByRole('heading', {name: 'Apply Changes'})
      expect(modalTitle).toBeInTheDocument()
    })

    it('does not show the confirmation modal if switching from auto to manual subscription', async () => {
      server.use(
        http.get('/api/v1/accounts/1/account_calendars', () => {
          return HttpResponse.json(RESPONSE_ACCOUNT_6)
        }),
        http.get('/api/v1/accounts/1/visible_calendars_count', () => {
          return HttpResponse.json(RESPONSE_ACCOUNT_6.length)
        }),
        http.put('/api/v1/accounts/1/account_calendars', async ({request}) => {
          lastPutRequestBody = await request.json()
          return HttpResponse.json({message: 'Updated 1 account'})
        }),
      )

      const {queryByRole, getByText, findByText, getByTestId} = render(
        <AccountCalendarSettings {...defaultProps} />,
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

    it('does not show the confirmation modal if changing only the account visibility', async () => {
      const {queryByRole, getByRole, getByTestId, findByText} = render(
        <AccountCalendarSettings {...defaultProps} />,
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
        // Reset and set up ACCOUNT_1 handlers for these tests
        server.resetHandlers(
          http.get('/api/v1/accounts/1/account_calendars', ({request}) => {
            const url = new URL(request.url)
            const searchTerm = url.searchParams.get('search_term') || ''
            if (searchTerm === 'elemen') {
              return HttpResponse.json([
                {
                  id: '134',
                  name: 'West Elementary School',
                  parent_account_id: '1',
                  root_account_id: '0',
                  visible: true,
                  sub_account_count: 0,
                },
              ])
            }
            return HttpResponse.json(RESPONSE_ACCOUNT_1)
          }),
          http.get('/api/v1/accounts/1/visible_calendars_count', () => {
            return HttpResponse.json(RESPONSE_ACCOUNT_1.length)
          }),
          http.put('/api/v1/accounts/1/account_calendars', async ({request}) => {
            lastPutRequestBody = await request.json()
            return HttpResponse.json({message: 'Updated 1 account'})
          }),
        )
      })

      it('calendar visibility changes', async () => {
        const getUniversityCheckbox = () =>
          getByRole('checkbox', {
            name: 'Show account calendar for University',
          })

        const {findByText, getByRole} = render(<AccountCalendarSettings {...defaultProps} />)
        expect(await findByText('University (5)')).toBeInTheDocument()

        act(() => getUniversityCheckbox().click())

        const event = new Event('beforeunload')
        event.preventDefault = vi.fn()
        window.dispatchEvent(event)
        expect(event.preventDefault).toHaveBeenCalled()

        act(() => getUniversityCheckbox().click())

        event.preventDefault = vi.fn()
        window.dispatchEvent(event)
        expect(event.preventDefault).not.toHaveBeenCalled()
      })

      it('calendar subscription type changes', async () => {
        const {findByText, getByText, getAllByTestId} = render(
          <AccountCalendarSettings {...defaultProps} />,
        )
        expect(await findByText('University (5)')).toBeInTheDocument()

        act(() => getAllByTestId('subscription-dropdown')[0].click())
        act(() => getByText('Auto subscribe').click())

        const event = new Event('beforeunload')
        event.preventDefault = vi.fn()
        window.dispatchEvent(event)
        expect(event.preventDefault).toHaveBeenCalled()

        act(() => getAllByTestId('subscription-dropdown')[0].click())
        act(() => getByText('Manual subscribe').click())

        event.preventDefault = vi.fn()
        window.dispatchEvent(event)
        expect(event.preventDefault).not.toHaveBeenCalled()
      })
    })
  })
})
