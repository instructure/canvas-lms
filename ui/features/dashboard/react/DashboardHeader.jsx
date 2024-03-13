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
import {useScope as useI18nScope} from '@canvas/i18n'
import axios from '@canvas/axios'
import classnames from 'classnames'
import {bool, func, string, object, oneOf} from 'prop-types'
import {
  initializePlanner,
  loadPlannerDashboard,
  reloadPlannerForObserver,
  renderToDoSidebar,
  responsiviser,
} from '@canvas/planner'
import {asAxios, getPrefetchedXHR} from '@canvas/util/xhr'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'
import apiUserContent from '@canvas/util/jquery/apiUserContent'
import DashboardOptionsMenu from './DashboardOptionsMenu'
import {CardDashboardLoader} from '@canvas/dashboard-card'
import $ from 'jquery'
import '@canvas/jquery/jquery.disableWhileLoading'
import {CreateCourseModal} from '@canvas/create-course-modal/react/CreateCourseModal'
import ObserverOptions from '@canvas/observer-picker'
import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('dashboard')

const [show, hide] = ['block', 'none'].map(displayVal => id => {
  const el = document.getElementById(id)
  if (el) el.style.display = displayVal
})

const observerMode = () => ENV.current_user_roles?.includes('observer')

/**
 * This component renders the header and the to do sidebar for the user
 * dashboard and loads the current dashboard.
 */
class DashboardHeader extends React.Component {
  static propTypes = {
    dashboard_view: string,
    planner_enabled: bool.isRequired,
    screenReaderFlashMessage: func,
    allowElementaryDashboard: bool,
    env: object,
    loadDashboardSidebar: func,
    responsiveSize: oneOf(['small', 'medium', 'large']),
    startNewCourseVisible: bool,
    viewGradesUrl: string,
  }

  static defaultProps = {
    dashboard_view: 'cards',
    screenReaderFlashMessage: () => {},
    env: {},
    loadDashboardSidebar,
    responsiveSize: 'large',
  }

