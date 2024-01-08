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
import {OBSERVER_COOKIE_PREFIX, clearObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import {act, render, waitFor} from '@testing-library/react'
import K5Dashboard from '../K5Dashboard'
import moxios from 'moxios'
import {
  opportunities,
  createPlannerMocks,
  defaultK5DashboardProps as defaultProps,
  defaultEnv,
} from './mocks'
import {resetCardCache} from '@canvas/dashboard-card'
import {MOCK_CARDS, MOCK_CARDS_2} from '@canvas/k5/react/__tests__/fixtures'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

jest.useFakeTimers()
jest.mock('@canvas/observer-picker/react/utils', () => ({
  ...jest.requireActual('@canvas/observer-picker/react/utils'),
  fetchShowK5Dashboard: jest.fn(),
}))

const currentUserId = defaultProps.currentUser.id
const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${currentUserId}`

describe('K5Dashboard Parent Support', () => {
  beforeEach(() => {
    document.cookie = `${observedUserCookieName}=4;path=/`
    moxios.install()
    global.ENV = defaultEnv
    fetchShowK5Dashboard.mockImplementation(() =>
      Promise.resolve({show_k5_dashboard: true, use_classic_font: false})
    )
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
      submission_types: ['online_text_entry'],
    },
  ]

  it('shows picker when user is an observer', () => {
    const {getByTestId} = render(
      <K5Dashboard
        {...defaultProps}
        canAddObservee={true}
        currentUserRoles={['user', 'observer']}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
      />
    )
    const select = getByTestId('observed-student-dropdown')
    expect(select).toBeInTheDocument()
    expect(select.value).toBe('Student 4')
  })

  // LF-1141
  it.skip('prefetches dashboard cards with the correct url param', async () => {
    moxios.stubRequest(
      window.location.origin + '/api/v1/dashboard/dashboard_cards?observed_user_id=4',
      {
        status: 200,
        response: MOCK_CARDS,
      }
    )

    render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        canAddObservee={true}
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
    expect(preFetchedRequest.url).toBe(
      window.location.origin + '/api/v1/dashboard/dashboard_cards?observed_user_id=4'
    )
    expect(moxios.requests.count()).toBe(1)
  })

  it.skip('does not make a request if the user has been already requested (flaky)', async () => {
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=4', {
      status: 200,
      response: MOCK_CARDS,
    })
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=2', {
      status: 200,
      response: MOCK_CARDS_2,
    })
    const {findByText, getByTestId, getByText, queryByText} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        canAddObservee={true}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
      />
    )
    expect(await findByText('Economics 101')).toBeInTheDocument()
    expect(queryByText('Economics 203')).not.toBeInTheDocument()
    const select = getByTestId('observed-student-dropdown')
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

  it.skip('shows the observee missing items on dashboard cards (flaky)', async () => {
    moxios.stubs.reset()
    moxios.requests.reset()
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=4', {
      status: 200,
      response: MOCK_CARDS,
    })
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=2', {
      status: 200,
      response: MOCK_CARDS_2,
    })
    moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submissions\?.*observed_user_id=4.*/, {
      status: 200,
      headers: {link: 'url; rel="current"'},
      response: opportunities,
    })
    moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submissions\?.*observed_user_id=2.*/, {
      status: 200,
      headers: {link: 'url; rel="current"'},
      response: opportunities2,
    })
    createPlannerMocks()

    const {getByText, findByTestId, getByTestId} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
        canAddObservee={true}
        plannerEnabled={true}
      />
    )
    // let the dashboard execute all its queries and render
    await waitFor(
      () => {
        expect(document.querySelectorAll('.ic-DashboardCard').length).toBeGreaterThan(0)
      },
      {timeout: 5000}
    )

    const missingItemsLink = await findByTestId('number-missing')
    expect(missingItemsLink).toBeInTheDocument()
    expect(missingItemsLink).toHaveTextContent(
      'View 2 missing items for course Economics 1012 missing'
    )

    const observerSelect = getByTestId('observed-student-dropdown')
    act(() => observerSelect.click())
    act(() => getByText('Student 2').click())

    await waitFor(() => {
      expect(getByTestId('number-missing')).toHaveTextContent(
        'View 1 missing items for course Economics 203'
      )
    })
    expect(getByTestId('number-missing')).toBeInTheDocument()
  })

  it('does not show options to disable k5 dashboard if student is selected', async () => {
    clearObservedId(defaultProps.currentUser.id)
    const {getByTestId, findByTestId, getByText, queryByTestId} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        observedUsersList={[defaultProps.currentUser, ...MOCK_OBSERVED_USERS_LIST]}
      />
    )
    const select = getByTestId('observed-student-dropdown')
    expect(select.value).toBe('Geoffrey Jellineck')
    expect(await findByTestId('k5-dashboard-options')).toBeInTheDocument()

    act(() => select.click())
    act(() => getByText('Student 4').click())
    expect(select.value).toBe('Student 4')
    await waitFor(() => expect(queryByTestId('k5-dashboard-options')).not.toBeInTheDocument())
  })

  describe('switching to classic student', () => {
    let originalLocation

    beforeEach(() => {
      originalLocation = window.location
      delete window.location
      window.location = {...originalLocation, reload: jest.fn()}
    })

    afterEach(() => {
      window.location = originalLocation
    })

    const switchToStudent2 = async () => {
      const {findByRole, getByText} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['user', 'observer', 'teacher']}
          observedUsersList={MOCK_OBSERVED_USERS_LIST}
          canAddObservee={true}
          plannerEnabled={true}
        />
      )
      const select = await findByRole('combobox', {name: 'Select a student to view'})
      act(() => select.click())
      act(() => getByText('Student 2').click())
    }

    it('does not reload the page if a k5 student with the same font selection is selected in the picker', async () => {
      await switchToStudent2()
      expect(window.location.reload).not.toHaveBeenCalled()
    })

    it('reloads the page when a classic student is selected in the students picker', async () => {
      fetchShowK5Dashboard.mockImplementationOnce(() =>
        Promise.resolve({show_k5_dashboard: false, use_classic_font: false})
      )
      await switchToStudent2()
      expect(window.location.reload).toHaveBeenCalled()
    })

    it('reloads the page when a k5 student with a different font selection is selected in the picker', async () => {
      fetchShowK5Dashboard.mockImplementationOnce(() =>
        Promise.resolve({show_k5_dashboard: true, use_classic_font: true})
      )
      await switchToStudent2()
      expect(window.location.reload).toHaveBeenCalled()
    })
  })

  describe('grades tab', () => {
    it('is visible to observers who have student enrollments', async () => {
      clearObservedId(defaultProps.currentUser.id)
      const {findByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['student', 'observer']}
          observedUsersList={[defaultProps.currentUser, ...MOCK_OBSERVED_USERS_LIST]}
        />
      )
      expect(await findByRole('tab', {name: 'Grades'})).toBeInTheDocument()
    })

    it('is visible to observers who have selected a student', async () => {
      const {findByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['observer']}
          observedUsersList={MOCK_OBSERVED_USERS_LIST}
        />
      )
      expect(await findByRole('tab', {name: 'Grades'})).toBeInTheDocument()
    })

    it('is not visible to observers who have themself selected (and no student/teacher enrollments)', async () => {
      clearObservedId(defaultProps.currentUser.id)
      const {findByRole, queryByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['observer']}
          observedUsersList={[defaultProps.currentUser, ...MOCK_OBSERVED_USERS_LIST]}
        />
      )
      await findByRole('tab', {name: 'Homeroom'})
      expect(queryByRole('tab', {name: 'Grades'})).not.toBeInTheDocument()
    })
  })
})
