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

import DateHelper from '../dateHelper'
import {isMidnight} from '@instructure/moment-utils'
import {isDate, isNull, isUndefined} from 'lodash'
import tzInTest from '@instructure/moment-utils/specHelpers'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import juneau from 'timezone/America/Juneau'
import tokyo from 'timezone/Asia/Tokyo'
import {getI18nFormats} from '../configureDateTime'

const defaultAssignment = () => ({
  title: 'assignment',
  created_at: '2015-07-06T18:35:22Z',
  due_at: '2015-07-14T18:35:22Z',
  updated_at: '2015-07-07T18:35:22Z',
})

describe('DateHelper', () => {
  describe('#parseDates', () => {
    test('returns a new object with specified dates parsed', () => {
      let assignment = defaultAssignment()
      const datesToParse = ['created_at', 'due_at']
      assignment = DateHelper.parseDates(assignment, datesToParse)
      expect(isDate(assignment.created_at)).toBe(true)
      expect(isDate(assignment.due_at)).toBe(true)
      expect(isDate(assignment.updated_at)).toBe(false)
    })

    test('gracefully handles null values', () => {
      let assignment = defaultAssignment()
      assignment.due_at = null
      const datesToParse = ['created_at', 'due_at']
      assignment = DateHelper.parseDates(assignment, datesToParse)
      expect(isDate(assignment.created_at)).toBe(true)
      expect(isNull(assignment.due_at)).toBe(true)
    })

    test('gracefully handles undefined values', () => {
      let assignment = defaultAssignment()
      const datesToParse = ['created_at', 'undefined_due_at']
      assignment = DateHelper.parseDates(assignment, datesToParse)
      expect(isDate(assignment.created_at)).toBe(true)
      expect(isUndefined(assignment.undefined_due_at)).toBe(true)
    })
  })

  describe('#formatDatetimeForDisplay', () => {
    afterEach(() => {
      tzInTest.restore()
    })

    test('formats the date for display, adjusted for the timezone', () => {
      const assignment = defaultAssignment()
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
        formats: getI18nFormats(),
      })
      let formattedDate = DateHelper.formatDatetimeForDisplay(assignment.due_at)
      expect(formattedDate).toBe('Jul 14, 2015 at 2:35pm')
      tzInTest.configureAndRestoreLater({
        tz: timezone(juneau, 'America/Juneau'),
        tzData: {
          'America/Juneau': juneau,
        },
        formats: getI18nFormats(),
      })
      formattedDate = DateHelper.formatDatetimeForDisplay(assignment.due_at)
      expect(formattedDate).toBe('Jul 14, 2015 at 10:35am')
    })

    test('by default, includes the year if it matches the current year', () => {
      const now = new Date()
      const year = now.getFullYear()
      const formattedDate = DateHelper.formatDatetimeForDisplay(now)
      const includesYear = new RegExp(`, ${year}`)
      expect(includesYear.test(formattedDate)).toBe(true)
    })

    test("can specify 'short' format which excludes the year if it matches the current year", () => {
      const now = new Date()
      const year = now.getFullYear()
      const formattedDate = DateHelper.formatDatetimeForDisplay(now, 'short')
      const includesYear = new RegExp(`, ${year}`)
      expect(includesYear.test(formattedDate)).toBe(false)
    })
  })

  describe('#formatDateForDisplay', () => {
    afterEach(() => {
      tzInTest.restore()
    })

    test('formats the date for display, adjusted for the timezone, excluding the time', () => {
      const assignment = defaultAssignment()
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
        formats: getI18nFormats(),
      })
      let formattedDate = DateHelper.formatDateForDisplay(assignment.due_at)
      expect(formattedDate).toBe('Jul 14, 2015')
      tzInTest.configureAndRestoreLater({
        tz: timezone(juneau, 'America/Juneau'),
        tzData: {
          'America/Juneau': juneau,
        },
        formats: getI18nFormats(),
      })
      formattedDate = DateHelper.formatDateForDisplay(assignment.due_at)
      expect(formattedDate).toBe('Jul 14, 2015')
    })
  })

  describe('#formatDatetimeForDiscussions', () => {
    afterEach(() => {
      tzInTest.restore()
    })

    test('formats the date for display, adjusted for the user settings timezone', () => {
      const assignment = defaultAssignment()
      tzInTest.configureAndRestoreLater({
        tzData: {
          'America/Detroit': detroit,
          'Asia/Tokyo': tokyo,
        },
        formats: getI18nFormats(),
      })
      ENV.TIMEZONE = 'Asia/Tokyo'
      let formattedDate = DateHelper.formatDatetimeForDiscussions(assignment.due_at)
      expect(formattedDate).toBe('Jul 15, 2015 3:35am')
      ENV.TIMEZONE = 'America/Detroit'
      formattedDate = DateHelper.formatDatetimeForDiscussions(assignment.due_at)
      expect(formattedDate).toBe('Jul 14, 2015 2:35pm')
    })
  })

  describe('#isMidnight', () => {
    afterEach(() => {
      tzInTest.restore()
    })

    test('returns true if the time is midnight, adjusted for the timezone', () => {
      const date = '2015-07-14T04:00:00Z'
      tzInTest.configureAndRestoreLater({
        tz: timezone(detroit, 'America/Detroit'),
        tzData: {
          'America/Detroit': detroit,
        },
      })
      expect(isMidnight(date)).toBe(true)
      tzInTest.configureAndRestoreLater({
        tz: timezone(juneau, 'America/Juneau'),
        tzData: {
          'America/Juneau': juneau,
        },
      })
      expect(isMidnight(date)).toBe(false)
    })
  })
})
