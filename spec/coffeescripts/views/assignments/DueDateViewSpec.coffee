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
      ENV.POSSIBLE_DATE_RANGE = {}

  test "#getFormValues unfudges for user timezone offset", ->
    formValues = @dueDateView.getFormValues()
    strictEqual formValues.due_at.toUTCString(), @date.toUTCString()
    strictEqual formValues.lock_at.toUTCString(), @date.toUTCString()
    strictEqual formValues.unlock_at.toUTCString(), @date.toUTCString()

  test "#validateBeforeSave validates dates when no date range set for course", ->
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


  test "#validateBeforeSave validates dates when date range set for course", ->
    ENV.POSSIBLE_DATE_RANGE = {
      start: Date.parse "October 12, 2012"
      end: Date.parse "October 12, 2016"
    }
    day1 = Date.parse "December 16, 2016"
    day2 = Date.parse "December 31, 1999"

    data =
      {lock_at: day1}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.lock_at
    strictEqual error, 'Lock date cannot be after course end'
    @dueDateView.$el.hideErrors()

    data =
      {unlock_at: day2}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.unlock_at
    strictEqual error, 'Unlock date cannot be before course start'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day1}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be after course end date'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day2}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be before course start date'
    @dueDateView.$el.hideErrors()

  test "#validateBeforeSave properly recognizes undefined course end date", ->
    day1 = Date.parse "December 16, 2014"

    data =
      {due_at: day1}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    strictEqual errs.assignmentOverrides, undefined
    @dueDateView.$el.hideErrors()
