define [
  'compiled/views/assignments/DueDateView'
  'compiled/models/AssignmentOverride'
  'timezone'
  'vendor/timezone/America/Denver'
  'jquery'
  'jquery.instructure_date_and_time'
], (DueDateView, AssignmentOverride, tz, denver, $) ->

  module "DueDateView",
    setup: ->
      @tzSnapshot = tz.snapshot()
      tz.changeZone(denver, 'America/Denver')

      @date = new Date "March 13 1992"
      @override = new AssignmentOverride
        course_section_id: 1
        due_at: @date.toISOString()
        lock_at: @date.toISOString()
        unlock_at: @date.toISOString()
      @dueDateView = new DueDateView model: @override
      @dueDateView.render()
      $('#fixtures').append @dueDateView.$el

    teardown: ->
      @dueDateView.remove()
      $('#fixtures').empty()
      tz.restore(@tzSnapshot)

  test "#getFormValues unfudges for user timezone offset", ->
    formValues = @dueDateView.getFormValues()
    strictEqual formValues.due_at.toUTCString(), @date.toUTCString()
    strictEqual formValues.lock_at.toUTCString(), @date.toUTCString()
    strictEqual formValues.unlock_at.toUTCString(), @date.toUTCString()

  test "#validateBeforeSave validates dates", ->
    day1 = Date.parse "August 14, 2013"
    day2 = Date.parse "August 15, 2013"
    day3 = Date.parse "August 16, 2013"

    data =
        {due_at: day2, lock_at: day1}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.lock_at
    strictEqual error, 'Lock date cannot be before due date'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day2, unlock_at: day3}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.unlock_at
    strictEqual error, 'Unlock date cannot be after due date'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {lock_at: day1, unlock_at:day3}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.unlock_at
    strictEqual error, 'Unlock date cannot be after lock date'
    @dueDateView.$el.hideErrors()

