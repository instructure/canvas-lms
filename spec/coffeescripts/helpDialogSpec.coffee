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
