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
import 'jqueryui/resizable'

QUnit.module('Resizable Widget', {
  beforeEach() {
    // Setup code that runs before each test
    $('#fixtures').append(
      '<div id="resizable-element" style="width: 100px; height: 100px;">Resizable Element</div>'
    )
    $('#resizable-element').resizable() // Initialize resizable widget
  },
  afterEach() {
    // Teardown code that runs after each test
    $('#fixtures').empty()
  },
})

QUnit.test('Resizable widget is initialized', function (assert) {
  const $resizableElement = $('#resizable-element')

  assert.ok($resizableElement.hasClass('ui-resizable'), 'Resizable element has class ui-resizable')
})

QUnit.test('Resize event is triggered', function (assert) {
  const $resizableElement = $('#resizable-element')
  let resizeTriggered = false

  $resizableElement.on('resize', function () {
    resizeTriggered = true
  })
  $resizableElement.trigger('resize') // Trigger resize event

  assert.ok(resizeTriggered, 'Resize event is triggered')
})
