#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/helpDialog'
  'helpers/fakeENV'
  'vendor/jquery.ba-tinypubsub'
], ($,helpDialog,fakeENV)->
  # more tests are in spec/selenium/help_dialog_spec.rb

  QUnit.module 'HelpDialog',
    setup: ->
      fakeENV.setup({
        help_link_name: 'Links'
      })
      helpDialog.animateDuration = 0
      @server = sinon.fakeServer.create()
      @server.respondWith '/help_links', '[]'
      @server.respondWith '/api/v1/courses.json', '[]'

    teardown: ->
      fakeENV.teardown()
      @server.restore()

      # if we don't close it after each test, subsequent tests get messed up.
      if helpDialog.$dialog?
        helpDialog.$dialog.dialog('close')
        helpDialog.$dialog = null

      # reset the shared object
      helpDialog.dialogInited = false
      helpDialog.teacherFeedbackInited = false
      $(".ui-dialog").remove()
      $('[id^=ui-id-]').remove()
      $("#help-dialog").remove()
      $("#fixtures").empty()

  test 'init', ->
    $tester = $('<a class="help_dialog_trigger" />').appendTo('#fixtures')
    helpDialog.initTriggers()
    $tester.click()
    ok $('.ui-dialog-content').is(':visible'), "help dialog appears when you click 'help' link"
    equal $('.ui-dialog-title:contains("Links")').length, 1
    $tester.remove()

  test 'teacher feedback', ->
    helpDialog.open()
    @server.respond()

    helpDialog.switchTo "#teacher_feedback"
    ok helpDialog.$dialog.find('#teacher-feedback-body').is(':visible'), "textarea shows up"

  test 'focus management', ->
    helpDialog.open()
    @server.respond()

    helpDialog.switchTo "#create_ticket"
    equal document.activeElement, helpDialog.$dialog.find('#error_subject')[0], 'focuses first input'
    ok !helpDialog.$dialog.find('#help-dialog-options').is(':visible'), 'out of view screen is hidden'

    helpDialog.switchTo "#help-dialog-options"
    ok helpDialog.$dialog.find('#help-dialog-options').is(':visible'), 'menu screen appears again'
