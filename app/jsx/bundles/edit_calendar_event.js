import $ from 'jquery'
import CalendarEvent from 'compiled/calendar/CalendarEvent'
import EditEventView from 'compiled/calendar/EditEventView'
import 'instructure'

$(() => {
  const calendarEvent = new CalendarEvent(ENV.CALENDAR_EVENT)
  new EditEventView({model: calendarEvent})
})
