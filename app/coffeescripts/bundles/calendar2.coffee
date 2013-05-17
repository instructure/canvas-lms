# this is responsible for gluing all the calendar parts together into a complete page
# the only thing on the erb page should be `calendarApp.init(<contexts>, <manageContexts>);`
require [
  'jquery',
  'compiled/calendar/Calendar'
  'compiled/calendar/MiniCalendar'
  'compiled/calendar/sidebar'
  'compiled/calendar/EventDataSource'
  'compiled/calendar/UndatedEventsList'
  'compiled/bundles/jquery_ui_menu'
], ($, Calendar, MiniCalendar, drawSidebar, EventDataSource, UndatedEventsList) ->
  @eventDataSource = new EventDataSource(ENV.CALENDAR.CONTEXTS)
  @calendar = new Calendar(
    "#calendar-app", ENV.CALENDAR.CONTEXTS, ENV.CALENDAR.MANAGE_CONTEXTS, @eventDataSource, 
    activateEvent: ENV.CALENDAR.ACTIVE_EVENT, 
    viewStart: ENV.CALENDAR.VIEW_START, 
    calendar2Only: ENV.CALENDAR.CAL2_ONLY, 
    showScheduler: ENV.CALENDAR.SHOW_SCHEDULER)
  new MiniCalendar("#minical", @calendar)
  new UndatedEventsList("#undated-events", @eventDataSource, @calendar)
  drawSidebar(ENV.CALENDAR.CONTEXTS, ENV.CALENDAR.SELECTED_CONTEXTS, @eventDataSource)
