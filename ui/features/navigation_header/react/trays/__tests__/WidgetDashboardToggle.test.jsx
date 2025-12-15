/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import WidgetDashboardToggle from '../WidgetDashboardToggle'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('WidgetDashboardToggle', () => {
  let route

  beforeEach(() => {
    fakeENV.setup({
      current_user_id: '1',
    })
    route = `/api/v1/users/${window.ENV.current_user_id}/settings`
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  describe('when widget dashboard is off', () => {
    beforeEach(() => {
      fakeENV.setup({
        current_user_id: '1',
      })
      fetchMock.put(route, {
        widget_dashboard_user_preference: true,
      })
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('shows a toggle in the "off" position', () => {
      const {getByRole, getByTestId} = render(<WidgetDashboardToggle />)
      const toggle = getByRole('checkbox')
      expect(toggle).not.toBeChecked()
      expect(getByTestId('widget-dashboard-toggle-off')).toBeInTheDocument()
    })

    it('makes an API call to turn on widget dashboard if the toggle is clicked', async () => {
      const {getByRole} = render(<WidgetDashboardToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      expect(fetchMock.calls(route)).toHaveLength(1)
      const response = JSON.parse(fetchMock.calls(route)[0][1].body)
      expect(response).toMatchObject({
        widget_dashboard_user_preference: true,
      })
    })

    it('shows the explainer after a successful return, and flips the toggle on', async () => {
      const {getByRole, findByText, getByTestId} = render(<WidgetDashboardToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      await findByText(/reload the page or navigate/i)
      expect(toggle).toBeChecked()
      expect(window.ENV.widget_dashboard_overridable).toBe(true)
      expect(getByTestId('widget-dashboard-toggle-on')).toBeInTheDocument()
    })
  })

  describe('when widget dashboard is on', () => {
    beforeEach(() => {
      fakeENV.setup({
        current_user_id: '1',
        widget_dashboard_overridable: true,
      })
      fetchMock.put(route, {
        widget_dashboard_user_preference: false,
      })
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('shows a toggle in the "on" position', () => {
      const {getByRole, getByTestId} = render(<WidgetDashboardToggle />)
      const toggle = getByRole('checkbox')
      expect(toggle).toBeChecked()
      expect(getByTestId('widget-dashboard-toggle-on')).toBeInTheDocument()
    })

    it('makes an API call to turn off widget dashboard if the toggle is clicked', async () => {
      const {getByRole} = render(<WidgetDashboardToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      expect(fetchMock.calls(route)).toHaveLength(1)
      const response = JSON.parse(fetchMock.calls(route)[0][1].body)
      expect(response).toMatchObject({
        widget_dashboard_user_preference: false,
      })
    })

    it('shows the explainer after a successful return, and flips the toggle off', async () => {
      const {getByRole, findByText, getByTestId} = render(<WidgetDashboardToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      await findByText(/reload the page or navigate/i)
      expect(toggle).not.toBeChecked()
      expect(window.ENV.widget_dashboard_overridable).toBe(false)
      expect(getByTestId('widget-dashboard-toggle-off')).toBeInTheDocument()
    })
  })

  describe('sad path', () => {
    const badResponse = {
      status: 400,
      body: {error: 'something terrible happened'},
    }

    beforeEach(() => {
      fakeENV.setup({
        current_user_id: '1',
        widget_dashboard_overridable: false,
      })
      fetchMock.put(route, badResponse, {overwriteRoutes: true})
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    })

    afterEach(() => {
      const liveRegion = document.getElementById('flash_screenreader_holder')
      if (liveRegion) {
        liveRegion.remove()
      }
      fetchMock.restore()
      fakeENV.teardown()
    })

    it('puts up a flash when bad data comes back from the API call', async () => {
      const {getByRole, findByRole} = render(<WidgetDashboardToggle />)
      const toggle = getByRole('checkbox')
      await userEvent.click(toggle)
      await findByRole('alert')
      expect(toggle).not.toBeChecked()
      expect(window.ENV.widget_dashboard_overridable).toBe(false)
    })
  })
})
