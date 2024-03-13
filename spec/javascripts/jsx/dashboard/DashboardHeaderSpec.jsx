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
import {shallow} from 'enzyme'
import moxios from 'moxios'
import {moxiosWait} from '@canvas/jest-moxios-utils'
import sinon from 'sinon'
import $ from 'jquery'
import 'jquery-migrate'
import {DashboardHeader} from 'ui/features/dashboard/react/DashboardHeader'
import {resetPlanner} from '@canvas/planner'
import fetchMock from 'fetch-mock'
import {
  SHOW_K5_DASHBOARD_ROUTE,
  showK5DashboardResponse,
} from '@canvas/observer-picker/react/__tests__/fixtures'

const container = document.getElementById('fixtures')

const FakeDashboard = function (props) {
  // let property be null to force the default property on DashboardHeader
  let loadDashboardSidebar = props.loadDashboardSidebar
  if (loadDashboardSidebar === null) loadDashboardSidebar = undefined
  return (
    <div>
      <DashboardHeader
        id="dashboard_header_container"
        ref={c => {
          props.headerRef(c)
        }}
        planner_enabled={props.planner_enabled}
        dashboard_view={props.dashboard_view}
        loadDashboardSidebar={loadDashboardSidebar}
        env={window.ENV}
      />
      <div id="flashalert_message_holder" style={{display: 'block'}} />
      {props.planner_enabled && <div id="dashboard-planner" style={{display: 'block'}} />}
      <div id="dashboard-activity" style={{display: 'block'}} />
      <div id="DashboardCard_Container" style={{display: 'none'}} />
    </div>
  )
}

FakeDashboard.propTypes = {
  planner_enabled: PropTypes.bool,
  dashboard_view: PropTypes.string,
  headerRef: PropTypes.func,
  loadDashboardSidebar: PropTypes.func,
}

FakeDashboard.defaultProps = {
  planner_enabled: false,
  dashboard_view: 'cards',
  headerRef: () => {},
  loadDashboardSidebar: () => {},
}

let plannerStub, saveDashboardViewStub, cardLoadSpy

