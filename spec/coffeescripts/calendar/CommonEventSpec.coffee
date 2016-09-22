define [
  'compiled/calendar/CommonEvent'
  'compiled/calendar/commonEventFactory'
], (CommonEvent, commonEventFactory) ->
  module "CommonEvent",
    setup: ->
    teardown: ->

  test 'CommonEvent: should prevent assignment-due events from wrapping to the next day', ->
    event = commonEventFactory
      assignment:
        due_at: '2016-02-25T23:30:00Z'
    ,
      ['course_1']
    equal event.end.date(), 26
    equal event.end.hours(), 0
    equal event.end.minutes(), 0

  test 'CommonEvent: should expand assignments to occupy 30 minutes so they are readable', ->
    event = commonEventFactory
      assignment:
        due_at: '2016-02-25T23:59:00Z'
    ,
      ['course_1']
    equal event.start.date(), 25
    equal event.start.hours(), 23
    equal event.start.minutes(), 30
    equal event.end.date(), 26
    equal event.end.hours(), 0
    equal event.end.minutes(), 0

  test 'CommonEvent: should leave events with defined end times alone', ->
    event = commonEventFactory
      title: 'Not an assignment'
      start_at: '2016-02-25T23:30:00Z'
      end_at: '2016-02-26T00:30:00Z'
    ,
      ['course_1']
    equal event.end.date(), 26
    equal event.end.hours(), 0
    equal event.end.minutes(), 30

  test 'CommonEvent: isOnCalendar', ->
    event = commonEventFactory
      title: 'blah',
      start_at: '2016-02-25T23:30:00Z',
      all_context_codes: 'course_1,course_23'
    ,
      ['course_1', 'course_23']

    ok event.isOnCalendar('course_1')
    ok event.isOnCalendar('course_23')
    notOk event.isOnCalendar('course_2')

  test 'commonEventFactory: finds a context for multi-context events', ->
    event = commonEventFactory
      title:"Another Dang Thing"
      start_at:"2016-10-02T10:00:00Z"
      type:"event"
      effective_context_code:"course_2,course_4"
      context_code:"user_2"
      all_context_codes:"course_2,course_4"
      parent_event_id:"172"
      appointment_group_id:"2"
      appointment_group_url:"http://localhost:3000/api/v1/appointment_groups/2"
      own_reservation:true
    ,
      [{asset_string: 'course_2'}]
    notOk event == null
