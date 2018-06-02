/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Calendar from 'compiled/calendar/Calendar'
import I18n from 'i18n!calendar'
import fcUtil from 'compiled/util/fcUtil'
import moment from 'moment'
import tz from 'timezone'
import denver from 'timezone/America/Denver'
import fixtures from 'helpers/fixtures'
import $ from 'jquery'

QUnit.module('Calendar', {
  setup() {
    this.snapshot = tz.snapshot()
    tz.changeZone(denver, 'America/Denver')
    return fixtures.setup()
  },
  teardown() {
    tz.restore(this.snapshot)
    fixtures.teardown()
  }
})
const makeMockDataSource = () => ({
  getAppointmentGroups: sinon.spy(),
  getEvents: sinon.spy(),
  getEventsForAppointmentGroup: sinon.spy(),
  clearCache: sinon.spy(),
  eventWithId: sinon.spy()
})
const makeMockHeader = () => ({
  setHeaderText: sinon.spy(),
  setSchedulerBadgeCount: sinon.spy(),
  selectView: sinon.spy(),
  on: sinon.spy(),
  animateLoading: sinon.spy(),
  showNavigator: sinon.spy(),
  showPrevNext: sinon.spy(),
  hidePrevNext: sinon.spy(),
  hideAgendaRecommendation: sinon.spy(),
  showAgendaRecommendation: sinon.spy(),
  showSchedulerTitle: sinon.spy(),
  showDoneButton: sinon.spy()
})
const makeCal = () =>
  new Calendar('#fixtures', [], null, makeMockDataSource(), {header: makeMockHeader()})

test('creates a fullcalendar instance', () => {
  const cal = makeCal()
  ok($('.fc')[0])
})

test('returns correct format for 24 hour times', function() {
  const cal = makeCal()
  const stub = sinon.stub(I18n, 'lookup').returns('%k:%M')
  strictEqual(cal.eventTimeFormat(), "HH:mm")
  stub.restore()
})

test('return correct format for non 24 hour times', function() {
  const cal = makeCal()
  const stub = sinon.stub(I18n, 'lookup').returns('whatever')
  strictEqual(cal.eventTimeFormat(), null)
  stub.restore()
})

test('collaborates with header and data source', () => {
  const mockHeader = makeMockHeader()
  const mockDataSource = makeMockDataSource()
  const cal = new Calendar('#fixtures', [], null, mockDataSource, {header: mockHeader})
  ok(mockDataSource.getEvents.called)
  ok(mockHeader.on.called)
})

test('animates loading', () => {
  const mockHeader = makeMockHeader()
  const mockDataSource = makeMockDataSource()
  const cal = new Calendar('#fixtures', [], null, mockDataSource, {header: mockHeader})
  cal.ajaxStarted()
  ok(mockHeader.animateLoading.called)
})

test('publishes event when date is changed', () => {
  const eventSpy = sinon.spy()
  $.subscribe('Calendar/currentDate', eventSpy)
  const cal = makeCal()
  cal.navigateDate(Date.now())
  ok(eventSpy.called)
})

test('renders events', () => {
  const cal = makeCal()
  const $eventDiv = $(
    '<div class="event"><div class="fc-title"></div><div class="fc-content"></div></div>'
  ).appendTo('#fixtures')
  const now = moment()
  const event = {
    startDate() {
      return now
    },
    endDate() {
      return now
    },
    isAppointmentGroupEvent() {
      return false
    },
    eventType: 'calendar_event',
    iconType() {
      return 'someicon'
    },
    contextInfo: {name: 'some calendar'},
    isCompleted() {
      return false
    }
  }
  cal.eventRender(event, $eventDiv, 'month')
  ok($('.icon-someicon')[0])
})

test('isSameWeek: should check boundaries in profile timezone', () => {
  const datetime1 = fcUtil.wrap('2015-10-31T23:59:59-06:00')
  const datetime2 = fcUtil.wrap('2015-11-01T00:00:00-06:00')
  const datetime3 = fcUtil.wrap('2015-11-07T23:59:59-07:00')
  ok(!Calendar.prototype.isSameWeek(datetime1, datetime2))
  ok(Calendar.prototype.isSameWeek(datetime2, datetime3))
})

test('isSameWeek: should behave with ambiguously timed/zoned arguments', () => {
  const datetime1 = fcUtil.wrap('2015-10-31T23:59:59-06:00')
  const datetime2 = fcUtil.wrap('2015-11-01T00:00:00-06:00')
  const datetime3 = fcUtil.wrap('2015-11-07T23:59:59-07:00')
  const date1 = fcUtil
    .clone(datetime1)
    .stripTime()
    .stripZone()
  const date2 = fcUtil
    .clone(datetime2)
    .stripTime()
    .stripZone()
  const date3 = fcUtil
    .clone(datetime3)
    .stripTime()
    .stripZone()
  ok(!Calendar.prototype.isSameWeek(date1, datetime2), 'sat-sun 1')
  ok(!Calendar.prototype.isSameWeek(datetime1, date2), 'sat-sun 2')
  ok(!Calendar.prototype.isSameWeek(date1, date2), 'sat-sun 3')
  ok(Calendar.prototype.isSameWeek(date2, datetime3), 'sun-sat 1')
  ok(Calendar.prototype.isSameWeek(datetime2, date3), 'sun-sat 2')
  ok(Calendar.prototype.isSameWeek(date2, date3), 'sun-sat 3')
})

test('gets appointment groups when show scheduler activated', () => {
  const mockHeader = makeMockHeader()
  const mockDataSource = makeMockDataSource()
  const cal = new Calendar('#fixtures', [], null, mockDataSource, {
    header: mockHeader,
    showScheduler: true
  })
  ok(mockDataSource.getAppointmentGroups.called)
  ok(mockDataSource.getEvents.called)
})
