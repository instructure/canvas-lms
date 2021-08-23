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

import DateHelper from '@canvas/datetime/dateHelper'
import {isDate, isNull, isUndefined} from 'lodash'
import tz from '@canvas/timezone'
import tzInTest from '@canvas/timezone/specHelpers'
import timezone from 'timezone'
import detroit from 'timezone/America/Detroit'
import juneau from 'timezone/America/Juneau'

const defaultAssignment = () => ({
  title: 'assignment',
  created_at: '2015-07-06T18:35:22Z',
  due_at: '2015-07-14T18:35:22Z',
  updated_at: '2015-07-07T18:35:22Z'
})

QUnit.module('DateHelper#parseDates')

test('returns a new object with specified dates parsed', () => {
  let assignment = defaultAssignment()
  const datesToParse = ['created_at', 'due_at']
  assignment = DateHelper.parseDates(assignment, datesToParse)
  ok(isDate(assignment.created_at))
  ok(isDate(assignment.due_at))
  notOk(isDate(assignment.updated_at))
})

test('gracefully handles null values', () => {
  let assignment = defaultAssignment()
  assignment.due_at = null
  const datesToParse = ['created_at', 'due_at']
  assignment = DateHelper.parseDates(assignment, datesToParse)
  ok(isDate(assignment.created_at))
  ok(isNull(assignment.due_at))
})

test('gracefully handles undefined values', () => {
  let assignment = defaultAssignment()
  const datesToParse = ['created_at', 'undefined_due_at']
  assignment = DateHelper.parseDates(assignment, datesToParse)
  ok(isDate(assignment.created_at))
  ok(isUndefined(assignment.undefined_due_at))
})

QUnit.module('DateHelper#formatDatetimeForDisplay', {
  setup() {
  },
  teardown() {
    tzInTest.restore()
  }
})

test('formats the date for display, adjusted for the timezone', () => {
  const assignment = defaultAssignment()
  tzInTest.configureAndRestoreLater({
    tz: timezone(detroit, 'America/Detroit'),
    tzData: {
      'America/Detroit': detroit
    }
  })
  let formattedDate = DateHelper.formatDatetimeForDisplay(assignment.due_at)
  equal(formattedDate, 'Jul 14, 2015 at 2:35pm')
  tzInTest.configureAndRestoreLater({
    tz: timezone(juneau, 'America/Juneau'),
    tzData: {
      'America/Juneau': juneau
    }
  })
  formattedDate = DateHelper.formatDatetimeForDisplay(assignment.due_at)
  equal(formattedDate, 'Jul 14, 2015 at 10:35am')
})

test('by default, includes the year if it matches the current year', () => {
  const now = new Date()
  const year = now.getFullYear()
  const formattedDate = DateHelper.formatDatetimeForDisplay(now)
  const includesYear = new RegExp(`, ${year}`)
  strictEqual(includesYear.test(formattedDate), true)
})

test("can specify 'short' format which excludes the year if it matches the current year", () => {
  const now = new Date()
  const year = now.getFullYear()
  const formattedDate = DateHelper.formatDatetimeForDisplay(now, 'short')
  const includesYear = new RegExp(`, ${year}`)
  strictEqual(includesYear.test(formattedDate), false)
})

QUnit.module('DateHelper#formatDateForDisplay', {
  teardown() {
    tzInTest.restore()
  }
})

test('formats the date for display, adjusted for the timezone, excluding the time', () => {
  const assignment = defaultAssignment()
  tzInTest.configureAndRestoreLater({
    tz: timezone(detroit, 'America/Detroit'),
    tzData: {
      'America/Detroit': detroit
    }
  })
  let formattedDate = DateHelper.formatDateForDisplay(assignment.due_at)
  equal(formattedDate, 'Jul 14, 2015')
  tzInTest.configureAndRestoreLater({
    tz: timezone(juneau, 'America/Juneau'),
    tzData: {
      'America/Juneau': juneau
    }
  })
  formattedDate = DateHelper.formatDateForDisplay(assignment.due_at)
  equal(formattedDate, 'Jul 14, 2015')
})

QUnit.module('DateHelper#isMidnight', {
  teardown() {
    tzInTest.restore()
  }
})

test('returns true if the time is midnight, adjusted for the timezone', () => {
  const date = '2015-07-14T04:00:00Z'
  tzInTest.configureAndRestoreLater({
    tz: timezone(detroit, 'America/Detroit'),
    tzData: {
      'America/Detroit': detroit
    }
  })
  ok(DateHelper.isMidnight(date))
  tzInTest.configureAndRestoreLater({
    tz: timezone(juneau, 'America/Juneau'),
    tzData: {
      'America/Juneau': juneau
    }
  })
  notOk(DateHelper.isMidnight(date))
})
