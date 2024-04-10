/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import helpDialog from '../../ui/boot/initializers/enableHelpDialog'
import fakeENV from 'helpers/fakeENV'
import 'jquery-tinypubsub'

// more tests are in spec/selenium/help_dialog_spec.rb

QUnit.module('HelpDialog', {
  setup() {
    fakeENV.setup({help_link_name: 'Links'})
    helpDialog.animateDuration = 0
    this.clock = sinon.useFakeTimers()
    this.server = sinon.fakeServer.create()
    this.server.respondWith('/help_links', '[]')
    return this.server.respondWith('/api/v1/courses.json', '[]')
  },
  teardown() {
    fakeENV.teardown()
    this.clock.restore()
    this.server.restore()

    // if we don't close it after each test, subsequent tests get messed up.
    if (helpDialog.$dialog != null) {
      helpDialog.$dialog.dialog('close')
      helpDialog.$dialog = null
    }
    helpDialog.dialogInited = false
    helpDialog.teacherFeedbackInited = false
    $('.ui-dialog').remove()
    $('[id^=ui-id-]').remove()
    $('#help-dialog').remove()
    $('#fixtures').empty()
  },
})

test('init', () => {
  const $tester = $('<a class="help_dialog_trigger" />').appendTo('#fixtures')
  helpDialog.initTriggers()
  $tester.click()
  ok($('.ui-dialog-content').is(':visible'), "help dialog appears when you click 'help' link")
  equal($('.ui-dialog-title:contains("Links")').length, 1)
  $tester.remove()
})

test('teacher feedback', function () {
  helpDialog.open()
  this.server.respond()
  helpDialog.switchTo('#teacher_feedback')
  ok(helpDialog.$dialog.find('#teacher-feedback-body').is(':visible'), 'textarea shows up')
})

// unskip in FOO-4344
QUnit.skip('focus management', function () {
  helpDialog.open()
  this.server.respond()
  this.clock.tick(1)
  helpDialog.switchTo('#create_ticket')
  this.clock.tick(1)
  equal(document.activeElement, helpDialog.$dialog.find('#error_subject')[0], 'focuses first input')
  ok(
    !helpDialog.$dialog.find('#help-dialog-options').is(':visible'),
    'out of view screen is hidden'
  )
  helpDialog.switchTo('#help-dialog-options')
  ok(helpDialog.$dialog.find('#help-dialog-options').is(':visible'), 'menu screen appears again')
})
