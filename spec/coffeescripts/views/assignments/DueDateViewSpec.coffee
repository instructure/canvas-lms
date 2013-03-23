define [
  'compiled/views/assignments/DueDateView'
  'compiled/models/AssignmentOverride'
  'jquery'
  'jquery.instructure_date_and_time'
], (DueDateView, AssignmentOverride, $) ->

  module "DueDateView",
    setup: ->
      $('#fixtures').append("<div id='time_zone_offset'>420</div>")
      @date = new Date "March 13 1992"
      @override = new AssignmentOverride
        course_section_id: 1
        due_at: @date.toISOString()
        lock_at: @date.toISOString()
        unlock_at: @date.toISOString()
      @dueDateView = new DueDateView model: @override
      $('#fixtures').append @dueDateView.$el
      @dueDateView.render()

    teardown: ->
      $('#fixtures').empty()

  test "#getFormValues unfudges for user timezone offset", ->
    formValues = @dueDateView.getFormValues()
    strictEqual formValues.due_at.toUTCString(), @date.toUTCString()
    strictEqual formValues.lock_at.toUTCString(), @date.toUTCString()
    strictEqual formValues.unlock_at.toUTCString(), @date.toUTCString()

