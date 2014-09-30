# this is responsible for gluing all the calendar parts together into a complete page
# the only thing on the erb page should be `calendarApp.init(<contexts>, <manageContexts>);`
require [
  'jquery',
  'compiled/calendar/Calendar'
  'compiled/calendar/MiniCalendar'
  'compiled/views/calendar/CalendarHeader'
  'compiled/calendar/sidebar'
  'compiled/calendar/EventDataSource'
  'compiled/calendar/UndatedEventsList'
  'compiled/bundles/jquery_ui_menu'
], ($, Calendar, MiniCalendar, CalendarHeader, drawSidebar, EventDataSource, UndatedEventsList) ->
  @eventDataSource = new EventDataSource(ENV.CALENDAR.CONTEXTS)
  @header = new CalendarHeader(
    el: "#calendar_header"
    calendar2Only: ENV.CALENDAR.CAL2_ONLY
    showScheduler: ENV.CALENDAR.SHOW_SCHEDULER
    )
  @calendar = new Calendar(
    "#calendar-app", ENV.CALENDAR.CONTEXTS, ENV.CALENDAR.MANAGE_CONTEXTS, @eventDataSource,
    activateEvent: ENV.CALENDAR.ACTIVE_EVENT
    viewStart:     ENV.CALENDAR.VIEW_START
    showScheduler: ENV.CALENDAR.SHOW_SCHEDULER
    header:        @header
    )
  new MiniCalendar("#minical", @calendar)
  new UndatedEventsList("#undated-events", @eventDataSource, @calendar)
  drawSidebar(ENV.CALENDAR.CONTEXTS, ENV.CALENDAR.SELECTED_CONTEXTS, @eventDataSource)

  keyboardUser = true

  $(".calendar-button").on 'mousedown', (e) =>
    keyboardUser = false
    $(e.target).find(".accessibility-warning").addClass("screenreader-only")

  $(document).on 'keydown', (e) =>
    if e.which == 9 #checking for tab press
      keyboardUser = true

  $(".calendar-button").on "focus", (e) =>
    if keyboardUser
      $(e.target).find(".accessibility-warning").removeClass("screenreader-only")

  $(".calendar-button").on "focusout", (e) =>
    $(e.target).find(".accessibility-warning").addClass("screenreader-only")



  
