define [
  'i18n!calendar'
  'compiled/util/semanticDateRange'
  'compiled/calendar/CommonEvent'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, semanticDateRange, CommonEvent) ->

  deleteConfirmation = I18n.t('prompts.delete_event', "Are you sure you want to delete this event?")

  class CalendarEvent extends CommonEvent
    constructor: (data, contextInfo, actualContextInfo) ->
      super data, contextInfo, actualContextInfo
      @eventType = 'calendar_event'
      @deleteConfirmation = deleteConfirmation
      @deleteURL = contextInfo.calendar_event_url

    copyDataFromObject: (data) =>
      data = data.calendar_event if data.calendar_event
      @object = @calendarEvent = data
      @id = "calendar_event_#{data.id}" if data.id
      @title = data.title || "Untitled"
      @start = if data.start_at then $.parseFromISO(data.start_at).time else null
      @end = if data.end_at then $.parseFromISO(data.end_at).time else null
      @allDay = data.all_day
      @editable = true
      @lockedTitle = @object.parent_event_id?
      @description = data.description
      @addClass "group_#{@contextCode()}"
      if @isAppointmentGroupEvent()
        @addClass "scheduler-event"
        if @object.reserved
          @addClass "scheduler-reserved"
        if @object.available_slots == 0
          @addClass "scheduler-full"
        if @object.available_slots == undefined || @object.available_slots > 0
          @addClass "scheduler-available"
        @editable = false

      super

    startDate: () ->
      if @calendarEvent.start_at then $.parseFromISO(@calendarEvent.start_at).time else null

    endDate: () ->
      if @calendarEvent.end_at then $.parseFromISO(@calendarEvent.end_at).time else null

    fullDetailsURL: () ->
      if @isAppointmentGroupEvent()
        "/appointment_groups/#{@object.appointment_group_id}"
      else
        $.replaceTags(@contextInfo.calendar_event_url, 'id', @calendarEvent.parent_event_id ? @calendarEvent.id)

    displayTimeString: () ->
        if @calendarEvent.all_day
          date = this.startDate()
          "<time datetime='#{date.toISOString()}'>#{$.dateString(date)}</time>"
        else
          semanticDateRange(@calendarEvent.start_at, @calendarEvent.end_at)

    saveDates: (success, error) =>
      @save {
        'calendar_event[start_at]': if @start then $.dateToISO8601UTC($.unfudgeDateForProfileTimezone(@start)) else ''
        'calendar_event[end_at]': if @end then $.dateToISO8601UTC($.unfudgeDateForProfileTimezone(@end)) else ''
      }, success, error

    methodAndURLForSave: () ->
      if @isNewEvent()
        method = 'POST'
        url = '/api/v1/calendar_events'
      else
        method = 'PUT'
        url = @calendarEvent.url
      [ method, url ]
