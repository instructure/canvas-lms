define [
  'i18n!calendar'
  'jquery'
  'compiled/util/fcUtil'
  'compiled/util/semanticDateRange'
  'compiled/calendar/CommonEvent'
  'compiled/util/natcompare'
  'jquery.instructure_date_and_time'
  'jquery.instructure_misc_helpers'
], (I18n, $, fcUtil, semanticDateRange, CommonEvent, natcompare) ->

  deleteConfirmation = I18n.t('prompts.delete_event', "Are you sure you want to delete this event?")

  class CalendarEvent extends CommonEvent
    constructor: (data, contextInfo, actualContextInfo) ->
      super data, contextInfo, actualContextInfo
      @eventType = 'calendar_event'
      @appointmentGroupEventStatus = @calculateAppointmentGroupEventStatus()
      @reservedUsers = @getListOfReservedPeople(5).join('; ')
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

    editGroupURL: () ->
      if @isAppointmentGroupEvent()
        "/appointment_groups/#{@object.appointment_group_id}/edit"
      else
        "#"

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
        status = I18n.t('%{availableSlots} Available', {availableSlots: I18n.n(@calendarEvent.available_slots)})
      if @calendarEvent.available_slots > 0 && @calendarEvent.child_events?.length
        status = I18n.t('%{availableSlots} more available', {availableSlots: I18n.n(@calendarEvent.available_slots)})
      if @calendarEvent.available_slots == 0
        status = I18n.t('Filled')
      if @consideredReserved()
        status = I18n.t('Reserved')

      status

    # Returns an array of sortable user names that have reserved this slot optionally
    # limited to a certain number.  The list is returned sorted naturally.  If there
    # are more than the limit 'and more...' will be appended.
    getListOfReservedPeople: (limit) ->
      return [] unless @calendarEvent.child_events?.length
      names = @calendarEvent.child_events?.map((child_event) -> child_event.user?.sortable_name)
      sorted = names.sort((a, b) => natcompare.strings(a, b))
      if (limit)
        sorted = sorted.slice(0, limit)
      if @calendarEvent.child_events?.length > limit
        sorted.push(I18n.t('and more...'))
      sorted

    # True if the slot should be considered reserved
    consideredReserved: -> @calendarEvent.reserved == true || (@calendarEvent.appointment_group_url && @calendarEvent.parent_event_id)
