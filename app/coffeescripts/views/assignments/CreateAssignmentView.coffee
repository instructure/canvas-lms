define [
  'underscore'
  'compiled/models/Assignment'
  'compiled/views/DialogFormView'
  'jst/assignments/CreateAssignment'
  'jst/EmptyDialogFormWrapper'
  'jquery'
  'jquery.instructure_date_and_time'
], (_, Assignment, DialogFormView, template, wrapper, $) ->

  class CreateAssignmentView extends DialogFormView
    defaults:
      width: 500
      height: 350

    events: _.extend {}, @::events,
      'click .dialog_closer': 'close'
      'click .more_options': 'moreOptions'

    template: template
    wrapperTemplate: wrapper

    @optionProperty 'assignmentGroup'

    initialize: ->
      super
      @model ?= @generateNewAssignment()
      @on "close", -> @$el[0].reset()

    onSaveSuccess: =>
      super
      if @assignmentGroup
        @assignmentGroup.get('assignments').add(@model)
        @model = @generateNewAssignment()

    getFormData: =>
      data = super
      unfudged = $.unfudgeDateForProfileTimezone(data.due_at)
      data.due_at = $.dateToISO8601UTC(unfudged) if unfudged?
      return data

    moreOptions: ->
      valid = ['submission_types', 'name', 'due_at', 'points_possible', 'assignment_group_id']

      data = @getFormData()
      data.assignment_group_id = @assignmentGroup.get('id') if @assignmentGroup

      dataParams = {}
      _.each data, (value, key) ->
        if value and _.contains(valid, key) and value != ""
          dataParams[key] = value

      url = if @assignmentGroup then @newAssignmentUrl() else @model.htmlEditUrl()

      @redirectTo("#{url}?#{$.param(dataParams)}")

    redirectTo: (url) ->
      window.location.href = url

    generateNewAssignment: ->
      assign = new Assignment
      assign.assignmentGroupId(@assignmentGroup.id) if @assignmentGroup
      assign

    toJSON: ->
      json = @model.toView()

      uniqLabel = if @assignmentGroup
        "ag_#{@assignmentGroup.get('id')}"
      else
        "assign_#{@model.get('id')}"

      _.extend json,
        canChooseType: @assignmentGroup?
        uniqLabel: uniqLabel

    openAgain: ->
      super

      timeField = @$el.find(".datetime_field")
      if @model.multipleDueDates()
        timeField.tooltip
          position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
          tooltipClass: 'center bottom vertical',
          content: -> $($(@).data('tooltipSelector')).html()
      else
        timeField.datetime_field() unless timeField.hasClass("hasDatepicker")

    newAssignmentUrl: ->
      ENV.URLS.new_assignment_url
