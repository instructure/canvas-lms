/*
 * Copyright (C) 2024 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import 'jqueryui/autocomplete'
import '../jquery.simulate'

describe('Autocomplete Widget', () => {
  let $input
  const availableTags = ['apple', 'banana', 'cherry']

  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    $input = $('<input id="autocomplete-input">').appendTo('#fixtures')
    $input.autocomplete({
      source: availableTags,
    })
  })

  afterEach(() => {
    $input.autocomplete('destroy')
    $input.remove()
    $('#fixtures').empty()
  })

  test.skip('Autocomplete widget is initialized', () => {
    expect($input.data('ui-autocomplete')).toBeTruthy()
  })

  test.skip('Autocomplete suggests available tags', done => {
    const input = $input

    input.val('a').trigger('input')

    setTimeout(() => {
      const menuItems = $('.ui-autocomplete li')
      expect(menuItems.length).toBe(2)
      done()
    }, 300)
  })
})
