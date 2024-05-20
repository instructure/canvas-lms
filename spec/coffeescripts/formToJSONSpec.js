/*
 * Copyright (C) 2012 - present Instructure, Inc.
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
import 'jquery-migrate'
import '@canvas/jquery/jquery.toJSON'

// TODO: share code with 'unflatten' module

const $datepickerEl = () => $(`<input type='text' name='date' class='datetime_field_enabled'/>`)

QUnit.module('jquery.toJSON', {
  setup() {
    this.form = $('<form/>').html(`
      <input type="text" name="foo"               value="foo">
      <input type="text" name="arr[]"             value="1">
      <input type="text" name="arr[]"             value="2">
      <input type="text" name="nested[foo]"       value="nested[foo]">
      <input type="text" name="nested[bar]"       value="nested[bar]">
      <input type="text" name="nested[baz][qux]"  value="nested[baz][qux]">
      <input type="text" name="nested[arr][]"     value="1">
      <input type="text" name="nested[arr][]"     value="2">
    `)
  },
})

test('serializes to a JSON string correctly', function () {
  const expected = {
    foo: 'foo',
    arr: ['1', '2'],
    nested: {
      foo: 'nested[foo]',
      bar: 'nested[bar]',
      baz: {
        qux: 'nested[baz][qux]',
      },
      arr: ['1', '2'],
    },
  }
  equal(JSON.stringify(expected), JSON.stringify(this.form))
})

test(`returns null if element with datetime_field enabled class has undefined for $.data( 'date' )`, function () {
  this.form.prepend($datepickerEl())
  strictEqual(this.form.toJSON().date, null)
})

test('returns date object for form element with datetime_field_enabled', function () {
  const $dateEl = $datepickerEl()
  this.form.prepend($dateEl)
  const date = Date.now()
  $dateEl.data('date', date)
  $dateEl.val(date)
  strictEqual(this.form.toJSON().date, date)
})
