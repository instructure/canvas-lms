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
import tourPubSub from '@canvas/tour-pubsub'
import {getTrayLabel} from './utils'

const I18n = useI18nScope('Navigation')

// We don't need to poll for new release notes very often since we expect
// new ones to appear only infrequently. The act of viewing them will reset
// the badge at the time of viewing.
const RELEASE_NOTES_POLL_INTERVAL = 60 * 60 * 1000 // one hour

const CoursesTray = React.lazy(() => import('./trays/CoursesTray'))
const GroupsTray = React.lazy(() => import('./trays/GroupsTray'))
const AccountsTray = React.lazy(() => import('./trays/AccountsTray'))
const ProfileTray = React.lazy(() => import('./trays/ProfileTray'))
const HistoryTray = React.lazy(() => import('./trays/HistoryTray'))
const HelpTray = React.lazy(() => import('./trays/HelpTray'))

const EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/
const ACTIVE_ROUTE_REGEX =
  /^\/(courses|groups|accounts|grades|calendar|conversations|profile)|^#history/
const ACTIVE_CLASS = 'ic-app-header__menu-list-item--active'

type ActiveItem = 'dashboard' | 'accounts' | 'courses' | 'groups' | 'profile' | 'history' | 'help'

const itemsWithResources = ['courses', 'groups', 'accounts', 'profile', 'history', 'help'] as const

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
  activeItem: ActiveItem
  isTrayOpen: boolean
  noFocus: boolean
  overrideDismiss: boolean
  releaseNotesBadgeDisabled: boolean
  type: ActiveItem | null
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
      activeItem: 'dashboard',
      isTrayOpen: false,
      noFocus: false,
      overrideDismiss: false,
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
          label={getTrayLabel(this.state.type)}
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
                {this.state.type === 'courses' && <CoursesTray />}
                {this.state.type === 'groups' && <GroupsTray />}
                {this.state.type === 'accounts' && <AccountsTray />}
                {this.state.type === 'profile' && (
                  <ProfileTray counts={{unreadShares: this.state.unreadSharesCount}} />
                )}
                {this.state.type === 'history' && <HistoryTray />}
                {this.state.type === 'help' && <HelpTray closeTray={this.closeTray} />}
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
            srText={(count: number) =>
              I18n.t(
                {
                  one: 'One unread share.',
                  other: '%{count} unread shares.',
                },
                {count}
              )
            }
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
            srText={(count: number) =>
              I18n.t(
                {
                  one: 'One unread message.',
                  other: '%{count} unread messages.',
                },
                {count}
              )
            }
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
            srText={(count: number) =>
              I18n.t(
                {
                  one: 'One unread release note.',
                  other: '%{count} unread release notes.',
                },
                {count}
              )
            }
            pollIntervalMs={RELEASE_NOTES_POLL_INTERVAL}
            pollNowPassback={this.setReleaseNotesUnreadPollNow}
          />
        )}
      </>
    )
  }
}
