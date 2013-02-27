define [
  'Backbone'
  'underscore'
  'jst/assignments/DueDateView'
  'jquery'
  'jquery.toJSON'
  'jquery.instructure_date_and_time'
], (Backbone, _, template, $) ->
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
      json.course_section_id = parseInt(json.course_section_id, 10)
      json
    updateOverride: =>
      @model.set @getFormValues()
