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
import 'jqueryui/sortable'
import '@canvas/jquery/jquery.simulate'

QUnit.module('Sortable Widget', {
  beforeEach() {
    // Setup code that runs before each test
    $('#fixtures').append(
      '<ul id="sortable-list">' +
        '<li style="height: 30px;">Item 1</li>' +
        '<li style="height: 30px;">Item 2</li>' +
        '<li style="height: 30px;">Item 3</li>' +
        '</ul>'
    )
    $('#sortable-list').sortable() // Initialize sortable widget
  },
  afterEach() {
    // Teardown code that runs after each test
    $('#fixtures').empty()
    $('#sortable-list').sortable('destroy')
  },
})

QUnit.test('Sortable widget is initialized', function (assert) {
  const $sortableList = $('#sortable-list')
  assert.ok($sortableList.hasClass('ui-sortable'), 'Sortable list has class ui-sortable')
})

QUnit.test('Check sortability', function (assert) {
  const $sortableList = $('#sortable-list')
  assert.strictEqual($sortableList.sortable('option', 'disabled'), false)
})
