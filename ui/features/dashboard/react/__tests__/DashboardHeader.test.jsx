/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, act, fireEvent, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {DashboardHeader} from '../DashboardHeader'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {resetPlanner} from '@canvas/planner'
import fetchMock from 'fetch-mock'

vi.mock('@canvas/planner', async () => {
  const actual = await vi.importActual('@canvas/planner')
  return {
    ...actual,
    resetPlanner: vi.fn(),
    initializePlanner: vi.fn().mockResolvedValue(),
    loadPlannerDashboard: vi.fn(),
  }
})

injectGlobalAlertContainers()

vi.useFakeTimers()

const defaultEnv = {
  current_user: {id: '1'},
  current_user_roles: ['user', 'student', 'observer'],
  OBSERVED_USERS_LIST: [
    {id: '2', name: 'Student 2', avatar_url: undefined},
    {id: '3', name: 'Student 3', avatar_url: undefined},
  ],
  CAN_ADD_OBSERVEE: false,
  MOMENT_LOCALE: 'en',
  TIMEZONE: 'UTC',
}

const defaultProps = {
  dashboard_view: 'planner',
  planner_enabled: true,
  allowElementaryDashboard: false,
  env: defaultEnv,
}

const FakeDashboardHeader = props => (
  <>
    <DashboardHeader id="dashboard_header_container" {...props} />
    <div id="flashalert_message_holder" style={{display: 'block'}} />
    <div id="dashboard-planner" style={{display: 'block'}} />
    <div id="dashboard-activity" style={{display: 'block'}} />
    <div id="DashboardCard_Container" style={{display: 'block'}} />
    <div id="application" />
  </>
)

