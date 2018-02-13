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

import london from 'timezone/Europe/London'
import tz from 'timezone'
import coupleTimeFields from 'compiled/util/coupleTimeFields'
import DatetimeField from 'compiled/widget/DatetimeField'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'

// make sure this is on today date but without seconds/milliseconds, so we
// don't get screwed by dates shifting and seconds truncated during
// reinterpretation of field values, but also make sure it's the middle of the
// day so timezones don't shift the actual date from under us either
const fixed = new Date()
fixed.setHours(12)
fixed.setMinutes(0)
fixed.setSeconds(0)
fixed.setMilliseconds(0)
const tomorrow = new Date(fixed)
tomorrow.setDate(tomorrow.getDate() + 1)

QUnit.module('initial coupling', {
  setup() {
    this.$start = $('<input type="text">')
    this.$end = $('<input type="text">')
    this.start = new DatetimeField(this.$start, {timeOnly: true})
    this.end = new DatetimeField(this.$end, {timeOnly: true})
  }
})

test('updates start to be <= end', function() {
  this.start.setTime(new Date(+fixed + 3600000))
  this.end.setTime(fixed)
  coupleTimeFields(this.$start, this.$end)
  equal(+this.start.datetime, +fixed)
})

test('leaves start < end alone', function() {
  const earlier = new Date(+fixed - 3600000)
  this.start.setTime(earlier)
  this.end.setTime(fixed)
  coupleTimeFields(this.$start, this.$end)
  equal(+this.start.datetime, +earlier)
})

test('leaves blank start alone', function() {
  this.start.setTime(null)
  this.end.setTime(fixed)
  coupleTimeFields(this.$start, this.$end)
  equal(this.start.blank, true)
})

test('leaves blank end alone', function() {
  this.start.setTime(fixed)
  this.end.setTime(null)
  coupleTimeFields(this.$start, this.$end)
  equal(this.end.blank, true)
})

test('leaves invalid start alone', function() {
  this.$start.val('invalid')
  this.start.setFromValue()
  this.end.setTime(fixed)
  coupleTimeFields(this.$start, this.$end)
  equal(this.$start.val(), 'invalid')
  equal(this.start.invalid, true)
})

test('leaves invalid end alone', function() {
  this.start.setTime(fixed)
  this.$end.val('invalid')
  this.end.setFromValue()
  coupleTimeFields(this.$start, this.$end)
  equal(this.$end.val(), 'invalid')
  equal(this.end.invalid, true)
})

test('interprets time as occurring on date', function() {
  this.$date = $('<input type="text">')
  this.date = new DatetimeField(this.$date, {dateOnly: true})
  this.date.setDate(tomorrow)
  this.start.setTime(fixed)
  this.end.setTime(fixed)
  coupleTimeFields(this.$start, this.$end, this.$date)
  equal(this.start.datetime.getDate(), tomorrow.getDate())
  equal(this.end.datetime.getDate(), tomorrow.getDate())
})

QUnit.module('post coupling', {
  setup() {
    this.$start = $('<input type="text">')
    this.$end = $('<input type="text">')
    this.start = new DatetimeField(this.$start, {timeOnly: true})
    this.end = new DatetimeField(this.$end, {timeOnly: true})
    return coupleTimeFields(this.$start, this.$end)
  }
})

test('changing end updates start to be <= end', function() {
  this.start.setTime(new Date(+fixed + 3600000))
  this.end.setTime(fixed)
  this.$end.trigger('blur')
  equal(+this.start.datetime, +fixed)
})

test('changing start updates end to be >= start', function() {
  this.end.setTime(new Date(+fixed - 3600000))
  this.start.setTime(fixed)
  this.$start.trigger('blur')
  equal(+this.end.datetime, +fixed)
})

test('leaves start < end alone', function() {
  const earlier = new Date(+fixed - 3600000)
  this.start.setTime(earlier)
  this.end.setTime(fixed)
  this.$start.trigger('blur')
  equal(+this.start.datetime, +earlier)
  equal(+this.end.datetime, +fixed)
})

test('leaves blank start alone', function() {
  this.start.setTime(null)
  this.end.setTime(fixed)
  this.$end.trigger('blur')
  equal(this.start.blank, true)
})

test('leaves blank end alone', function() {
  this.start.setTime(fixed)
  this.end.setTime(null)
  this.$start.trigger('blur')
  equal(this.end.blank, true)
})

test('leaves invalid start alone', function() {
  this.$start.val('invalid')
  this.start.setFromValue()
  this.end.setTime(fixed)
  this.$end.trigger('blur')
  equal(this.$start.val(), 'invalid')
  equal(this.start.invalid, true)
})

test('leaves invalid end alone', function() {
  this.start.setTime(fixed)
  this.$end.val('invalid')
  this.end.setFromValue()
  this.$start.trigger('blur')
  equal(this.$end.val(), 'invalid')
  equal(this.end.invalid, true)
})

test('does not rewrite blurred input', function() {
  this.$start.val('7') // interpreted as 7pm, but should not be rewritten
  this.start.setFromValue()
  this.end.setTime(new Date(+this.start.datetime + 3600000))
  this.$start.trigger('blur')
  equal(this.$start.val(), '7')
})

test('does not rewrite other input', function() {
  this.$start.val('7') // interpreted as 7pm, but should not be rewritten
  this.start.setFromValue()
  this.end.setTime(new Date(+this.start.datetime + 3600000))
  this.$end.trigger('blur')
  equal(this.$start.val(), '7')
})

test('does not switch time fields if in order by user profile timezone, even if out of order in local timezone', function() {
  // set local timezone to UTC
  const snapshot = tz.snapshot()
  tz.changeZone(london, 'Europe/London')

  // set user profile timezone to EST (UTC-4)
  fakeENV.setup({TIMEZONE: 'America/Detroit'})

  // 1am in profile timezone, or 9pm in local timezone
  this.$start.val('1:00 AM')
  this.start.setFromValue()

  // 5pm in profile timezone, or 1pm in local timezone
  this.$end.val('5:00 PM')
  this.end.setFromValue()

  // store current end datetime
  const endTime = +this.end.datetime

  this.$start.trigger('blur')

  tz.restore(snapshot)
  fakeENV.teardown()
  // check that the end datetime has not been changed
  equal(+this.end.datetime, endTime)
})

QUnit.module('with date field', {
  setup() {
    this.$start = $('<input type="text">')
    this.$end = $('<input type="text">')
    this.$date = $('<input type="text">')
    this.start = new DatetimeField(this.$start, {timeOnly: true})
    this.end = new DatetimeField(this.$end, {timeOnly: true})
    this.date = new DatetimeField(this.$date, {dateOnly: true})
    coupleTimeFields(this.$start, this.$end, this.$date)
  }
})

test('interprets time as occurring on date', function() {
  this.date.setDate(tomorrow)
  this.$date.trigger('blur')
  this.start.setTime(fixed)
  this.start.parseValue()
  this.end.setTime(fixed)
  this.end.parseValue()
  equal(this.start.datetime.getDate(), tomorrow.getDate())
  equal(this.end.datetime.getDate(), tomorrow.getDate())
})
