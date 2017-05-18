/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

define([
  'jquery',
  'jsx/subnav_menu/updateSubnavMenuToggle'
], ($, updateSubnavMenuToggle) => {
  const container = $('#fixtures')

  QUnit.module('SubnavMenuToggle', {
    setup () {
      $('<button/>', {
        id: 'courseMenuToggle',
        className: 'Button Button--link Button--small ic-app-course-nav-toggle',
        title: 'Hide Navigation Menu',
        ariaLabel: 'Hide Navigation Menu',
        ariaLive: 'polite'
      }).appendTo(container)
    },
    teardown () {
      container.empty()
    }
  })

  test('it should toggle the title and aria-label text correctly for show and hide on click', function () {
    const subnavMenuToggle = $('#courseMenuToggle')
    subnavMenuToggle.click(() => {
      $('body').toggleClass('course-menu-expanded')
      updateSubnavMenuToggle()
    })

    subnavMenuToggle.click()
    equal(subnavMenuToggle.attr('title'), 'Hide Navigation Menu')
    equal(subnavMenuToggle.attr('aria-label'), 'Hide Navigation Menu')

    subnavMenuToggle.click()
    equal(subnavMenuToggle.attr('title'), 'Show Navigation Menu')
    equal(subnavMenuToggle.attr('aria-label'), 'Show Navigation Menu')
  })

  test('it should correctly generate title and aria-label text based on the pathname', function () {
    const subnavMenuToggle = $('#courseMenuToggle')

    subnavMenuToggle.click(updateSubnavMenuToggle('/profile/communication'))
    subnavMenuToggle.click()
    equal(subnavMenuToggle.attr('title'), 'Show Account Navigation Menu')
    equal(subnavMenuToggle.attr('aria-label'), 'Show Account Navigation Menu')
    subnavMenuToggle.unbind()

    subnavMenuToggle.click(updateSubnavMenuToggle('/accounts/1/permissions'))
    subnavMenuToggle.click()
    equal(subnavMenuToggle.attr('title'), 'Show Admin Navigation Menu')
    equal(subnavMenuToggle.attr('aria-label'), 'Show Admin Navigation Menu')
    subnavMenuToggle.unbind()

    subnavMenuToggle.click(updateSubnavMenuToggle('/courses/2/users'))
    subnavMenuToggle.click()
    equal(subnavMenuToggle.attr('title'), 'Show Courses Navigation Menu')
    equal(subnavMenuToggle.attr('aria-label'), 'Show Courses Navigation Menu')
    subnavMenuToggle.unbind()

    subnavMenuToggle.click(updateSubnavMenuToggle('/groups/1'))
    subnavMenuToggle.click()
    equal(subnavMenuToggle.attr('title'), 'Show Groups Navigation Menu')
    equal(subnavMenuToggle.attr('aria-label'), 'Show Groups Navigation Menu')
  })
})
