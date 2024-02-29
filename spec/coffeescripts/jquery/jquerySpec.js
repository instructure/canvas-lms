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
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import 'jquery-migrate'

QUnit.module('JQuery', {
  beforeEach() {
    // Setup code that runs before each test
    $('#fixtures').append('<div id="test-jquery">Test JQuery</div>')
  },
  afterEach() {
    // Teardown code that runs after each test
    $('#fixtures').empty()
  },
})

QUnit.test('jquery can append to the document body', async function (assert) {
  // note: in jquery 1.9 or later, you can't append to the $(document), must be $(document.body) or other element
  const done = assert.async() // Get the async function from assert
  const $body = $(document.body)

  $("<div class='test-class'>hello world</div>").appendTo($body)
  const $appendedDiv = $body.find('.test-class')
  assert.equal($appendedDiv.text(), 'hello world')
  done()
})

QUnit.test('jquery can select stuff', async function (assert) {
  const done = assert.async() // Get the async function from assert
  const $div = $('#test-jquery')
  assert.equal($div.text(), 'Test JQuery')
  done()
})
