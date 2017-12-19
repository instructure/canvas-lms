#
# Copyright (C) 2012 - present Instructure, Inc.
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
  'i18n!calendar'
  'jquery'
  'underscore'
  'timezone'
  '../util/fcUtil'
  '../util/natcompare'
  '../calendar/commonEventFactory'
  '../views/ValidatedFormView'
  '../calendar/CommonEvent.CalendarEvent'
  '../util/SisValidationHelper'
  'jst/calendar/editAssignment'
  'jst/calendar/editAssignmentOverride'
  'jst/EmptyDialogFormWrapper'
  'jst/calendar/genericSelectOptions'
  'jsx/shared/helpers/datePickerFormat'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jquery.instructure_misc_helpers'
  '../calendar/fcMomentHandlebarsHelpers'
], (I18n, $, _, tz, fcUtil, natcompare, commonEventFactory, ValidatedFormView,
    CalendarEvent, SisValidationHelper, editAssignmentTemplate,
    editAssignmentOverrideTemplate, wrapper, genericSelectOptionsTemplate,
    datePickerFormat) ->

  class EditAssignmentDetailsRewrite extends ValidatedFormView

    defaults:
      width: 440
      height: 384

    events: _.extend {}, @::events,
      'click .save_assignment': 'submitAssignment'
      'click .more_options_link': 'moreOptions'
      'change .context_id': 'contextChange'

    template: editAssignmentTemplate
    wrapper: wrapper

    @optionProperty 'assignmentGroup'

    initialize: (selector, @event, @contextChangeCB, @closeCB) ->
      super(
        title: @event.title
        contexts: @event.possibleContexts()
        date: @event.startDate()
        postToSISEnabled: ENV.POST_TO_SIS
        postToSISName: ENV.SIS_NAME
        postToSIS: @event.assignment.post_to_sis if @event.eventType == 'assignment'
        datePickerFormat: if @event.allDay then 'medium_with_weekday' else 'full_with_weekday'
      )
      @currentContextInfo = null
      @.template = editAssignmentOverrideTemplate if @event.override

      $(selector).append @.render().el

      @setupTimeAndDatePickers()
      @$el.find("select.context_id").triggerHandler('change', false)

      @model ?= @generateNewEvent()

      if !@event.isNewEvent()
        @$el.find(".context_select").hide()
        @$el.attr('method', 'PUT')
        @$el.attr('action', $.replaceTags(@event.contextInfo.assignment_url, 'id', @event.object.id))

    setContext: (newContext) =>
      @$el.find("select.context_id").val(newContext).triggerHandler('change', false)

    contextInfoForCode: (code) ->
      for context in @event.possibleContexts()
        if context.asset_string == code
          return context
      return null

    activate: () =>
      @$el.find("select.context_id").change()
      if @event.assignment?.assignment_group_id
        @$el.find(".assignment_group_select .assignment_group").val(@event.assignment.assignment_group_id)

    moreOptions: (jsEvent) =>
      jsEvent.preventDefault()
      pieces = $(jsEvent.target).attr('href').split("#")
      data = @$el.getFormData( object_name: 'assignment' )
      params = {}
      params['title'] = data.name if data.name
      if data.due_at and @$el.find(".datetime_field").data('unfudged-date')
          params['due_at'] = @$el.find(".datetime_field").data('unfudged-date').toISOString()

      if data.assignment_group_id then params['assignment_group_id'] = data.assignment_group_id
      params['return_to'] = window.location.href
      pieces[0] += "?" + $.param(params)
      window.location.href = pieces.join("#")

    setContext: (newContext) =>
      @$el.find("select.context_id").val(newContext).triggerHandler('change', false)

    contextChange: (jsEvent, propagate) =>
      return if @ignoreContextChange

      context = $(jsEvent.target).val()
      @currentContextInfo = @contextInfoForCode(context)
      @event.contextInfo = @currentContextInfo
      if @currentContextInfo == null then return

      if propagate != false
        @contextChangeCB(context)

      # TODO: support adding a new assignment group from this select box
      assignmentGroupsSelectOptionsInfo =
        collection: @currentContextInfo.assignment_groups.sort(natcompare.byKey('name'))
      @$el.find(".assignment_group").html(genericSelectOptionsTemplate(assignmentGroupsSelectOptionsInfo))

      # Update the edit and more options links with the new context
      @$el.attr('action', @currentContextInfo.create_assignment_url)
      moreOptionsUrl = if @event.assignment
                           "#{@event.assignment.html_url}/edit"
                         else
                           @currentContextInfo.new_assignment_url
      @$el.find(".more_options_link").attr('href', moreOptionsUrl)

    setupTimeAndDatePickers: () =>
      $field = @$el.find(".datetime_field")
      $field.datetime_field({ datepicker: { dateFormat: datePickerFormat(if @event.allDay then I18n.t('#date.formats.medium_with_weekday') else I18n.t('#date.formats.full_with_weekday')) } })

    generateNewEvent: ->
      commonEventFactory({}, [])

    submitAssignment: (e) =>
      e.preventDefault()
      data = @getFormData()
      @disableWhileLoadingOpts = {buttons: ['.save_assignment']}
      if data.assignment?
        @submitRegularAssignment(e, data.assignment)
      else
        @submitOverride(e, data.assignment_override)

    unfudgedDate: (date) ->
      unfudged = $.unfudgeDateForProfileTimezone(date)
      if unfudged then unfudged.toISOString() else ""

    getFormData: =>
      data = super
      if data.assignment?
        data.assignment.due_at = @unfudgedDate(data.assignment.due_at)
      else
        data.assignment_override.due_at = @unfudgedDate(data.assignment_override.due_at)

      return data

    submitRegularAssignment: (event, data) ->
      data.due_at = @unfudgedDate(data.due_at)

      if @event.isNewEvent()
        data.context_code = $(@$el).find(".context_id").val()
        @model = commonEventFactory(data, @event.possibleContexts())
        @submit(event)
      else
        @event.title = data.title
        @event.start = data.due_at # fudged
        @model = @event
        @submit(event)

    submitOverride: (event, data) ->
      @event.start = data.due_at # fudged
      data.due_at = @unfudgedDate(data.due_at)
      @model = @event
      @submit(event)

    onSaveSuccess: =>
      @closeCB()

    onSaveFail: (xhr) =>
      @disableWhileLoadingOpts = {}
      super(xhr)

    validateBeforeSave: (data, errors) ->
      if data.assignment?
        data = data.assignment
        errors = @_validateTitle data, errors
      else
        data = data.assignment_override
      errors = @_validateDueDate data, errors
      errors

    _validateTitle: (data, errors) ->
      post_to_sis = data.post_to_sis == '1'
      max_name_length = 256
      max_name_length_required = ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT

      if post_to_sis && max_name_length_required
        max_name_length = ENV.MAX_NAME_LENGTH

      validationHelper = new SisValidationHelper({
        postToSIS: post_to_sis
        maxNameLength: max_name_length
        name: data.name
        maxNameLengthRequired: max_name_length_required
      })

      if !data.name or $.trim(data.name.toString()).length == 0
        errors["assignment[name]"] = [
          message: I18n.t 'name_is_required', 'Name is required!'
        ]
      else if validationHelper.nameTooLong()
        errors["assignment[name]"] = [
          message: I18n.t("Name is too long, must be under %{length} characters",
                          length: max_name_length + 1)
        ]
      errors

    _validateDueDate: (data, errors) ->
      post_to_sis = data.post_to_sis == '1'
      return errors unless post_to_sis

      validationHelper = new SisValidationHelper({
        postToSIS: post_to_sis
        dueDateRequired: ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT
        dueDate: data.due_at
      })

      error_tag = if data.name? then "assignment[due_at]" else "assignment_override[due_at]"
      if validationHelper.dueDateMissing()
        errors[error_tag] = [
          message: I18n.t('Due Date is required!')
        ]
      errors
