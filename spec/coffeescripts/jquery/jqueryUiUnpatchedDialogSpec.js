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

import 'jqueryui-unpatched/core'
import 'jqueryui-unpatched/widget'
import 'jqueryui-unpatched/position'
import 'jqueryui-unpatched/button'
import 'jqueryui-unpatched/mouse'
import 'jqueryui-unpatched/resizable'
import 'jqueryui-unpatched/draggable'
import 'jqueryui-unpatched/dialog'

QUnit.module('Dialog Widget', {
  beforeEach() {
    // Setup code that runs before each test
    $('#fixtures').append('<div id="test-dialog" title="Test Dialog">Test Content</div>')
  },
  afterEach() {
    // Teardown code that runs after each test
    $('#fixtures').empty()
    $('#test-dialog').dialog('destroy') // Cleanup dialog widget
    $('#test-dialog').remove() // Remove test dialog from DOM
  },
})

QUnit.test('Dialog widget is initialized', function (assert) {
  // Arrange
  const $dialog = $('#test-dialog')
  $dialog.dialog()

  // Act
  $dialog.dialog('open') // Open the dialog
  // Assert
  assert.ok($dialog.hasClass('ui-dialog-content'), 'Dialog has class ui-dialog-content')
  assert.ok($dialog.hasClass('ui-widget-content'), 'Dialog has class ui-widget-content')
  assert.ok($dialog.parent().hasClass('ui-corner-all'), 'Dialog has class ui-corner-all')
  assert.equal($dialog.parent().attr('role'), 'dialog', 'Dialog has role attribute set to dialog')
})

QUnit.test('Open and Close events are triggered', async function (assert) {
  const done = assert.async()
  const $dialog = $('#test-dialog')
  let openTriggered = false

  $dialog.dialog({
    open() {
      openTriggered = true
    },
    close() {
      ok(openTriggered, 'dialog on open was not called')
      done()
    },
  })

  $dialog.dialog('open') // Open the dialog
  $dialog.dialog('close') // Close the dialog
})
