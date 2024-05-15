/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import TestUtils from 'react-dom/test-utils'
import {shallow} from 'enzyme'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DashboardOptionsMenu from '../DashboardOptionsMenu'
import sinon from 'sinon'

const FakeDashboard = function (props) {
  return (
    <div>
      <DashboardOptionsMenu
        ref={c => {
          props.menuRef(c)
        }}
        view={props.view}
        planner_enabled={props.planner_enabled}
        onDashboardChange={props.onDashboardChange}
      />
      {props.planner_enabled && (
        <div>
          <div id="dashboard-planner" style={{display: 'block'}} />
          <div id="dashboard-planner-header" style={{display: 'block'}} />
        </div>
      )}
      <div id="dashboard-activity" style={{display: 'block'}} />
      <div id="DashboardCard_Container" style={{display: 'none'}}>
        <div className="ic-DashboardCard__header">
          <div className="ic-DashboardCard__header_image">
            <div className="ic-DashboardCard__header_hero" style={{opacity: 0.6}} />
          </div>
          <div className="ic-DashboardCard__header-button-bg" style={{opacity: 0}} />
        </div>
      </div>
    </div>
  )
}

FakeDashboard.propTypes = {
  menuRef: PropTypes.func.isRequired,
  view: PropTypes.string,
  planner_enabled: PropTypes.bool,
  onDashboardChange: PropTypes.func,
}

FakeDashboard.defaultProps = {
  view: 'cards',
  planner_enabled: false,
  onDashboardChange: () => {},
}

describe('Dashboard Options Menu', () => {
  test('it renders', () => {
    const dashboardMenu = TestUtils.renderIntoDocument(
      <DashboardOptionsMenu onDashboardChange={() => {}} />
    )
    expect(dashboardMenu).toBeTruthy()
  })

  test('it should call onDashboardChange when new view is selected', () => {
    const onDashboardChangeSpy = sinon.spy()

    const wrapper = shallow(
      <DashboardOptionsMenu view="planner" onDashboardChange={onDashboardChangeSpy} />
    )

    wrapper.instance().handleViewOptionSelect(null, ['cards'])
    expect(onDashboardChangeSpy.callCount).toEqual(1)
    expect(onDashboardChangeSpy.calledWith('cards')).toBeTruthy()
  })

  test('it should not call onDashboardChange when correct view is already set', async () => {
    const onDashboardChangeSpy = sinon.spy()

    const wrapper = render(
      <DashboardOptionsMenu view="activity" onDashboardChange={onDashboardChangeSpy} />
    )
    const button = wrapper.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
    const recentActivity = menuItems.filter(
      menuItem => menuItem.textContent.trim() === 'Recent Activity'
    )[0]
    recentActivity.click()

    expect(onDashboardChangeSpy.callCount).toEqual(0)
  })

  test('it should include a List View menu item when Student Planner is enabled', async () => {
    const wrapper = render(
      <DashboardOptionsMenu planner_enabled={true} onDashboardChange={() => {}} />
    )
    const button = wrapper.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
    expect(menuItems.some(menuItem => menuItem.textContent.trim() === 'List View')).toBeTruthy()
  })

  test('it should include an Homeroom View option when the Elementary dashboard is disabled', async () => {
    const wrapper = render(
      <DashboardOptionsMenu canEnableElementaryDashboard={true} onDashboardChange={() => {}} />
    )
    const button = wrapper.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)
    const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
    expect(menuItems.some(menuItem => menuItem.textContent.trim() === 'Homeroom View')).toBeTruthy()
  })

  test('it should display toggle color overlay option if card view is set', async () => {
    const wrapper = render(<DashboardOptionsMenu onDashboardChange={() => {}} />)
    const button = wrapper.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
    const colorToggle = menuItems.filter(
      menuItem => menuItem.textContent.trim() === 'Color Overlay'
    )[0]

    expect(colorToggle).toBeTruthy()
  })

  test('it should not display toggle color overlay option if recent activity view is set', async () => {
    const wrapper = render(<DashboardOptionsMenu view="activity" onDashboardChange={() => {}} />)
    const button = wrapper.container.querySelector('button')
    const user = userEvent.setup({delay: null})
    await user.click(button)

    const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
    const colorToggle = menuItems.filter(
      menuItem => menuItem.textContent.trim() === 'Color Overlay'
    )[0]

    expect(colorToggle).toBeFalsy()
  })

  test('it should toggle color overlays', () => {
    // sandbox.stub(DashboardOptionsMenu.prototype, 'postToggleColorOverlays')
    let dashboardMenu = null
    render(
      <FakeDashboard
        menuRef={c => {
          dashboardMenu = c
        }}
        dashboard_view="cards"
      />
    )

    dashboardMenu.handleColorOverlayOptionSelect(false)
    expect(
      document.getElementsByClassName('ic-DashboardCard__header_hero')[0].style.opacity
    ).toEqual('0')
    expect(
      document.getElementsByClassName('ic-DashboardCard__header-button-bg')[0].style.opacity
    ).toEqual('1')

    dashboardMenu.handleColorOverlayOptionSelect(true)
    expect(
      document.getElementsByClassName('ic-DashboardCard__header_hero')[0].style.opacity
    ).toEqual('0.6')
    expect(
      document.getElementsByClassName('ic-DashboardCard__header-button-bg')[0].style.opacity
    ).toEqual('0')
  })
})
