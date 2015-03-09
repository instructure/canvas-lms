define [
  'jquery'
  'compiled/widget/assignmentRubricDialog'
], ($, assignmentRubricDialog)->

  module 'assignmentRubricDialog',

  test 'make sure it picks up the right data attrs', ->
    $trigger = $('<div />').addClass('rubric_dialog_trigger')
    $trigger.data('noRubricExists', false)
    $trigger.data('url', '/example')
    $trigger.data('focusReturnsTo', '.announcement_cog')
    $('#fixtures').append($trigger)
    
    assignmentRubricDialog.initTriggers()

    equal assignmentRubricDialog.noRubricExists, false
    equal assignmentRubricDialog.url, '/example'
    ok assignmentRubricDialog.$focusReturnsTo

    $('#fixtures').empty()