describe('DashboardHeader', () => {
  let plannerSpy
  let saveDashboardViewSpy
  let cardLoadSpy

  beforeEach(() => {
    window.ENV = {
      ...defaultEnv,
      MOMENT_LOCALE: 'en',
      TIMEZONE: 'UTC',
      PREFERENCES: {},
      STUDENT_PLANNER_COURSES: [],
    }
    resetPlanner()
    plannerSpy = vi.spyOn(DashboardHeader.prototype, 'loadPlannerComponent')
    saveDashboardViewSpy = vi
      .spyOn(DashboardHeader.prototype, 'saveDashboardView')
      .mockImplementation(() => {})
    cardLoadSpy = vi.spyOn(DashboardHeader.prototype, 'loadCardDashboard')
    document.body.innerHTML = ''
    document.body.innerHTML = `
      <div id="dashboard-planner" style="display: none;"></div>
      <div id="dashboard-planner-header" style="display: none;"></div>
      <div id="dashboard-planner-header-aux" style="display: none;"></div>
      <div id="dashboard-activity" style="display: block;"></div>
      <div id="DashboardCard_Container" style="display: none;"></div>
      <div id="right-side-wrapper" style="display: none;"></div>
    `
  })

  afterEach(() => {
    plannerSpy.mockRestore()
    saveDashboardViewSpy.mockRestore()
    cardLoadSpy.mockRestore()
    resetPlanner()
    document.body.innerHTML = ''
  })

  it('renders', () => {
    const {container} = render(
      <DashboardHeader planner_enabled={true} planner_selected={true} env={window.ENV} />,
    )
    expect(container).toBeTruthy()
  })

  it('switches between dashboard views', async () => {
    const {getByRole} = render(
      <FakeDashboardHeader planner_enabled={false} dashboard_view="activity" />,
    )

    const dashboardActivity = document.getElementById('dashboard-activity')
    const dashboardCards = document.getElementById('DashboardCard_Container')

    // Initial state should show activity view
    expect(dashboardActivity.style.display).toBe('block')
    expect(dashboardCards.style.display).toBe('none')

    // Open menu and switch to cards view
    const menuButton = getByRole('button', {name: /dashboard options/i})
    await act(async () => {
      fireEvent.click(menuButton)
    })

    const cardsButton = getByRole('menuitemradio', {name: /card view/i})
    await act(async () => {
      fireEvent.click(cardsButton)
    })

    // Should now show cards view
    expect(dashboardActivity.style.display).toBe('none')
    expect(dashboardCards.style.display).toBe('block')

    // Switch back to activity view
    await act(async () => {
      fireEvent.click(menuButton)
    })

    const activityButton = getByRole('menuitemradio', {name: /recent activity/i})
    await act(async () => {
      fireEvent.click(activityButton)
    })

    // Should show activity view again
    expect(dashboardActivity.style.display).toBe('block')
    expect(dashboardCards.style.display).toBe('none')
  })

  it('shows planner view when enabled', async () => {
    const {getByRole} = render(
      <FakeDashboardHeader planner_enabled={true} dashboard_view="activity" />,
    )

    const dashboardPlanner = document.getElementById('dashboard-planner')
    const dashboardPlannerHeader = document.getElementById('dashboard-planner-header')
    const dashboardActivity = document.getElementById('dashboard-activity')
    const dashboardCards = document.getElementById('DashboardCard_Container')

    // Initial state
    expect(dashboardPlanner.style.display).toBe('none')
    expect(dashboardPlannerHeader.style.display).toBe('none')
    expect(dashboardActivity.style.display).toBe('block')

    // Switch to planner view
    const menuButton = getByRole('button', {name: /dashboard options/i})
    await act(async () => {
      fireEvent.click(menuButton)
    })

    const plannerButton = getByRole('menuitemradio', {name: /list view/i})
    await act(async () => {
      fireEvent.click(plannerButton)
    })

    // Should show planner view
    expect(dashboardPlanner.style.display).toBe('block')
    expect(dashboardPlannerHeader.style.display).toBe('block')
    expect(dashboardActivity.style.display).toBe('none')
    expect(dashboardCards.style.display).toBe('none')
  })

  describe('as an observer', () => {
    beforeEach(() => {
      window.ENV = {
        current_user_roles: ['observer'],
        current_user: {id: '1'},
        OBSERVED_USERS_LIST: [
          {id: '2', name: 'Student 2', avatar_url: ''},
          {id: '3', name: 'Student 3', avatar_url: ''},
        ],
        CAN_ADD_OBSERVEE: false,
        FEATURES: {
          instui_header: false,
        },
      }
    })

    it('maintains planner state when switching between students', async () => {
      const {getByTestId} = render(
        <FakeDashboardHeader
          planner_enabled={true}
          dashboard_view="planner"
          env={window.ENV}
          canAddObservee={false}
        />,
      )

      const dashboardPlanner = document.getElementById('dashboard-planner')
      const dashboardActivity = document.getElementById('dashboard-activity')

      // Initial state should show planner
      expect(dashboardPlanner.style.display).toBe('block')
      expect(dashboardActivity.style.display).toBe('none')

      // Change student
      const studentSelector = getByTestId('observed-student-dropdown')
      await act(async () => {
        fireEvent.change(studentSelector, {target: {value: '3'}})
      })

      // Should still show planner view
      expect(dashboardPlanner.style.display).toBe('block')
      expect(dashboardActivity.style.display).toBe('none')
    })

    it('does not trigger page reload on mount when widget_dashboard feature flag is on but user is on classic dashboard', async () => {
      delete window.location
      window.location = {reload: vi.fn()}

      window.ENV = {
        current_user_roles: ['observer'],
        current_user: {id: '1'},
        current_user_id: '1',
        OBSERVED_USERS_LIST: [
          {id: '2', name: 'Student 2', avatar_url: ''},
          {id: '3', name: 'Student 3', avatar_url: ''},
        ],
        CAN_ADD_OBSERVEE: false,
        FEATURES: {
          widget_dashboard: true,
        },
      }

      render(
        <FakeDashboardHeader planner_enabled={false} dashboard_view="activity" env={window.ENV} />,
      )

      await act(async () => {
        vi.advanceTimersByTime(100)
      })

      expect(window.location.reload).not.toHaveBeenCalled()
    })

    it('does not call loadCardDashboard if preloaded cards passed in', async () => {
      window.ENV = {
        ...defaultEnv,
        FEATURES: {
          dashboard_graphql_integration: true,
        },
      }
      const loadCardDashboardSpy = vi.spyOn(DashboardHeader.prototype, 'loadCardDashboard')
      render(<FakeDashboardHeader {...defaultProps} preloadedCards={[]} />)
      expect(loadCardDashboardSpy).not.toHaveBeenCalled()
    })
  })

  describe('Dashboard Toggle Button', () => {
    let reloadSpy

    beforeEach(() => {
      delete window.location
      window.location = {reload: vi.fn()}
      reloadSpy = window.location.reload
      fetchMock.restore()
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('renders switch button when widget_dashboard_overridable is false', () => {
      window.ENV = {
        ...defaultEnv,
        widget_dashboard_overridable: false,
        current_user_id: '1',
      }

      const {getByTestId} = render(<FakeDashboardHeader {...defaultProps} />)
      expect(getByTestId('switch-to-new-dashboard-button')).toBeInTheDocument()
      expect(getByTestId('switch-to-new-dashboard-button')).toHaveTextContent(
        'Switch to new dashboard view',
      )
    })

    it('does not render switch button when widget_dashboard_overridable is undefined', () => {
      window.ENV = {
        ...defaultEnv,
        current_user_id: '1',
      }

      const {queryByTestId} = render(<FakeDashboardHeader {...defaultProps} />)
      expect(queryByTestId('switch-to-new-dashboard-button')).not.toBeInTheDocument()
    })

    it('does not render switch button when widget_dashboard_overridable is true', () => {
      window.ENV = {
        ...defaultEnv,
        widget_dashboard_overridable: true,
        current_user_id: '1',
      }

      const {queryByTestId} = render(<FakeDashboardHeader {...defaultProps} />)
      expect(queryByTestId('switch-to-new-dashboard-button')).not.toBeInTheDocument()
    })

    it('calls API and reloads page when switch button is clicked', async () => {
      window.ENV = {
        ...defaultEnv,
        widget_dashboard_overridable: false,
        current_user_id: '1',
      }

      fetchMock.put('/api/v1/users/1/settings', {
        widget_dashboard_user_preference: true,
      })

      const {getByTestId} = render(<FakeDashboardHeader {...defaultProps} />)
      const switchButton = getByTestId('switch-to-new-dashboard-button')

      await act(async () => {
        fireEvent.click(switchButton)
      })

      await waitFor(() => {
        expect(fetchMock.called('/api/v1/users/1/settings')).toBe(true)
      })

      await waitFor(() => {
        expect(reloadSpy).toHaveBeenCalled()
      })
    })

    it('renders switch button in responsive view', () => {
      window.ENV = {
        ...defaultEnv,
        widget_dashboard_overridable: false,
        current_user_id: '1',
        FEATURES: {
          instui_header: true,
        },
      }

      const {getByTestId} = render(<FakeDashboardHeader {...defaultProps} responsiveSize="small" />)
      expect(getByTestId('switch-to-new-dashboard-button')).toBeInTheDocument()
    })
  })
})
