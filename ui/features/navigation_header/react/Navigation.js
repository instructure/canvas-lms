/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {func} from 'prop-types'
import {Tray} from '@instructure/ui-tray'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import UnreadCounts from './UnreadCounts'
import preventDefault from 'prevent-default'
import parseLinkHeader from 'link-header-parsing/parseLinkHeaderFromXHR'
import tourPubSub from '@canvas/tour-pubsub'
import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'

const I18n = useI18nScope('Navigation')

const CoursesTray = React.lazy(() =>
  import(
    /* webpackChunkName: "[request]" */
    './trays/CoursesTray'
  )
)
const GroupsTray = React.lazy(() =>
  import(/* webpackChunkName: "[request]" */ './trays/GroupsTray')
)

const AccountsTray = React.lazy(() =>
  import(
    /* webpackChunkName: "[request]" */
    './trays/AccountsTray'
  )
)
const ProfileTray = React.lazy(() =>
  import(
    /* webpackChunkName: "[request]" */
    './trays/ProfileTray'
  )
)
const HistoryTray = React.lazy(() =>
  import(
    /* webpackChunkName: "[request]" */
    './trays/HistoryTray'
  )
)
const HelpTray = React.lazy(() =>
  import(
    /* webpackChunkName: "[request]" */
    './trays/HelpTray'
  )
)

const EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/
const ACTIVE_ROUTE_REGEX =
  /^\/(courses|groups|accounts|grades|calendar|conversations|profile)|^#history/
const ACTIVE_CLASS = 'ic-app-header__menu-list-item--active'

const TYPE_URL_MAP = {
  courses:
    '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname',
  groups: '/api/v1/users/self/groups?include[]=can_access',
  accounts: '/api/v1/accounts',
  profile: '/api/v1/users/self/tabs',
  history: '/api/v1/users/self/history',
  help: '/help_links',
}

const TYPE_FILTER_MAP = {
  groups: group => group.can_access && !group.concluded,
}

const RESOURCE_COUNT = 10

// give the trays that slide out from the the nav bar
// a place to mount. It has to be outside the <div id=application>
// to aria-hide everything but the tray when open.
let portal
function getPortal() {
  if (!portal) {
    portal = document.createElement('div')
    portal.id = 'nav-tray-portal'
    // the <header> has z-index: 100. This has to be behind it,
    portal.setAttribute('style', 'position: relative; z-index: 99;')
    document.body.appendChild(portal)
  }
  return portal
}

function noop() {}

export default class Navigation extends React.Component {
  static propTypes = {
    unreadComponent: func, // for testing only
    onDataReceived: func,
  }

  static defaultProps = {
    unreadComponent: UnreadCounts,
  }

  state = {
    groups: [],
    accounts: [],
    courses: [],
    help: [],
    profile: [],
    unreadSharesCount: 0,
    isTrayOpen: false,
    type: null,
    coursesLoading: false,
    coursesAreLoaded: false,
    observedUserId: '',
    accountsLoading: false,
    accountsAreLoaded: false,
    groupsLoading: false,
    groupsAreLoaded: false,
    helpLoading: false,
    helpAreLoaded: false,
    profileAreLoading: false,
    profileAreLoaded: false,
    historyLoading: false,
    historyAreLoaded: false,
    releaseNotesPollInterval: 30000,
    releaseNotesBadgeDisabled:
      !ENV.FEATURES.embedded_release_notes || ENV.SETTINGS.release_notes_badge_disabled,
  }

