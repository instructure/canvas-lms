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
import React, {useEffect, useState, useCallback} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tray} from '@instructure/ui-tray'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import tourPubSub from '@canvas/tour-pubsub'
import {getTrayLabel, getTrayPortal} from './utils'
import useHoverIntent from './hooks/useHoverIntent'
import coursesQuery from './queries/coursesQuery'
import accountsQuery from './queries/accountsQuery'
import groupsQuery from './queries/groupsQuery'
import NavigationBadges from './NavigationBadges'
import {prefetchQuery} from '@canvas/query'
import profileQuery from './queries/profileQuery'

const I18n = useI18nScope('Navigation')

const CoursesTray = React.lazy(() => import('./trays/CoursesTray'))
const GroupsTray = React.lazy(() => import('./trays/GroupsTray'))
const AccountsTray = React.lazy(() => import('./trays/AccountsTray'))
const ProfileTray = React.lazy(() => import('./trays/ProfileTray'))
const HistoryTray = React.lazy(() => import('./trays/HistoryTray'))
const HelpTray = React.lazy(() => import('./trays/HelpTray'))

const accountsNavLink = document.querySelector(`#global_nav_accounts_link`)
const coursesNavLink = document.querySelector(`#global_nav_courses_link`)
const groupsNavLink = document.querySelector(`#global_nav_groups_link`)
const profileNavLink = document.querySelector(`#global_nav_profile_link`)
// const helpNavLink = document.querySelector(`#global_nav_help_link`)

const EXTERNAL_TOOLS_REGEX = /^\/accounts\/[^\/]*\/(external_tools)/
const ACTIVE_ROUTE_REGEX =
  /^\/(courses|groups|accounts|grades|calendar|conversations|profile)|^#history|(passport$)/
// learning_passport is a temporary flag for a prototpye
const LEARNER_PASSPORT_REGEX = ENV.FEATURES.learner_passport ? /\/users\/\d+\/passport/ : null
const ACTIVE_CLASS = 'ic-app-header__menu-list-item--active'

type ActiveItem =
  | 'dashboard'
  | 'accounts'
  | 'courses'
  | 'groups'
  | 'profile'
  | 'history'
  | 'help'
  | 'passport'
  | null

const itemsWithResources = ['courses', 'groups', 'accounts', 'profile', 'history', 'help'] as const

function noop() {}

function handleActiveItem() {
  const path = window.location.pathname
  const matchData = path.match(EXTERNAL_TOOLS_REGEX) || path.match(ACTIVE_ROUTE_REGEX)
  return path === '/' && !matchData ? 'dashboard' : ((matchData && matchData[1]) as ActiveItem)
}

