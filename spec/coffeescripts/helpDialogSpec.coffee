define [
  'jquery'
  'compiled/helpDialog'
  'helpers/fakeENV'
  'vendor/jquery.ba-tinypubsub'
], ($,helpDialog,fakeENV)->
  # more tests are in spec/selenium/help_dialog_spec.rb

  # mock INST.browser for test to work
  originalBrowser = null

  module 'HelpDialog',
    setup: ->
      fakeENV.setup()
      @clock = sinon.useFakeTimers()
      @server = sinon.fakeServer.create()
      @server.respondWith '/help_links', '[]'
      @server.respondWith '/api/v1/courses.json', '[]'
      originalBrowser = window.INST.browser
      window.INST.browser =
        ie: true
        version: 8

    teardown: ->
      fakeENV.teardown()
      @server.restore()

      # if we don't close it after each test, subsequent tests get messed up.
      if helpDialog.$dialog?
        helpDialog.$dialog.dialog('close')
        helpDialog.$dialog = null

      @clock.restore()

      # reset the shared object
      helpDialog.dialogInited = false
      helpDialog.teacherFeedbackInited = false
      window.INST.browser = originalBrowser
      $("#fixtures").empty()

  test 'init', ->
    $tester = $('<a class="help_dialog_trigger" />').appendTo('#fixtures')
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
