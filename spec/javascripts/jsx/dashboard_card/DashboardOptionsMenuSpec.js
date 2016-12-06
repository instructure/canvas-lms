import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import { mount } from 'enzyme'
import DashboardOptionsMenu from 'jsx/dashboard_card/DashboardOptionsMenu'

const container = document.getElementById('fixtures')

const FakeDashboard = function ({menuRef}) {
  return (
    <div>
      <DashboardOptionsMenu
        ref={(c) => { menuRef(c) }}
        recent_activity_dashboard
      />
      <div
        id="dashboard-activity"
        style={{ display: 'block' }}
      />
      <div
        id="DashboardCard_Container"
        style={{ display: 'none' }}
      />
    </div>
  )
}

FakeDashboard.propTypes = {
  menuRef: React.PropTypes.func.isRequired
}

QUnit.module('Dashboard Options Menu', {
  teardown () {
    ReactDOM.unmountComponentAtNode(container)
  }
})

test('it renders', function () {
  const dashboardMenu = TestUtils.renderIntoDocument(
    <DashboardOptionsMenu recent_activity_dashboard />
  )
  ok(dashboardMenu)
})

test('it should switch dashboard view appropriately when view option is selected', function () {
  this.stub(DashboardOptionsMenu.prototype, 'postDashboardToggle')

  let dashboardMenu = null
  ReactDOM.render(<FakeDashboard menuRef={(c) => { dashboardMenu = c }} />, container)

  dashboardMenu.handleViewOptionSelect(null, ['cards'])
  ok(document.getElementById('dashboard-activity').style.display === 'none')
  ok(document.getElementById('DashboardCard_Container').style.display === 'block')

  dashboardMenu.handleViewOptionSelect(null, ['activity'])
  ok(document.getElementById('dashboard-activity').style.display === 'block')
  ok(document.getElementById('DashboardCard_Container').style.display === 'none')
})

test('it should not call toggleDashboardView when correct view is already set', function () {
  this.stub(DashboardOptionsMenu.prototype, 'postDashboardToggle')
  const toggleDashboardView = this.stub(DashboardOptionsMenu.prototype, 'toggleDashboardView')

  const wrapper = mount(<DashboardOptionsMenu recent_activity_dashboard />)
  wrapper.find('button').simulate('click')

  const menuItems = Array.from(document.querySelectorAll('[role="menuitemradio"]'))
  const recentActivity = menuItems.filter(function (menuItem) {
    return menuItem.textContent === 'Recent Activity'
  })[0]
  recentActivity.click()

  equal(toggleDashboardView.callCount, 0)
  wrapper.unmount()
})
