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
import {render, act} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import {DashboardHeader} from '../DashboardHeader'
import {
  SHOW_K5_DASHBOARD_ROUTE,
  showK5DashboardResponse,
} from '@canvas/observer-picker/react/__tests__/fixtures'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

jest.useFakeTimers()

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
  describe('as an observer', () => {
    beforeAll(() => {
      window.ENV = defaultEnv
    })

    beforeEach(() => {
      fetchMock.get(SHOW_K5_DASHBOARD_ROUTE, JSON.stringify(showK5DashboardResponse(false, false)))
    })

    afterEach(async () => {
      await act(async () => jest.runOnlyPendingTimers())

      fetchMock.restore()
    })

    afterAll(() => {
      window.ENV = {}
    })

    it('does not load planner again after switching students', async () => {
      const loadPlannerSpy = jest.spyOn(DashboardHeader.prototype, 'loadPlannerComponent')
      const {findByRole, getByText, findByText} = render(<FakeDashboardHeader {...defaultProps} />)
      const select = await findByRole('combobox', {name: 'Select a student to view'})
      expect(loadPlannerSpy).toHaveBeenCalledTimes(1)
      await act(async () => select.click())
      await act(async () => getByText('Student 3').click())
      await findByText('Loading planner items')
      expect(loadPlannerSpy).toHaveBeenCalledTimes(1)
    })
  })
})