  componentDidMount() {
    /**
     * Mount up stuff to our existing DOM elements, yes, it's not very
     * React-y, but it is workable and maintainable, plus it doesn't require
     * us to trash what Rails has already rendered.
     */

    // ////////////////////////////////
    // / Click Events
    // ////////////////////////////////
    Object.keys(TYPE_URL_MAP).forEach(type => {
      $(`#global_nav_${type}_link`).on(
        'click',
        preventDefault(this.handleMenuClick.bind(this, type))
      )
    })
    this.openPublishUnsubscribe = tourPubSub.subscribe(
      'navigation-tray-open',
      ({type, noFocus}) => {
        this.ensureLoaded(type)
        this.openTray(type, noFocus)

        // If we're already open for the specified type
        // send a message that we are open.
        if (this.state.isTrayOpen && this.state.type === type) {
          tourPubSub.publish('navigation-tray-opened', type)
        }
      }
    )
    this.closePublishUnsubscribe = tourPubSub.subscribe('navigation-tray-close', () => {
      this.closeTray()
    })
    this.overrideDismissUnsubscribe = tourPubSub.subscribe(
      'navigation-tray-override-dismiss',
      tf => {
        this.setState({overrideDismiss: tf})
      }
    )
  }

  componentWillUnmount() {
    this.openPublishUnsubscribe && this.openPublishUnsubscribe()
    this.overrideDismissUnsubscribe && this.overrideDismissUnsubscribe()
    this.closePublishUnsubscribe && this.closePublishUnsubscribe()
  }

  componentDidUpdate(_prevProps, prevState) {
    if (prevState.activeItem !== this.state.activeItem) {
      $(`.${ACTIVE_CLASS}`).removeClass(ACTIVE_CLASS).removeAttr('aria-current')
      $(`#global_nav_${this.state.activeItem}_link`)
        .closest('li')
        .addClass(ACTIVE_CLASS)
        .attr('aria-current', 'page')
    }
  }

  /**
   * Given a URL and a type value, it gets the data and updates state.
   */
  getResource(url, type) {
    this.setState({[`${type}Loading`]: true})
    this.loadResourcePage(url, type)
  }

  _isLoadedOrLoading = type => this.state[`${type}AreLoaded`] || this.state[`${type}Loading`]

  ensureLoaded(type) {
    let url = TYPE_URL_MAP[type]
    if (!url) return

    // if going after courses and I'm an observer,
    // only retrive the courses for my observee
    if (type === 'courses' && ENV.current_user_roles.includes('observer')) {
      let forceLoad = false
      const k5_observed_user_id = savedObservedId(ENV.current_user_id)
      if (k5_observed_user_id) {
        url = `${url}&observed_user_id=${k5_observed_user_id}`
        if (k5_observed_user_id !== this.state.observedUserId) {
          this.setState({
            observedUserId: k5_observed_user_id,
            [`${type}AreLoaded}`]: false,
            [`${type}Loading`]: false,
          })
          forceLoad = true
        }
      }
      if (forceLoad || !this._isLoadedOrLoading(type)) {
        this.getResource(url, type)
      }
    } else if (!this._isLoadedOrLoading(type)) {
      this.getResource(url, type)
    }
  }

  loadResourcePage(url, type, previousData = []) {
    $.getJSON(url, (data, __, xhr) => {
      const newData = previousData.concat(this.filterDataForType(data, type))

      // queue the next page if we need one
      if (newData.length < RESOURCE_COUNT) {
        const link = parseLinkHeader(xhr)
        if (link.next) {
          this.loadResourcePage(link.next, type, newData)
          return
        }
      }

      // finished
      this.setState(
        {
          [type]: newData,
          [`${type}Loading`]: false,
          [`${type}AreLoaded`]: true,
        },
        this.props.onDataReceived
      )
    })
  }

  filterDataForType(data, type) {
    const filterFunc = TYPE_FILTER_MAP[type]
    if (typeof filterFunc === 'function') {
      return data.filter(filterFunc)
    }
    return data
  }

  determineActiveLink() {
    const path = window.location.pathname
    const matchData = path.match(EXTERNAL_TOOLS_REGEX) || path.match(ACTIVE_ROUTE_REGEX)
    const activeItem = matchData && matchData[1]
    if (!activeItem) {
      this.setState({activeItem: 'dashboard'})
    } else {
      this.setState({activeItem})
    }
  }

