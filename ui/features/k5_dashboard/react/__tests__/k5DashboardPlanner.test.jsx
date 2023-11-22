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
import {resetPlanner} from '@canvas/planner'
import {MOCK_CARDS, MOCK_CARDS_2, MOCK_PLANNER_ITEM} from '@canvas/k5/react/__tests__/fixtures'
import {
  createPlannerMocks,
  opportunities,
  defaultK5DashboardProps as defaultProps,
  defaultEnv,
} from './mocks'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'
import {enableFetchMocks} from 'jest-fetch-mock'

enableFetchMocks()

jest.mock('@canvas/observer-picker/react/utils', () => ({
  ...jest.requireActual('@canvas/observer-picker/react/utils'),
  fetchShowK5Dashboard: jest.fn(),
}))

const currentUserId = defaultProps.currentUser.id
const moxiosWait = () => new Promise(resolve => moxios.wait(resolve))

describe('K5Dashboard Schedule Section', () => {
  beforeEach(() => {
    moxios.install()
    createPlannerMocks()
    global.ENV = defaultEnv
    fetchShowK5Dashboard.mockImplementation(() =>
      Promise.resolve({show_k5_dashboard: true, use_classic_font: false})
    )
  })

  afterEach(() => {
    moxios.uninstall()
    global.ENV = {}
    resetPlanner()
  })

  // FOO-3831
  it.skip('displays the planner with a planned item', async () => {
    const {findByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
  })

  // FOO-3831
  it.skip('displays a list of missing assignments if there are any (flaky)', async () => {
    const {findByTestId, findByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />
    )
    const missingAssignments = await findByTestId('missing-item-info')
    expect(missingAssignments).toHaveTextContent('Show 2 missing items')
    expect(missingAssignments).toBeInTheDocument()

    act(() => missingAssignments.click())
    expect(missingAssignments).toHaveTextContent('Hide 2 missing items')
    expect(await findByText('Assignment 1')).toBeInTheDocument()
    expect(await findByText('Assignment 2')).toBeInTheDocument()
  })

  // FOO-3831
  it.skip('renders the weekly planner header (flaky)', async () => {
    const {findByTestId} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />
    )
    const planner = await findByTestId('PlannerApp', {timeout: 4000}) // give it some more time
    expect(planner).toBeInTheDocument()
    const header = await findByTestId('WeeklyPlannerHeader')
    expect(header).toBeInTheDocument()
  })

  it('renders an "jump to navigation" button at the bottom of the schedule tab', async () => {
    const {findByTestId} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />
    )
    const jumpToNavButton = await findByTestId('jump-to-weekly-nav-button')
    expect(jumpToNavButton).not.toBeVisible()
    act(() => jumpToNavButton.focus())
    expect(jumpToNavButton).toBeVisible()
    act(() => jumpToNavButton.click())
    expect(document.activeElement.id).toBe('weekly-header-active-button')
    expect(jumpToNavButton).not.toBeVisible()
  })

  it('allows navigating to next/previous weeks if there are plannable items in the future/past', async () => {
    const {findByTestId, getByTestId} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />
    )
    const todayButton = await findByTestId('jump-to-today-button')
    expect(todayButton).toBeEnabled()
    const previousButton = getByTestId('view-previous-week-button')
    await waitFor(() => expect(previousButton).toBeEnabled())
    const nextButton = getByTestId('view-next-week-button')
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

  it('preloads surrounding weeks only once schedule tab is visible', async () => {
    const {findByText, getByText} = render(
      <K5Dashboard {...defaultProps} currentUserRoles={['user', 'student']} plannerEnabled={true} />
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
    expect(moxios.requests.count()).toBe(6)
    act(() => getByText('Schedule').click())
    await moxiosWait()
    expect(moxios.requests.count()).toBe(8) // 2 more requests for prev and next week preloads
  })

  // FOO-3831
  it.skip('reloads the planner with correct data when the selected observee is updated (flaky)', async () => {
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=1', {
      status: 200,
      response: MOCK_CARDS,
    })
    const observerPlannerItem = cloneDeep(MOCK_PLANNER_ITEM)
    observerPlannerItem[0].plannable.title = 'Assignment for Observee'
    const observedUsersList = [
      {
        id: currentUserId,
        name: 'Self',
      },
      {
        id: '2',
        name: 'Student 2',
      },
    ]
    const {findByText, findByTestId, getByTestId, getByText} = render(
      <K5Dashboard
        {...defaultProps}
        defaultTab="tab-schedule"
        plannerEnabled={true}
        canAddObservee={true}
        currentUserRoles={['user', 'observer']}
        observedUsersList={observedUsersList}
      />
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
    expect(await findByTestId('missing-item-info')).toHaveTextContent('Show 2 missing items')
    moxios.stubs.reset()
    moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user_id=2', {
      status: 200,
      response: MOCK_CARDS_2,
    })
    moxios.stubRequest(/api\/v1\/planner\/items\?.*observed_user_id=2.*/, {
      status: 200,
      headers: {link: 'url; rel="current"'},
      response: observerPlannerItem,
    })
    moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submissions\?.*observed_user_id=2.*/, {
      status: 200,
      headers: {link: 'url; rel="current"'},
      response: [opportunities[0]],
    })
    const observerSelect = getByTestId('observed-student-dropdown')
    act(() => observerSelect.click())
    act(() => getByText('Student 2').click())
    expect(await findByText('Assignment for Observee')).toBeInTheDocument()
    expect(await findByTestId('missing-item-info')).toHaveTextContent('Show 1 missing item')
    await moxiosWait()
    const request = moxios.requests.mostRecent()
    expect(request.url).toContain('observed_user_id=2')
  })
})
