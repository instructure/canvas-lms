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

import '@canvas/jquery/jquery.simulate'
import 'jqueryui/droppable'

QUnit.module('droppable widget', {
  beforeEach() {
    $('#fixtures').append(
      '<div id="droppable-element" style="width: 100px; height: 100px; background: blue;">Droppable Element</div>'
    )
    $('#droppable-element').droppable()
  },
  afterEach() {
    $('#fixtures').empty()
  },
})

QUnit.test('hover class is applied', function (assert) {
  const $droppableElement = $('#droppable-element').droppable({
    drop() {
      // add class upon drop
      $(this).addClass('ui-state-hover')
    },
  })
  const $draggableElement = $(
    '<div class="draggable" style="width: 50px; height: 50px; background: red;"></div>'
  )
    .appendTo('#fixtures')
    .draggable()
  // simulate the drag action with adjusted displacement
  $draggableElement.simulate('drag', {dx: 25, dy: -75})
  assert.ok($droppableElement.hasClass('ui-state-hover'), 'hover class is applied')
})

QUnit.test('droppable widget is initialized', function (assert) {
  const $droppableElement = $('#droppable-element')
  assert.ok($droppableElement.hasClass('ui-droppable'), 'droppable element has class ui-droppable')
})

QUnit.test('Drop event is triggered', function (assert) {
  const $droppableElement = $('#droppable-element')
  let dropTriggered = false
  $droppableElement.on('drop', function () {
    dropTriggered = true
  })
  $droppableElement.trigger('drop')
  assert.ok(dropTriggered, 'drop event is triggered')
})

QUnit.test('activation option works', function (assert) {
  const done = assert.async() // Handle asynchronous operations
  const $droppableElement = $('#droppable-element')
  const $draggableElement = $(
    '<div class="draggable" style="width: 50px; height: 50px; background: red;"></div>'
  )
    .appendTo('#fixtures')
    .draggable()
  let activateCalled = false
  let deactivateCalled = false
  let dropEventHandled = false
  $droppableElement.droppable({
    activate() {
      activateCalled = true
    },
    deactivate() {
      deactivateCalled = true
      if (dropEventHandled) {
        // assert after drop event to ensure correct sequence
        assert.ok(activateCalled, 'droppable element activated')
        assert.ok(deactivateCalled, 'droppable element deactivated')
        done()
      }
    },
    drop() {
      dropEventHandled = true
      // do not call done() here, wait for deactivate to be called
    },
  })
  $draggableElement.simulate('drag', {dx: 25, dy: -75})
})
