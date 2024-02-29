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
import '@canvas/jquery/jquery.simulate'

QUnit.module('Autocomplete Widget', {
  beforeEach() {
    this.$input = $('<input id="autocomplete-input">').appendTo('#fixtures')
    this.availableTags = ['apple', 'banana', 'cherry']
    this.$input.autocomplete({
      source: this.availableTags,
    })
  },
  afterEach() {
    this.$input.autocomplete('destroy')
    this.$input.remove()
    $('#fixtures').empty()
  },
})

QUnit.test('Autocomplete widget is initialized', function (assert) {
  assert.ok(this.$input.data('ui-autocomplete'), 'Autocomplete widget is initialized')
})

QUnit.test('Autocomplete suggests available tags', function (assert) {
  const done = assert.async()
  const input = this.$input

  input.val('a').trigger('input')
  setTimeout(function () {
    const menuItems = $('.ui-autocomplete li')
    assert.equal(menuItems.length, 2, 'Two suggestions are displayed for input "a"')
    done()
  }, 300)
})
