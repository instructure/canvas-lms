define [
  'i18n!overrides'
  'Backbone'
  'underscore'
  'timezone'
  'jst/assignments/DueDateView'
  'jquery'
  'jquery.toJSON'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
], (I18n,Backbone, _, tz, template, $) ->
  class DueDateView extends Backbone.View
    template: template
    tagName: 'li'
    className: 'due-date-row'

    events:
      'click .remove-link' : 'removeDueDate'

    # Method Summary
    #  Apply bindings and calendar js to each view
    afterRender: =>
      @$el.find('.date_field').datetime_field()

    # Method Summary
    #   Removes a due date override from the collection when clicked. Find the
    #   specific due date and remove it.
    # @api private
    removeDueDate: (event) =>
      event.preventDefault()
      @trigger 'remove', @model
      @remove()

    hideRemoveButton: =>
      @$el.find('.remove-link').hide()

    showRemoveButton: =>
      @$el.find('.remove-link').show()

    reRenderSections: (sections) =>
      _.each @options.views, (view) ->
        view.sections = sections
        view.render()

    getFormValues: =>
      json = @$el.find('form').toJSON()
      for dateField in [ 'due_at', 'lock_at', 'unlock_at' ]
        json[dateField] = $.unfudgeDateForProfileTimezone(json[dateField])
      errs = @validateBeforeSave json, {}
      @$el.hideErrors()
      for own el, msg of errs.assignmentOverrides
        @$("[name=#{el}]").errorBox msg
      json

    validateBeforeSave: (data, errors) =>
      return unless data

      errs = {}
      datesToValidate = []

      lockAt = data.lock_at
      unlockAt = data.unlock_at
      dueAt = data.due_at
      dateRange = @getDateRange()

      if dateRange
        if dateRange.start
          datesToValidate.push {
            date: tz.parse(dateRange.start.date),
            validationDates: {"due_at": dueAt, "unlock_at": unlockAt},
            range: "start_range",
            type: dateRange.start.appliedBy
          }
        if dateRange.end
          datesToValidate.push {
            date: tz.parse(dateRange.end.date),
            validationDates: {"due_at": dueAt, "lock_at": lockAt},
            range: "end_range",
            type: dateRange.end.appliedBy
          }
      if dueAt
        datesToValidate.push {
          date: dueAt,
          validationDates: {"lock_at": lockAt},
          range: "start_range",
          type: "due"
        }
        datesToValidate.push {
          date: dueAt,
          validationDates: {"unlock_at": unlockAt},
          range: "end_range",
          type: "due"
        }
      if lockAt
        datesToValidate.push {
          date: lockAt,
          validationDates: {"unlock_at": unlockAt},
          range: "end_range",
          type: "lock"
        }
      @_validateDateSequences(datesToValidate, errs)
      errors['assignmentOverrides'] = errs if _.keys(errs).length > 0
      errors

    _validateDateSequences: (datesToValidate, errs) =>
      for dateSet in datesToValidate
        if dateSet.date
          switch dateSet.range
            when "start_range"
              _.each dateSet.validationDates, (validationDate, dateType) =>
                if validationDate && dateSet.date > validationDate
                  errs[dateType] = DATE_RANGE_ERRORS[dateType][dateSet.range][dateSet.type]
            when "end_range"
              _.each dateSet.validationDates, (validationDate, dateType) =>
                if validationDate && dateSet.date < validationDate
                  errs[dateType] = DATE_RANGE_ERRORS[dateType][dateSet.range][dateSet.type]

    getDateRange: =>
      sectionID = @model.getCourseSectionID()
      section = _.find(ENV.SECTION_LIST, {id: sectionID}) if sectionID != 0
      course = ENV.COURSE_DATE_RANGE
      term = ENV.TERM_DATE_RANGE

      return unless section || course || term

      range = {}

      range["start"] = @_findApplicableDate("start_at", section, course, term)
      range["end"] = @_findApplicableDate("end_at", section, course, term)

      range

    _findApplicableDate: (dateType, section, course, term) =>
      if section?.override_course_dates && section?[dateType]
        {appliedBy: "section", date: section[dateType]}
      else if course.override_term_dates && course[dateType]
        {appliedBy: "course", date: course[dateType]}
      else if term[dateType]
        {appliedBy: "term", date: term[dateType]}
      else
        null

    updateOverride: =>
      @model.set @getFormValues()


    DATE_RANGE_ERRORS = {
      "due_at": {
        "start_range": {
          "section": I18n.t('Due date cannot be before section start')
          "course": I18n.t('Due date cannot be before course start')
          "term": I18n.t('Due date cannot be before term start')
        },
        "end_range": {
          "section": I18n.t('Due date cannot be after section end')
          "course": I18n.t('Due date cannot be after course end')
          "term": I18n.t('Due date cannot be after term end')
        }
      },
      "unlock_at": {
        "start_range": {
          "section": I18n.t('Unlock date cannot be before section start')
          "course": I18n.t('Unlock date cannot be before course start')
          "term": I18n.t('Unlock date cannot be before term start')
        },
        "end_range" : {
          "due": I18n.t('Unlock date cannot be after due date'),
          "lock": I18n.t('Unlock date cannot be after lock date')
        }
      },
      "lock_at": {
        "start_range": {
          "due": I18n.t('Lock date cannot be before due date')
        },
        "end_range": {
          "section": I18n.t('Lock date cannot be after section end')
          "course": I18n.t('Lock date cannot be after course end')
          "term": I18n.t('Lock date cannot be after term end')
        }
      }
    }