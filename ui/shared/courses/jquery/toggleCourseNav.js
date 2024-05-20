/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {debounce} from 'lodash'
import $ from 'jquery'
import updateSubnavMenuToggle from './updateSubnavMenuToggle'

const WIDE_BREAKPOINT = 1200

const resetMenuItemTabIndexes = () => {
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
const resizeStickyFrame = () => {
  const $stickyFrame = $('#left-side #sticky-container')
  const menuPaddingBottom = parseInt($stickyFrame.css('padding-bottom'), 10)
  const menuPaddingTop = parseInt($stickyFrame.css('padding-top'), 10)
  const menuHeight = $stickyFrame.get(0).scrollHeight - menuPaddingBottom - menuPaddingTop
  if (menuHeight > $stickyFrame.height()) {
    $stickyFrame.addClass('has-scrollbar')
  } else {
    $stickyFrame.removeClass('has-scrollbar')
  }
}

const saveCourseNavCollapseState = () => {
  const menuExpanded = $('body').hasClass('course-menu-expanded')
  $.ajaxJSON('/api/v1/users/self/settings', 'PUT', {collapse_course_nav: !menuExpanded})
}

/**
 * should be called on page load
 */
const initialize = () => {
  const $stickyFrame = $('#left-side #sticky-container').get(0)
  if ($stickyFrame) {
    $(resizeStickyFrame)
    $(window).on('resize', debounce(resizeStickyFrame, 20))
  }
  $(resetMenuItemTabIndexes)
  $(window).on('resize', debounce(resetMenuItemTabIndexes, 50))
  $('body').on(
    'click',
    '#courseMenuToggle',
    $stickyFrame
      ? () => {
          toggleCourseNav()
          resizeStickyFrame()
          saveCourseNavCollapseState()
        }
      : () => {
          toggleCourseNav()
          saveCourseNavCollapseState()
        }
  )
}

/**
 * toggles the course navigation menu
 *
 * exported separately for usage other than the initialize call on page load
 */
const toggleCourseNav = () => {
  $('body').toggleClass('course-menu-expanded')
  updateSubnavMenuToggle()
  $('#left-side').css({
    display: $('body').hasClass('course-menu-expanded') ? 'block' : 'none',
  })

  resetMenuItemTabIndexes()
}

export {initialize, toggleCourseNav}
