require [
  'jquery'
  'compiled/calendar/CalendarEvent'
  'compiled/calendar/EditEventView'
  'instructure' # until we can fix the more general ajaxPrefilter race condition
], ($, CalendarEvent, EditEventView) ->

  $ ->
    calendarEvent = new CalendarEvent(ENV.CALENDAR_EVENT)
    new EditEventView(model: calendarEvent)
