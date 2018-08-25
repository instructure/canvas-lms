#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'underscore'
  '../../models/Assignment'
  '../DialogFormView'
  '../../util/DateValidator'
  'jst/assignments/CreateAssignment'
  'jst/EmptyDialogFormWrapper'
  'jsx/shared/helpers/numberHelper'
  'i18n!assignments'
  '../../util/round'
  'jquery'
  '../../api/gradingPeriodsApi'
  '../../util/SisValidationHelper'
  'jquery.instructure_date_and_time'
], (_, Assignment, DialogFormView, DateValidator, template, wrapper,
  numberHelper, I18n, round, $, GradingPeriodsAPI, SisValidationHelper) ->

  class CreateAssignmentView extends DialogFormView
    defaults:
      width: 500
      height: 380

    events: _.extend {}, @::events,
      'click .dialog_closer': 'close'
      'click .save_and_publish': 'saveAndPublish'
      'click .more_options': 'moreOptions'
      'blur .points_possible': 'roundPointsPossible'

    template: template
    wrapperTemplate: wrapper

    @optionProperty 'assignmentGroup'

    initialize: (options) ->
      super(
        assignmentGroup: options.assignmentGroup,
        title: if @model? then I18n.t("Edit Assignment") else null    # let title come from trigger (see DialogForm.getDialogTitle)
      )
      @model ?= @generateNewAssignment()
      @on "close", -> @$el[0].reset()

    onSaveSuccess: =>
      @shouldPublish = false
      super
      # Person who creates the assignment should always have permission to update it
      ENV.PERMISSIONS.by_assignment_id && ENV.PERMISSIONS.by_assignment_id[@model.id] = {
        update: true
      }
      if @assignmentGroup
        @assignmentGroup.get('assignments').add(@model)
        @model = @generateNewAssignment()

    getFormData: =>
      data = super
      unfudged = $.unfudgeDateForProfileTimezone(data.due_at)
      data.due_at = unfudged.toISOString() if unfudged?
      data.published = true if @shouldPublish
      data.points_possible = numberHelper.parse(data.points_possible)
      return data

    saveAndPublish: (event) ->
      @shouldPublish = true
      @disableWhileLoadingOpts = {buttons: ['.save_and_publish']}
      @submit(event)

    onSaveFail: (xhr) =>
      @shouldPublish = false
      @disableWhileLoadingOpts = {}
      super(xhr)

    moreOptions: ->
      valid = ['submission_types', 'name', 'due_at', 'points_possible', 'assignment_group_id']

      data = @getFormData()
      data.assignment_group_id = @assignmentGroup.get('id') if @assignmentGroup

      dataParams = {}
      _.each data, (value, key) ->
        if _.contains(valid, key)
          dataParams[key] = value

      if dataParams.submission_types == 'online_quiz'
        button = @$('.more_options')
        button.prop('disabled', true)
        $.post(@newQuizUrl(), dataParams)
          .done((response) => @redirectTo(response.url))
          .always(-> button.prop('disabled', false))
      else
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
        disableDueAt: @disableDueAt()
        postToSISName: ENV.SIS_NAME
        isInClosedPeriod: @model.inClosedGradingPeriod()

      # master_course_restrictions only apply if this is a child course
      # and is restricted by a master course.
      # the handlebars template doesn't do logical combinations conditions,
      # so summarize here
      doRestrictionsApply = !!json.is_master_course_child_content && !!json.restricted_by_master_course
      for k, v of json.master_course_restrictions
        json.master_course_restrictions[k] =  doRestrictionsApply && v
      json

    currentUserIsAdmin: ->
      _.contains(ENV.current_user_roles, "admin")

    disableDueAt: ->
      _.contains(@model.frozenAttributes(), "due_at") || @model.inClosedGradingPeriod()

    openAgain: ->
      super
      this.hideErrors()

      timeField = @$el.find(".datetime_field")
      if @model.multipleDueDates() || @model.isOnlyVisibleToOverrides() || @model.nonBaseDates() || @disableDueAt()
        timeField.tooltip
          position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
          tooltipClass: 'center bottom vertical',
          content: -> $($(@).data('tooltipSelector')).html()
      else
        timeField.datetime_field() unless timeField.hasClass("hasDatepicker")

    newAssignmentUrl: ->
      ENV.URLS.new_assignment_url

    newQuizUrl: ->
      ENV.URLS.new_quiz_url

    validateBeforeSave: (data, errors) ->
      errors = @_validateTitle data, errors
      errors = @_validatePointsPossible data, errors
      errors = @_validateDueDate data, errors
      errors

    _validateTitle: (data, errors) ->
      return errors if _.contains(@model.frozenAttributes(), "title")

      post_to_sis = data.post_to_sis == '1'
      max_name_length = 256
      if post_to_sis && ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT && data.grading_type != 'not_graded'
        max_name_length = ENV.MAX_NAME_LENGTH

      validationHelper = new SisValidationHelper({
        postToSIS: post_to_sis
        maxNameLength: max_name_length
        name: data.name
        maxNameLengthRequired: ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT
      })

      if !data.name or $.trim(data.name.toString()).length == 0
        errors["name"] = [
          message: I18n.t 'name_is_required', 'Name is required!'
        ]
      else if validationHelper.nameTooLong()
        errors["name"] = [
          message: I18n.t("Name is too long, must be under %{length} characters", length: max_name_length + 1)
        ]
      errors

    _validatePointsPossible: (data, errors) =>
      return errors if _.contains(@model.frozenAttributes(), "points_possible")

      if data.points_possible and isNaN(data.points_possible)
        errors["points_possible"] = [
          message: I18n.t 'points_possible_number', 'Points possible must be a number'
        ]
      errors

    _dueAtHasChanged: (dueAt) =>
      originalDueAt = new Date(@model.dueAt()).getTime()
      newDueAt = new Date(dueAt).getTime()
      originalDueAt != newDueAt

    _validateDueDate: (data, errors) ->
      return errors unless data.due_at

      validRange = ENV.VALID_DATE_RANGE
      data.lock_at = @model.lockAt()
      data.unlock_at = @model.unlockAt()
      data.persisted = !@_dueAtHasChanged(data.due_at)
      dateValidator = new DateValidator(
        date_range: _.extend({}, validRange)
        data: data
        hasGradingPeriods: !!ENV.HAS_GRADING_PERIODS
        gradingPeriods: GradingPeriodsAPI.deserializePeriods(ENV.active_grading_periods)
        userIsAdmin: @currentUserIsAdmin(),
        data
      )
      errs = dateValidator.validateDatetimes()

      return errors if _.isEmpty(errs)

      # need to override default error message to focus only on due date field for quick add/edit
      if errs['lock_at']
        errs['due_at'] = I18n.t('Due date cannot be after lock date')
      if errs['unlock_at']
        errs['due_at'] = I18n.t('Due date cannot be before unlock date')

      errors["due_at"] = [message: errs["due_at"]]
      errors

    roundPointsPossible: (e) ->
      value = $(e.target).val()
      rounded_value = round(numberHelper.parse(value), 2)
      if isNaN(rounded_value)
        return
      else
        $(e.target).val(I18n.n(rounded_value))
