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

import _ from 'underscore'
import $ from 'jquery'
import I18n from 'i18n!new_nav'
import React from 'react'
import Tray from '@instructure/ui-overlays/lib/components/Tray'
import CloseButton from '@instructure/ui-buttons/lib/components/CloseButton'
import CoursesTray from './trays/CoursesTray'
import GroupsTray from './trays/GroupsTray'
import AccountsTray from './trays/AccountsTray'
import ProfileTray from './trays/ProfileTray'
import HelpTray from './trays/HelpTray'
import preventDefault from 'compiled/fn/preventDefault'
import parseLinkHeader from 'compiled/fn/parseLinkHeader'

const EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/
const ACTIVE_ROUTE_REGEX = /^\/(courses|groups|accounts|grades|calendar|conversations|profile)/
const ACTIVE_CLASS = 'ic-app-header__menu-list-item--active'

const UNREAD_COUNT_POLL_INTERVAL = 60000 // 60 seconds

const TYPE_URL_MAP = {
  courses: '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments',
  groups: '/api/v1/users/self/groups?include[]=can_access',
  accounts: '/api/v1/accounts',
  help: '/help_links'
}

const TYPE_FILTER_MAP = {
  groups: group => group.can_access && !group.concluded
}

const RESOURCE_COUNT = 10

export default class Navigation extends React.Component {
  state = {
    groups: [],
    accounts: [],
    courses: [],
    help: [],
    unread_count: 0,
    unread_count_attempts: 0,
    isTrayOpen: false,
    type: null,
    coursesLoading: false,
    coursesAreLoaded: false,
    accountsLoading: false,
    accountsAreLoaded: false,
    groupsLoading: false,
    groupsAreLoaded: false,
    helpLoading: false,
    helpAreLoaded: false
  }

  componentWillMount() {
    /**
     * Mount up stuff to our existing DOM elements, yes, it's not very
     * React-y, but it is workable and maintainable, plus it doesn't require
     * us to trash what Rails has already rendered.
     */

    // ////////////////////////////////
    // / Hover Events
    // ////////////////////////////////

    _.forEach(TYPE_URL_MAP, (url, type) => {
      $(`#global_nav_${type}_link`).one('mouseover', () => {
        this.getResource(url, type)
      })
    })

    // ////////////////////////////////
    // / Click Events
    // ////////////////////////////////
    ;['courses', 'groups', 'accounts', 'profile', 'help'].forEach(type => {
      $(`#global_nav_${type}_link`).on(
        'click',
        preventDefault(this.handleMenuClick.bind(this, type))
      )
    })

    // give the trays that slide out from the the nav bar
    // a place to mount. It has to be outside the <div id=application>
    // to aria-hide everything but the tray when open.
    let portal = document.getElementById('nav-tray-portal')
    if (!portal) {
      portal = document.createElement('div')
      portal.id = 'nav-tray-portal'
      // the <header> has z-index: 100. This has to be behind it,
      portal.setAttribute('style', 'position: relative; z-index: 99;')
      document.body.appendChild(portal)
    }
  }

  componentDidMount() {
    if (
      !this.state.unread_count_attempts &&
      window.ENV.current_user_id &&
      !window.ENV.current_user_disabled_inbox &&
      this.unreadCountElement().length &&
      !(window.ENV.current_user && window.ENV.current_user.fake_student)
    ) {
      this.pollUnreadCount()
    }
  }

  componentWillUpdate(newProps, newState) {
    if (newState.activeItem !== this.state.activeItem) {
      $(`.${ACTIVE_CLASS}`).removeClass(ACTIVE_CLASS)
      $(`#global_nav_${newState.activeItem}_link`)
        .closest('li')
        .addClass(ACTIVE_CLASS)
    }
  }

  /**
   * Given a URL and a type value, it gets the data and updates state.
   */
  getResource(url, type) {
    this.setState({[`${type}Loading`]: true})
    this.loadResourcePage(url, type)
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
      this.setState({
        [type]: newData,
        [`${type}Loading`]: false,
        [`${type}AreLoaded`]: true
      })
    })
  }

  filterDataForType(data, type) {
    const filterFunc = TYPE_FILTER_MAP[type]
    if (typeof filterFunc === 'function') {
      return data.filter(filterFunc)
    }
    return data
  }

  pollUnreadCount() {
    this.setState({unread_count_attempts: this.state.unread_count_attempts + 1}, function() {
      if (this.state.unread_count_attempts <= 5) {
        $.ajax('/api/v1/conversations/unread_count')
          .then(data => this.updateUnreadCount(data.unread_count))
          .then(null, console.log.bind(console, 'something went wrong updating unread count'))
          .always(() =>
            setTimeout(
              () => this.pollUnreadCount(),
              this.state.unread_count_attempts * UNREAD_COUNT_POLL_INTERVAL
            )
          )
      }
    })
  }

  unreadCountElement() {
    return (
      this.$unreadCount ||
      (this.$unreadCount = $('#global_nav_conversations_link').find('.menu-item__badge'))
    )
  }

  updateUnreadCount(count) {
    count = parseInt(count, 10)
    this.unreadCountElement().text(I18n.n(count))
    this.unreadCountElement().toggle(count > 0)
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
    if (TYPE_URL_MAP[type] && !this.state[`${type}AreLoaded`] && !this.state[`${type}Loading`]) {
      this.getResource(TYPE_URL_MAP[type], type)
    }

    if (this.state.isTrayOpen && this.state.activeItem === type) {
      this.closeTray()
    } else if (this.state.isTrayOpen && this.state.activeItem !== type) {
      this.openTray(type)
    } else {
      this.openTray(type)
    }
  }

  openTray(type) {
    this.setState({type, isTrayOpen: true, activeItem: type})
  }

  closeTray = () => {
    this.determineActiveLink()
    this.setState({isTrayOpen: false}, () => {
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
            courses={this.state.courses}
            hasLoaded={this.state.coursesAreLoaded}
            closeTray={this.closeTray}
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
            userAvatarURL={
              window.ENV.current_user.avatar_is_fallback
                ? null
                : window.ENV.current_user.avatar_image_url
            }
            profileEnabled={window.ENV.SETTINGS.enable_profiles}
            eportfoliosEnabled={window.ENV.SETTINGS.eportfolios_enabled}
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
          />
        )
      default:
        return null
    }
  }

  getTrayLabel() {
    switch (this.state.type) {
      case "courses":
        return I18n.t("Courses tray");
      case "groups":
        return I18n.t("Groups tray");
      case "accounts":
        return I18n.t("Admin tray");
      case "profile":
        return I18n.t("Profile tray");
      case "help":
        return I18n.t("%{title} tray", { title: window.ENV.help_link_name });
      default:
        return I18n.t("Global navigation tray");
    }
  }

  render() {
    return (
      <Tray
        label={this.getTrayLabel()}
        size="small"
        open={this.state.isTrayOpen}
        onDismiss={this.closeTray}
        shouldCloseOnDocumentClick
        mountNode={document.getElementById('nav-tray-portal')}
        theme={{smallWidth: '28em'}}
      >
        <CloseButton placement="end" onClick={this.closeTray}>
          {I18n.t('Close')}
        </CloseButton>
        <div className="tray-with-space-for-global-nav">{this.renderTrayContent()}</div>
      </Tray>
    )
  }
}
