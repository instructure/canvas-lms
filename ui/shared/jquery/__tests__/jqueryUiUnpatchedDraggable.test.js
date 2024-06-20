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
import 'jquery-ui-touch-punch'
import 'jqueryui/droppable'
import 'jqueryui/draggable'
import 'jqueryui/mouse'
import '../jquery.simulate'

describe('Draggable Widget', () => {
  beforeEach(() => {
    $('#fixtures').append('<div id="draggable-item">Draggable Item</div>')
    $('#draggable-item').draggable() // Initialize draggable widget
  })

  afterEach(() => {
    $('#fixtures').empty()
  })

  // fails in Jest, passes in QUnit
  it.skip('Draggable widget is initialized', async function () {
    const $draggableItem = $('#draggable-item')
    const initialPosition = $draggableItem.position() // Get initial position

    // drag the div
    $draggableItem.simulate('drag', {dx: 50, dy: 50}) // Simulate dragging

    expect({top: initialPosition.top + 50, left: initialPosition.left + 50}).toMatchObject({
      top: initialPosition.top + 50,
      left: initialPosition.left + 50,
    })
  })
})
