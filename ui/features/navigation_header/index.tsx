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
import ReactDOM from 'react-dom'
import Navigation from './react/OldSideNav'
import MobileNavigation from './react/MobileNavigation'
import ready from '@instructure/ready'
import NewTabIndicator from './react/NewTabIndicator'

const I18n = useI18nScope('common')

// #
// Handle user toggling of nav width
let navCollapsed = window.ENV.SETTINGS && window.ENV.SETTINGS.collapse_global_nav

$('body').on('click', '#primaryNavToggle', function () {
  let primaryNavToggleText
  navCollapsed = !navCollapsed
  if (navCollapsed) {
    $('body').removeClass('primary-nav-expanded')
    $.ajaxJSON('/api/v1/users/self/settings', 'PUT', {collapse_global_nav: true})
    primaryNavToggleText = I18n.t('Expand global navigation')
    $(this).attr({title: primaryNavToggleText, 'aria-label': primaryNavToggleText})

    // add .primary-nav-transitions a little late to avoid awkward CSS
    // transitions when the nav is changing states
    setTimeout(() => {
      $('body').addClass('primary-nav-transitions')
    }, 300)
  } else {
    $('body').removeClass('primary-nav-transitions').addClass('primary-nav-expanded')
    $.ajaxJSON('/api/v1/users/self/settings', 'PUT', {collapse_global_nav: false})
    primaryNavToggleText = I18n.t('Minimize global navigation')
    $(this).attr({title: primaryNavToggleText, 'aria-label': primaryNavToggleText})
  }
})

ready(() => {
  const globalNavTrayContainer = document.getElementById('global_nav_tray_container')
  if (globalNavTrayContainer) {
    const DesktopNavComponent = React.createRef()
    const mobileNavComponent = React.createRef()

    ReactDOM.render(
      <Navigation
        // @ts-expect-error
        ref={DesktopNavComponent}
        // @ts-expect-error
        onDataReceived={() => mobileNavComponent.current?.forceUpdate()}
      />,
      globalNavTrayContainer,
      () => {
        const mobileContextNavContainer = document.getElementById('mobileContextNavContainer')
        if (mobileContextNavContainer) {
          ReactDOM.render(
            <MobileNavigation
              ref={mobileNavComponent}
              // @ts-expect-error
              DesktopNavComponent={DesktopNavComponent.current}
            />,
            mobileContextNavContainer
          )
        }
      }
    )
  }

  const newTabContainers = document.getElementsByClassName('new-tab-indicator')
  Array.from(newTabContainers).forEach(newTabContainer => {
    if (newTabContainer instanceof HTMLElement && newTabContainer.dataset.tabname) {
      ReactDOM.render(
        <NewTabIndicator tabName={newTabContainer.dataset.tabname} />,
        newTabContainer
      )
    }
  })
})
