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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import DarkModeToggle from '../DarkModeToggle'
import {WidgetThemeProvider} from '../../theme/WidgetThemeContext'

const server = setupServer()

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

const renderToggle = ({isDark = false, setIsDark = jest.fn()} = {}) => {
  return {
    setIsDark,
    ...render(
      <WidgetThemeProvider isDark={isDark} setIsDark={setIsDark}>
        <DarkModeToggle />
      </WidgetThemeProvider>,
    ),
  }
}

describe('DarkModeToggle', () => {
  beforeEach(() => {
    ENV.current_user_id = '1'
  })

  it('renders the toggle with off test ID when light mode', () => {
    renderToggle()
    expect(screen.getByTestId('dashboard-darkmode-toggle-off')).toBeInTheDocument()
    expect(screen.getByText('Switch to dark mode')).toBeInTheDocument()
  })

  it('renders the toggle with on test ID when dark mode', () => {
    renderToggle({isDark: true})
    expect(screen.getByTestId('dashboard-darkmode-toggle-on')).toBeInTheDocument()
    expect(screen.getByText('Switch to light mode')).toBeInTheDocument()
  })

  it('reflects light state as unchecked', () => {
    renderToggle({isDark: false})
    expect(screen.getByText('Switch to dark mode')).toBeInTheDocument()
  })

  it('calls settings API and setIsDark on toggle', async () => {
    const user = userEvent.setup()
    server.use(
      http.put('/api/v1/users/1/settings', () => {
        return HttpResponse.json({widget_dashboard_dark_mode: true})
      }),
    )

    const {setIsDark} = renderToggle({isDark: false})
    await user.click(screen.getByTestId('dashboard-darkmode-toggle-off'))

    await waitFor(() => {
      expect(setIsDark).toHaveBeenCalledWith(true)
    })
  })

  it('calls settings API to turn off dark mode', async () => {
    const user = userEvent.setup()
    server.use(
      http.put('/api/v1/users/1/settings', () => {
        return HttpResponse.json({widget_dashboard_dark_mode: false})
      }),
    )

    const {setIsDark} = renderToggle({isDark: true})
    await user.click(screen.getByTestId('dashboard-darkmode-toggle-on'))

    await waitFor(() => {
      expect(setIsDark).toHaveBeenCalledWith(false)
    })
  })
})
