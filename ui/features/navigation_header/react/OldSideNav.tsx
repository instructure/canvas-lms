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
import preventDefault from '@canvas/util/preventDefault'
import parseLinkHeader from 'link-header-parsing/parseLinkHeaderFromXHR'
import tourPubSub from '@canvas/tour-pubsub'
import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import type {
  AccessibleGroup,
  Account,
  Course,
  HelpLink,
  HistoryEntry,
  ProfileTab,
} from '../../../api.d'

const I18n = useI18nScope('Navigation')

// We don't need to poll for new release notes very often since we expect
// new ones to appear only infrequently. The act of viewing them will reset
// the badge at the time of viewing.
const RELEASE_NOTES_POLL_INTERVAL = 60 * 60 * 1000 // one hour

const CoursesTray = React.lazy(
  () =>
    import(
      /* webpackChunkName: "[request]" */
      './trays/CoursesTray'
    )
)
const GroupsTray = React.lazy(
  () => import(/* webpackChunkName: "[request]" */ './trays/GroupsTray')
)

const AccountsTray = React.lazy(
  () =>
    import(
      /* webpackChunkName: "[request]" */
      './trays/AccountsTray'
    )
)
const ProfileTray = React.lazy(
  () =>
    import(
      /* webpackChunkName: "[request]" */
      './trays/ProfileTray'
    )
)
const HistoryTray = React.lazy(
  () =>
    import(
      /* webpackChunkName: "[request]" */
      './trays/HistoryTray'
    )
)
const HelpTray = React.lazy(
  () =>
    import(
      /* webpackChunkName: "[request]" */
      './trays/HelpTray'
    )
)

const EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/
const ACTIVE_ROUTE_REGEX =
  /^\/(courses|groups|accounts|grades|calendar|conversations|profile)|^#history/
const ACTIVE_CLASS = 'ic-app-header__menu-list-item--active'

const groupFilter = (group: AccessibleGroup) => group.can_access && !group.concluded

type ActiveItem = 'dashboard' | 'accounts' | 'courses' | 'groups' | 'profile' | 'history' | 'help'

const itemsWithResources = ['courses', 'groups', 'accounts', 'profile', 'history', 'help'] as const
type ItemWithResources = (typeof itemsWithResources)[number]

const TYPE_URL_MAP = {
  courses:
    '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname',
  groups: '/api/v1/users/self/groups?include[]=can_access',
  accounts: '/api/v1/accounts',
  profile: '/api/v1/users/self/tabs',
  history: '/api/v1/users/self/history',
  help: '/help_links',
} as const

const RESOURCE_COUNT = 10

// give the trays that slide out from the the nav bar
// a place to mount. It has to be outside the <div id=application>
// to aria-hide everything but the tray when open.
let portal: HTMLDivElement | undefined
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

type Props = {
  unreadComponent: any
  onDataReceived: () => void
}

type State = {
  accounts: Account[]
  accountsAreLoaded: boolean
  accountsLoading: boolean
  activeItem: ActiveItem
  courses: Course[]
  coursesAreLoaded: boolean
  coursesLoading: boolean
  groups: AccessibleGroup[]
  groupsAreLoaded: boolean
  groupsLoading: boolean
  help: HelpLink[]
  helpAreLoaded: boolean
  helpLoading: boolean
  history: HistoryEntry[]
  historyAreLoaded: boolean
  historyLoading: boolean
  isTrayOpen: boolean
  noFocus: boolean
  observedUserId: string
  overrideDismiss: boolean
  profile: ProfileTab[]
  profileAreLoaded: boolean
  profileAreLoading: boolean
  releaseNotesBadgeDisabled: boolean
  type: string | null
  unreadInboxCount: number
  unreadSharesCount: number
}

export default class Navigation extends React.Component<Props, State> {
  forceUnreadReleaseNotesPoll: (() => void) | undefined

  openPublishUnsubscribe: () => void = noop

  overrideDismissUnsubscribe: () => void = noop

  closePublishUnsubscribe: () => void = noop

  unreadReleaseNotesCountElement: HTMLElement | null = null

  unreadInboxCountElement: HTMLElement | null = null

  unreadSharesCountElement: HTMLElement | null = null

  static propTypes = {
    unreadComponent: func, // for testing only
    onDataReceived: func,
  }

  static defaultProps = {
    unreadComponent: UnreadCounts,
  }

