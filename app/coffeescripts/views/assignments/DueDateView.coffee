define [
  'i18n!overrides'
  'Backbone'
  'underscore'
  'jst/assignments/DueDateView'
  'jquery'
  'jquery.toJSON'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
], (I18n,Backbone, _, template, $) ->
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
          if lockAt && dueAt && lockAt < dueAt
            errs.lock_at = I18n.t('lock_date_before_due_date',
              'Lock date cannot be before due date')
          if unlockAt && dueAt && unlockAt > dueAt
            errs.unlock_at = I18n.t('unlock_date_after_due_date',
              'Unlock date cannot be after due date')
          else if unlockAt && lockAt && unlockAt > lockAt
            errs.unlock_at = I18n.t('unlock_date_after_lock_date',
              'Unlock date cannot be after lock date')
      errors['assignmentOverrides'] = errs if _.keys(errs).length > 0
      errors

    updateOverride: =>
      @model.set @getFormValues()
