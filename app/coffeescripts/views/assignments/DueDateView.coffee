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
      errs = {}
      if data
        lockAt = data.lock_at
        unlockAt = data.unlock_at
        dueAt = data.due_at
        if ENV.POSSIBLE_DATE_RANGE
          firstDate = tz.parse(ENV.POSSIBLE_DATE_RANGE.start) if ENV.POSSIBLE_DATE_RANGE.start
          lastDate = tz.parse(ENV.POSSIBLE_DATE_RANGE.end) if ENV.POSSIBLE_DATE_RANGE.end
          if firstDate
            errs.due_at = I18n.t('due_date_before_course_start', 'Due date cannot be before course start date') unless @_validDateSequence(firstDate, dueAt)
            errs.unlock_at = I18n.t('unlock_date_before_course_start', 'Unlock date cannot be before course start') unless @_validDateSequence(firstDate, unlockAt)
          if lastDate
            errs.due_at = I18n.t('due_date_after_course_conclude', 'Due date cannot be after course end date') unless @_validDateSequence(dueAt, lastDate)
            errs.lock_at = I18n.t('lock_date_after_course_end', 'Lock date cannot be after course end') unless @_validDateSequence(lockAt, lastDate)
        errs.lock_at = I18n.t('lock_date_before_due_date', 'Lock date cannot be before due date') unless @_validDateSequence(dueAt, lockAt)
        errs.unlock_at = I18n.t('unlock_date_after_due_date', 'Unlock date cannot be after due date') unless @_validDateSequence(unlockAt, dueAt)
        errs.unlock_at = I18n.t('unlock_date_after_lock_date','Unlock date cannot be after lock date') unless @_validDateSequence(unlockAt, lockAt)
      errors['assignmentOverrides'] = errs if _.keys(errs).length > 0
      errors

    _validDateSequence: (earlyDate, laterDate) =>
      !(earlyDate && laterDate && earlyDate > laterDate)

    updateOverride: =>
      @model.set @getFormValues()
