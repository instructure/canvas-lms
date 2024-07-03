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

import $ from 'jquery'
import updateSubnavMenuToggle from '../updateSubnavMenuToggle'

const container = $('<div id="fixtures"></div>')
$('body').append(container)

describe('SubnavMenuToggle', () => {
  beforeEach(() => {
    $('<button/>', {
      id: 'courseMenuToggle',
      className: 'Button Button--link Button--small ic-app-course-nav-toggle',
      ariaLabel: 'Hide Navigation Menu',
      ariaLive: 'polite',
    }).appendTo(container)
  })

  afterEach(() => {
    container.empty()
  })

  test.skip('it should toggle the aria-label text correctly for show and hide on click', () => {
    const subnavMenuToggle = $('#courseMenuToggle')
    subnavMenuToggle.click(() => {
      $('body').toggleClass('course-menu-expanded')
      updateSubnavMenuToggle()
    })

    subnavMenuToggle.click()
    expect(subnavMenuToggle.attr('aria-label')).toBe('Hide Navigation Menu')

    subnavMenuToggle.click()
    expect(subnavMenuToggle.attr('aria-label')).toBe('Show Navigation Menu')
  })

  test.skip('it should correctly generate title and aria-label text based on the pathname', () => {
    const subnavMenuToggle = $('#courseMenuToggle')

    subnavMenuToggle.click(updateSubnavMenuToggle('/profile/communication'))
    subnavMenuToggle.click()
    expect(subnavMenuToggle.attr('aria-label')).toBe('Show Account Navigation Menu')
    subnavMenuToggle.off()

    subnavMenuToggle.click(updateSubnavMenuToggle('/accounts/1/permissions'))
    subnavMenuToggle.click()
    expect(subnavMenuToggle.attr('aria-label')).toBe('Show Admin Navigation Menu')
    subnavMenuToggle.off()

    subnavMenuToggle.click(updateSubnavMenuToggle('/courses/2/users'))
    subnavMenuToggle.click()
    expect(subnavMenuToggle.attr('aria-label')).toBe('Show Courses Navigation Menu')
    subnavMenuToggle.off()

    subnavMenuToggle.click(updateSubnavMenuToggle('/groups/1'))
    subnavMenuToggle.click()
    expect(subnavMenuToggle.attr('aria-label')).toBe('Show Groups Navigation Menu')
  })
})
