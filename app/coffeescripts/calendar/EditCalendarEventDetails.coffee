define [
  'jquery'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/TimeBlockList'
  'jst/calendar/editCalendarEvent'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jquery.instructure_misc_helpers'
  'vendor/date'
], ($, commonEventFactory, TimeBlockList, editCalendarEventTemplate) ->

  class EditCalendarEventDetails
    constructor: (selector, @event, @contextChangeCB, @closeCB) ->
      @currentContextInfo = null
      @form = $(editCalendarEventTemplate({
        title: @event.title
        contexts: @event.possibleContexts()
        lockedTitle: @event.lockedTitle
      }))
      $(selector).append @form

      @setupTimeAndDatePickers()

      @form.submit @formSubmit
      @form.find(".more_options_link").click @moreOptionsClick
      @form.find("select.context_id").change @contextChange
      @form.find("select.context_id").triggerHandler('change', false)

      # Hide the context selector completely if this is an existing event, since it can't be changed.
      if !@event.isNewEvent()
        @form.find(".context_select").hide()

    contextInfoForCode: (code) ->
      for context in @event.possibleContexts()
        if context.asset_string == code
          return context
      return null

    activate: () =>
      @form.find("select.context_id").change()

    moreOptionsClick: (jsEvent) =>
      return if @event.object.parent_event_id
      jsEvent.preventDefault()
      pieces = $(jsEvent.target).attr('href').split("#")
      data = $("#edit_calendar_event_form").getFormData(object_name: 'calendar_event')
      params = {}
      if data.title then params['title'] = data.title
      if data.date
        params['start_at'] = "#{data.date} #{data.start_time || ''}"
        params['end_at'] = "#{data.date} #{data.end_time || ''}"
      params['return_to'] = window.location.href
      pieces[0] += "?" + $.param(params)
      window.location.href = pieces.join("#")

    setContext: (newContext) =>
      @form.find("select.context_id").val(newContext).triggerHandler('change', false)

    contextChange: (jsEvent, propagate) =>
      context = $(jsEvent.target).val()
      @currentContextInfo = @contextInfoForCode(context)
      @event.contextInfo = @currentContextInfo
      if @currentContextInfo == null then return

      if propagate != false
        @contextChangeCB(context)

      # Update the edit and more option urls
      moreOptionsHref = null
      if @event.isNewEvent()
        moreOptionsHref = @currentContextInfo.new_calendar_event_url
      else
        moreOptionsHref = @event.fullDetailsURL() + '/edit'
      @form.find(".more_options_link").attr 'href', moreOptionsHref

    setupTimeAndDatePickers: () =>
      @form.find(".date_field").date_field()
      # TODO: Refactor this logic that forms a relationship between two time fields into a module
      @form.find(".time_field").time_field().
        blur (jsEvent) =>
          start_time = @form.find(".time_field.start_time").next(".datetime_suggest").text()
          if @form.find(".time_field.start_time").next(".datetime_suggest").hasClass('invalid_datetime')
            start_time = null
          start_time ?= @form.find(".time_field.start_time").val()
          end_time = @form.find(".time_field.end_time").next(".datetime_suggest").text()
          if @form.find(".time_field.end_time").next(".datetime_suggest").hasClass('invalid_datetime')
            end_time = null
          end_time ?= @form.find(".time_field.end_time").val()

          startDate = Date.parse(start_time)
          endDate = Date.parse(end_time)

          startDate = startDate || endDate
          endDate = endDate || startDate

          if $(jsEvent.target).hasClass('end_time')
            if startDate > endDate then startDate = endDate
          else
            if endDate < startDate then endDate = startDate
          if startDate
            @form.find(".time_field.start_time").val(startDate.toString('h:mmtt').toLowerCase())
          if endDate
            @form.find(".time_field.end_time").val(endDate.toString('h:mmtt').toLowerCase())

      startDate = @event.startDate()
      endDate = @event.endDate()

      if !@event.allDay
        if startDate
          @form.find(".time_field.start_time").val(startDate.toString('h:mmtt')).change().blur()
        if endDate
          @form.find(".time_field.end_time").val(endDate.toString('h:mmtt')).change().blur()

      if startDate
        @form.find(".date_field").val(startDate.toString('MMM d, yyyy')).change()

    formSubmit: (jsEvent) =>
      jsEvent.preventDefault()

      data = @form.getFormData({ object_name: 'calendar_event' })
      if data.date
        start_date = Date.parse "#{data.date} #{data.start_time}"
        data.end_time ?= data.start_time
        end_date = Date.parse "#{data.date} #{data.end_time}"
      else
        start_date = null
        end_date = null

      params = {
        'calendar_event[title]': data.title ? @event.title
        'calendar_event[start_at]': if start_date then $.unfudgeDateForProfileTimezone(start_date).toISOString() else ''
        'calendar_event[end_at]': if end_date then $.unfudgeDateForProfileTimezone(end_date).toISOString() else ''
      }

      if @event.isNewEvent()
        params['calendar_event[context_code]'] = data.context_code
        objectData =
          calendar_event:
            title: params['calendar_event[title]']
            start_at: if start_date then start_date.toISOString() else null
            end_at: if end_date then end_date.toISOString() else null
            context_code: @form.find(".context_id").val()
        newEvent = commonEventFactory(objectData, @event.possibleContexts())
        newEvent.save(params)
      else
        @event.title = params['calendar_event[title]']
        @event.start = start_date
        @event.end = end_date
        @event.save(params)

      @closeCB()
