/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import { shallow } from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'
import moxios from 'moxios'
import sinon from 'sinon'
import $ from 'jquery'
import DashboardHeader from 'jsx/dashboard/DashboardHeader'

const container = document.getElementById('fixtures')

const FakeDashboard = function (props) {
  // let property be null to force the default property on DashboardHeader
  let showTodoList = props.showTodoList
  if (showTodoList === null) showTodoList = undefined;
  return (
    <div>
      <DashboardHeader
        id="dashboard_header_container"
        ref={(c) => { props.headerRef(c) }}
        planner_enabled={props.planner_enabled}
        dashboard_view={props.dashboard_view}
        showTodoList={showTodoList}
      />
      <div
        id="flashalert_message_holder"
        style={{ display: 'block'}}
      />
      {
        props.planner_enabled && (
          <div
            id="dashboard-planner"
            style={{ display: 'block' }}
          />
        )
      }
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
  planner_enabled: PropTypes.bool,
  dashboard_view: PropTypes.string,
  headerRef: PropTypes.func,
  showTodoList: PropTypes.func,
}

FakeDashboard.defaultProps = {
  planner_enabled: false,
  dashboard_view: 'cards',
  headerRef: () => {},
  showTodoList: () => {},
}

let plannerStub

QUnit.module('Dashboard Header', {
  setup () {
    window.ENV = {
      PREFERENCES: {},
      STUDENT_PLANNER_COURSES: [],
    }
    moxios.install()
    plannerStub = sinon.stub(DashboardHeader.prototype, 'loadPlannerComponent')
  },

  teardown () {
    moxios.uninstall()
    plannerStub.restore()
    ReactDOM.unmountComponentAtNode(container)
  }
})

test('it renders', () => {
  const dashboardHeader = shallow(
    <DashboardHeader planner_enabled planner_selected />
  )
  ok(dashboardHeader)
})

test('it waits for the parent element to appear and then renders the the ToDoSidebar', () => {
  const clock = sinon.useFakeTimers(new Date('2018-01-01'))
  try {
    ReactDOM.render(
      <FakeDashboard
        planner_enabled={false}
        dashboard_view='activity'
        showTodoList={null}
      />, container)
      clock.tick(510) // don't bork when the element isn't there
      notOk(container.textContent.match(/Loading/), 'container should not contain "Loading"')
      const todoContainer = document.createElement('div')
      todoContainer.className = 'Sidebar__TodoListContainer'
      container.appendChild(todoContainer)
      clock.tick(510)
      ok(todoContainer.textContent.match(/Loading/), 'container should contain "Loading"')
    } finally {
      clock.restore()
    }
})

test('it should switch dashboard view appropriately when changeDashboard is called', () => {
  const stub = sinon.stub(DashboardHeader.prototype, 'saveDashboardView')
  let dashboardHeader = null
  ReactDOM.render(
    <FakeDashboard
      headerRef={(c) => { dashboardHeader = c }}
      planner_enabled={false}
      dashboard_view='activity'
    />, container)

  dashboardHeader.changeDashboard('cards')
  strictEqual(document.getElementById('dashboard-activity').style.display, 'none')
  strictEqual(document.getElementById('DashboardCard_Container').style.display, 'block')
  strictEqual(stub.callCount, 1)

  dashboardHeader.changeDashboard('activity')
  strictEqual(document.getElementById('dashboard-activity').style.display, 'block')
  strictEqual(document.getElementById('DashboardCard_Container').style.display, 'none')
  strictEqual(stub.callCount, 2)
  stub.restore()
})

test('it should switch dashboard view appropriately with Student Planner enabled', () => {
  const stub = sinon.stub(DashboardHeader.prototype, 'saveDashboardView')
  const cardLoadSpy = sinon.spy(DashboardHeader.prototype, 'loadCardDashboard')

  let dashboardHeader = null
  ReactDOM.render(
    <FakeDashboard
      headerRef={(c) => { dashboardHeader = c }}
      planner_enabled
      dashboard_view='activity'
    />, container)

  dashboardHeader.changeDashboard('cards')
  strictEqual(document.getElementById('dashboard-planner').style.display, 'none')
  strictEqual(document.getElementById('dashboard-planner-header').style.display, 'none')
  strictEqual(document.getElementById('dashboard-planner-header-aux').style.display, 'none')
  strictEqual(document.getElementById('DashboardCard_Container').style.display, 'block')
  strictEqual(document.getElementById('dashboard-activity').style.display, 'none')
  strictEqual(dashboardHeader.getActiveApp(), 'cards')

  dashboardHeader.changeDashboard('planner')
  strictEqual(document.getElementById('dashboard-planner').style.display, 'block')
  strictEqual(document.getElementById('dashboard-planner-header').style.display, 'block')
  strictEqual(document.getElementById('dashboard-planner-header-aux').style.display, 'block')
  strictEqual(document.getElementById('DashboardCard_Container').style.display, 'none')
  strictEqual(document.getElementById('dashboard-activity').style.display, 'none')
  strictEqual(dashboardHeader.getActiveApp(), 'planner')

  dashboardHeader.changeDashboard('activity')
  strictEqual(document.getElementById('dashboard-planner').style.display, 'none')
  strictEqual(document.getElementById('dashboard-planner-header').style.display, 'none')
  strictEqual(document.getElementById('dashboard-planner-header-aux').style.display, 'none')
  strictEqual(document.getElementById('DashboardCard_Container').style.display, 'none')
  strictEqual(document.getElementById('dashboard-activity').style.display, 'block')
  strictEqual(dashboardHeader.getActiveApp(), 'activity')

  dashboardHeader.changeDashboard('cards')
  dashboardHeader.changeDashboard('planner')
  strictEqual(cardLoadSpy.callCount, 1)
  strictEqual(plannerStub.callCount, 1)
  stub.restore()
})

test('it should use the dashboard view endpoint when Student Planner is enabled', (assert) => {
  const done = assert.async();
  let dashboardHeader = null
  ReactDOM.render(
    <FakeDashboard
      headerRef={(c) => { dashboardHeader = c }}
      planner_enabled
      dashboard_view='activity'
    />, container)

  dashboardHeader.changeDashboard('cards')

  moxios.wait(() => {
    const request = moxios.requests.mostRecent()
    equal(request.url, '/dashboard/view')
    equal(request.config.data, '{"dashboard_view":"cards"}');
    done()
  })
  ok(plannerStub.notCalled)
})

test('it should show the card dashboard if planner is selected, but not enabled', () => {
  const stub = sinon.stub(DashboardHeader.prototype, 'saveDashboardView')
  ReactDOM.render(
    <FakeDashboard
      headerRef={() => false}
      planner_enabled={false}
      dashboard_view='planner'
    />, container)

  strictEqual(document.getElementById('dashboard-planner'), null)
  strictEqual(document.getElementById('dashboard-planner-header'), null)
  strictEqual(document.getElementById('DashboardCard_Container').style.display, 'block')
  strictEqual(document.getElementById('dashboard-activity').style.display, 'none')
  stub.restore()
})

test('it should show a flash error if saving dashboard API call fails', (assert) => {
  const done = assert.async();
  let dashboardHeader = null
  ReactDOM.render(
    <FakeDashboard
      headerRef={(c) => { dashboardHeader = c }}
      planner_enabled
      dashboard_view='activity'
    />, container)

  moxios.stubRequest('/dashboard/view', {
    status: 500,
    response: {error: 'Error Text'},
  })

  dashboardHeader.changeDashboard('cards')

  moxios.wait(() => {
    strictEqual($('#flashalert_message_holder p').text(), 'Failed to save dashboard selection')
    done()
  })
})

test('it should add planner classes to the page when planner is loaded', () => {
  const stub = sinon.stub(DashboardHeader.prototype, 'saveDashboardView')
  let dashboardHeader = null
  ReactDOM.render(
    <FakeDashboard
      headerRef={(c) => { dashboardHeader = c }}
      dashboard_view='planner'
      planner_enabled
    />, container)

  ok(document.body.classList.contains('dashboard-is-planner'))
  dashboardHeader.changeDashboard('cards')
  notOk(document.body.classList.contains('dashboard-is-planner'))
  stub.restore()
})
