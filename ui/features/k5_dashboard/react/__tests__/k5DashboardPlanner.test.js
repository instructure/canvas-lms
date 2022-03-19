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
import K5Dashboard from '../K5Dashboard'
import moxios from 'moxios'
import {cloneDeep} from 'lodash'
import {resetPlanner} from '@instructure/canvas-planner'
import {MOCK_CARDS, MOCK_CARDS_2, MOCK_PLANNER_ITEM} from '@canvas/k5/react/__tests__/fixtures'
import {
  createPlannerMocks,
  opportunities,
  defaultK5DashboardProps as defaultProps,
  defaultEnv
} from './mocks'

const currentUserId = defaultProps.currentUser.id

describe('K5Dashboard Schedule Section', () => {
  beforeAll(() => {
    jest.setTimeout(15000)
  })

  afterAll(() => {
    jest.setTimeout(5000)
  })
  beforeEach(() => {
    moxios.install()
    createPlannerMocks()
    global.ENV = defaultEnv
  })
  afterEach(() => {
    moxios.uninstall()
    global.ENV = {}
    resetPlanner()
  })

  it('displays the planner with a planned item', async () => {
    const {findByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
    // The new weekly planner doesn't display the PlannerEmptyState.
    // This will get addressed one way or another with LS-2042
    // expect(await findByText("Looks like there isn't anything here")).toBeInTheDocument()
    // expect(await findByText('Nothing More To Do')).toBeInTheDocument()
  })
  // Skipping for flakiness. See https://instructure.atlassian.net/browse/LS-2243.
  it.skip('displays a list of missing assignments if there are any', async () => {
    const {findByRole, getByRole, getByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
    )
    const missingAssignments = await findByRole('button', {
      name: 'Show 2 missing items',
      timeout: 5000
    })
    expect(missingAssignments).toBeInTheDocument()
    act(() => missingAssignments.click())
    expect(getByRole('button', {name: 'Hide 2 missing items'})).toBeInTheDocument()
    expect(getByText('Assignment 1')).toBeInTheDocument()
    expect(getByText('Assignment 2')).toBeInTheDocument()
  })

  it('renders the weekly planner header', async () => {
    const {findByTestId} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
    )
    const planner = await findByTestId('PlannerApp', {timeout: 4000}) // give it some more time
    expect(planner).toBeInTheDocument()
    const header = await findByTestId('WeeklyPlannerHeader')
    expect(header).toBeInTheDocument()
  })

  it('renders an "jump to navigation" button at the bottom of the schedule tab', async () => {
    const {findByRole} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
    )
    const jumpToNavButton = await findByRole('button', {name: 'Jump to navigation toolbar'})
    expect(jumpToNavButton).not.toBeVisible()
    act(() => jumpToNavButton.focus())
    expect(jumpToNavButton).toBeVisible()
    act(() => jumpToNavButton.click())
    expect(document.activeElement.id).toBe('weekly-header-active-button')
    expect(jumpToNavButton).not.toBeVisible()
  })

  it('allows navigating to next/previous weeks if there are plannable items in the future/past', async () => {
    const {findByRole, getByRole} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
    )
    const todayButton = await findByRole('button', {name: 'Jump to Today'})
    expect(todayButton).toBeEnabled()
    const previousButton = getByRole('button', {name: 'View previous week'})
    await waitFor(() => expect(previousButton).toBeEnabled())
    const nextButton = getByRole('button', {name: 'View next week'})
    expect(nextButton).toBeEnabled()
  })

  it('displays a teacher preview if the user has no student enrollments', async () => {
    const {findByTestId, getByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={false} />
    )
    expect(await findByTestId('kinder-panda')).toBeInTheDocument()
    expect(getByText('Schedule Preview')).toBeInTheDocument()
    expect(
      getByText('Below is an example of how students will see their schedule')
    ).toBeInTheDocument()
    expect(getByText('Math')).toBeInTheDocument()
    expect(getByText('A wonderful assignment')).toBeInTheDocument()
    expect(getByText('Social Studies')).toBeInTheDocument()
    expect(getByText('Exciting discussion')).toBeInTheDocument()
  })

  it('preloads surrounding weeks only once schedule tab is visible', async done => {
    const {findByText, getByRole} = render(
      <K5Dashboard {...defaultProps} currentUserRoles={['user', 'student']} plannerEnabled />
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
    expect(moxios.requests.count()).toBe(6)
    act(() => getByRole('tab', {name: 'Schedule'}).click())
    moxios.wait(() => {
      expect(moxios.requests.count()).toBe(8) // 2 more requests for prev and next week preloads
      done()
    })
  })

  it('reloads the planner with correct data when the selected observee is updated', async done => {
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=1', {
      status: 200,
      response: MOCK_CARDS
    })
    const observerPlannerItem = cloneDeep(MOCK_PLANNER_ITEM)
    observerPlannerItem[0].plannable.title = 'Assignment for Observee'
    const observedUsersList = [
      {
        id: currentUserId,
        name: 'Self'
      },
      {
        id: '2',
        name: 'Student 2'
      }
    ]
    const {findByText, findByRole, getByRole, getByText} = render(
      <K5Dashboard
        {...defaultProps}
        defaultTab="tab-schedule"
        plannerEnabled
        canAddObservee
        currentUserRoles={['user', 'observer']}
        observedUsersList={observedUsersList}
      />
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
    expect(
      await findByRole('button', {
        name: 'Show 2 missing items',
        timeout: 5000
      })
    ).toBeInTheDocument()
    moxios.stubs.reset()
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=2', {
      status: 200,
      response: MOCK_CARDS_2
    })
    moxios.stubRequest(/api\/v1\/planner\/items\?.*observed_user_id=2.*/, {
      status: 200,
      headers: {link: 'url; rel="current"'},
      response: observerPlannerItem
    })
    moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submissions\?.*observed_user_id=2.*/, {
      status: 200,
      headers: {link: 'url; rel="current"'},
      response: [opportunities[0]]
    })
    const observerSelect = getByRole('combobox', {name: 'Select a student to view'})
    act(() => observerSelect.click())
    act(() => getByText('Student 2').click())
    expect(await findByText('Assignment for Observee')).toBeInTheDocument()
    expect(
      await findByRole('button', {
        name: 'Show 1 missing item',
        timeout: 10000
      })
    ).toBeInTheDocument()
    moxios.wait(() => {
      const request = moxios.requests.mostRecent()
      expect(request.url).toContain('observed_user_id=2')
      done()
    })
  })
})
