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

import React from 'react'
import ReactDOM from 'react-dom'
import I18n from 'i18n!dashboard'
import axios from '@canvas/axios'
import classnames from 'classnames'
import {bool, func, string, object, oneOf} from 'prop-types'
import {
  initializePlanner,
  loadPlannerDashboard,
  renderToDoSidebar,
  responsiviser
} from '@instructure/canvas-planner'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import DashboardOptionsMenu from './DashboardOptionsMenu'
import loadCardDashboard, {resetDashboardCards} from '@canvas/dashboard-card'
import $ from 'jquery'
import {asText, getPrefetchedXHR} from '@instructure/js-utils'
import '@canvas/jquery/jquery.disableWhileLoading'
import {CreateCourseModal} from '@canvas/create-course-modal/react/CreateCourseModal'
import ObserverOptions from '@canvas/observer-picker'
import {View} from '@instructure/ui-view'

const [show, hide] = ['block', 'none'].map(displayVal => id => {
  const el = document.getElementById(id)
  if (el) el.style.display = displayVal
})

const observerMode = () =>
  ENV.FEATURES?.observer_picker && ENV.current_user_roles?.includes('observer')

/**
 * This component renders the header and the to do sidebar for the user
 * dashboard and loads the current dashboard.
 */
class DashboardHeader extends React.Component {
  static propTypes = {
    dashboard_view: string,
    planner_enabled: bool.isRequired,
    screenReaderFlashMessage: func,
    canEnableElementaryDashboard: bool,
    env: object,
    loadDashboardSidebar: func,
    responsiveSize: oneOf(['small', 'medium', 'large'])
  }

  static defaultProps = {
    dashboard_view: 'cards',
    screenReaderFlashMessage: () => {},
    env: {},
    loadDashboardSidebar,
    responsiveSize: 'large'
  }

  constructor(...args) {
    super(...args)
    this.planner_init_promise = undefined
    if (this.props.planner_enabled) {
      this.planner_init_promise = initializePlanner({
        changeDashboardView: this.changeDashboard,
        getActiveApp: this.getActiveApp,
        flashError: message => showFlashAlert({message, type: 'error'}),
        flashMessage: message => showFlashAlert({message, type: 'info'}),
        srFlashMessage: this.props.screenReaderFlashMessage,
        convertApiUserContent: apiUserContent.convert,
        dateTimeFormatters: {
          dateString: $.dateString,
          timeString: $.timeString,
          datetimeString: $.datetimeString
        },
        externalFallbackFocusable: this.menuButtonFocusable,
        env: this.props.env
      })
    }
  }

  state = {
    currentDashboard: ['cards', 'activity', this.props.planner_enabled && 'planner']
      .filter(Boolean)
      .includes(this.props.dashboard_view)
      ? this.props.dashboard_view
      : 'cards',
    loadedViews: []
  }

  componentDidMount() {
    this.showDashboard(this.state.currentDashboard)
  }

  ready = () => {
    if (this.props.planner_enabled) {
      return this.planner_init_promise
    } else {
      return Promise.resolve()
    }
  }

  getActiveApp = () => this.state.currentDashboard

  resetClasses(newDashboard) {
    if (newDashboard === 'planner') {
      document.body.classList.add('dashboard-is-planner')
    } else {
      document.body.classList.remove('dashboard-is-planner')
    }
  }

  loadPlannerComponent() {
    loadPlannerDashboard()
  }

  loadCardDashboard() {
    // I put this in so I can spy on the imported function in a spec :'(
    if (!observerMode()) {
      loadCardDashboard()
    }
    // if in observer mode, ObserverOptions will handle loading the cards for the right user
  }

  loadStreamItemDashboard() {
    // populates the stream items via ajax when the toggle is switched
    const $dashboardActivity = $('#dashboard-activity')
    if ($dashboardActivity.text().trim()) return // don't do anything if it is already populated

    const promiseToGetCode = import('../backbone/views/DashboardView')
    const promiseToGetHtml = axios.get('/dashboard/stream_items')
    $dashboardActivity.show().disableWhileLoading(
      Promise.all([promiseToGetCode, promiseToGetHtml])
        .then(([{default: DashboardView}, axiosResponse]) => {
          // xsslint safeString.property data
          $dashboardActivity.html(axiosResponse.data)
          new DashboardView()
        })
        .catch(showFlashError(I18n.t('Failed to load recent activity')))
    )
  }

  loadDashboard(newView) {
    if (this.state.loadedViews.includes(newView)) return

    if (newView === 'planner' && this.props.planner_enabled) {
      this.planner_init_promise
        .then(() => {
          this.loadPlannerComponent()
        })
        .catch(() =>
          showFlashAlert({message: I18n.t('Failed initializing dashboard'), type: 'error'})
        )
    } else if (newView === 'cards') {
      this.loadCardDashboard()
    } else if (newView === 'activity') {
      this.loadStreamItemDashboard()
    }

    // also load the sidebar if we need to
    // (no sidebar is shown in planner dashboard; ObserverOptions loads sidebar for observers)
    if (newView !== 'planner' && !this.sidebarHasLoaded && !observerMode()) {
      this.props.loadDashboardSidebar()
      this.sidebarHasLoaded = true
    }

    this.setState((state, _props) => {
      return {loadedViews: state.loadedViews.concat(newView)}
    })
  }