  constructor(props: Props) {
    super(props)
    this.forceUnreadReleaseNotesPoll = undefined
    this.setReleaseNotesUnreadPollNow = this.setReleaseNotesUnreadPollNow.bind(this)
    this.state = {
      accounts: [],
      accountsAreLoaded: false,
      accountsLoading: false,
      activeItem: 'dashboard',
      courses: [],
      coursesAreLoaded: false,
      coursesLoading: false,
      groups: [],
      groupsAreLoaded: false,
      groupsLoading: false,
      // eslint-disable-next-line react/no-unused-state
      help: [],
      helpAreLoaded: false,
      helpLoading: false,
      // eslint-disable-next-line react/no-unused-state
      history: [],
      historyAreLoaded: false,
      historyLoading: false,
      isTrayOpen: false,
      noFocus: false,
      observedUserId: '',
      overrideDismiss: false,
      profile: [],
      profileAreLoaded: false,
      profileAreLoading: false,
      type: null,
      unreadInboxCount: 0,
      unreadSharesCount: 0,
      releaseNotesBadgeDisabled:
        !ENV.FEATURES.embedded_release_notes || ENV.SETTINGS.release_notes_badge_disabled,
    }
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
    itemsWithResources.forEach(type => {
      $(`#global_nav_${type}_link`).on(
        'click',
        preventDefault(this.handleMenuClick.bind(this, type))
      )
    })
    this.openPublishUnsubscribe = tourPubSub.subscribe<{
      type: ActiveItem
      noFocus: boolean
    }>('navigation-tray-open', ({type, noFocus}) => {
      if (itemsWithResources.includes(type as ItemWithResources)) {
        this.ensureLoaded(type as ItemWithResources)
      }
      this.openTray(type, noFocus)

      // If we're already open for the specified type
      // send a message that we are open.
      if (this.state.isTrayOpen && this.state.type === type) {
        tourPubSub.publish('navigation-tray-opened', type)
      }
    })
    this.closePublishUnsubscribe = tourPubSub.subscribe('navigation-tray-close', () => {
      this.closeTray()
    })
    this.overrideDismissUnsubscribe = tourPubSub.subscribe(
      'navigation-tray-override-dismiss',
      tf => {
        this.setState({overrideDismiss: Boolean(tf)})
      }
    )
  }

  componentWillUnmount() {
    this.openPublishUnsubscribe && this.openPublishUnsubscribe()
    this.overrideDismissUnsubscribe && this.overrideDismissUnsubscribe()
    this.closePublishUnsubscribe && this.closePublishUnsubscribe()
  }

  componentDidUpdate(_prevProps: Props, prevState: State) {
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
  getResource(url: string, type: ActiveItem) {
    switch (type) {
      case 'courses':
        this.setState({coursesLoading: true})
        break
      case 'groups':
        this.setState({groupsLoading: true})
        break
      case 'accounts':
        this.setState({accountsLoading: true})
        break
      case 'profile':
        this.setState({profileAreLoading: true})
        break
      case 'history':
        this.setState({historyLoading: true})
        break
      case 'help':
        this.setState({helpLoading: true})
        break
    }
    this.loadResourcePage(url, type)
  }

  _isLoadedOrLoading = (type: string) => {
    switch (type) {
      case 'courses':
        return this.state.coursesAreLoaded || this.state.coursesLoading
      case 'groups':
        return this.state.groupsAreLoaded || this.state.groupsLoading
      case 'accounts':
        return this.state.accountsAreLoaded || this.state.accountsLoading
      case 'profile':
        return this.state.profileAreLoaded || this.state.profileAreLoading
      case 'history':
        return this.state.historyAreLoaded || this.state.historyLoading
      case 'help':
        return this.state.helpAreLoaded || this.state.helpLoading
    }
  }

  ensureLoaded(type: ItemWithResources) {
    let url: string = TYPE_URL_MAP[type]
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
            coursesAreLoaded: false,
            coursesLoading: false,
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

  loadResourcePage(url: string, type: ActiveItem, previousData = []) {
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
      switch (type) {
        case 'courses':
          this.setState(
            {
              courses: newData,
              coursesLoading: false,
              coursesAreLoaded: true,
            },
            this.props.onDataReceived
          )
          break
        case 'groups':
          this.setState(
            {
              groups: newData,
              groupsLoading: false,
              groupsAreLoaded: true,
            },
            this.props.onDataReceived
          )
          break
        case 'accounts':
          this.setState(
            {
              accounts: newData,
              accountsLoading: false,
              accountsAreLoaded: true,
            },
            this.props.onDataReceived
          )
          break
        case 'profile':
          this.setState(
            {
              profile: newData,
              profileAreLoading: false,
              profileAreLoaded: true,
            },
            this.props.onDataReceived
          )
          break
      }
    })
  }

