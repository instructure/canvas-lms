require [
  'jquery'
  'compiled/calendar/CalendarEvent'
  'compiled/calendar/EditEventView'
], ($, CalendarEvent, EditEventView) ->

  $ ->
    calendarEvent = new CalendarEvent(ENV.CALENDAR_EVENT)
    new EditEventView(model: calendarEvent)
