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

import _ from 'underscore'
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

/**
 * should be called on page load
 */
const initialize = () => {
  $(resetMenuItemTabIndexes)
  $(window).on('resize', _.debounce(resetMenuItemTabIndexes, 50))
  $('body').on('click', '#courseMenuToggle', toggleCourseNav)
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
    display: $('body').hasClass('course-menu-expanded') ? 'block' : 'none'
  })

  resetMenuItemTabIndexes()
}

export {initialize, toggleCourseNav}
