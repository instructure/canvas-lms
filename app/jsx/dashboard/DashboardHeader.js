/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react';
import $ from 'jquery'
import I18n from 'i18n!dashboard';
import axios from 'axios';
import { bool, func, string, object } from 'prop-types';
import loadPlannerDashboard, { renderToDoSidebar } from 'canvas-planner';
import { showFlashAlert, showFlashError } from '../shared/FlashAlert'
import DashboardOptionsMenu from '../dashboard_card/DashboardOptionsMenu';
import loadCardDashboard from '../bundles/dashboard_card'

const [show, hide] = ['block', 'none'].map(displayVal => id => {
  const el = document.getElementById(id)
  if (el) el.style.display = displayVal
})
/**
 * This component renders the header and the to do sidebar for the user
 * dashboard and loads the current dashboard.
 */
export default class DashboardHeader extends React.Component {
  static propTypes = {
    dashboard_view: string,
    planner_enabled: bool.isRequired,
    screenReaderFlashMessage: func,
    env: object, // eslint-disable-line react/forbid-prop-types
    showTodoList: func
  }

  static defaultProps = {
    dashboard_view: 'cards',
    screenReaderFlashMessage: () => {},
    env: {},
    showTodoList
  }

  state = {
    currentDashboard: ['cards', 'activity', this.props.planner_enabled && 'planner']
      .filter(Boolean)
      .includes(this.props.dashboard_view)
      ? this.props.dashboard_view
      : 'cards',
    loadedViews: []
  }

  componentDidMount () {
    this.showDashboard(this.state.currentDashboard)
    this.props.showTodoList(this.switchDashboard)
  }

  getActiveApp = () => this.state.currentDashboard

  resetClasses (newDashboard) {
    if (newDashboard === 'planner') {
      document.body.classList.add('dashboard-is-planner')
    } else {
      document.body.classList.remove('dashboard-is-planner')
    }
  }

  loadPlannerComponent () {
    loadPlannerDashboard({
      changeDashboardView: this.changeDashboard,
      getActiveApp: this.getActiveApp,
      flashError: (message) => showFlashAlert({message, type: 'error'}),
      flashMessage: (message) => showFlashAlert({message, type: 'info'}),
      srFlashMessage: this.props.screenReaderFlashMessage,
      externalFallbackFocusable: this.menuButtonFocusable,
      env: this.props.env,
    })
  }

  loadCardDashboard () {
    // I put this in so I can spy on the imported function in a spec :'(
    loadCardDashboard()
  }

  loadStreamItemDashboard() {
    // populates the stream items via ajax when the toggle is switched
    const $dashboardActivity = $('#dashboard-activity')
    if ($dashboardActivity.text().trim()) return // don't do anything if it is already populated

    const promiseToGetCode = import('../views/DashboardView')
    const promiseToGetHtml = axios.get('/dashboard/stream_items')
    $dashboardActivity.show().disableWhileLoading(
      Promise.all([promiseToGetCode, promiseToGetHtml])
        .then(([DashboardView, axiosResponse]) => {
          $dashboardActivity.html(axiosResponse.data)
          new DashboardView()
        })
        .catch(showFlashError(I18n.t('Failed to load recent activity')))
    )
  }

  loadDashboard(newView) {
    if (this.state.loadedViews.includes(newView)) return

    if (newView === 'planner' && this.props.planner_enabled) {
      this.loadPlannerComponent()
    } else if (newView === 'cards') {
      this.loadCardDashboard()
    } else if (newView === 'activity') {
      this.loadStreamItemDashboard()
    }

    this.setState({loadedViews: this.state.loadedViews.concat(newView)})
  }

  saveDashboardView (newView) {
    axios.put('/dashboard/view', {
      dashboard_view: newView
    }).catch(() => {
      showFlashError(I18n.t('Failed to save dashboard selection'))()
    })
  }

  changeDashboard = (newView) => {
    this.saveDashboardView(newView)
    this.switchDashboard(newView)
  }

  switchDashboard = (newView) => {
    this.showDashboard(newView)
    this.setState({ currentDashboard: newView })
  }

  showDashboard = newView => {
    this.resetClasses(newView)
    const elements = {
      planner: ['dashboard-planner', 'dashboard-planner-header', 'dashboard-planner-header-aux'],
      activity: ['dashboard-activity', 'right-side-wrapper'],
      cards: ['DashboardCard_Container', 'right-side-wrapper']
    }
    this.loadDashboard(newView)

    // hide the elements not part of this view
    Object.keys(elements)
      .filter(k => k !== newView)
      .forEach(k => elements[k].forEach(hide))

    // show the ones that are
    elements[newView].forEach(show)
  }

  render () {
    return (
      <div className="ic-Dashboard-header__layout">
        <h1 className="ic-Dashboard-header__title">{I18n.t('Dashboard')}</h1>
        <div className="ic-Dashboard-header__actions">
          {this.props.planner_enabled && (
            <div
              id="dashboard-planner-header"
              className="CanvasPlanner__HeaderContainer"
              style={{ display: (this.state.currentDashboard === 'planner') ? 'block' : 'none' }}
            />
          )}
          <div id="DashboardOptionsMenu_Container">
            <DashboardOptionsMenu
              view={this.state.currentDashboard}
              planner_enabled={this.props.planner_enabled}
              onDashboardChange={this.changeDashboard}
              menuButtonRef={(ref) => {this.menuButtonFocusable = ref}}
            />
          </div>
          {this.props.planner_enabled && (
            <div id="dashboard-planner-header-aux" />
          )}
        </div>
      </div>
    );
  }
}

// extract this out to a property so tests can override it and not have to mock
// out the timers in every single test.
function showTodoList (changeDashboard) {
  // The sidebar itself is loaded via a separate fetch from the server. This
  // means we need to wait for the element to appear on the page before we can
  // render the to do list.
  const interval = window.setInterval(() => {
    const container = document.querySelector('.Sidebar__TodoListContainer')
    if (container) {
      renderToDoSidebar(container, {
        changeDashboardView: changeDashboard,
      });
      window.clearInterval(interval);
    }
  }, 100);
}
