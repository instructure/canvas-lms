require [
  'compiled/helpDialog'
  'vendor/jquery.ba-tinypubsub'
  'helpers/fakeENV'
], (helpDialog)->

  # more tests are in spec/selenium/help_dialog_spec.rb

  # mock INST.browser for test to work
  window.INST.browser =
    ie: true
    version: 8

  module 'HelpDialog',

    setup: ->
      @clock = sinon.useFakeTimers()
      @server = sinon.fakeServer.create()
      @server.respondWith '/help_links', '[]'
      @server.respondWith '/api/v1/courses.json', '[]'

    teardown: ->
      @server.restore()

      # if we don't close it after each test, subsequent tests get messed up.
      # additionally, closing it starts an animation, so tick past that.
      if helpDialog.$dialog?
        helpDialog.$dialog.remove()
        @clock.tick 200
      @clock.restore()

      # reset the shared object
      helpDialog.dialogInited = false
      helpDialog.teacherFeedbackInited = false

  test 'init', ->
    $tester = $('<a class="help_dialog_trigger" />').appendTo('body')
    helpDialog.initTriggers()
    $tester.click()
    ok $('.ui-dialog-content').is(':visible'), "help dialog appears when you click 'help' link"
    $tester.remove()

  test 'teacher feedback', ->
    helpDialog.open()
    @server.respond()

    helpDialog.switchTo "#teacher_feedback"
    @clock.tick 200

    ok helpDialog.$dialog.find('#teacher-feedback-body').is(':visible'), "textarea shows up"
