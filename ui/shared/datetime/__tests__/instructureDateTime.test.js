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
import * as tz from '@instructure/moment-utils'
import tzInTest from '@instructure/moment-utils/specHelpers'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import juneau from 'timezone/America/Juneau'
import kolkata from 'timezone/Asia/Kolkata'
import portuguese from 'timezone/pt_PT'
import I18nStubber from '@canvas/test-utils/I18nStubber'
import {
  dateString,
  datetimeString,
  fudgeDateForProfileTimezone,
  sameDate,
  sameYear,
  timeString,
  unfudgeDateForProfileTimezone,
} from '../date-functions'
import {getI18nFormats} from '../configureDateTime'
import '../jquery/datepicker'

describe('fudgeDateForProfileTimezone', () => {
  let original

  beforeEach(() => {
    original = new Date(Date.UTC(2013, 8, 1))
  })

  afterEach(() => {
    tzInTest.restore()
  })

  it('should produce a date that formats via toString same as the original formats via tz', () => {
    const fudged = fudgeDateForProfileTimezone(original)
    expect(fudged.toString('yyyy-MM-dd HH:mm:ss')).toBe(tz.format(original, '%F %T'))
  })

  it('should parse dates before the year 1000', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America Detroit'),
      tzData: {
        'America Detroit': detroit,
      },
      formats: getI18nFormats(),
    })

    const oldDate = new Date(Date.UTC(900, 1, 1, 0, 0, 0))
    const oldFudgeDate = fudgeDateForProfileTimezone(oldDate)
    expect(oldFudgeDate.toString('yyyy-MM-dd HH:mm:ss')).toBe('0900-02-01 00:00:00')
  })

  it('should work on non-date date-like values', () => {
    let fudged = fudgeDateForProfileTimezone(+original)
    expect(fudged.toString('yyyy-MM-dd HH:mm:ss')).toBe(tz.format(original, '%F %T'))

    fudged = fudgeDateForProfileTimezone(original.toISOString())
    expect(fudged.toString('yyyy-MM-dd HH:mm:ss')).toBe(tz.format(original, '%F %T'))
  })

  it('should return null for invalid values', () => {
    expect(fudgeDateForProfileTimezone(null)).toBeNull()
    expect(fudgeDateForProfileTimezone('')).toBeNull()
    expect(fudgeDateForProfileTimezone('bogus')).toBeNull()
  })

  it('should not treat 0 as invalid', () => {
    expect(+fudgeDateForProfileTimezone(0)).toBe(+fudgeDateForProfileTimezone(new Date(0)))
  })

  it('should be sensitive to profile time zone', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })
    let fudged = fudgeDateForProfileTimezone(original)
    expect(fudged.toString('yyyy-MM-dd HH:mm:ss')).toBe(tz.format(original, '%F %T'))

    tzInTest.configureAndRestoreLater({
      tz: timezone(juneau, 'America/Juneau'),
      tzData: {
        'America/Juneau': juneau,
      },
    })
    fudged = fudgeDateForProfileTimezone(original)
    expect(fudged.toString('yyyy-MM-dd HH:mm:ss')).toBe(tz.format(original, '%F %T'))
  })
})

describe('unfudgeDateForProfileTimezone', () => {
  let original

  beforeEach(() => {
    original = new Date(Date.UTC(2013, 8, 1))
  })

  afterEach(() => {
    tzInTest.restore()
  })

  it('should produce a date that formats via tz same as the original formats via toString()', () => {
    const unfudged = unfudgeDateForProfileTimezone(original)
    expect(tz.format(unfudged, '%F %T')).toBe(original.toString('yyyy-MM-dd HH:mm:ss'))
  })

  it('should work on non-date date-like values', () => {
    let unfudged = unfudgeDateForProfileTimezone(+original)
    expect(tz.format(unfudged, '%F %T')).toBe(original.toString('yyyy-MM-dd HH:mm:ss'))

    unfudged = unfudgeDateForProfileTimezone(original.toISOString())
    expect(tz.format(unfudged, '%F %T')).toBe(original.toString('yyyy-MM-dd HH:mm:ss'))
  })

  it('should return null for invalid values', () => {
    expect(unfudgeDateForProfileTimezone(null)).toBeNull()
    expect(unfudgeDateForProfileTimezone('')).toBeNull()
    expect(unfudgeDateForProfileTimezone('bogus')).toBeNull()
  })

  it('should not treat 0 as invalid', () => {
    expect(+unfudgeDateForProfileTimezone(0)).toBe(+unfudgeDateForProfileTimezone(new Date(0)))
  })

  it('should be sensitive to profile time zone', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })
    let unfudged = unfudgeDateForProfileTimezone(original)
    expect(tz.format(unfudged, '%F %T')).toBe(original.toString('yyyy-MM-dd HH:mm:ss'))

    tzInTest.configureAndRestoreLater({
      tz: timezone(juneau, 'America/Juneau'),
      tzData: {
        'America/Juneau': juneau,
      },
    })
    unfudged = unfudgeDateForProfileTimezone(original)
    expect(tz.format(unfudged, '%F %T')).toBe(original.toString('yyyy-MM-dd HH:mm:ss'))
  })
})

describe('sameYear', () => {
  afterEach(() => {
    tzInTest.restore()
  })

  it('should return true iff both dates from same year', () => {
    const date1 = new Date(0)
    const date2 = new Date(+date1 + 86400000)
    const date3 = new Date(+date1 - 86400000)
    expect(sameYear(date1, date2)).toBe(true)
    expect(sameYear(date1, date3)).toBe(false)
  })

  it('should compare relative to profile timezone', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
    })
    const date1 = new Date(5 * 3600000) // 5am UTC = 12am EST
    const date2 = new Date(+date1 + 1000) // Jan 1, 1970 at 11:59:59pm EST
    const date3 = new Date(+date1 - 1000) // Jan 2, 1970 at 00:00:01am EST
    expect(sameYear(date1, date2)).toBe(true)
    expect(sameYear(date1, date3)).toBe(false)
  })
})

describe('sameDate', () => {
  afterEach(() => {
    tzInTest.restore()
  })

  it('should return true iff both times from same day', () => {
    const date1 = new Date(86400000)
    const date2 = new Date(+date1 + 3600000)
    const date3 = new Date(+date1 - 3600000)
    expect(sameDate(date1, date2)).toBe(true)
    expect(sameDate(date1, date3)).toBe(false)
  })
})