  saveDashboardView(newView) {
    axios
      .put('/dashboard/view', {
        dashboard_view: newView
      })
      .catch(() => {
        showFlashError(I18n.t('Failed to save dashboard selection'))()
      })
  }

  saveElementaryPreference(disabled) {
    return axios
      .put('/api/v1/users/self/settings', {
        elementary_dashboard_disabled: disabled
      })
      .then(() => window.location.reload())
      .catch(showFlashError(I18n.t('Failed to save dashboard selection')))
  }

  changeDashboard = newView => {
    if (newView === 'elementary') {
      this.switchToElementary()
    } else {
      this.saveDashboardView(newView)
      this.switchDashboard(newView)
    }
    return this.ready()
  }

  switchDashboard = newView => {
    this.showDashboard(newView)
    this.setState({currentDashboard: newView})
  }

  switchToElementary = () => {
    this.saveElementaryPreference(false)
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

  reloadDashboardForObserver = userId => {
    resetDashboardCards()
    loadCardDashboard(undefined, userId)
    this.props.loadDashboardSidebar(userId)
  }

  render() {
    return (
      <div className={classnames(this.props.responsiveSize, 'ic-Dashboard-header__layout')}>
        <h1 className="ic-Dashboard-header__title">
          <span className="hidden-phone">{I18n.t('Dashboard')}</span>
        </h1>
        <div className="ic-Dashboard-header__actions">
          {ENV.FEATURES?.observer_picker && ENV.current_user_roles?.includes('observer') && (
            <View as="div" maxWidth="16em" margin="0 small">
              <ObserverOptions
                currentUser={ENV.current_user}
                currentUserRoles={ENV.current_user_roles}
                observedUsersList={ENV.OBSERVED_USERS_LIST}
                canAddObservee={ENV.CAN_ADD_OBSERVEE}
                handleChangeObservedUser={this.reloadDashboardForObserver}
              />
            </View>
          )}
          {this.props.planner_enabled && (
            <div
              id="dashboard-planner-header"
              className="CanvasPlanner__HeaderContainer"
              style={{display: this.state.currentDashboard === 'planner' ? 'block' : 'none'}}
            />
          )}
          <div id="DashboardOptionsMenu_Container">
            <DashboardOptionsMenu
              view={this.state.currentDashboard}
              planner_enabled={this.props.planner_enabled}
              onDashboardChange={this.changeDashboard}
              menuButtonRef={ref => {
                this.menuButtonFocusable = ref
              }}
              canEnableElementaryDashboard={this.props.canEnableElementaryDashboard}
            />
          </div>
          {this.props.planner_enabled && <div id="dashboard-planner-header-aux" />}
        </div>
      </div>
    )
  }
}

export {DashboardHeader}
export default responsiviser()(DashboardHeader)

let readSidebarPrefetch = false
// extract this out to a property so tests can override it and not have to mock
// out the timers in every single test.
function loadDashboardSidebar(observedUserId) {
  const dashboardSidebarUrl =
    observedUserId && observerMode()
      ? `/dashboard-sidebar?observed_user=${observedUserId}`
      : '/dashboard-sidebar'

  const rightSide = $('#right-side')
  const promiseToGetNewCourseForm = import('../jquery/util/newCourseForm')
  const prefetchedXhr = getPrefetchedXHR(dashboardSidebarUrl)
  const promiseToGetHtml =
    !readSidebarPrefetch && prefetchedXhr !== undefined
      ? asText(prefetchedXhr)
      : $.get(dashboardSidebarUrl)
  readSidebarPrefetch = true

  rightSide.disableWhileLoading(
    Promise.all([promiseToGetNewCourseForm, promiseToGetHtml]).then(
      ([{default: newCourseForm}, html]) => {
        // inject the erb html we got from the server
        rightSide.html(html)
        newCourseForm()

        // the injected html has a .Sidebar__TodoListContainer element in it,
        // render the canvas-planner ToDo list into it
        const container = document.querySelector('.Sidebar__TodoListContainer')
        if (container) renderToDoSidebar(container)

        const startButton = document.getElementById('start_new_course')
        const modalContainer = document.getElementById('create_course_modal_container')
        if (startButton && modalContainer && ENV.FEATURES?.create_course_subaccount_picker) {
          startButton.addEventListener('click', () => {
            ReactDOM.render(
              <CreateCourseModal
                isModalOpen
                setModalOpen={isOpen => {
                  if (!isOpen) ReactDOM.unmountComponentAtNode(modalContainer)
                }}
                permissions={ENV.CREATE_COURSES_PERMISSIONS.PERMISSION}
                restrictToMCCAccount={ENV.CREATE_COURSES_PERMISSIONS.RESTRICT_TO_MCC_ACCOUNT}
                isK5User={false} // can't be k5 user if classic dashboard is showing
              />,
              modalContainer
            )
          })
        }
      }
    )
  )
}
