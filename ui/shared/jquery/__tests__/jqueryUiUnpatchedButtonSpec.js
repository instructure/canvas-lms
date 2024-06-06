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
import 'jqueryui/button'

QUnit.module('Button Widget', {
  beforeEach() {
    // Setup code that runs before each test
    $('#fixtures').append('<button id="test-button">Test Button</button>')
    $('#test-button').button() // Initialize button widget
  },
  afterEach() {
    // Teardown code that runs after each test
    $('#fixtures').empty()
    $('#test-button').button('destroy') // Cleanup button widget
    $('#test-button').remove() // Remove test button from DOM
  },
})

QUnit.test('Button widget is initialized', function (assert) {
  // Arrange
  const $button = $('#test-button')

  // Act
  $button.trigger('focus') // Trigger focus event

  // Assert
  assert.ok($button.hasClass('ui-button'), 'Button has class ui-button')
  assert.ok($button.hasClass('ui-widget'), 'Button has class ui-widget')
  assert.ok($button.hasClass('ui-corner-all'), 'Button has class ui-corner-all')
  assert.equal($button.prop('tabindex'), '0', 'Button has tabindex attribute set to 0')
})

QUnit.test('Click event is triggered on button click', function (assert) {
  // Arrange
  const $button = $('#test-button')
  let clickTriggered = false

  // Act
  $button.on('click', function () {
    clickTriggered = true
  })
  $button.trigger('click') // Trigger click event

  // Assert
  assert.ok(clickTriggered, 'Click event is triggered')
})
