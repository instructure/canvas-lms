define [
  'Backbone'
  'underscore'
  'jst/assignments/DueDateOverride'
  'compiled/models/AssignmentOverride'
  'i18n!overrides'
], (Backbone, _, template, AssignmentOverride, I18n) ->

  # Class Summary
  #   Holds a list of Due Dates and adds items to the collection
  #   when the user creates a new due date.
  class DueDateOverrideView extends Backbone.View

    template: template

    events:
      'click #add_due_date' : 'addDueDate'

    className: 'due-date-container'

    initialize: ->
      super
      @model.overrides.on 'remove', @showAddDueDateButton
      @model.overrides.on 'remove', @toggleUnassignedWarning
      @model.overrides.on 'add', @toggleUnassignedWarning

    # Method Summary
    #   Adds a new due date to the collection of due dates
    #   Due dates have sane defaults and aren't saved until you
    #   call .save
    # @api private
    addDueDate: (event) ->
      event.preventDefault()
      availableSections = @model.availableSections()
      assignmentOverride = if @model.containsSectionsWithoutOverrides()
        AssignmentOverride.defaultDueDate()
      else
        new AssignmentOverride
          course_section_id: availableSections[0]?.id
      @model.addOverride assignmentOverride

      @hideAddDueDateButton() if @shouldHideDueDate()

    # 1 instead of 0 because of the extra "fake" section for everyone.  you
    # never need to cover all the sections AND everyone else
    shouldHideDueDate: => @model.availableSections().length <= 1

    toggleUnassignedWarning: =>
      @$el.find("#unassigned_warning").toggle(@needsUnassignedWarning())

    needsUnassignedWarning: =>
      return false unless @model.onlyVisibleToOverrides()
      !(@model.overrides.length)

    toJSON: =>
      json = super
      json.shouldHideDueDate = @shouldHideDueDate()
      json.needsUnassignedWarning = @needsUnassignedWarning()
      json

    updateOverrides: =>
      @options.views['due-date-overrides'].updateOverrides()

    getDefaultDueDate: =>
      @model.getDefaultDueDate()

    containsSectionsWithoutOverrides: =>
      @model.containsSectionsWithoutOverrides()

    sectionsWithoutOverrides: =>
      @model.sectionsWithoutOverrides()

    getOverrides: => @model.overrides.toJSON()

    getAllDates: (data) =>
      data or={}
      @getOverrides().concat data

    showAddDueDateButton: => @$el.find( '#add_due_date' ).show()

    hideAddDueDateButton: => @$el.find( '#add_due_date' ).hide()

    validateBeforeSave: (data, errors) =>
      @options.views['due-date-overrides'].validateBeforeSave(data,errors)
      errors
