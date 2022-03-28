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
import {MOCK_OBSERVED_USERS_LIST} from '@canvas/observer-picker/react/__tests__/fixtures'
import {OBSERVER_COOKIE_PREFIX} from '@canvas/observer-picker/ObserverGetObservee'
import {act, render, waitFor} from '@testing-library/react'
import K5Dashboard from '../K5Dashboard'
import moxios from 'moxios'
import {
  opportunities,
  createPlannerMocks,
  defaultK5DashboardProps as defaultProps,
  defaultEnv
} from './mocks'
import {resetCardCache} from '@canvas/dashboard-card'
import {MOCK_CARDS, MOCK_CARDS_2} from '@canvas/k5/react/__tests__/fixtures'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'

jest.mock('@canvas/observer-picker/react/utils', () => ({
  ...jest.requireActual('@canvas/observer-picker/react/utils'),
  fetchShowK5Dashboard: jest.fn()
}))

const currentUserId = defaultProps.currentUser.id
const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${currentUserId}`

describe('K5Dashboard Parent Support', () => {
  beforeAll(() => {
    jest.setTimeout(15000)
  })

  afterAll(() => {
    jest.setTimeout(5000)
  })
  beforeEach(() => {
    document.cookie = `${observedUserCookieName}=4;path=/`
    moxios.install()
    global.ENV = defaultEnv
    fetchShowK5Dashboard.mockImplementation(() => Promise.resolve(true))
  })

  afterEach(() => {
    moxios.uninstall()
    global.ENV = {}
    resetCardCache()
  })

  const opportunities2 = [
    {
      id: '3',
      course_id: '23',
      name: 'A new Assignment',
      points_possible: 10,
      html_url: '/courses/23/assignments/3',
      due_at: '2021-02-15T05:59:00Z',
      submission_types: ['online_text_entry']
    }
  ]

  it('shows picker when user is an observer', () => {
    const {getByRole} = render(
      <K5Dashboard
        {...defaultProps}
        canAddObservee
        currentUserRoles={['user', 'observer']}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
      />
    )
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select).toBeInTheDocument()
    expect(select.value).toBe('Student 4')
  })

  it('prefetches dashboard cards with the correct url param', async done => {
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=4', {
      status: 200,
      response: MOCK_CARDS
    })

    render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        canAddObservee
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
      />
    )
    // let the dashboard execute all its queries and render
    await waitFor(
      () => {
        expect(moxios.requests.mostRecent()).not.toBeNull()
      },
      {timeout: 5000}
    )
    const preFetchedRequest = moxios.requests.mostRecent()
    expect(preFetchedRequest.url).toBe('/api/v1/dashboard/dashboard_cards?observed_user_id=4')
    expect(moxios.requests.count()).toBe(1)
    done()
  })

  it('does not make a request if the user has been already requested', async () => {
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=4', {
      status: 200,
      response: MOCK_CARDS
    })
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=2', {
      status: 200,
      response: MOCK_CARDS_2
    })
    const {findByText, getByRole, getByText, queryByText} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        canAddObservee
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
      />
    )
    expect(await findByText('Economics 101')).toBeInTheDocument()
    expect(queryByText('Economics 203')).not.toBeInTheDocument()
    const select = getByRole('combobox', {name: 'Select a student to view'})
    expect(select.value).toBe('Student 4')
    expect(moxios.requests.mostRecent().url).toBe(
      '/api/v1/dashboard/dashboard_cards?observed_user_id=4'
    )
    act(() => select.click())
    act(() => getByText('Student 2').click())
    expect(await findByText('Economics 203')).toBeInTheDocument()
    expect(queryByText('Economics 101')).not.toBeInTheDocument()
    expect(moxios.requests.mostRecent().url).toBe(
      '/api/v1/dashboard/dashboard_cards?observed_user_id=2'
    )
    act(() => select.click())
    act(() => getByText('Student 4').click())
    expect(await findByText('Economics 101')).toBeInTheDocument()
    expect(queryByText('Economics 203')).not.toBeInTheDocument()
    // Should not fetch student 4's cards again; they've been cached
    expect(moxios.requests.mostRecent().url).toBe(
      '/api/v1/dashboard/dashboard_cards?observed_user_id=2'
    )
    // 2 total requests - one for student 4, one for student 2
    expect(moxios.requests.count()).toBe(2)
  })

  it('shows the observee missing items on dashboard cards', async () => {
    moxios.stubs.reset()
    moxios.requests.reset()
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=4', {
      status: 200,
      response: MOCK_CARDS
    })
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=2', {
      status: 200,
      response: MOCK_CARDS_2
    })
    moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submissions\?.*observed_user_id=4.*/, {
      status: 200,
      headers: {link: 'url; rel="current"'},
      response: opportunities
    })
    moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submissions\?.*observed_user_id=2.*/, {
      status: 200,
      headers: {link: 'url; rel="current"'},
      response: opportunities2
    })
    createPlannerMocks()

    const {getByText, findByRole, getByRole} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
        canAddObservee
        plannerEnabled
      />
    )
    // let the dashboard execute all its queries and render
    await waitFor(
      () => {
        expect(document.querySelectorAll('.ic-DashboardCard').length).toBeGreaterThan(0)
      },
      {timeout: 5000}
    )
    expect(
      await findByRole('link', {
        name: 'View 2 missing items for course Economics 101',
        timeout: 5000,
        exact: false
      })
    ).toBeInTheDocument()
    const observerSelect = getByRole('combobox', {name: 'Select a student to view'})
    act(() => observerSelect.click())
    act(() => getByText('Student 2').click())
    expect(
      await findByRole('link', {
        name: 'View 1 missing items for course Economics 203',
        timeout: 5000,
        exact: false
      })
    ).toBeInTheDocument()
  })

  describe('switching to classic student', () => {
    let originalLocation
    let reloadMock

    beforeAll(() => {
      originalLocation = window.location
      reloadMock = jest.fn()
      Object.defineProperty(window, 'location', {
        configurable: true,
        value: {...window.location, reload: reloadMock}
      })
    })

    afterAll(() => {
      Object.defineProperty(window, 'location', {
        configurable: true,
        value: originalLocation
      })
    })

    beforeEach(() => {
      fetchShowK5Dashboard.mockImplementationOnce(() => Promise.resolve(false))
      reloadMock.mockClear()
    })

    it('reloads the page if observer_picker is on', async () => {
      const {findByRole, getByText} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['user', 'observer', 'teacher']}
          observedUsersList={MOCK_OBSERVED_USERS_LIST}
          canAddObservee
          plannerEnabled
        />
      )
      const select = await findByRole('combobox', {name: 'Select a student to view'})
      act(() => select.click())
      act(() => getByText('Student 2').click())
      await waitFor(() => expect(reloadMock).toHaveBeenCalled())
    })

    it('does not reload the page if observer_picker is off', async () => {
      moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=2', {
        status: 200,
        response: MOCK_CARDS_2
      })

      const {findByRole, getByText, findByText} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['user', 'observer', 'teacher']}
          observedUsersList={MOCK_OBSERVED_USERS_LIST}
          canAddObservee
          plannerEnabled
          observerPickerEnabled={false}
        />
      )
      const select = await findByRole('combobox', {name: 'Select a student to view'})
      act(() => select.click())
      act(() => getByText('Student 2').click())
      expect(await findByText('Economics 203')).toBeInTheDocument()
      expect(reloadMock).not.toHaveBeenCalled()
    })
  })
})
