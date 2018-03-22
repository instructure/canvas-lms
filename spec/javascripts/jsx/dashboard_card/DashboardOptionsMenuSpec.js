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
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import { shallow, mount } from 'enzyme'
import DashboardOptionsMenu from 'jsx/dashboard_card/DashboardOptionsMenu'
import moxios from 'moxios';
import sinon from 'sinon'

const container = document.getElementById('fixtures')

const FakeDashboard = function (props) {
  return (
    <div>
      <DashboardOptionsMenu
        ref={(c) => { props.menuRef(c) }}
        view={props.view}
        planner_enabled={props.planner_enabled}
        onDashboardChange={props.onDashboardChange}
      />
      {
        props.planner_enabled && (
          <div>
            <div
              id="dashboard-planner"
              style={{ display: 'block' }}
            />
            <div
              id="dashboard-planner-header"
              style={{ display: 'block' }}
            />
          </div>
        )
      }
      <div
        id="dashboard-activity"
        style={{ display: 'block' }}
      />
      <div
        id="DashboardCard_Container"
        style={{ display: 'none' }}
      >
        <div className="ic-DashboardCard__header">
          <div className="ic-DashboardCard__header_image">
            <div
              className="ic-DashboardCard__header_hero"
              style={{opacity: 0.6}}
            />
          </div>
          <div
            className="ic-DashboardCard__header-button-bg"
            style={{opacity: 0}}
          />
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

QUnit.module('Dashboard Options Menu', {
  teardown () {
    ReactDOM.unmountComponentAtNode(container)
  }
})

test('it renders', function () {
  const dashboardMenu = TestUtils.renderIntoDocument(
    <DashboardOptionsMenu onDashboardChange={() => {}} />
  )
  ok(dashboardMenu)
})

test('it should call onDashboardChange when new view is selected', function () {
  const onDashboardChangeSpy = sinon.spy()

  const wrapper = shallow(
    <DashboardOptionsMenu
      view="planner"
      onDashboardChange={onDashboardChangeSpy}
    />)

  wrapper.instance().handleViewOptionSelect(null, ['cards'])
  equal(onDashboardChangeSpy.callCount, 1)
  ok(onDashboardChangeSpy.calledWith('cards'))
})

test('it should not call onDashboardChange when correct view is already set', function () {
  const onDashboardChangeSpy = sinon.spy()

  const wrapper = mount(<DashboardOptionsMenu view="activity" onDashboardChange={onDashboardChangeSpy} />)
  wrapper.find('button').simulate('click')

  const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
  const recentActivity = menuItems.filter(menuItem => menuItem.textContent.trim() === 'Recent Activity')[0]
  recentActivity.click()

  equal(onDashboardChangeSpy.callCount, 0)
  wrapper.unmount()
})

test('it should include a List View menu item when Student Planner is enabled', function () {
  const wrapper = mount(
    <DashboardOptionsMenu
      planner_enabled
      onDashboardChange={() => {}}
    />
  )
  wrapper.find('button').simulate('click')
  const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
  ok(menuItems.some(menuItem => menuItem.textContent.trim() === 'List View'))
  wrapper.unmount()
});

test('it should display toggle color overlay option if card view is set', function () {
  const wrapper = mount(<DashboardOptionsMenu onDashboardChange={() => {}} />)
  wrapper.find('button').simulate('click')

  const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
  const colorToggle = menuItems.filter(menuItem => menuItem.textContent.trim() === 'Color Overlay')[0]

  ok(colorToggle)
  wrapper.unmount()
})

test('it should not display toggle color overlay option if recent activity view is set', function () {
  const wrapper = mount(<DashboardOptionsMenu view="activity" onDashboardChange={() => {}} />)
  wrapper.find('button').simulate('click')

  const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
  const colorToggle = menuItems.filter(menuItem => menuItem.textContent.trim() === 'Color Overlay')[0]

  notOk(colorToggle)
  wrapper.unmount()
})

test('it should toggle color overlays', function () {
  this.stub(DashboardOptionsMenu.prototype, 'postToggleColorOverlays')
  let dashboardMenu = null
  ReactDOM.render(
    <FakeDashboard
      menuRef={(c) => { dashboardMenu = c }}
      recent_activity_dashboard={false}
    />, container)

  dashboardMenu.handleColorOverlayOptionSelect(null, [''])
  ok(document.getElementsByClassName('ic-DashboardCard__header_hero')[0].style.opacity === '0')
  ok(document.getElementsByClassName('ic-DashboardCard__header-button-bg')[0].style.opacity === '1')

  dashboardMenu.handleColorOverlayOptionSelect(null, ['colorOverlays'])
  ok(document.getElementsByClassName('ic-DashboardCard__header_hero')[0].style.opacity === '0.6')
  ok(document.getElementsByClassName('ic-DashboardCard__header-button-bg')[0].style.opacity === '0')
});
