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
import DashboardTabs from '../DashboardTabs'

type Props = Record<string, never> // DashboardTabs has no props

const setUp = (props: Props) => {
  const user = userEvent.setup()
  const renderResult = render(<DashboardTabs {...props} />)

  return {
    user,
    ...renderResult,
  }
}

const buildDefaultProps = (overrides = {}): Props => {
  const defaultProps: Props = {}

  return {...defaultProps, ...overrides}
}

describe('DashboardTabs', () => {
  it('should render both tab labels', () => {
    const {getByTestId} = setUp(buildDefaultProps())

    expect(getByTestId('tab-dashboard')).toBeInTheDocument()
    expect(getByTestId('tab-courses')).toBeInTheDocument()
  })

  it('should show Dashboard tab content by default', () => {
    const {getByText, queryByText} = setUp(buildDefaultProps())

    expect(getByText(/Welcome to your dashboard/)).toBeInTheDocument()
    expect(
      queryByText(/Here you can view and navigate to your enrolled courses/),
    ).not.toBeInTheDocument()
  })

  it('should switch to Courses tab when clicked', async () => {
    const {user, getByTestId, queryByText} = setUp(buildDefaultProps())

    const coursesTab = getByTestId('tab-courses')
    await user.click(coursesTab)

    expect(getByTestId('courses-tab-content')).toBeInTheDocument()
    expect(queryByText(/Welcome to your dashboard/)).not.toBeInTheDocument()
  })

  it('should switch back to Dashboard tab when clicked', async () => {
    const {user, getByTestId, queryByText} = setUp(buildDefaultProps())

    // Click Courses tab first
    const coursesTab = getByTestId('tab-courses')
    await user.click(coursesTab)

    // Then click Dashboard tab
    const dashboardTab = getByTestId('tab-dashboard')
    await user.click(dashboardTab)

    expect(getByTestId('dashboard-tab-content')).toBeInTheDocument()
    expect(
      queryByText(/Here you can view and navigate to your enrolled courses/),
    ).not.toBeInTheDocument()
  })

  it('should have proper ARIA attributes for accessibility', () => {
    const {getByTestId, container} = setUp(buildDefaultProps())

    const tabList = container.querySelector('[role="tablist"]')
    expect(tabList).toBeInTheDocument()

    expect(getByTestId('tab-dashboard')).toBeInTheDocument()
    expect(getByTestId('tab-courses')).toBeInTheDocument()
  })

  it('should update ARIA states when switching tabs', async () => {
    const {user, getByTestId, queryByTestId} = setUp(buildDefaultProps())

    const coursesTab = getByTestId('tab-courses')
    await user.click(coursesTab)

    expect(getByTestId('courses-tab-content')).toBeInTheDocument()
    expect(queryByTestId('dashboard-tab-content')).not.toBeInTheDocument()
  })

  it('renders properly with default props', () => {
    const {container} = setUp(buildDefaultProps())
    expect(container).not.toBeEmptyDOMElement()
  })
})
