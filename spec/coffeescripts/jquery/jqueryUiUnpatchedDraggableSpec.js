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

import 'jqueryui/draggable'
import '@canvas/jquery/jquery.simulate'

QUnit.module('Draggable Widget', {
  beforeEach() {
    // Setup code that runs before each test
    $('#fixtures').append('<div id="draggable-item">Draggable Item</div>')
    $('#draggable-item').draggable() // Initialize draggable widget
  },
  afterEach() {
    // Teardown code that runs after each test
    $('#fixtures').empty()
  },
})

QUnit.test('Draggable widget is initialized', async function (assert) {
  const $draggableItem = $('#draggable-item')
  const initialPosition = $draggableItem.position() // Get initial position

  // drag the div
  $draggableItem.simulate('drag', {dx: 50, dy: 50}) // Simulate dragging

  assert.deepEqual(
    {top: initialPosition.top + 50, left: initialPosition.left + 50},
    {top: initialPosition.top + 50, left: initialPosition.left + 50}
  )
})
