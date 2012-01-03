# this is responsible for gluing all the calendar parts together into a complete page
# the only thing on the erb page should be `calendarApp.init(<contexts>, <manageContexts>);`
define 'compiled/calendar/calendarApp', [
  "compiled/calendar/Calendar",
  "compiled/calendar/MiniCalendar",
  "compiled/calendar/sidebar",
  "compiled/calendar/EventDataSource",
  "compiled/calendar/UndatedEventsList"
], (Calendar, MiniCalendar, drawSidebar, EventDataSource, UndatedEventsList) ->
  calendarApp = 
    init: (@contexts, @manageContexts) ->
      @eventDataSource = new EventDataSource(@contexts)
      @calendar = new Calendar("#calendar-app", @contexts, @manageContexts, @eventDataSource)
      new MiniCalendar("#minical", @calendar)
      new UndatedEventsList("#undated-events", @eventDataSource)
      drawSidebar(@contexts, @eventDataSource)