  constructor(...args) {
    super(...args)
    this.cardDashboardLoader = new CardDashboardLoader()
    this.planner_init_promise = undefined
    this.plannerLoaded = false
    if (this.props.planner_enabled) {
      // setup observing another user?
      let observedUser
      if (observerMode() && ENV.OBSERVED_USERS_LIST.length > 0) {
        const storedObservedUserId = savedObservedId(ENV.current_user.id)
        const {id, name, avatar_url} =
          ENV.OBSERVED_USERS_LIST.find(u => u.id === storedObservedUserId) ||
          ENV.OBSERVED_USERS_LIST[0]
        observedUser = id === ENV.current_user_id ? null : {id, name, avatarUrl: avatar_url}
      }

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
          datetimeString: $.datetimeString,
        },
        externalFallbackFocusable: this.menuButtonFocusable,
        observedUser,
        env: this.props.env,
      })
    }
  }

  state = {
    currentDashboard: ['cards', 'activity', this.props.planner_enabled && 'planner']
      .filter(Boolean)
      .includes(this.props.dashboard_view)
      ? this.props.dashboard_view
      : 'cards',
    loadedViews: [],
    selectedObserveeId: null,
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

  loadCardDashboard(observedUserId) {
    // I put this in so I can spy on the imported function in a spec :'(
    this.cardDashboardLoader.loadCardDashboard(undefined, observedUserId)
  }

  loadStreamItemDashboard(observedUserId) {
    // populates the stream items via ajax when the toggle is switched
    const streamItemsUrl =
      observedUserId && observerMode()
        ? `/dashboard/stream_items?observed_user_id=${observedUserId}`
        : '/dashboard/stream_items'

    const $dashboardActivity = $('#dashboard-activity')
    // don't do anything if it is already populated and user isn't an observer
    if (!observerMode() && $dashboardActivity.text().trim()) return

    // unbind any existing callbacks on stream item dashboard
    if (this.streamItemDashboard) {
      this.streamItemDashboard.undelegateEvents()
      this.streamItemDashboard = undefined
    }

    const promiseToGetCode = import('../backbone/views/DashboardView')
    const promiseToGetHtml = axios.get(streamItemsUrl)
    $dashboardActivity.show().disableWhileLoading(
      Promise.all([promiseToGetCode, promiseToGetHtml])
        .then(([{default: DashboardView}, axiosResponse]) => {
          // xsslint safeString.identifier axiosResponse
          // xsslint safeString.property data
          $dashboardActivity.html(axiosResponse.data)
          this.streamItemDashboard = new DashboardView()
        })
        .catch(showFlashError(I18n.t('Failed to load recent activity')))
    )
  }

  loadDashboard(newView) {
    // if user is an observer, wait until we have an id to load
    // (this might be the observer's id, and is available as soon as the observer picker loads)
    if (observerMode() && !this.state.selectedObserveeId) return
    if (this.state.loadedViews.includes(newView)) return

    if (newView === 'planner' && this.props.planner_enabled) {
      this.planner_init_promise
        .then(() => {
          if (!this.plannerLoaded) {
            this.loadPlannerComponent()
            this.plannerLoaded = true
          }
        })
        .catch(_ex => {
          showFlashAlert({message: I18n.t('Failed initializing dashboard'), type: 'error'})
        })
    } else if (newView === 'cards') {
      this.loadCardDashboard(this.state.selectedObserveeId)
    } else if (newView === 'activity') {
      this.loadStreamItemDashboard(this.state.selectedObserveeId)
    }

    // also load the sidebar if we need to
    // (no sidebar is shown in planner dashboard)
    if (newView !== 'planner' && !this.sidebarHasLoaded) {
      this.props.loadDashboardSidebar(this.state.selectedObserveeId)
      this.sidebarHasLoaded = true
    }

    this.setState((state, _props) => {
      return {loadedViews: state.loadedViews.concat(newView)}
    })
  }

  saveDashboardView(newView) {
    axios
      .put('/dashboard/view', {
        dashboard_view: newView,
      })
      .catch(() => {
        showFlashError(I18n.t('Failed to save dashboard selection'))()
      })
  }

  saveElementaryPreference(disabled) {
    return axios
      .put('/api/v1/users/self/settings', {
        elementary_dashboard_disabled: disabled,
      })
      .then(() => window.location.reload())
      .catch(showFlashError(I18n.t('Failed to save dashboard selection')))
  }

  handleChangeObservedUser(id) {
    if (id !== this.state.selectedObserveeId) {
      fetchShowK5Dashboard(id)
        .then(response => {
          if (!response.show_k5_dashboard) {
            this.reloadDashboardForObserver(id)
            if (this.props.planner_enabled) {
              this.planner_init_promise
                .then(() => {
                  reloadPlannerForObserver(id)
                })
                .catch(() => {
                  // ignore. handled elsewhere
                })
            }
          } else {
            window.location.reload()
          }
        })
        .catch(err => showFlashError(I18n.t('Unable to switch students'))(err))
    }
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
      cards: ['DashboardCard_Container', 'right-side-wrapper'],
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
    this.sidebarHasLoaded = false
    this.setState({selectedObserveeId: userId, loadedViews: []}, () => {
      this.cardDashboardLoader = new CardDashboardLoader()
      this.loadDashboard(this.state.currentDashboard)
    })
  }

  renderLegacy(canEnableElementaryDashboard) {
    return (
      <div className={classnames(this.props.responsiveSize, 'ic-Dashboard-header__layout')}>
        <Flex direction="row" alignItems="center" justifyItems="space-between" width="100%">
          <Flex.Item>
            <Heading as="span" level="h1" className=".ic-Dashboard-header__title">
              <span className="hidden-phone">{I18n.t('Dashboard')}</span>
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <div className="ic-Dashboard-header__actions">
              {observerMode() && (
                <View as="div" maxWidth="16em" margin="0 small">
                  <ObserverOptions
                    currentUser={ENV.current_user}
                    currentUserRoles={ENV.current_user_roles}
                    observedUsersList={ENV.OBSERVED_USERS_LIST}
                    canAddObservee={ENV.CAN_ADD_OBSERVEE}
                    handleChangeObservedUser={id => this.handleChangeObservedUser(id)}
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
                  canEnableElementaryDashboard={canEnableElementaryDashboard}
                />
              </div>
              {this.props.planner_enabled && <div id="dashboard-planner-header-aux" />}
            </div>
          </Flex.Item>
        </Flex>
      </div>
    )
  }

  renderResponsiveContent(canEnableElementaryDashboard) {
    return (
      <div style={{backgroundColor: 'white', paddingBottom: 'small'}}>
        <Flex
          margin="0 0 medium"
          as="div"
          direction={this.props.responsiveSize == 'large' ? 'row' : 'column'}
          withVisualDebug={false}
          alignItems="stretch"
        >
          <Flex.Item
            shouldGrow={true}
            shouldShrink={false}
            margin={this.props.responsiveSize == 'large' ? '0' : '0 0 medium 0'}
          >
            <Heading level="h1" margin="0 0 small 0">
              {I18n.t('Dashboard')}
            </Heading>
          </Flex.Item>
          <Flex.Item
            overflowY="visible"
            margin={this.props.responsiveSize == 'large' ? 'x-small 0 0 0' : '0'}
          >
            <Flex
              gap="small"
              withVisualDebug={false}
              direction={this.props.responsiveSize == 'small' ? 'column-reverse' : 'row'}
            >
              {observerMode() && (
                <Flex.Item overflowY="visible">
                  <ObserverOptions
                      currentUser={ENV.current_user}
                      currentUserRoles={ENV.current_user_roles}
                      observedUsersList={ENV.OBSERVED_USERS_LIST}
                      canAddObservee={ENV.CAN_ADD_OBSERVEE}
                      handleChangeObservedUser={id => this.handleChangeObservedUser(id)}
                    />
                </Flex.Item>
              )}
              <Flex.Item overflowY="visible">
                <div id="DashboardOptionsMenu_Container">
                  <DashboardOptionsMenu
                    view={this.state.currentDashboard}
                    planner_enabled={this.props.planner_enabled}
                    onDashboardChange={this.changeDashboard}
                    menuButtonRef={ref => {
                      this.menuButtonFocusable = ref
                    }}
                    canEnableElementaryDashboard={canEnableElementaryDashboard}
                    responsiveSize={this.props.responsiveSize}
                  />
                </div>
              </Flex.Item>
              <span style={{display: (this.props.planner_enabled && this.state.currentDashboard == 'planner' ? 'block' : 'none')}}>
                <Flex.Item overflowY="visible">
                  <span id="dashboard-planner-header"></span>
                  <span id="dashboard-planner-header-aux"></span>
                </Flex.Item>
              </span>
              {(this.props.startNewCourseVisible) && (
                <Flex.Item overflowY="visible">
                  <Button 
                    display={this.props.responsiveSize == 'small' ? 'block' : 'inline-block'}
                    onclick={() => {}}
                    id="start_new_course"
                    aria-controls="new_course_form"
                  >
                    {I18n.t('Start a New Course')}
                  </Button>
                </Flex.Item>
              )}
              {this.state.currentDashboard != 'planner' && (
              <Flex.Item overflowY="visible">
                <Button 
                  id="ic-Dashboard-header__view_grades_button"
                  display={this.props.responsiveSize == 'small' ? 'block' : 'inline-block'}
                  href={this.props.viewGradesUrl}
                >
                  {I18n.t('View Grades')}
                </Button>
              </Flex.Item>
              )}
            </Flex>
          </Flex.Item>
        </Flex>
      </div>
    )
  }

  render() {
    const canEnableElementaryDashboard =
      this.props.allowElementaryDashboard &&
      (!observerMode() || this.state.selectedObserveeId === ENV.current_user_id)

    if (!ENV.FEATURES?.instui_header) {
      return this.renderLegacy(canEnableElementaryDashboard)
    }

    return this.renderResponsiveContent(canEnableElementaryDashboard)
  }
}

export {DashboardHeader}
export default responsiviser()(DashboardHeader)

// extract this out to a property so tests can override it and not have to mock
// out the timers in every single test.
function loadDashboardSidebar(observedUserId) {
  const dashboardSidebarUrl =
    observedUserId && observerMode()
      ? `/dashboard-sidebar?observed_user_id=${observedUserId}`
      : '/dashboard-sidebar'

  const rightSide = $('#right-side')
  const promiseToGetNewCourseForm = import('../jquery/util/newCourseForm')
  const promiseToGetHtml =
    asAxios(getPrefetchedXHR(dashboardSidebarUrl), 'text') || axios.get(dashboardSidebarUrl)

  rightSide.disableWhileLoading(
    Promise.all([promiseToGetNewCourseForm, promiseToGetHtml]).then(response => {
      const newCourseForm = response[0].default
      const html = response[1].data
      // inject the erb html we got from the server
      rightSide.html(html)
      newCourseForm()

      // the injected html has a .Sidebar__TodoListContainer element in it,
      // render the canvas-planner ToDo list into it
      const container = document.querySelector('.Sidebar__TodoListContainer')
      if (container) renderToDoSidebar(container)

      loadStartNewCourseHandler()
    })
  )
}

function loadStartNewCourseHandler() {
  const startButton = document.getElementById('start_new_course')
  if (ENV.FEATURES?.instui_header && startButton) {
    // class name cannot be added to the Button component
    $(startButton).addClass('element_toggler')
  }

  const modalContainer = document.getElementById('create_course_modal_container')
  if (startButton && modalContainer && ENV.FEATURES?.create_course_subaccount_picker) {
    startButton.addEventListener('click', () => {
      ReactDOM.render(
        <CreateCourseModal
          isModalOpen={true}
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