const Navigation = () => {
  const [activeItem, setActiveItem] = useState<ActiveItem | null>(handleActiveItem)
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const [noFocus, setNoFocus] = useState(false)
  const [overrideDismiss, setOverrideDismiss] = useState(false)
  const [type, setType] = useState<ActiveItem | null>(activeItem)

  useEffect(() => {
    if (!isTrayOpen) {
      // when tray is closed, set active item based on current path
      const path = window.location.pathname
      if (LEARNER_PASSPORT_REGEX && path.match(LEARNER_PASSPORT_REGEX)) {
        setActiveItem('passport')
      } else {
        setActiveItem(handleActiveItem())
      }
    }
  }, [isTrayOpen])

  useHoverIntent(profileNavLink, () => {
    import('./trays/ProfileTray')
    prefetchQuery(['profile'], profileQuery)
  })

  useHoverIntent(coursesNavLink, () => {
    import('./trays/CoursesTray')
    prefetchQuery(['courses'], coursesQuery)
  })

  useHoverIntent(accountsNavLink, () => {
    import('./trays/AccountsTray')
    prefetchQuery(['accounts'], accountsQuery)
  })

  useHoverIntent(groupsNavLink, () => {
    import('./trays/GroupsTray')
    prefetchQuery(['groups'], groupsQuery)
  })

  useEffect(() => {
    $(`.${ACTIVE_CLASS}`).removeClass(ACTIVE_CLASS).removeAttr('aria-current')
    $(`#global_nav_${activeItem}_link`)
      .closest('li')
      .addClass(ACTIVE_CLASS)
      .attr('aria-current', 'page')
  }, [activeItem])

  const openTray = useCallback((type_: ActiveItem, focus: boolean = false) => {
    setType(type_)
    setNoFocus(focus)
    setIsTrayOpen(true)
    setActiveItem(type_)
  }, [])

  const closeTray = useCallback(() => {
    setIsTrayOpen(false)
    setNoFocus(false)
    setTimeout(() => setType(null), 150)
  }, [])

  const handleMenuClick = useCallback(
    (type_: ActiveItem) => {
      if (isTrayOpen && activeItem === type_) {
        closeTray()
      } else if (isTrayOpen && activeItem !== type_) {
        openTray(type_)
      } else {
        openTray(type_)
      }
    },
    [activeItem, closeTray, isTrayOpen, openTray]
  )

  useEffect(() => {
    itemsWithResources.forEach(type_ => {
      $(`#global_nav_${type_}_link`).on('click', (event: Event) => {
        event.preventDefault()
        handleMenuClick(type_)
      })
    })

    return () => {
      itemsWithResources.forEach(type_ => {
        $(`#global_nav_${type_}_link`).off('click')
      })
    }
  }, [handleMenuClick])

  /*
  begin student tour code
  */
  useEffect(() => {
    const openPublishUnsubscribe = tourPubSub.subscribe<{
      type: ActiveItem
      noFocus: boolean
    }>('navigation-tray-open', ({type: type_, noFocus: noFocus_}) => {
      openTray(type_, noFocus_)
      if (isTrayOpen && type_ === type) {
        tourPubSub.publish('navigation-tray-opened', type_)
      }
    })

    const closePublishUnsubscribe = tourPubSub.subscribe('navigation-tray-close', closeTray)

    const overrideDismissUnsubscribe = tourPubSub.subscribe(
      'navigation-tray-override-dismiss',
      tf => setOverrideDismiss(Boolean(tf))
    )

    return () => {
      openPublishUnsubscribe()
      overrideDismissUnsubscribe()
      closePublishUnsubscribe()
    }
  }, [isTrayOpen, type, closeTray, openTray])
  /*
  end student tour code
  */

  return (
    <>
      <Tray
        key={type}
        label={getTrayLabel(type)}
        size="small"
        open={isTrayOpen}
        // We need to override closing trays
        // so the tour can properly go through them
        // without them unexpectedly closing.
        onDismiss={overrideDismiss ? noop : closeTray}
        shouldCloseOnDocumentClick={true}
        shouldContainFocus={!noFocus}
        mountNode={getTrayPortal()}
        themeOverride={{smallWidth: '28em'}}
        onEntered={() => {
          tourPubSub.publish('navigation-tray-opened', type)
        }}
      >
        <div className={`navigation-tray-container ${type}-tray`}>
          <CloseButton placement="end" onClick={closeTray} screenReaderLabel={I18n.t('Close')} />
          <div className="tray-with-space-for-global-nav">
            <React.Suspense
              fallback={
                <View display="block" textAlign="center">
                  <Spinner size="large" margin="large auto" renderTitle={() => I18n.t('Loading')} />
                </View>
              }
            >
              {type === 'courses' && <CoursesTray />}
              {type === 'groups' && <GroupsTray />}
              {type === 'accounts' && <AccountsTray />}
              {type === 'profile' && <ProfileTray />}
              {type === 'history' && <HistoryTray />}
              {type === 'help' && <HelpTray closeTray={closeTray} />}
            </React.Suspense>
          </div>
        </div>
      </Tray>
      <NavigationBadges />
    </>
  )
}

export default Navigation
