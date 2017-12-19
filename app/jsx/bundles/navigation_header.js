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
import I18n from 'i18n!common'
import React from 'react'
import ReactDOM from 'react-dom'
import Navigation from '../navigation_header/Navigation'

// #
// Handle user toggling of nav width
let navCollapsed = window.ENV.SETTINGS && window.ENV.SETTINGS.collapse_global_nav

$('body').on('click', '#primaryNavToggle', function () {
  let primaryNavToggleText
  navCollapsed = !navCollapsed
  if (navCollapsed) {
    $('body').removeClass('primary-nav-expanded')
    $.ajaxJSON('/api/v1/users/self/settings', 'PUT',
        {collapse_global_nav: true})
    primaryNavToggleText = I18n.t('Expand global navigation')
    $(this).attr({title: primaryNavToggleText, 'aria-label': primaryNavToggleText})

    // add .primary-nav-transitions a little late to avoid awkward CSS
    // transitions when the nav is changing states
    setTimeout((() => {
      $('body').addClass('primary-nav-transitions')
    }), 300)
  } else {
    $('body').removeClass('primary-nav-transitions').addClass('primary-nav-expanded')
    $.ajaxJSON('/api/v1/users/self/settings', 'PUT',
        {collapse_global_nav: false})
    primaryNavToggleText = I18n.t('Minimize global navigation')
    $(this).attr({title: primaryNavToggleText, 'aria-label': primaryNavToggleText})
  }
})

ReactDOM.render(<Navigation />, document.getElementById('global_nav_tray_container'))
