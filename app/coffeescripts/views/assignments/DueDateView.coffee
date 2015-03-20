define [
  'Backbone'
  'underscore'
  'jst/assignments/DueDateView'
  'compiled/util/DateValidator'
  'jquery'
  'jquery.toJSON'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
], (Backbone, _, template, DateValidator, $) ->
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
      return errors unless data

      dateRange = $.extend({},ENV.VALID_DATE_RANGE)

      dateValidator = new DateValidator({date_range: dateRange, data: data})

      errs = dateValidator.validateDates()
      errors['assignmentOverrides'] = errs if !_.isEmpty(errs)
      errors

    updateOverride: =>
      @model.set @getFormValues()
