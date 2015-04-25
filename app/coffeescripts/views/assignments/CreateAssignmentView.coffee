define [
  'underscore'
  'compiled/models/Assignment'
  'compiled/views/DialogFormView'
  'compiled/util/DateValidator'
  'jst/assignments/CreateAssignment'
  'jst/EmptyDialogFormWrapper'
  'i18n!assignments'
  'jquery'
  'jquery.instructure_date_and_time'
], (_, Assignment, DialogFormView, DateValidator, template, wrapper, I18n, $) ->

  class CreateAssignmentView extends DialogFormView
    defaults:
      width: 500
      height: 380

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
      data.due_at = unfudged.toISOString() if unfudged?
      return data

    moreOptions: ->
      valid = ['submission_types', 'name', 'due_at', 'points_possible', 'assignment_group_id']

      data = @getFormData()
      data.assignment_group_id = @assignmentGroup.get('id') if @assignmentGroup

      dataParams = {}
      _.each data, (value, key) ->
        if _.contains(valid, key)
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
      if @model.multipleDueDates() || @model.isOnlyVisibleToOverrides()
        timeField.tooltip
          position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
          tooltipClass: 'center bottom vertical',
          content: -> $($(@).data('tooltipSelector')).html()
      else
        timeField.datetime_field() unless timeField.hasClass("hasDatepicker")

    newAssignmentUrl: ->
      ENV.URLS.new_assignment_url

    validateBeforeSave: (data, errors) ->
      errors = @_validateTitle data, errors
      errors = @_validatePointsPossible data, errors
      errors = @_validateDueDate data, errors
      errors

    _validateTitle: (data, errors) ->
      frozenTitle = _.contains(@model.frozenAttributes(), "title")
      if !frozenTitle and (!data.name or $.trim(data.name.toString()).length == 0)
        errors["name"] = [
          message: I18n.t 'name_is_required', 'Name is required!'
        ]
      if $.trim(data.name.toString()).length > 255
        errors["name"] = [
          message: I18n.t 'name_too_long', 'Name is too long'
        ]
      errors

    _validatePointsPossible: (data, errors) =>
      frozenPoints = _.contains(@model.frozenAttributes(), "points_possible")

      if !frozenPoints and data.points_possible and isNaN(parseFloat(data.points_possible))
        errors["points_possible"] = [
          message: I18n.t 'points_possible_number', 'Points possible must be a number'
        ]
      errors

    _validateDueDate: (data, errors) ->
      return errors unless data.due_at

      validRange = ENV.VALID_DATE_RANGE
      data.lock_at = @model.lockAt()
      data.unlock_at = @model.unlockAt()
      dateValidator = new DateValidator({date_range: validRange, data: data})
      errs = dateValidator.validateDates()

      return errors if _.isEmpty(errs)

      # need to override default error message to focus only on due date field for quick add/edit
      if errs['lock_at']
        errs['due_at'] = I18n.t('Due date cannot be after lock date')
      if errs['unlock_at']
        errs['due_at'] = I18n.t('Due date cannot be before unlock date')

      errors["due_at"] = [message: errs["due_at"]]
      errors

