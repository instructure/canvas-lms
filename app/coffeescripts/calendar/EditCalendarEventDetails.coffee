define [
  'i18n!calendar'
  'jquery'
  'underscore'
  'timezone'
  'compiled/util/fcUtil'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/TimeBlockList'
  'jst/calendar/editCalendarEvent'
  'compiled/util/coupleTimeFields'
  'jsx/shared/helpers/datePickerFormat'
  'jquery.instructure_date_and_time'
  'jquery.instructure_forms'
  'jquery.instructure_misc_helpers'
  'vendor/date'
  'compiled/calendar/fcMomentHandlebarsHelpers'
], (I18n, $, _, tz, fcUtil, commonEventFactory, TimeBlockList, editCalendarEventTemplate, coupleTimeFields, datePickerFormat) ->

  class EditCalendarEventDetails
    constructor: (selector, @event, @contextChangeCB, @closeCB) ->
      @currentContextInfo = null
      @$form = $(editCalendarEventTemplate({
        title: @event.title
        contexts: @event.possibleContexts()
        lockedTitle: @event.lockedTitle
        location_name: @event.location_name
        date: @event.startDate()
      }))
      $(selector).append @$form

      @setupTimeAndDatePickers()

      @$form.submit @formSubmit
      @$form.find(".more_options_link").click @moreOptionsClick
      @$form.find("select.context_id").change @contextChange
      @$form.find("#duplicate_event").change @duplicateCheckboxChanged
      @$form.find("select.context_id").triggerHandler('change', false)

      # show context select if the event allows moving between calendars
      if @event.can_change_context
        @setContext(@event.object.context_code) unless @event.isNewEvent()
      else
        @$form.find(".context_select").hide()

      # duplication only works on create
      unless @event.isNewEvent()
        @$form.find(".duplicate_event_row, .duplicate_event_toggle_row").hide()

    contextInfoForCode: (code) ->
      for context in @event.possibleContexts()
        if context.asset_string == code
          return context
      return null

    activate: () =>
      @$form.find("select.context_id").change()

    getFormData: =>
      data = @$form.getFormData(object_name: 'calendar_event')
      data = _.omit(data,
        'date', 'start_time', 'end_time',
        'duplicate', 'duplicate_count', 'duplicate_interval', 'duplicate_frequency', 'append_iterator')

      # check if input box was cleared for explicitly undated
      date = @$form.find('input[name=date]').data('date') if @$form.find('input[name=date]').val()
      if date
        start_time = @$form.find('input[name=start_time]').data('date')
        start_at = date.toString('yyyy-MM-dd')
        start_at += start_time.toString(' HH:mm') if start_time
        data.start_at = tz.parse(start_at)

        end_time = @$form.find('input[name=end_time]').data('date')
        end_at = date.toString('yyyy-MM-dd')
        end_at += end_time.toString(' HH:mm') if end_time
        data.end_at = tz.parse(end_at)

      if duplicate = @$form.find('#duplicate_event').prop('checked')
        data.duplicate = {
          count: @$form.find('#duplicate_count').val()
          interval: @$form.find('#duplicate_interval').val()
          frequency: @$form.find('#duplicate_frequency').val()
          append_iterator: @$form.find('#append_iterator').is(":checked")
        }

      data

    moreOptionsClick: (jsEvent) =>
      return if @event.object.parent_event_id

      jsEvent.preventDefault()
      params = return_to: window.location.href

      data = @getFormData()

      # override parsed input with user input (for 'More Options' only)
      data.start_date = @$form.find('input[name=date]').val()
      if data.start_date
        data.start_date = $.unfudgeDateForProfileTimezone(data.start_date).toISOString()
      data.start_time = @$form.find('input[name=start_time]').val()
      data.end_time = @$form.find('input[name=end_time]').val()

      if data.title then params['title'] = data.title
      if data.location_name then params['location_name'] = data.location_name
      if data.start_date then params['start_date'] = data.start_date
      if data.start_time then params['start_time'] = data.start_time
      if data.end_time then params['end_time'] = data.end_time
      if data.duplicate then params['duplicate'] = data.duplicate

      pieces = $(jsEvent.target).attr('href').split("#")
      pieces[0] += "?" + $.param(params)
      window.location.href = pieces.join("#")

    setContext: (newContext) =>
      @$form.find("select.context_id").val(newContext).triggerHandler('change', false)

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
      @$form.find(".more_options_link").attr 'href', moreOptionsHref

    duplicateCheckboxChanged: (jsEvent, propagate) =>
      @enableDuplicateFields(jsEvent.target.checked)

    enableDuplicateFields: (shouldEnable) =>
      elts = @$form.find(".duplicate_fields").find('input')
      disableValue = !shouldEnable
      elts.prop("disabled", disableValue)
      @$form.find('.duplicate_event_row').toggle(!disableValue)

    setupTimeAndDatePickers: () =>
      # select the appropriate fields
      $date = @$form.find(".date_field")
      $start = @$form.find(".time_field.start_time")
      $end = @$form.find(".time_field.end_time")

      # set them up as appropriate variants of datetime_field
      $date.date_field({ datepicker: { dateFormat: datePickerFormat(I18n.t('#date.formats.medium_with_weekday')) } })
      $start.time_field()
      $end.time_field()

      # fill initial values of each field according to @event
      start = fcUtil.unwrap(@event.startDate())
      end = fcUtil.unwrap(@event.endDate())

      $start.data('instance').setTime(if @event.allDay then null else start)
      $end.data('instance').setTime(if @event.allDay then null else end)

      # couple start and end times so that end time will never precede start
      coupleTimeFields($start, $end, $date)

    formSubmit: (jsEvent) =>
      jsEvent.preventDefault()

      data = @getFormData()
      location_name = data.location_name || ''

      params = {
        'calendar_event[title]': data.title ? @event.title
        'calendar_event[start_at]': if data.start_at then data.start_at.toISOString() else ''
        'calendar_event[end_at]': if data.end_at then data.end_at.toISOString() else ''
        'calendar_event[location_name]': location_name
      }

      params['calendar_event[duplicate]'] = data.duplicate if data.duplicate?

      if @event.isNewEvent()
        params['calendar_event[context_code]'] = data.context_code
        objectData =
          calendar_event:
            title: params['calendar_event[title]']
            start_at: if data.start_at then data.start_at.toISOString() else null
            end_at: if data.end_at then data.end_at.toISOString() else null
            location_name: location_name
            context_code: @$form.find(".context_id").val()
        newEvent = commonEventFactory(objectData, @event.possibleContexts())
        newEvent.save(params)
      else
        @event.title = params['calendar_event[title]']
        # event unfudges/unwraps values when sending to server (so wrap here)
        @event.start = fcUtil.wrap(data.start_at)
        @event.end = fcUtil.wrap(data.end_at)
        @event.location_name = location_name
        if @event.can_change_context && data.context_code != @event.object.context_code
          @event.old_context_code = @event.object.context_code
          @event.removeClass "group_#{@event.old_context_code}"
          @event.object.context_code = data.context_code
          @event.contextInfo = @contextInfoForCode(data.context_code)
          params['calendar_event[context_code]'] = data.context_code
        @event.save(params)

      @closeCB()
