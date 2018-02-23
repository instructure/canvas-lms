#
# Copyright (C) 2017 - present Instructure, Inc.
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
  'str/htmlEscape'
  '../util/fcUtil'
  '../calendar/commonEventFactory'
  '../views/ValidatedFormView'
  'jst/calendar/editPlannerNote'
  'jst/EmptyDialogFormWrapper'
  '../util/coupleTimeFields'
  'jsx/shared/helpers/datePickerFormat'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jquery.instructure_misc_helpers'
  'vendor/date'
  '../calendar/fcMomentHandlebarsHelpers'
], (I18n, $, _, tz, htmlEscape, fcUtil, commonEventFactory, ValidatedFormView, editPlannerNoteTemplate, wrapper, coupleTimeFields, datePickerFormat) ->

  class EditPlannerNoteDetails extends ValidatedFormView

    events: _.extend {}, @::events,
      'click .save_note': 'submitNote'
      'change .context_id': 'contextChange'

    template: editPlannerNoteTemplate
    wrapper: wrapper

    initialize: (selector, @event, @contextChangeCB, @closeCB) ->
      super(
        title: @event.title
        contexts: @event.possibleContexts()
        date: @event.startDate()
        details: htmlEscape(@event.description)
      )
      @currentContextInfo = null

      $(selector).append @.render().el

      @setupTimeAndDatePickers()
      @$el.find("select.context_id").triggerHandler('change', false)

      # show context select if the event allows moving between calendars
      if @event.can_change_context
        @setContext(@event.object.context_code) unless @event.isNewEvent()
      else
        @$el.find(".context_select").hide()

      @model = @event

    submitNote: (e) =>
      data = @getFormData()
      if @event.isNewEvent()
        data.contextInfo = @event.contextInfo
        data.context_code = @event.contextInfo.asset_string
        @model = commonEventFactory(data, @event.possibleContexts())
      else if @event.can_change_context && data.context_code != @event.object.context_code
        # need to update @event so it is cached in the right calendar (aka context_code)
        @event.old_context_code = @event.object.context_code
        @event.removeClass "group_#{@event.old_context_code}"
        @event.object.context_code = data.context_code
        @event.contextInfo = @contextInfoForCode(data.context_code)

      @submit(e)

    contextInfoForCode: (code) ->
      for context in @event.possibleContexts()
        if context.asset_string == code
          return context
      return null

    activate: () =>
      @$el.find("select.context_id").change()

    setContext: (newContext) =>
      @$el.find("select.context_id").val(newContext).triggerHandler('change', false)

    contextChange: (jsEvent, propagate) =>
      context = $(jsEvent.target).val()
      @currentContextInfo = @contextInfoForCode(context)
      @event.contextInfo = @currentContextInfo
      if @currentContextInfo == null then return

      if propagate != false
        @contextChangeCB(context)

      # TODO: when we can create planner notes from the calendar
      # # Update the edit and more option urls
      # moreOptionsHref = null
      # if @event.isNewEvent()
      #   moreOptionsHref = @currentContextInfo.new_planner_note_url
      # else
      #   moreOptionsHref = @event.fullDetailsURL() + '/edit'
      # @$el.find(".more_options_link").attr 'href', moreOptionsHref

    setupTimeAndDatePickers: () =>
      # select the appropriate fields
      $date = @$el.find(".date_field")
      # $start = @$el.find(".time_field.start_time")
      # $end = @$el.find(".time_field.end_time")

      # set them up as appropriate variants of datetime_field
      $date.datetime_field({ datepicker: { dateFormat: datePickerFormat(if @event.allDay then I18n.t('#date.formats.medium_with_weekday') else I18n.t('#date.formats.full_with_weekday')) } })
      # $start.time_field()
      # $end.time_field()

      # fill initial values of each field according to @event
      start = fcUtil.unwrap(@event.startDate())
      # end = fcUtil.unwrap(@event.endDate())

      $date.data('instance', start)
      # $start.data('instance').setTime(if @event.allDay then null else start)
      # $end.data('instance').setTime(if @event.allDay then null else end)
      #
      # # couple start and end times so that end time will never precede start
      # coupleTimeFields($start, $end, $date)

    getFormData: =>
      data = super

      params = {
        'title': data.title
        'todo_date': if data.date then data.date.toISOString() else ''
        'details': data.details
        'id': @event.object.id
        'type': 'planner_note'
        'context_code': data.context_code
      }
      if data.context_code.match(/^course_/)
        # is in a course's calendar
        params.context_type = 'Course'
        params.course_id = data.context_code.replace('course_', '')
      else
        # is in the user's calendar
        if !@event.isNewEvent()
          params.course_id = ""
        params.user_id = data.context_code.replace('user_', '')

      params

    onSaveSuccess: =>
      @closeCB()

    onSaveFail: (xhr) =>
      @disableWhileLoadingOpts = {}
      super(xhr)

    validateBeforeSave: (data, errors) ->
      errors = @_validateTitle data, errors
      errors = @_validateDate data, errors
      errors

    _validateTitle: (data, errors) ->
      if !data.title or $.trim(data.title.toString()).length == 0
        errors.title = [
          message: I18n.t 'Title is required!'
        ]
      errors

    _validateDate: (data, errors) ->
      if !data.todo_date or $.trim(data.todo_date.toString()).length == 0
        errors.date = [
          message: I18n.t 'Date is required!'
        ]
      errors
