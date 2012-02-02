require [
  'compiled/helpDialog'
  'vendor/jquery.ba-tinypubsub'
  'helpers/fakeENV'
  'helpers/ajax_mocks/help_links'
  'helpers/ajax_mocks/api/v1/courses'

], (helpDialog)->

  # more tests are in spec/selenium/help_dialog_spec.rb

  # mock INST.browser for test to work
  window.INST.browser =
    ie: true
    version: 8

  module 'HelpDialog Static methods'

  test 'init', 1, ->
    $tester = $('<a class="help_dialog_trigger" />').appendTo('body')
    helpDialog.initTriggers()
    $tester.click()
    ok $('.ui-dialog-content').is(':visible'), "help dialog appears when you click 'help' link"

  module 'HelpDialog'

  asyncTest 'teacher feedback', 1, ->
    $(helpDialog).bind 'ready', ->
      helpDialog.switchTo "#teacher_feedback"
      setTimeout ->
        ok helpDialog.$dialog.find('#teacher-feedback-body').is(':visible'), "textarea shows up"
        helpDialog.$dialog.dialog('close') #cleanup
        start()
      , 101
    helpDialog.open()