  handleMenuClick(type) {
    // Make sure data is loaded up
    this.ensureLoaded(type)

    if (this.state.isTrayOpen && this.state.activeItem === type) {
      this.closeTray()
    } else if (this.state.isTrayOpen && this.state.activeItem !== type) {
      this.openTray(type)
    } else {
      this.openTray(type)
    }
  }

  openTray(type, noFocus) {
    // Sometimes we don't want the tray to capture focus,
    // so we specify that here.
    this.setState({type, noFocus, isTrayOpen: true, activeItem: type})
  }

  closeTray = () => {
    this.determineActiveLink()
    // Regardless of whether it captured focus before,
    // we should make sure it does on future openings.
    this.setState({isTrayOpen: false, noFocus: false}, () => {
      setTimeout(() => {
        this.setState({type: null})
      }, 150)
    })
  }

  handlePollingInterval = count => {
    if (count > 0) {
      this.setState({releaseNotesPollInterval: 30000})
    } else {
      this.setState({releaseNotesPollInterval: 300000})
    }
  }

  renderTrayContent() {
    switch (this.state.type) {
      case 'courses':
        return (
          <CoursesTray
            courses={
              window.ENV.K5_USER &&
              window.ENV.current_user_roles?.every(role => role === 'student' || role === 'user')
                ? this.state.courses.filter(c => !c.homeroom_course)
                : this.state.courses
            }
            hasLoaded={this.state.coursesAreLoaded}
            closeTray={this.closeTray}
            k5User={window.ENV.K5_USER}
          />
        )
      case 'groups':
        return (
          <GroupsTray
            groups={this.state.groups}
            hasLoaded={this.state.groupsAreLoaded}
            closeTray={this.closeTray}
          />
        )
      case 'accounts':
        return (
          <AccountsTray
            accounts={this.state.accounts}
            hasLoaded={this.state.accountsAreLoaded}
            closeTray={this.closeTray}
          />
        )
      case 'profile':
        return (
          <ProfileTray
            userDisplayName={window.ENV.current_user.display_name}
            userPronouns={window.ENV.current_user.pronouns}
            userAvatarURL={
              window.ENV.current_user.avatar_is_fallback
                ? null
                : window.ENV.current_user.avatar_image_url
            }
            loaded={this.state.profileAreLoaded}
            tabs={this.state.profile}
            counts={{unreadShares: this.state.unreadSharesCount}}
          />
        )
      case 'history':
        return (
          <HistoryTray
            history={this.state.history}
            hasLoaded={this.state.historyAreLoaded}
            closeTray={this.closeTray}
          />
        )
      case 'help':
        return (
          <HelpTray
            trayTitle={window.ENV.help_link_name}
            links={this.state.help}
            hasLoaded={this.state.helpAreLoaded}
            closeTray={this.closeTray}
            showNotes={ENV.FEATURES.embedded_release_notes}
            badgeDisabled={this.state.releaseNotesBadgeDisabled}
            setBadgeDisabled={val => this.setState({releaseNotesBadgeDisabled: val})}
          />
        )
      default:
        return null
    }
  }

  getTrayLabel() {
    switch (this.state.type) {
      case 'courses':
        return I18n.t('Courses tray')
      case 'groups':
        return I18n.t('Groups tray')
      case 'accounts':
        return I18n.t('Admin tray')
      case 'profile':
        return I18n.t('Profile tray')
      case 'help':
        return I18n.t('%{title} tray', {title: window.ENV.help_link_name})
      case 'history':
        return I18n.t('Recent History tray')
      default:
        return I18n.t('Global navigation tray')
    }
  }

