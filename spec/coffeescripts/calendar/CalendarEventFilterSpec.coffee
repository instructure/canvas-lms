define [
  'compiled/calendar/CommonEvent'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/CalendarEventFilter'
  'helpers/fakeENV'
], (CommonEvent, commonEventFactory, CalendarEventFilter, fakeENV) ->

  test_events = (can_edit, child_events_count, available_slots = 1, reserved = false) ->
    [
      commonEventFactory
        id: "1"
        title: "Normal Event"
        start_at: "2016-08-29T11:00:00Z"
        end_at: "2016-08-29T11:30:00Z"
        workflow_state: "active"
        type: "event"
        description: ""
        child_events_count: 0
        effective_context_code: "course_1"
        context_code: "course_1"
        all_context_codes: "course_1"
        parent_event_id: null
        hidden: false
        child_events: []
        url: "http://example.org/api/v1/calendar_events/1"
      ,
        [{asset_string: 'course_1', id: 1}]
    ,
      commonEventFactory
        id: "20"
        title: "Appointment Slot"
        start_at: "2016-08-29T11:00:00Z"
        end_at: "2016-08-29T11:30:00Z"
        workflow_state: "active"
        type: "event"
        description: ""
        child_events_count: child_events_count
        effective_context_code: "course_1"
        context_code: "course_1"
        all_context_codes: "course_1,course_2"
        parent_event_id: null
        hidden: false
        appointment_group_id: "2"
        appointment_group_url: "http://example.org/api/v1/appointment_groups/2"
        reserve_url: "http://example.org/api/v1/calendar_events/20/reservations/%7B%7B%20id%20%7D%7D"
        child_events: []
        url: "http://example.org/api/v1/calendar_events/20"
        available_slots: available_slots
        reserved: reserved
      ,
        [{asset_string: 'course_1', id: 1, can_create_calendar_events: can_edit}]
    ]

  module "CalendarEventFilter",
    setup: ->
    teardown: ->

  test 'CalendarEventFilter: hides appointment slots and grays nothing when schedulerState is not provided', ->
    filteredEvents = CalendarEventFilter(null, test_events(false, 0))
    equal filteredEvents.length, 1
    equal filteredEvents[0].id, 'calendar_event_1'
    equal filteredEvents[0].className.indexOf('grayed'), -1

  test 'CalendarEventFilter: hides appointment slots and grays nothing when not in find-appointment mode', ->
    filteredEvents = CalendarEventFilter(null, test_events(false, 0), {inFindAppointmentMode: false, selectedCourse: null})
    equal filteredEvents.length, 1
    equal filteredEvents[0].id, 'calendar_event_1'
    equal filteredEvents[0].className.indexOf('grayed'), -1

  test 'CalendarEventFilter: grays non-appointment events when in find-appointment mode', ->
    filteredEvents = CalendarEventFilter(null, test_events(false, 0), {inFindAppointmentMode: true, selectedCourse: {id: 789, asset_string: 'course_789'}})
    equal filteredEvents.length, 1
    equal filteredEvents[0].id, 'calendar_event_1'
    notEqual filteredEvents[0].className.indexOf('grayed'), -1

  test 'CalendarEventFilter: unhides appointment slots when in find-appointment mode and the course is selected', ->
    filteredEvents = CalendarEventFilter(null, test_events(false, 0), {inFindAppointmentMode: true, selectedCourse: {id: 1, asset_string: 'course_1'}})
    equal filteredEvents.length, 2
    equal filteredEvents[0].id, 'calendar_event_1'
    notEqual filteredEvents[0].className.indexOf('grayed'), -1
    equal filteredEvents[1].id, 'calendar_event_20'
    equal filteredEvents[1].className.indexOf('grayed'), -1

  test 'CalendarEventFilter: grays appointment events for created appointments that are unreserved in appointmentMode', ->
    filteredEvents = CalendarEventFilter(null, test_events(true, 0), {inFindAppointmentMode: false, selectedCourse: {id: 789, asset_string: 'course_789'}})
    equal filteredEvents.length, 2
    equal filteredEvents[0].id, 'calendar_event_1'
    equal filteredEvents[0].className.indexOf('grayed'), -1
    notEqual filteredEvents[1].className.indexOf('grayed'), -1

  test 'CalendarEventFilter: does not gray appointment events for created appointments that are reserved without appointmentMode', ->
    filteredEvents = CalendarEventFilter(null, test_events(true, 2), {selectedCourse: {id: 789, asset_string: 'course_789'}})
    equal filteredEvents.length, 2
    equal filteredEvents[0].id, 'calendar_event_1'
    equal filteredEvents[0].className.indexOf('grayed'), -1
    equal filteredEvents[1].className.indexOf('grayed'), -1

  test 'CalendarEventFilter: hides filled slots', ->
    events = test_events(false, 0, 0)
    filteredEvents = CalendarEventFilter(null, events, {inFindAppointmentMode: true, selectedCourse: {id: 1, asset_string: 'course_1'}})
    equal filteredEvents.length, 1
    equal filteredEvents[0].id, 'calendar_event_1'

  test 'CalendarEventFilter: hides already-reserved appointments that still have available slots', ->
    events = test_events(false, 0, 1, true)
    filteredEvents = CalendarEventFilter(null, events, {inFindAppointmentMode: true, selectedCourse: {id: 1, asset_string: 'course_1'}})
    equal filteredEvents.length, 1
    equal filteredEvents[0].id, 'calendar_event_1'

  test 'CalendarEventFilter: With Viewing Group: do not include events that are actual appointment events', ->
    fakeENV.setup({CALENDAR: {BETTER_SCHEDULER: false}})
    events = test_events(true, 0, 1, false)
    events[1].calendarEvent.reserve_url = null
    filteredEvents = CalendarEventFilter({id: "2"}, events, {})
    equal filteredEvents.length, 1
    equal filteredEvents[0].id, 'calendar_event_1', 'does not include calendar_event_20'
    fakeENV.teardown()

  test 'CalendarEventFilter: With Viewing Group: include appointment groups for different viewing groups that are filled', ->
    fakeENV.setup({CALENDAR: {BETTER_SCHEDULER: false}})
    events = test_events(true, 0, 1, true)
    events[1].calendarEvent.reserve_url = null
    filteredEvents = CalendarEventFilter({id: "25"}, events, {})
    equal filteredEvents.length, 2
    fakeENV.teardown()

  test 'CalendarEventFilter: With Viewing Group: always follow the normal calendar view flow, if BETTER_SCHEDULER is enabled', ->
    fakeENV.setup({CALENDAR: {BETTER_SCHEDULER: true}})
    events = test_events(false, 0, 1, true)
    filteredEvents = CalendarEventFilter(true, events, {})
    equal filteredEvents.length, 1
    equal filteredEvents[0].id, 'calendar_event_1'
    fakeENV.teardown()
