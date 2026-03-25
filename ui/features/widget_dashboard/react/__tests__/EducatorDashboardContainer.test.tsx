/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import EducatorDashboardContainer from '../EducatorDashboardContainer'
import {WidgetDashboardProvider} from '../hooks/useWidgetDashboardContext'
import {ResponsiveProvider} from '../hooks/useResponsiveContext'
import {PlatformTestWrapper} from './testHelpers'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('../components/WidgetGrid', () => ({
  default: () => <div data-testid="widget-grid" />,
}))

vi.mock('../components/DashboardNotifications', () => ({
  default: () => <div data-testid="dashboard-notifications" />,
}))

const setup = (contextProps = {}) => {
  return render(
    <PlatformTestWrapper>
      <WidgetDashboardProvider
        dashboardFeatures={{widget_dashboard_customization: true}}
        currentUser={{id: '123', display_name: 'Test Teacher', avatar_image_url: 'test.jpg'}}
        {...contextProps}
      >
        <ResponsiveProvider matches={['desktop']}>
          <EducatorDashboardContainer />
        </ResponsiveProvider>
      </WidgetDashboardProvider>
    </PlatformTestWrapper>,
  )
}

describe('EducatorDashboardContainer', () => {
  beforeEach(() => {
    fakeENV.setup({current_user_id: '123'})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders educator heading with greeting', () => {
    const {getByTestId} = setup()

    const heading = getByTestId('educator-dashboard-heading')
    expect(heading).toBeInTheDocument()
    expect(heading).toHaveTextContent('Hi, Test Teacher!')
  })

  it('shows Customize button when widget_dashboard_customization is enabled', () => {
    const {getByTestId} = setup()

    expect(getByTestId('customize-dashboard-button')).toBeInTheDocument()
  })

  it('hides Customize button when widget_dashboard_customization is disabled', () => {
    const {queryByTestId} = setup({
      dashboardFeatures: {widget_dashboard_customization: false},
    })

    expect(queryByTestId('customize-dashboard-button')).not.toBeInTheDocument()
  })

  it('renders greeting without name when currentUser has no display_name', () => {
    const {getByTestId} = setup({
      currentUser: {id: '123', display_name: '', avatar_image_url: ''},
    })

    expect(getByTestId('educator-dashboard-heading')).toHaveTextContent('Hi!')
  })
})