  // Also have to attend to the unread dot on the mobile view inbox
  onInboxUnreadUpdate(unreadCount) {
    if (this.state.unreadInboxCount !== unreadCount) this.setState({unreadInboxCount: unreadCount})
    const el = document.getElementById('mobileHeaderInboxUnreadBadge')
    if (el) el.style.display = unreadCount > 0 ? '' : 'none'
    if (typeof this.props.onDataReceived === 'function') this.props.onDataReceived()
  }

  onSharesUnreadUpdate(unreadCount) {
    if (this.state.unreadSharesCount !== unreadCount)
      this.setState({unreadSharesCount: unreadCount})
  }

  inboxUnreadSRText(count) {
    return I18n.t(
      {
        one: 'One unread message.',
        other: '%{count} unread messages.',
      },
      {count}
    )
  }

  sharesUnreadSRText(count) {
    return I18n.t(
      {
        one: 'One unread share.',
        other: '%{count} unread shares.',
      },
      {count}
    )
  }

  releaseNotesBadgeText(count) {
    return I18n.t(
      {
        one: 'One unread release note.',
        other: '%{count} release notes.',
      },
      {count}
    )
  }

  render() {
    const UnreadComponent = this.props.unreadComponent

    return (
      <>
        <Tray
          key={this.state.type}
          label={this.getTrayLabel()}
          size="small"
          open={this.state.isTrayOpen}
          // We need to override closing trays
          // so the tour can properly go through them
          // without them unexpectedly closing.
          onDismiss={this.state.overrideDismiss ? noop : this.closeTray}
          shouldCloseOnDocumentClick={true}
          shouldContainFocus={!this.state.noFocus}
          mountNode={getPortal()}
          theme={{smallWidth: '28em'}}
          onEntered={() => {
            tourPubSub.publish('navigation-tray-opened', this.state.type)
          }}
        >
          <div className={`navigation-tray-container ${this.state.type}-tray`}>
            <CloseButton
              placement="end"
              onClick={this.closeTray}
              screenReaderLabel={I18n.t('Close')}
            />
            <div className="tray-with-space-for-global-nav">
              <React.Suspense
                fallback={
                  <View display="block" textAlign="center">
                    <Spinner
                      size="large"
                      margin="large auto"
                      renderTitle={() => I18n.t('Loading')}
                    />
                  </View>
                }
              >
                {this.renderTrayContent()}
              </React.Suspense>
            </div>
          </div>
        </Tray>
        {ENV.DIRECT_SHARE_ENABLED && ENV.current_user_id && (
          <UnreadComponent
            targetEl={
              this.unreadSharesCountElement ||
              (this.unreadSharesCountElement = document.querySelector(
                '#global_nav_profile_link .menu-item__badge'
              ))
            }
            dataUrl="/api/v1/users/self/content_shares/unread_count"
            onUpdate={unreadCount => this.onSharesUnreadUpdate(unreadCount)}
            srText={this.sharesUnreadSRText}
          />
        )}
        {!ENV.current_user_disabled_inbox && (
          <UnreadComponent
            targetEl={
              this.unreadInboxCountElement ||
              (this.unreadInboxCountElement = document.querySelector(
                '#global_nav_conversations_link .menu-item__badge'
              ))
            }
            dataUrl="/api/v1/conversations/unread_count"
            onUpdate={unreadCount => this.onInboxUnreadUpdate(unreadCount)}
            srText={this.inboxUnreadSRText}
            useSessionStorage={false}
          />
        )}
        {!this.state.releaseNotesBadgeDisabled && (
          <UnreadComponent
            targetEl={
              this.unreadReleaseNotesCountElement ||
              (this.unreadReleaseNotesCountElement = document.querySelector(
                '#global_nav_help_link .menu-item__badge'
              ))
            }
            dataUrl="/api/v1/release_notes/unread_count"
            srText={this.releaseNotesBadgeText}
            onUpdate={this.handlePollingInterval}
            pollIntervalMs={this.state.releaseNotesPollInterval}
          />
        )}
      </>
    )
  }
}
