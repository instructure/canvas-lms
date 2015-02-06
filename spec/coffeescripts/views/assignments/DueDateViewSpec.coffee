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
        course_section_id: 0
        due_at: @date.toISOString()
        lock_at: @date.toISOString()
        unlock_at: @date.toISOString()
      @dueDateView = new DueDateView model: @override
      @dueDateView.render()
      $('#fixtures').append @dueDateView.$el
      ENV.COURSE_DATE_RANGE = {
        start_at: Date.parse "October 12, 2012"
        end_at: Date.parse "October 12, 2016"
        override_term_dates: false
      }
      ENV.TERM_DATE_RANGE = {
        start_at: Date.parse "August 12, 2012"
        end_at: Date.parse "December 12, 2016"
      }
      ENV.SECTION_LIST = [
              {
                id: 1
                name: "first session"
                start_at: Date.parse "September 12, 2012"
                end_at: Date.parse "November 12, 2016"
                override_course_dates: true
              },
              {
                id: 2
                name: "second session"
                start_at: Date.parse "September 12, 2012"
                end_at: Date.parse "November 12, 2016"
                override_course_dates: false
              },
              {
                id: 3
                name: "third session"
                start_at: Date.parse "September 12, 2012"
                end_at: null
                override_course_dates: true
              }
            ]

    teardown: ->
      @dueDateView.remove()
      $('#fixtures').empty()
      tz.restore(@tzSnapshot)
      ENV.COURSE_DATE_RANGE.override_term_dates = false
      @override.course_section_id = 0

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

  test "#validateBeforeSave validates dates by course when date range set for
    course and course set to override term dates", ->
    ENV.COURSE_DATE_RANGE.override_term_dates = true

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
    strictEqual error, 'Due date cannot be after course end'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day2}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be before course start'
    @dueDateView.$el.hideErrors()

  test "#validateBeforeSave validates dates by section when date range set for
    custom section and section set to override course dates", ->
    ENV.COURSE_DATE_RANGE.override_term_dates = true
    @override.set('course_section_id', 1)

    day1 = Date.parse "December 16, 2016"
    day2 = Date.parse "December 31, 1999"

    data =
      {lock_at: day1}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.lock_at
    strictEqual error, 'Lock date cannot be after section end'
    @dueDateView.$el.hideErrors()

    data =
      {unlock_at: day2}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.unlock_at
    strictEqual error, 'Unlock date cannot be before section start'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day1}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be after section end'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day2}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be before section start'
    @dueDateView.$el.hideErrors()

  test "#validateBeforeSave validates dates by term when no date range is
    set for custom section or course dates", ->
    @override.set('course_section_id', 2)

    day1 = Date.parse "December 16, 2016"
    day2 = Date.parse "December 31, 1999"

    data =
      {lock_at: day1}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.lock_at
    strictEqual error, 'Lock date cannot be after term end'
    @dueDateView.$el.hideErrors()

    data =
      {unlock_at: day2}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.unlock_at
    strictEqual error, 'Unlock date cannot be before term start'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day1}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be after term end'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day2}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be before term start'
    @dueDateView.$el.hideErrors()

  test "#validateBeforeSave validates dates properly navigates through date
    priorities when null values exist", ->
    ENV.COURSE_DATE_RANGE.override_term_dates = true

    @override.set('course_section_id', 3)

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
    strictEqual error, 'Unlock date cannot be before section start'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day1}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be after course end'
    @dueDateView.$el.hideErrors()

    errors = {}
    data =
      {due_at: day2}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be before section start'
    @dueDateView.$el.hideErrors()

    ENV.COURSE_DATE_RANGE.end_at = null

    errors = {}
    data =
      {due_at: day1}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.due_at
    strictEqual error, 'Due date cannot be after term end'
    @dueDateView.$el.hideErrors()

    data =
      {lock_at: day1}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    error = errs.assignmentOverrides.lock_at
    strictEqual error, 'Lock date cannot be after term end'
    @dueDateView.$el.hideErrors()

  test "#validateBeforeSave properly recognizes undefined term end", ->
    day1 = Date.parse "December 16, 2014"

    ENV.TERM_DATE_RANGE.end_at = null

    data =
      {due_at: day1}
    errors = {}

    errs = @dueDateView.validateBeforeSave(data,errors,false)
    strictEqual errs.assignmentOverrides, undefined
    @dueDateView.$el.hideErrors()
