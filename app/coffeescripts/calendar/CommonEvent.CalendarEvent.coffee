define [
  'i18n!calendar'
  'jquery'
  'compiled/util/fcUtil'
  'compiled/util/semanticDateRange'
  'compiled/calendar/CommonEvent'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, $, fcUtil, semanticDateRange, CommonEvent) ->

  deleteConfirmation = I18n.t('prompts.delete_event', "Are you sure you want to delete this event?")

  class CalendarEvent extends CommonEvent
    constructor: (data, contextInfo, actualContextInfo) ->
      super data, contextInfo, actualContextInfo
      @eventType = 'calendar_event'
      @appointmentGroupEventStatus = @calculateAppointmentGroupEventStatus()
      @deleteConfirmation = deleteConfirmation
      @deleteURL = contextInfo.calendar_event_url

    copyDataFromObject: (data) ->
      data = data.calendar_event if data.calendar_event
      @object = @calendarEvent = data
      @id = "calendar_event_#{data.id}" if data.id
      @title = data.title || "Untitled"
      @comments = data.comments
      @location_name = data.location_name
      @location_address = data.location_address
      @start = @parseStartDate()
      @end = @parseEndDate()
      # see originalStart in super's copyDataFromObject
      @originalEndDate = fcUtil.clone(@end) if @end
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

    endDate: () -> @originalEndDate

    parseStartDate: () ->
      fcUtil.wrap(@calendarEvent.start_at) if @calendarEvent.start_at

    parseEndDate: () ->
      fcUtil.wrap(@calendarEvent.end_at) if @calendarEvent.end_at

    fullDetailsURL: () ->
      if @isAppointmentGroupEvent()
        "/appointment_groups/#{@object.appointment_group_id}"
      else
        $.replaceTags(@contextInfo.calendar_event_url, 'id', @calendarEvent.parent_event_id ? @calendarEvent.id)

    displayTimeString: () ->
        if @calendarEvent.all_day
          @formatTime(@startDate(), true)
        else
          semanticDateRange(@calendarEvent.start_at, @calendarEvent.end_at)

    readableType: () ->
      @readableTypes['event']

    saveDates: (success, error) ->
      @save {
        'calendar_event[start_at]': if @start then fcUtil.unwrap(@start).toISOString() else ''
        'calendar_event[end_at]': if @end then fcUtil.unwrap(@end).toISOString() else ''
        'calendar_event[all_day]': @allDay
      }, success, error

    methodAndURLForSave: () ->
      if @isNewEvent()
        method = 'POST'
        url = '/api/v1/calendar_events'
      else
        method = 'PUT'
        url = @calendarEvent.url
      [ method, url ]

    calculateAppointmentGroupEventStatus: ->
      status = I18n.t 'Available'

      if @calendarEvent.available_slots > 0
        status = I18n.t('%{availableSlots} Available', {availableSlots: @calendarEvent.available_slots})
      if @calendarEvent.available_slots == 0
        status = I18n.t('Filled')
      if @calendarEvent.reserved == true
        status = I18n.t('Reserved')

      status
