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

import $ from 'jquery'
import 'jquery-migrate'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import TimeBlockList from '../TimeBlockList'
import TimeBlockRow from '../TimeBlockRow'
import * as tz from '@instructure/moment-utils'
import tzInTest from '@instructure/moment-utils/specHelpers'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'

const nextYear = new Date().getFullYear() + 1
const unfudged_start = tz.parse(`${nextYear}-02-03T12:32:00Z`)
const unfudged_end = tz.parse(`${nextYear}-02-03T17:32:00Z`)

describe('TimeBlockRow', () => {
  let timeBlockList
  let $holder
  let start
  let end

  const mockErrorBox = () => {
    const $errorBox = $('<div class="error_box" style="display: block" />')
    $.fn.errorBox = function () {
      this.data('associated_error_box', $errorBox)
      return $errorBox
    }
    return $errorBox
  }

  beforeEach(() => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
      formats: getI18nFormats(),
    })

    start = fcUtil.wrap(unfudged_start)
    end = fcUtil.wrap(unfudged_end)
    $holder = $('<table />').appendTo(document.getElementById('fixtures'))
    timeBlockList = new TimeBlockList($holder)

    jest.useFakeTimers()
    mockErrorBox()
  })

  afterEach(() => {
    jest.advanceTimersByTime(250) // advance past any errorBox fade-ins
    jest.useRealTimers()
    $holder.detach()
    $('#fixtures').empty()
    $('.ui-tooltip').remove()
    $('.error_box').remove()
    tzInTest.restore()
  })

  it('initializes properly', () => {
    const timeBlockRow = new TimeBlockRow(timeBlockList, {start, end})
    expect(timeBlockRow.$date.val().trim()).toBe(tz.format(unfudged_start, 'date.formats.default'))
    expect(timeBlockRow.$start_time.val().trim()).toBe(
      tz.format(unfudged_start, 'time.formats.tiny'),
    )
    expect(timeBlockRow.$end_time.val().trim()).toBe(tz.format(unfudged_end, 'time.formats.tiny'))
  })

  it('removes row when delete link is clicked', () => {
    const timeBlockRow = timeBlockList.addRow({start, end})
    expect(timeBlockList.rows).toContain(timeBlockRow)

    timeBlockRow.$row.find('.delete-block-link').click()

    expect(timeBlockList.rows).not.toContain(timeBlockRow)
    expect(timeBlockRow.$row[0].parentElement).toBeFalsy()
  })

  describe('validation', () => {
    it('fails validation when fields are invalid', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList)

      timeBlockRow.$date.val('invalid').change()
      expect(timeBlockRow.validate()).toBeFalsy()

      timeBlockRow.$date.data('instance').setDate(start)
      timeBlockRow.$start_time.val('invalid').change()
      expect(timeBlockRow.validate()).toBeFalsy()

      timeBlockRow.$start_time.data('instance').setDate(start)
      timeBlockRow.$end_time.val('invalid').change()
      expect(timeBlockRow.validate()).toBeFalsy()
    })

    it('passes validation with valid data', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList, {start, end})
      expect(timeBlockRow.validate()).toBeTruthy()
    })

    it('fails validation for date in past', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList, {start, end})
      timeBlockRow.$date.val('1/1/2000').change()

      expect(timeBlockRow.validate()).toBeFalsy()
      expect(timeBlockRow.$end_time.hasClass('error')).toBeTruthy()
    })

    it('fails validation for time in past', () => {
      const fudgedMidnight = fcUtil.now().minutes(0).hours(0)
      const fudgedEnd = fcUtil.clone(fudgedMidnight)
      fudgedEnd.minutes(1)

      const timeBlockRow = new TimeBlockRow(timeBlockList, {start: fudgedMidnight, end: fudgedEnd})

      expect(timeBlockRow.validate()).toBeFalsy()
      expect(timeBlockRow.$end_time.hasClass('error')).toBeTruthy()
    })

    it('fails validation when end is before start', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList, {start: end, end: start})

      expect(timeBlockRow.validate()).toBeFalsy()
      expect(timeBlockRow.$start_time.hasClass('error')).toBeTruthy()
    })

    it('passes validation when row is blank', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList)
      expect(timeBlockRow.validate()).toBeTruthy()
    })

    it('passes validation when row is incomplete', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList, {start, end: null})
      expect(timeBlockRow.validate()).toBeTruthy()
    })
  })

  describe('getData', () => {
    it('returns correct data', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList, {start, end})
      timeBlockRow.validate()
      const [resultStart, resultEnd, locked] = timeBlockRow.getData()

      expect(+resultStart).toBe(+start)
      expect(+resultEnd).toBe(+end)
      expect(locked).toBeFalsy()
    })
  })

  describe('incomplete', () => {
    it('returns false when row is blank', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList)
      expect(timeBlockRow.incomplete()).toBeFalsy()
    })

    it('returns false when row is fully populated', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList, {start, end})
      expect(timeBlockRow.incomplete()).toBeFalsy()
    })

    it('returns true when only some fields are populated', () => {
      const timeBlockRow = new TimeBlockRow(timeBlockList, {start, end: null})
      expect(timeBlockRow.incomplete()).toBeTruthy()
    })
  })
})
