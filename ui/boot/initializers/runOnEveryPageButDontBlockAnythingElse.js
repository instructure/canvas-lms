/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

// code in this file is stuff that needs to run on every page but that should
// not block anything else from loading. It will be loaded by webpack as an
// async chunk so it will always be loaded eventually, but not necessarily before
// any other js_bundle code runs. and by moving it into an async chunk,
// the critical code to display a page will be executed sooner

import _ from 'underscore'
import $ from 'jquery'
import updateSubnavMenuToggle from './updateSubnavMenuToggle.js'
import preventDefault from 'prevent-default'

// modules that do their own thing on every page that simply need to be required
import '@canvas/media-comments'
import './activateReminderControls.js'
import '../../features/navigation_header/jquery/instructure'
import '@canvas/authenticity-token'
import './ujsLinks.js'
import './expandAdminLinkMenusOnClick.js'
import './activateElementToggler.js'
import './toggleICSuperToggleWidgetsOnEnterKeyEvent.js'
import './loadInlineMediaComments.js'
import './ping.js'
import './markBrokenImages.js'
import './activateLtiThumbnailLauncher.js'
import './sanitizeCSSOverflow.js'

if (ENV.page_view_update_url) import('./trackPageViews.js')

// preventDefault so we dont change the hash
// this will make nested apps that use the hash happy
$('#skip_navigation_link').on(
  'click',
  preventDefault(function() {
    $($(this).attr('href'))
      .attr('tabindex', -1)
      .focus()
  })
)

// show and hide the courses vertical menu when the user clicks the hamburger button
// This was in the courses bundle, but it sometimes needs to work in places that don't
// load that bundle.
const WIDE_BREAKPOINT = 1200

function resetMenuItemTabIndexes() {
  const $sectionTabLinks = $('#section-tabs li a')
  if ($sectionTabLinks.length) {
    // in testing this, it seems that $(document).width() returns 15px less than what it should.
    const tabIndex =
      $('body').hasClass('course-menu-expanded') || $(document).width() >= WIDE_BREAKPOINT - 15
        ? 0
        : -1
    $sectionTabLinks.attr('tabIndex', tabIndex)
  }
}

$(resetMenuItemTabIndexes)
$(window).on('resize', _.debounce(resetMenuItemTabIndexes, 50))
$('body').on('click', '#courseMenuToggle', () => {
  $('body').toggleClass('course-menu-expanded')
  updateSubnavMenuToggle()
  $('#left-side').css({
    display: $('body').hasClass('course-menu-expanded') ? 'block' : 'none'
  })

  resetMenuItemTabIndexes()
})
