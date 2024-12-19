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

import moment from 'moment'
import coupleTimeFields from '../coupleTimeFields'
import DatetimeField, {PARSE_RESULTS} from '@canvas/datetime/jquery/DatetimeField'
import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from '@canvas/test-utils/fakeENV'

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

describe('coupleTimeFields', () => {
  let $start
  let $end
  let start
  let end

  beforeEach(() => {
    $start = $('<input type="text">')
    $end = $('<input type="text">')
    start = new DatetimeField($start, {timeOnly: true})
    end = new DatetimeField($end, {timeOnly: true})
  })

  describe('initial coupling', () => {
    it('updates start to be <= end', () => {
      start.setTime(new Date(+fixed + 3600000))
      end.setTime(fixed)
      coupleTimeFields($start, $end)
      expect(+start.datetime).toBe(+fixed)
    })

    it('leaves start < end alone', () => {
      const earlier = new Date(+fixed - 3600000)
      start.setTime(earlier)
      end.setTime(fixed)
      coupleTimeFields($start, $end)
      expect(+start.datetime).toBe(+earlier)
    })

    it('leaves blank start alone', () => {
      start.setTime(null)
      end.setTime(fixed)
      coupleTimeFields($start, $end)
      expect(start.blank).toBe(true)
    })

    it('leaves blank end alone', () => {
      start.setTime(fixed)
      end.setTime(null)
      coupleTimeFields($start, $end)
      expect(end.blank).toBe(true)
    })

    it('leaves invalid start alone', () => {
      $start.val('invalid')
      start.setFromValue()
      end.setTime(fixed)
      coupleTimeFields($start, $end)
      expect($start.val()).toBe('invalid')
      expect(start.valid).toBe(PARSE_RESULTS.ERROR)
    })

    it('leaves invalid end alone', () => {
      start.setTime(fixed)
      $end.val('invalid')
      end.setFromValue()
      coupleTimeFields($start, $end)
      expect($end.val()).toBe('invalid')
      expect(end.valid).toBe(PARSE_RESULTS.ERROR)
    })

    it('interprets time as occurring on date', () => {
      const $date = $('<input type="text">')
      const date = new DatetimeField($date, {dateOnly: true})
      date.setDate(tomorrow)
      start.setTime(fixed)
      end.setTime(fixed)
      coupleTimeFields($start, $end, $date)
      expect(start.datetime.getDate()).toBe(tomorrow.getDate())
      expect(end.datetime.getDate()).toBe(tomorrow.getDate())
    })
  })

  describe('post coupling', () => {
    beforeEach(() => {
      coupleTimeFields($start, $end)
    })

    it('changing end updates start to be <= end', () => {
      start.setTime(new Date(+fixed + 3600000))
      end.setTime(fixed)
      $end.trigger('blur')
      expect(+start.datetime).toBe(+fixed)
    })

    it('changing start updates end to be >= start', () => {
      end.setTime(new Date(+fixed - 3600000))
      start.setTime(fixed)
      $start.trigger('blur')
      expect(+end.datetime).toBe(+fixed)
    })

    it('leaves start < end alone', () => {
      const earlier = new Date(+fixed - 3600000)
      start.setTime(earlier)
      end.setTime(fixed)
      $start.trigger('blur')
      expect(+start.datetime).toBe(+earlier)
      expect(+end.datetime).toBe(+fixed)
    })

    it('leaves blank start alone', () => {
      start.setTime(null)
      end.setTime(fixed)
      $end.trigger('blur')
      expect(start.blank).toBe(true)
    })

    it('leaves blank end alone', () => {
      start.setTime(fixed)
      end.setTime(null)
      $start.trigger('blur')
      expect(end.blank).toBe(true)
    })

    it('leaves invalid start alone', () => {
      $start.val('invalid')
      start.setFromValue()
      end.setTime(fixed)
      $end.trigger('blur')
      expect($start.val()).toBe('invalid')
      expect(start.valid).toBe(PARSE_RESULTS.ERROR)
    })

    it('leaves invalid end alone', () => {
      start.setTime(fixed)
      $end.val('invalid')
      end.setFromValue()
      $start.trigger('blur')
      expect($end.val()).toBe('invalid')
      expect(end.valid).toBe(PARSE_RESULTS.ERROR)
    })

    it('does not rewrite blurred input', () => {
      $start.val('7') // interpreted as 7pm, but should not be rewritten
      start.setFromValue()
      end.setTime(new Date(+start.datetime + 3600000))
      $start.trigger('blur')
      expect($start.val()).toBe('7')
    })

    it('does not rewrite other input', () => {
      $start.val('7') // interpreted as 7pm, but should not be rewritten
      start.setFromValue()
      end.setTime(new Date(+start.datetime + 3600000))
      $end.trigger('blur')
      expect($start.val()).toBe('7')
    })

    it('does not switch time fields if in order by user profile timezone, even if out of order in local timezone', () => {
      // Set the timezone to America/Detroit in the environment
      fakeENV.setup({TIMEZONE: 'America/Detroit'})

      // 1am in profile timezone
      $start.val('1:00 AM')
      start.setFromValue()

      // 5pm in profile timezone
      $end.val('5:00 PM')
      end.setFromValue()

      // Store current end datetime before triggering blur
      const endTime = +end.datetime

      // Trigger blur on start field (not end field like before)
      $start.trigger('blur')

      // Check that the end datetime has not been changed
      expect(+end.datetime).toBe(endTime)

      fakeENV.teardown()
    })
  })

  describe('with date field', () => {
    let $date
    let date

    beforeEach(() => {
      $date = $('<input type="text">')
      date = new DatetimeField($date, {dateOnly: true})
      coupleTimeFields($start, $end, $date)
    })

    it('interprets time as occurring on date when date changes', () => {
      date.setDate(tomorrow)
      start.setTime(fixed)
      end.setTime(fixed)
      $date.trigger('blur')

      // Compare timestamps instead of dates since the dates might be in different timezones
      expect(+start.datetime).toBe(+tomorrow)
      expect(+end.datetime).toBe(+tomorrow)
    })
  })
})
