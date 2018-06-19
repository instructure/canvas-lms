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
import I18n from 'i18n!dashboard';
import axios from 'axios';
import { bool, func, string } from 'prop-types';
import { showFlashError } from '../shared/FlashAlert'
import DashboardOptionsMenu from '../dashboard_card/DashboardOptionsMenu';
import loadCardDashboard from '../bundles/dashboard_card'

/**
 * This component renders the header for the user dashboard and loads the current dashboard.
 */
class DashboardHeader extends React.Component {

  constructor (props) {
    super(props);

    let currentDashboard;
    const enabledViews = ['cards', 'activity']

    if (props.planner_enabled) enabledViews.push('planner')

    if (enabledViews.includes(props.dashboard_view)) {
      currentDashboard = props.dashboard_view
    } else {
      currentDashboard = 'cards'
    }

    this.state = { currentDashboard, loadedViews: ['activity'] }
  }

  componentDidMount () {
    this.showDashboard(this.state.currentDashboard)
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
    require.ensure([], (require) => {
      const Planner = require('canvas-planner')
      const props = {
        changeToCardView: () => this.changeDashboard('cards'),
        getActiveApp: this.getActiveApp,
        flashError: this.props.flashError,
        flashMessage: this.props.flashMessage,
        srFlashMessage: this.props.screenReaderFlashMessage,
        externalFallbackFocusable: this.menuButtonFocusable,
        env: this.props.env,
      }
      Planner.default(props)
    })
  }

  loadCardDashboard () {
    // I put this in so I can spy on the imported function in a spec :'(
    loadCardDashboard()
  }

  loadDashboard (newView) {
    if (this.state.loadedViews.includes(newView)) return
    if (newView === 'planner' && this.props.planner_enabled) {
      this.loadPlannerComponent()
    } else if (newView === 'cards') {
      this.loadCardDashboard()
    }
    this.setState({loadedViews: this.state.loadedViews.concat(newView) })
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
    this.showDashboard(newView)
    this.setState({ currentDashboard: newView })
  }

  showDashboard = (newView) => {
    this.resetClasses(newView)
    const fakeObj = {
      style: {}
    }
    const dashboardPlanner = document.getElementById('dashboard-planner') || fakeObj
    const dashboardPlannerHeader = document.getElementById('dashboard-planner-header') || fakeObj
    const dashboardActivity = document.getElementById('dashboard-activity')
    const dashboardCards = document.getElementById('DashboardCard_Container')
    const rightSideContent = document.getElementById('right-side-wrapper') || fakeObj

    this.loadDashboard(newView)

    if (newView === 'planner') {
      dashboardPlanner.style.display = 'block'
      dashboardPlannerHeader.style.display = 'block'
      dashboardActivity.style.display = 'none'
      dashboardCards.style.display = 'none'
      rightSideContent.style.display = 'none'
    } else if (newView === 'activity') {
      dashboardPlanner.style.display = 'none'
      dashboardPlannerHeader.style.display = 'none'
      dashboardActivity.style.display = 'block'
      dashboardCards.style.display = 'none'
      rightSideContent.style.display = 'block'
    } else {
      dashboardPlanner.style.display = 'none'
      dashboardPlannerHeader.style.display = 'none'
      dashboardActivity.style.display = 'none'
      dashboardCards.style.display = 'block'
      rightSideContent.style.display = 'block'
    }
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
              hide_dashcard_color_overlays={this.props.hide_dashcard_color_overlays}
              planner_enabled={this.props.planner_enabled}
              onDashboardChange={this.changeDashboard}
              menuButtonRef={(ref) => {this.menuButtonFocusable = ref}}
            />
          </div>
        </div>
      </div>
    );
  }
}

DashboardHeader.propTypes = {
  dashboard_view: string,
  hide_dashcard_color_overlays: bool,
  planner_enabled: bool.isRequired,
  flashError: func,
  flashMessage: func,
  screenReaderFlashMessage: func,
}

DashboardHeader.defaultProps = {
  dashboard_view: 'cards',
  hide_dashcard_color_overlays: false,
  flashError: () => {},
  flashMessage: () => {},
  screenReaderFlashMessage: () => {},
}

export default DashboardHeader;
