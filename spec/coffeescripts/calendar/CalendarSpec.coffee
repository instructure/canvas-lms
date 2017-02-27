define [
  'compiled/calendar/Calendar'
  'compiled/util/fcUtil',
  'moment'
  'timezone'
  'timezone/America/Denver'
  'helpers/fixtures'
  'jquery'
], (Calendar, fcUtil, moment, tz, denver, fixtures, $) ->

  QUnit.module "Calendar",
    setup: ->
      @snapshot = tz.snapshot()
      tz.changeZone(denver, 'America/Denver')
      fixtures.setup()

    teardown: ->
      tz.restore(@snapshot)
      fixtures.teardown()

  makeMockDataSource = () ->
    getAppointmentGroups: sinon.spy()
    getEvents: sinon.spy()
    getEventsForAppointmentGroup: sinon.spy()
    clearCache: sinon.spy()
    eventWithId: sinon.spy()

  makeMockHeader = () ->
    setHeaderText: sinon.spy()
    setSchedulerBadgeCount: sinon.spy()
    selectView: sinon.spy()
    on: sinon.spy()
    animateLoading: sinon.spy()
    showNavigator: sinon.spy()
    showPrevNext: sinon.spy()
    hidePrevNext: sinon.spy()
    hideAgendaRecommendation: sinon.spy()
    showAgendaRecommendation: sinon.spy()
    showSchedulerTitle: sinon.spy()
    showDoneButton: sinon.spy()

  makeCal = () ->
    new Calendar('#fixtures', [], null, makeMockDataSource(), header: makeMockHeader())

  test 'creates a fullcalendar instance', ->
    cal = makeCal()
    ok $('.fc')[0]

  test 'collaborates with header and data source', ->
    mockHeader = makeMockHeader()
    mockDataSource = makeMockDataSource()
    cal = new Calendar('#fixtures', [], null, mockDataSource, header: mockHeader)
    ok mockDataSource.getEvents.called
    ok mockHeader.on.called

  test 'animates loading', ->
    mockHeader = makeMockHeader()
    mockDataSource = makeMockDataSource()
    cal = new Calendar('#fixtures', [], null, mockDataSource, header: mockHeader)
    cal.ajaxStarted()
    ok mockHeader.animateLoading.called

  test 'publishes event when date is changed', ->
    eventSpy = sinon.spy()
    $.subscribe('Calendar/currentDate', eventSpy)
    cal = makeCal()
    cal.navigateDate(Date.now())
    ok eventSpy.called

  test 'renders events', ->
    cal = makeCal()
    $eventDiv = $('<div class="event"><div class="fc-title"></div><div class="fc-content"></div></div>').appendTo('#fixtures')
    now = moment()
    event =
      startDate: () -> now
      endDate: () -> now
      isAppointmentGroupEvent: () -> false
      eventType: 'calendar_event'
      iconType: () -> 'someicon'
      contextInfo:
        name: 'some calendar'
      isCompleted: () -> false

    cal.eventRender(event, $eventDiv, 'month')
    ok $('.icon-someicon')[0]

  test 'isSameWeek: should check boundaries in profile timezone', ->
    datetime1 = fcUtil.wrap('2015-10-31T23:59:59-06:00')
    datetime2 = fcUtil.wrap('2015-11-01T00:00:00-06:00')
    datetime3 = fcUtil.wrap('2015-11-07T23:59:59-07:00')

    ok !Calendar.prototype.isSameWeek(datetime1, datetime2)
    ok Calendar.prototype.isSameWeek(datetime2, datetime3)

  test 'isSameWeek: should behave with ambiguously timed/zoned arguments', ->
    datetime1 = fcUtil.wrap('2015-10-31T23:59:59-06:00')
    datetime2 = fcUtil.wrap('2015-11-01T00:00:00-06:00')
    datetime3 = fcUtil.wrap('2015-11-07T23:59:59-07:00')

    date1 = fcUtil.clone(datetime1).stripTime().stripZone()
    date2 = fcUtil.clone(datetime2).stripTime().stripZone()
    date3 = fcUtil.clone(datetime3).stripTime().stripZone()

    ok !Calendar.prototype.isSameWeek(date1, datetime2), 'sat-sun 1'
    ok !Calendar.prototype.isSameWeek(datetime1, date2), 'sat-sun 2'
    ok !Calendar.prototype.isSameWeek(date1, date2), 'sat-sun 3'

    ok Calendar.prototype.isSameWeek(date2, datetime3), 'sun-sat 1'
    ok Calendar.prototype.isSameWeek(datetime2, date3), 'sun-sat 2'
    ok Calendar.prototype.isSameWeek(date2, date3), 'sun-sat 3'

  test 'gets appointment groups when show scheduler activated', ->
    mockHeader = makeMockHeader()
    mockDataSource = makeMockDataSource()
    cal = new Calendar('#fixtures', [], null, mockDataSource, {header: mockHeader, showScheduler: true})
    ok mockDataSource.getAppointmentGroups.called
    ok mockDataSource.getEvents.called
