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
import 'jqueryui/progressbar'

QUnit.module('Progressbar Widget', {
  beforeEach() {
    $('#fixtures').append('<div id="progressbar"></div>')
    $('#progressbar').progressbar()
  },
  afterEach() {
    $('#fixtures').empty()
  },
})

QUnit.test('Check initial value', function (assert) {
  const $progressbar = $('#progressbar')
  const initialValue = $progressbar.progressbar('value')
  assert.equal(initialValue, 0, 'Initial value is 0')
})

QUnit.test('Set and check value', function (assert) {
  const $progressbar = $('#progressbar')
  $progressbar.progressbar('value', 50)
  const updatedValue = $progressbar.progressbar('value')
  assert.equal(updatedValue, 50, 'Value is set and retrieved correctly')
})

QUnit.test('Check options', function (assert) {
  const $progressbar = $('#progressbar')
  const options = $progressbar.progressbar('option')
  assert.strictEqual(options.value, 0)
  assert.strictEqual(options.max, 100)
})