  filterDataForType(data: any, type: ActiveItem) {
    if (type === 'groups') {
      return data.filter(groupFilter)
    }
    return data
  }

  determineActiveLink() {
    const path = window.location.pathname
    const matchData = path.match(EXTERNAL_TOOLS_REGEX) || path.match(ACTIVE_ROUTE_REGEX)
    const activeItem = (matchData && matchData[1]) as ActiveItem | null
    if (!activeItem) {
      this.setState({activeItem: 'dashboard'})
    } else {
      this.setState({activeItem})
    }
  }

  handleMenuClick(type: ActiveItem) {
    // Make sure data is loaded up
    if (itemsWithResources.includes(type as ItemWithResources)) {
      this.ensureLoaded(type as ItemWithResources)
    }

    if (this.state.isTrayOpen && this.state.activeItem === type) {
      this.closeTray()
    } else if (this.state.isTrayOpen && this.state.activeItem !== type) {
      this.openTray(type)
    } else {
      this.openTray(type)
    }
  }

  openTray(type: ActiveItem, noFocus: boolean = false) {
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
            k5User={window.ENV.K5_USER}
          />
        )
      case 'groups':
        return <GroupsTray groups={this.state.groups} hasLoaded={this.state.groupsAreLoaded} />
      case 'accounts':
        return (
          <AccountsTray accounts={this.state.accounts} hasLoaded={this.state.accountsAreLoaded} />
        )
      case 'profile':
        return (
          <ProfileTray
            userDisplayName={window.ENV.current_user.display_name}
            userPronouns={window.ENV.current_user.pronouns}
            userAvatarURL={
              window.ENV.current_user.avatar_is_fallback
                ? ''
                : window.ENV.current_user.avatar_image_url
            }
            loaded={this.state.profileAreLoaded}
            tabs={this.state.profile}
            counts={{unreadShares: this.state.unreadSharesCount}}
          />
        )
      case 'history':
        return <HistoryTray />
      case 'help':
        return (
          <HelpTray
            closeTray={this.closeTray}
            showNotes={ENV.FEATURES.embedded_release_notes}
            badgeDisabled={this.state.releaseNotesBadgeDisabled}
            setBadgeDisabled={val => this.setState({releaseNotesBadgeDisabled: val})}
            forceUnreadPoll={this.forceUnreadReleaseNotesPoll}
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
  onInboxUnreadUpdate(unreadCount: number) {
    if (this.state.unreadInboxCount !== unreadCount) this.setState({unreadInboxCount: unreadCount})
    const el = document.getElementById('mobileHeaderInboxUnreadBadge')
    if (el) el.style.display = unreadCount > 0 ? '' : 'none'
    if (typeof this.props.onDataReceived === 'function') this.props.onDataReceived()
  }

  onSharesUnreadUpdate(unreadCount: number) {
    if (this.state.unreadSharesCount !== unreadCount)
      this.setState({unreadSharesCount: unreadCount})
  }

  inboxUnreadSRText(count: number) {
    return I18n.t(
      {
        one: 'One unread message.',
        other: '%{count} unread messages.',
      },
      {count}
    )
  }

  sharesUnreadSRText(count: number) {
    return I18n.t(
      {
        one: 'One unread share.',
        other: '%{count} unread shares.',
      },
      {count}
    )
  }

  releaseNotesBadgeText(count: number) {
    return I18n.t(
      {
        one: 'One unread release note.',
        other: '%{count} unread release notes.',
      },
      {count}
    )
  }

  setReleaseNotesUnreadPollNow(callback: () => void) {
    if (typeof this.forceUnreadReleaseNotesPoll === 'undefined')
      this.forceUnreadReleaseNotesPoll = callback
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
          themeOverride={{smallWidth: '28em'}}
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
        {ENV.CAN_VIEW_CONTENT_SHARES && ENV.current_user_id && (
          <UnreadComponent
            targetEl={
              this.unreadSharesCountElement ||
              (this.unreadSharesCountElement = document.querySelector(
                '#global_nav_profile_link .menu-item__badge'
              ))
            }
            dataUrl="/api/v1/users/self/content_shares/unread_count"
            onUpdate={(unreadCount: number) => this.onSharesUnreadUpdate(unreadCount)}
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
            onUpdate={(unreadCount: number) => this.onInboxUnreadUpdate(unreadCount)}
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
            pollIntervalMs={RELEASE_NOTES_POLL_INTERVAL}
            pollNowPassback={this.setReleaseNotesUnreadPollNow}
          />
        )}
      </>
    )
  }
}
