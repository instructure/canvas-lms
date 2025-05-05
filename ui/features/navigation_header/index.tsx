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
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {createRoot} from 'react-dom/client' // Updated import
import SideNav from './react/SideNav'
import Navigation from './react/OldSideNav'
import MobileNavigation from './react/MobileNavigation'
import ready from '@instructure/ready'
import NewTabIndicator from './react/NewTabIndicator'
import {QueryClientProvider} from '@tanstack/react-query'
import {getExternalTools} from './react/utils'
import AlertManager from '@canvas/alerts/react/AlertManager'
import {queryClient} from '@canvas/query'

const I18n = createI18nScope('common')

// #
// Handle user toggling of nav width
let navCollapsed = Boolean(window.ENV.SETTINGS?.collapse_global_nav)
let globalNavIsOpen = Boolean(false)

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

if (window.ENV.FEATURES.instui_nav || localStorage.instui_nav_dev) {
  const mobileHeaderHamburger = document.getElementsByClassName('mobile-header-hamburger')
  if (mobileHeaderHamburger.length > 0) {
    mobileHeaderHamburger[0].addEventListener('touchstart', event => {
      event.preventDefault()
      globalNavIsOpen = !globalNavIsOpen
    })
    mobileHeaderHamburger[0].addEventListener('click', event => {
      event.preventDefault()
      globalNavIsOpen = !globalNavIsOpen
    })
  }
}

ready(() => {
  const showInstUiNavbar = window.ENV.FEATURES.instui_nav || localStorage.instui_nav_dev
  if (showInstUiNavbar) {
    const mobileContextNavContainer = document.getElementById('mobileContextNavContainer')
    if (mobileContextNavContainer) {
      const sideNavRoot = createRoot(mobileContextNavContainer)
      sideNavRoot.render(
        <QueryClientProvider client={queryClient}>
          <SideNav externalTools={getExternalTools()} />
        </QueryClientProvider>,
      )

      // Render MobileNavigation after SideNav
      const mobileNavRoot = createRoot(mobileContextNavContainer)
      mobileNavRoot.render(
        <QueryClientProvider client={queryClient}>
          <AlertManager breakpoints={{}}>
            <MobileNavigation navIsOpen={globalNavIsOpen} />
          </AlertManager>
        </QueryClientProvider>,
      )
    }
  } else {
    const globalNavTrayContainer = document.getElementById('global_nav_tray_container')
    if (globalNavTrayContainer) {
      const navigationRoot = createRoot(globalNavTrayContainer)
      navigationRoot.render(
        <QueryClientProvider client={queryClient}>
          <Navigation />
        </QueryClientProvider>,
      )

      const mobileContextNavContainer = document.getElementById('mobileContextNavContainer')
      if (mobileContextNavContainer) {
        const mobileNavRoot = createRoot(mobileContextNavContainer)
        mobileNavRoot.render(
          <QueryClientProvider client={queryClient}>
            <AlertManager breakpoints={{}}>
              <MobileNavigation />
            </AlertManager>
          </QueryClientProvider>,
        )
      }
    }
  }

  // Each element in the side bar menu can be triggered by enter and space.
  const navLinksSelector = showInstUiNavbar ? '#instui-sidenav > ul > li > a' : '#menu > li > a'
  const navLinks = document.querySelectorAll<HTMLAnchorElement>(navLinksSelector)
  navLinks.forEach(link => {
    link.addEventListener('keydown', (event: KeyboardEvent) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault()
        link.click()
      }
    })
  })

  const newTabContainers = document.getElementsByClassName('new-tab-indicator')
  Array.from(newTabContainers).forEach(newTabContainer => {
    if (newTabContainer instanceof HTMLElement && newTabContainer.dataset.tabname) {
      const newTabRoot = createRoot(newTabContainer)
      newTabRoot.render(<NewTabIndicator tabName={newTabContainer.dataset.tabname} />)
    }
  })
})
