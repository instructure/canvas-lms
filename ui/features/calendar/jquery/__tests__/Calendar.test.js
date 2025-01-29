/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import Calendar from '../index'
import CalendarEvent from '@canvas/calendar/jquery/CommonEvent/CalendarEvent'
import {useScope as createI18nScope} from '@canvas/i18n'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import moment from 'moment'
import tzInTest from '@instructure/moment-utils/specHelpers'
import timezone from 'timezone'
import denver from 'timezone/America/Denver'
import fixtures from '@canvas/test-utils/fixtures'
import $ from 'jquery'
import 'jquery-migrate'
import {subscribe} from 'jquery-tinypubsub'
import fakeENV from '@canvas/test-utils/fakeENV'

const I18n = createI18nScope('calendar')

const makeMockDataSource = () => ({
  getAppointmentGroups: jest.fn(),
  getEvents: jest.fn(),
  getEventsForAppointmentGroup: jest.fn(),
  clearCache: jest.fn(),
  eventWithId: jest.fn(),
})

const makeMockHeader = () => ({
  setHeaderText: jest.fn(),
  setSchedulerBadgeCount: jest.fn(),
  selectView: jest.fn(),
  on: jest.fn(),
  animateLoading: jest.fn(),
  showNavigator: jest.fn(),
  showPrevNext: jest.fn(),
  hidePrevNext: jest.fn(),
  hideAgendaRecommendation: jest.fn(),
  showAgendaRecommendation: jest.fn(),
})

const makeCal = () =>
  new Calendar('#fixtures', [], null, makeMockDataSource(), {header: makeMockHeader()})

describe('Calendar', () => {
  beforeEach(() => {
    jest.useFakeTimers()
    tzInTest.configureAndRestoreLater({
      tz: timezone(denver, 'America/Denver'),
      tzData: {
        'America/Denver': denver,
      },
    })

    fixtures.setup()
    $('<div id="fixtures" />').appendTo(document.body)
    jest.spyOn($, 'getJSON')
    fakeENV.setup()
  })

  afterEach(() => {
    jest.useRealTimers()
    tzInTest.restore()
    const calendar = $('#fixtures .calendar').data('fullCalendar')
    if (calendar) {
      calendar.destroy()
    }
    $('#fixtures').remove()
    fixtures.teardown()
    $.getJSON.mockRestore()
    fakeENV.teardown()
  })

  it('creates a fullcalendar instance', () => {
    const cal = makeCal()
    // Wait for fullcalendar to initialize
    jest.advanceTimersByTime(0)
    expect($('#fixtures .fc')).toHaveLength(1)
  })

  it('returns correct format for 24 hour times', () => {
    const cal = makeCal()
    jest.spyOn(I18n.constructor.prototype, 'lookup').mockReturnValue('%k:%M')
    expect(cal.eventTimeFormat()).toBe('HH:mm')
  })

  it('returns correct format for non 24 hour times', () => {
    const cal = makeCal()
    jest.spyOn(I18n.constructor.prototype, 'lookup').mockReturnValue('whatever')
    expect(cal.eventTimeFormat()).toBeNull()
  })

  it('collaborates with header and data source', () => {
    const mockHeader = makeMockHeader()
    const mockDataSource = makeMockDataSource()
    new Calendar('#fixtures', [], null, mockDataSource, {header: mockHeader})
    // Wait for initialization
    jest.advanceTimersByTime(0)
    expect(mockDataSource.getEvents).toHaveBeenCalled()
    expect(mockHeader.on).toHaveBeenCalled()
  })

  it('animates loading', () => {
    const mockHeader = makeMockHeader()
    const mockDataSource = makeMockDataSource()
    const cal = new Calendar('#fixtures', [], null, mockDataSource, {header: mockHeader})
    cal.ajaxStarted()
    expect(mockHeader.animateLoading).toHaveBeenCalled()
  })

  it('publishes event when date is changed', () => {
    const eventSpy = jest.fn()
    subscribe('Calendar/currentDate', eventSpy)
    const cal = makeCal()
    cal.navigateDate(Date.now())
    expect(eventSpy).toHaveBeenCalled()
  })

  it('renders events', () => {
    const cal = makeCal()
    const $eventDiv = $(
      '<div class="event"><div class="fc-title"></div><div class="fc-content"></div></div>',
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
      },
    }
    cal.eventRender(event, $eventDiv, 'month')
    // Wait for render
    jest.advanceTimersByTime(0)
    expect($('#fixtures .icon-someicon')).toHaveLength(1)
  })

  describe('isSameWeek', () => {
    it('checks boundaries in profile timezone', () => {
      const datetime1 = fcUtil.wrap('2015-10-31T23:59:59-06:00')
      const datetime2 = fcUtil.wrap('2015-11-01T00:00:00-06:00')
      const datetime3 = fcUtil.wrap('2015-11-07T23:59:59-07:00')
      expect(Calendar.prototype.isSameWeek(datetime1, datetime2)).toBeFalsy()
      expect(Calendar.prototype.isSameWeek(datetime2, datetime3)).toBeTruthy()
    })

    it('behaves with ambiguously timed/zoned arguments', () => {
      const datetime1 = fcUtil.wrap('2015-10-31T23:59:59-06:00')
      const datetime2 = fcUtil.wrap('2015-11-01T00:00:00-06:00')
      const datetime3 = fcUtil.wrap('2015-11-07T23:59:59-07:00')
      const date1 = fcUtil.clone(datetime1).stripTime().stripZone()
      const date2 = fcUtil.clone(datetime2).stripTime().stripZone()
      const date3 = fcUtil.clone(datetime3).stripTime().stripZone()
      expect(Calendar.prototype.isSameWeek(date1, datetime2)).toBeFalsy()
      expect(Calendar.prototype.isSameWeek(datetime1, date2)).toBeFalsy()
      expect(Calendar.prototype.isSameWeek(date1, date2)).toBeFalsy()
      expect(Calendar.prototype.isSameWeek(date2, datetime3)).toBeTruthy()
      expect(Calendar.prototype.isSameWeek(datetime2, date3)).toBeTruthy()
      expect(Calendar.prototype.isSameWeek(date2, date3)).toBeTruthy()
    })
  })

  it('gets appointment groups when show scheduler activated', () => {
    const mockHeader = makeMockHeader()
    const mockDataSource = makeMockDataSource()
    new Calendar('#fixtures', [], null, mockDataSource, {
      header: mockHeader,
      showScheduler: true,
    })
    // Wait for initialization
    jest.advanceTimersByTime(0)
    expect(mockDataSource.getAppointmentGroups).toHaveBeenCalled()
    expect(mockDataSource.getEvents).toHaveBeenCalled()
  })

  it('displays group name in tooltip', () => {
    fakeENV.setup({CALENDAR: {SHOW_SCHEDULER: true}})
    const cal = makeCal()
    const $eventDiv = $(
      '<div class="event"><div class="fc-title"></div><div class="fc-content"></div></div>',
    ).appendTo('#fixtures')
    const now = moment()
    const data = {
      start_at: now,
      end_at: now,
      child_events: [
        {
          group: {
            name: 'Foobar',
          },
        },
      ],
      appointment_group_url: '/foo/bar',
    }
    const event = new CalendarEvent(data, {calendar_event_url: '/foo/bar'})
    cal.eventRender(event, $eventDiv, 'month')
    // Wait for render
    jest.advanceTimersByTime(0)
    expect($eventDiv.attr('title')).toContain('Reserved By:  Foobar')
  })
})
