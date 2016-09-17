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
  'jsx/calendar/scheduler/store/configureStore'
  'compiled/jquery.kylemenu'
], ($, Calendar, MiniCalendar, CalendarHeader, drawSidebar, EventDataSource, UndatedEventsList, configureSchedulerStore) ->
  @eventDataSource = new EventDataSource(ENV.CALENDAR.CONTEXTS)

  @schedulerStore = if ENV.CALENDAR.BETTER_SCHEDULER then configureSchedulerStore() else null

  console.log(@schedulerStore?.getState())


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
    userId:        ENV.current_user_id
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

  $(".rs-section .accessibility-warning").on "focus", (e) =>
    $(e.target).removeClass("screenreader-only")

  $(".rs-section .accessibility-warning").on "focusout", (e) =>
    $(e.target).addClass("screenreader-only")
