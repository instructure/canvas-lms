/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import addAriaDescription from '../quiz_labels'

describe('Add aria descriptions', () => {
  let $elem

  beforeEach(() => {
    // Setup the DOM element
    document.body.innerHTML = '<div id="fixtures"></div>'
    $elem = $(
      `<div>
        <input type="text" />
        <div class="deleteAnswerId"></div>
        <div class="editAnswerId"></div>
        <div class="commentAnswerId"></div>
        <div class="selectAsCorrectAnswerId"></div>
      </div>`
    )
    $('#fixtures').append($elem)
  })

  afterEach(() => {
    // Clean up the DOM
    $('#fixtures').empty()
  })

  test('add aria descriptions to quiz answer options', () => {
    addAriaDescription($elem, '1')
    expect($elem.find('input[type="text"]').attr('aria-describedby')).toBe('answer1')
    expect($elem.find('.deleteAnswerId').text()).toBe('Answer 1')
    expect($elem.find('.editAnswerId').text()).toBe('Answer 1')
    expect($elem.find('.commentAnswerId').text()).toBe('Answer 1')
    expect($elem.find('.selectAsCorrectAnswerId').text()).toBe('Answer 1')
  })
})
