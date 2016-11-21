define [
  'compiled/calendar/EventDataSource'
  'compiled/util/fcUtil',
  'timezone'
  'vendor/timezone/America/Denver'
], (EventDataSource, fcUtil, tz, denver) ->

  module "EventDataSource: getEvents",
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(denver, 'America/Denver')

      @date1 = fcUtil.wrap('2015-11-01T20:00:00-07:00')
      @date2 = fcUtil.wrap('2015-11-02T20:00:00-07:00')
      @date3 = fcUtil.wrap('2015-11-03T20:00:00-07:00')
      @date4 = fcUtil.wrap('2015-11-04T20:00:00-07:00')

      # create the data source with a couple of recognized contexts. we'll use
      # those same context codes in querying
      @source = new EventDataSource([
        {asset_string: 'course_1'}
        {asset_string: 'course_2'}
      ])
      @contexts = ['course_1', 'course_2']

      # a container for stubbing queries, along with helpers to populate
      # the stubbed results in individual specs and a slot for the most recent
      # query (distilled)
      @server =
        calendarEvents: []
        assignments: []
        lastQuery: null
        reset: ->
          @calendarEvents = []
          @assignments = []
          @lastQuery = null
        addCalendarEvent: (context_code, id, start_at) ->
          @calendarEvents.push
            context_code: context_code
            calendar_event: {id: id, start_at: start_at}
        addAssignment: (context_code, id, due_at) ->
          @assignments.push
            context_code: context_code
            assignment: {id: id, due_at: due_at}

      # stub the fetch method on the source to just use our stubbed query
      # results, and also to record the query made
      @source.startFetch = (requests, dataCB, doneCB, _) =>
        {start_date, end_date, undated} = requests[0][1]
        @server.lastQuery = {start_date, end_date, undated}
        dataCB(@server.calendarEvents, null, type: 'events')
        dataCB(@server.assignments, null, type: 'assignments')
        doneCB()

    teardown: ->
      tz.restore(@snapshot)

  test 'addEventToCache handles cases where the contextCode returns a list', ->
    fakeEvent = {
      contextCode: -> "course_1,course_2",
      id: 42
    }
    @source.addEventToCache(fakeEvent)
    ok(this.source.cache.contexts.course_1.events[42])

  test 'addEventToCache handles the case where contextCode contains context not in the cache', ->
    fakeEvent = {
      contextCode: -> "course_3,course_2",
      id: 42
    }
    @source.addEventToCache(fakeEvent)
    ok(this.source.cache.contexts.course_2.events[42])

  test 'addEventToCache handles cases where the contextCode is a single item', ->
    fakeEvent = {
      contextCode: -> "course_1",
      id: 42
    }
    @source.addEventToCache(fakeEvent)
    ok(this.source.cache.contexts.course_1.events[42])

  test 'overlapping ranges: overlap at start shifts start to end of overlap', ->
    @source.getEvents(@date1, @date2, @contexts, ->)
    @source.getEvents(@date1, @date4, @contexts, ->)
    equal @server.lastQuery.start_date, fcUtil.unwrap(@date2).toISOString()

  test 'overlapping ranges: no overlap at start leaves start alone', ->
    @source.getEvents(@date1, @date2, @contexts, ->)
    @source.getEvents(@date3, @date4, @contexts, ->)
    equal @server.lastQuery.start_date, fcUtil.unwrap(@date3).toISOString()

  test 'overlapping ranges: no overlap at end leaves end alone', ->
    @source.getEvents(@date3, @date4, @contexts, ->)
    @source.getEvents(@date1, @date2, @contexts, ->)
    equal @server.lastQuery.end_date, fcUtil.unwrap(@date2).toISOString()

  test 'overlapping ranges: overlap at end shifts end to start of overlap', ->
    @source.getEvents(@date3, @date4, @contexts, ->)
    @source.getEvents(@date1, @date4, @contexts, ->)
    equal @server.lastQuery.end_date, fcUtil.unwrap(@date3).toISOString()

  test 'overlapping ranges: fully interior overlap leaves ends alone', ->
    @source.getEvents(@date2, @date3, @contexts, ->)
    @source.getEvents(@date1, @date4, @contexts, ->)
    equal @server.lastQuery.start_date, fcUtil.unwrap(@date1).toISOString()
    equal @server.lastQuery.end_date, fcUtil.unwrap(@date4).toISOString()

  test 'overlapping ranges: both ends move if necessary', ->
    @source.getEvents(@date1, @date2, @contexts, ->)
    @source.getEvents(@date3, @date4, @contexts, ->)
    @source.getEvents(@date1, @date4, @contexts, ->)
    equal @server.lastQuery.start_date, fcUtil.unwrap(@date2).toISOString()
    equal @server.lastQuery.end_date, fcUtil.unwrap(@date3).toISOString()

  test 'overlapping ranges: full overlap means no query', ->
    @source.getEvents(@date1, @date3, @contexts, ->)
    @source.getEvents(@date2, @date4, @contexts, ->)
    @server.reset()
    @source.getEvents(@date1, @date4, @contexts, ->)
    ok !@server.lastQuery

  test 'date-only boundaries: date-only end is treated as midnight in profile timezone (excludes that date)', ->
    end = fcUtil.clone(@date4).stripTime().stripZone()
    @server.addCalendarEvent('course_1', '1', fcUtil.unwrap(@date3).toISOString())
    @server.addCalendarEvent('course_2', '2', fcUtil.unwrap(@date4).toISOString())
    @source.getEvents @date1, end, @contexts, (list) ->
      equal list.length, 1
      equal list[0].id, 'calendar_event_1'
    equal @server.lastQuery.end_date, '2015-11-04T07:00:00.000Z'

  test 'date-only boundaries: date-only start is treated as midnight in profile timezone (includes that date)', ->
    start = fcUtil.clone(@date2).stripTime().stripZone()
    @server.addCalendarEvent('course_1', '1', fcUtil.unwrap(@date1).toISOString())
    @server.addCalendarEvent('course_2', '2', fcUtil.unwrap(@date2).toISOString())
    @source.getEvents start, @date4, @contexts, (list) ->
      equal list.length, 1
      equal list[0].id, 'calendar_event_2'
    equal @server.lastQuery.start_date, '2015-11-02T07:00:00.000Z'

  test 'pagination: both pages final returns full range and leaves nextPageDate unset', ->
    @server.addCalendarEvent('course_1', '1', fcUtil.unwrap(@date1).toISOString())
    @server.addCalendarEvent('course_2', '2', fcUtil.unwrap(@date2).toISOString())
    @server.addAssignment('course_2', '3', fcUtil.unwrap(@date3).toISOString())
    @source.getEvents @date1, @date4, @contexts, (list) ->
      ok !list.nextPageDate
      equal list.length, 3

  test 'pagination: one page final sets nextPageDate and returns only up to nextPageDate (exclusive)', ->
    # since the max calendarEvent date is @date2, nextPageDate will be @date2
    # and nothing >= @date2 will be included
    @server.addCalendarEvent('course_1', '1', fcUtil.unwrap(@date1).toISOString())
    @server.addCalendarEvent('course_2', '2', fcUtil.unwrap(@date2).toISOString())
    @server.addAssignment('course_1', '3', fcUtil.unwrap(@date1).toISOString())
    @server.addAssignment('course_2', '4', fcUtil.unwrap(@date2).toISOString())
    @server.addAssignment('course_2', '5', fcUtil.unwrap(@date3).toISOString())
    @server.calendarEvents.next = true
    @source.getEvents @date1, @date4, @contexts, (list) =>
      equal +list.nextPageDate, +@date2
      equal list.length, 2
      ok ['calendar_event_1', 'assignment_3'].indexOf(list[0].id) >= 0
      ok ['calendar_event_1', 'assignment_3'].indexOf(list[1].id) >= 0

  test 'pagination: both pages final sets nextPageDate and returns only up to nextPageDate (exclusive)', ->
    # since assignments has the smallest max date at @date2, nextPageDate will be
    # @date2 and nothing >= @date2 will be included
    @server.addCalendarEvent('course_1', '1', fcUtil.unwrap(@date1).toISOString())
    @server.addCalendarEvent('course_2', '2', fcUtil.unwrap(@date2).toISOString())
    @server.addAssignment('course_1', '3', fcUtil.unwrap(@date1).toISOString())
    @server.addAssignment('course_2', '4', fcUtil.unwrap(@date2).toISOString())
    @server.addAssignment('course_2', '5', fcUtil.unwrap(@date3).toISOString())
    @server.calendarEvents.next = true
    @server.assignments.next = true
    @source.getEvents @date1, @date4, @contexts, (list) =>
      equal +list.nextPageDate, +@date2
      equal list.length, 2
      ok ['calendar_event_1', 'assignment_3'].indexOf(list[0].id) >= 0
      ok ['calendar_event_1', 'assignment_3'].indexOf(list[1].id) >= 0

  test 'pagination: calls data callback with each page of data if set', ->
    @server.addCalendarEvent('course_1', '1', fcUtil.unwrap(@date1).toISOString())
    @server.addAssignment('course_2', '3', fcUtil.unwrap(@date3).toISOString())
    pages = 0
    @source.getEvents @date1, @date4, @contexts, (list) ->
      equal list.length, 2
      equal pages, 2
    , (list) ->
      pages += 1
      equal list.length, 1