QUnit.module('Dashboard Header', hooks => {
  hooks.beforeEach(() => {
    window.ENV = {
      MOMENT_LOCALE: 'en',
      TIMEZONE: 'UTC',
      current_user: {},
      PREFERENCES: {},
      STUDENT_PLANNER_COURSES: [],
    }
    moxios.install()
    plannerStub = sinon.stub(DashboardHeader.prototype, 'loadPlannerComponent')
    saveDashboardViewStub = sinon.stub(DashboardHeader.prototype, 'saveDashboardView')
    cardLoadSpy = sinon.spy(DashboardHeader.prototype, 'loadCardDashboard')
  })
  hooks.afterEach(() => {
    resetPlanner()
    moxios.uninstall()
    plannerStub.restore()
    ReactDOM.unmountComponentAtNode(container)
    saveDashboardViewStub.restore()
    cardLoadSpy.restore()
  })

  test('it renders', () => {
    const dashboardHeader = shallow(
      <DashboardHeader planner_enabled={true} planner_selected={true} env={window.ENV} />
    )
    ok(dashboardHeader)
  })

  QUnit.skip(
    'it waits for the erb html to be injected before rendering the ToDoSidebar',
    async () => {
      ENV.STUDENT_PLANNER_ENABLED = true
      const $fakeRightSide = $('<div id="right-side">').appendTo(document.body)
      const fakeServerResponse = Promise.resolve(`
      <div class="Sidebar__TodoListContainer"></div>
      This came from the server
    `)

      sandbox
        .mock($)
        .expects('get')
        .once()
        .withArgs('/dashboard-sidebar')
        .returns(fakeServerResponse)

      moxios.stubOnce('GET', '/api/v1/planner/items', {
        status: 200,
        responseText: {},
      })
      const promiseToGetNewCourseForm = import('ui/features/dashboard/jquery/util/newCourseForm')

      ReactDOM.render(
        <FakeDashboard
          planner_enabled={false}
          dashboard_view="activity"
          loadDashboardSidebar={null}
        />,
        container
      )
      notOk(
        $fakeRightSide.find('.Sidebar__TodoListContainer').text().includes('Loading'),
        'container should not contain "Loading"'
      )

      await Promise.all([promiseToGetNewCourseForm, promiseToGetNewCourseForm])
      moxios.wait(() => {
        ok(
          $fakeRightSide.text().includes('This came from the server'),
          'injects the server erb html where it should'
        )

        ok(
          $fakeRightSide.find('.Sidebar__TodoListContainer').text().includes('Loading'),
          'container should contain "Loading"'
        )
        $fakeRightSide.remove()
      })
    }
  )

  test('it should switch dashboard view appropriately when changeDashboard is called', async assert => {
    const done = assert.async()
    let dashboardHeader = null
    ReactDOM.render(
      <FakeDashboard
        headerRef={c => {
          dashboardHeader = c
        }}
        planner_enabled={false}
        dashboard_view="activity"
      />,
      container
    )

    await dashboardHeader.changeDashboard('cards')
    strictEqual(document.getElementById('dashboard-activity').style.display, 'none')
    strictEqual(document.getElementById('DashboardCard_Container').style.display, 'block')
    strictEqual(saveDashboardViewStub.callCount, 1)

    await dashboardHeader.changeDashboard('activity')
    strictEqual(document.getElementById('dashboard-activity').style.display, 'block')
    strictEqual(document.getElementById('DashboardCard_Container').style.display, 'none')
    strictEqual(saveDashboardViewStub.callCount, 2)
    done()
  })

  test('it should switch dashboard view appropriately with Student Planner enabled', async assert => {
    const done = assert.async()
    let dashboardHeader = null
    ReactDOM.render(
      <FakeDashboard
        headerRef={c => {
          dashboardHeader = c
        }}
        planner_enabled={true}
        dashboard_view="activity"
      />,
      container
    )

    await dashboardHeader.changeDashboard('cards')
    strictEqual(document.getElementById('dashboard-planner').style.display, 'none')
    strictEqual(document.getElementById('dashboard-planner-header').style.display, 'none')
    strictEqual(document.getElementById('dashboard-planner-header-aux').style.display, 'none')
    strictEqual(document.getElementById('DashboardCard_Container').style.display, 'block')
    strictEqual(document.getElementById('dashboard-activity').style.display, 'none')
    strictEqual(dashboardHeader.getActiveApp(), 'cards')

    await dashboardHeader.changeDashboard('planner')
    strictEqual(document.getElementById('dashboard-planner').style.display, 'block')
    strictEqual(document.getElementById('dashboard-planner-header').style.display, 'block')
    strictEqual(document.getElementById('dashboard-planner-header-aux').style.display, 'block')
    strictEqual(document.getElementById('DashboardCard_Container').style.display, 'none')
    strictEqual(document.getElementById('dashboard-activity').style.display, 'none')
    strictEqual(dashboardHeader.getActiveApp(), 'planner')

    await dashboardHeader.changeDashboard('activity')
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
    done()
  })

  test('it should use the dashboard view endpoint when Student Planner is enabled', assert => {
    saveDashboardViewStub.restore()
    const done = assert.async()
    let dashboardHeader = null
    ReactDOM.render(
      <FakeDashboard
        headerRef={c => {
          dashboardHeader = c
        }}
        planner_enabled={true}
        dashboard_view="activity"
      />,
      container
    )

    dashboardHeader.changeDashboard('cards')

    moxios.wait(() => {
      const requests = moxios.requests
      equal(requests.at(1).url, '/dashboard/view')
      equal(requests.at(1).config.data, '{"dashboard_view":"cards"}')
      done()
    })
    ok(plannerStub.notCalled)
  })

  test('it should show the card dashboard if planner is selected, but not enabled', () => {
    ReactDOM.render(
      <FakeDashboard headerRef={() => false} planner_enabled={false} dashboard_view="planner" />,
      container
    )

    strictEqual(document.getElementById('dashboard-planner'), null)
    strictEqual(document.getElementById('dashboard-planner-header'), null)
    strictEqual(document.getElementById('DashboardCard_Container').style.display, 'block')
    strictEqual(document.getElementById('dashboard-activity').style.display, 'none')
  })

  test('it should show a flash error if saving dashboard API call fails', assert => {
    saveDashboardViewStub.restore()
    const done = assert.async()
    let dashboardHeader = null
    ReactDOM.render(
      <FakeDashboard
        headerRef={c => {
          dashboardHeader = c
        }}
        planner_enabled={true}
        dashboard_view="activity"
      />,
      container
    )

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
    let dashboardHeader = null
    ReactDOM.render(
      <FakeDashboard
        headerRef={c => {
          dashboardHeader = c
        }}
        dashboard_view="planner"
        planner_enabled={true}
      />,
      container
    )

    ok(document.body.classList.contains('dashboard-is-planner'))
    dashboardHeader.changeDashboard('cards')
    notOk(document.body.classList.contains('dashboard-is-planner'))
  })

  test('it should allow switching back to the Elementary dashboard if it was disabled', () => {
    let dashboardHeader = null
    ReactDOM.render(
      <FakeDashboard
        headerRef={c => {
          dashboardHeader = c
        }}
        dashboard_view="activity"
        canEnableElementaryDashboard={true}
      />,
      container
    )
    dashboardHeader.changeDashboard('elementary')

    return moxiosWait(req => {
      strictEqual(req.config.method, 'put')
      strictEqual(req.config.data, JSON.stringify({elementary_dashboard_disabled: false}))
      strictEqual(req.url, '/api/v1/users/self/settings')
    })
  })

  QUnit.module('with observer', hooks2 => {
    hooks2.beforeEach(() => {
      ENV.current_user_roles = ['user', 'observer']
      ENV.OBSERVED_USERS_LIST = [
        {id: '17', name: 'bob', avatar_url: undefined},
        {id: '19', name: 'mary', avatar_url: undefined},
      ]

      fetchMock.get(SHOW_K5_DASHBOARD_ROUTE, JSON.stringify(showK5DashboardResponse(false, false)))
    })

    hooks2.afterEach(() => {
      fetchMock.restore()
    })

    test('it should show the observer options Select on planner dashboard', () => {
      ReactDOM.render(<FakeDashboard planner_enabled={true} dashboard_view="planner" />, container)
      ok(document.querySelector('[data-testid="observed-student-dropdown"]'))
    })

    test('it should show the observer options Select on recent activity dashboard', () => {
      ReactDOM.render(<FakeDashboard planner_enabled={true} dashboard_view="activity" />, container)
      ok(document.querySelector('[data-testid="observed-student-dropdown"]'))
    })
  })
})
