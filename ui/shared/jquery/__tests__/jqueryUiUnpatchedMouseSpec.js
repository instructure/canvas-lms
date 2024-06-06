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
import 'jqueryui/mouse'

QUnit.module('Mouse Widget', {
  beforeEach() {
    // Setup code that runs before each test
    $('#fixtures').append('<div id="test-mouse">Test Mouse</div>')
  },
  afterEach() {
    // Teardown code that runs after each test
    $('#fixtures').empty()
  },
})

QUnit.test('Mouse down event fires', async function (assert) {
  const done = assert.async() // Get the async function from assert
  const $mouse = $('#test-mouse')

  // setup mouse events
  $mouse.mousedown(() => {
    ok(true)
    done()
  })

  // make the call we are testing: Trigger mousedown event
  $mouse.trigger('mousedown')
})

QUnit.test('Mouse up event fires', async function (assert) {
  const done = assert.async() // Get the async function from assert
  const $mouse = $('#test-mouse')

  // setup mouse events
  $mouse.mouseup(() => {
    ok(true)
    done()
  })

  // make the call we are testing: Trigger mouse up event
  $mouse.trigger('mouseup')
})
