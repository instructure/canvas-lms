/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import fcUtil from '@canvas/calendar/jquery/fcUtil'
import * as tz from '@canvas/datetime'
import tzInTest from '@canvas/datetime/specHelpers'
import timezone from 'timezone'
import denver from 'timezone/America/Denver'

QUnit.module('Calendar', {
  setup() {
    tzInTest.configureAndRestoreLater({
      tz: timezone(denver, 'America/Denver'),
      tzData: {
        'America/Denver': denver,
      },
    })
  },
  teardown() {
    tzInTest.restore()
  },
})

test('addMinuteDelta: works with no DST shift', () => {
  let datetime1 = fcUtil.wrap('2017-01-01T00:00:00-07:00')
  let datetime2 = fcUtil.addMinuteDelta(datetime1, 1440)
  equal(tz.format(fcUtil.unwrap(datetime2), '%FT%T%z'), '2017-01-02T00:00:00-0700')
  datetime1 = fcUtil.wrap('2017-01-02T00:00:00-07:00')
  datetime2 = fcUtil.addMinuteDelta(datetime1, -1440)
  equal(tz.format(fcUtil.unwrap(datetime2), '%FT%T%z'), '2017-01-01T00:00:00-0700')
})

test('addMinuteDelta: works across standard -> DST shift', () => {
  let datetime1 = fcUtil.wrap('2017-03-12T00:00:00-07:00')
  let datetime2 = fcUtil.addMinuteDelta(datetime1, 1440)
  equal(tz.format(fcUtil.unwrap(datetime2), '%FT%T%z'), '2017-03-13T00:00:00-0600')
  datetime1 = fcUtil.wrap('2017-11-06T00:00:00-07:00')
  datetime2 = fcUtil.addMinuteDelta(datetime1, -1440)
  equal(tz.format(fcUtil.unwrap(datetime2), '%FT%T%z'), '2017-11-05T00:00:00-0600')
})

test('addMinuteDelta: works across DST -> standard shift', () => {
  let datetime1 = fcUtil.wrap('2017-11-05T00:00:00-06:00')
  let datetime2 = fcUtil.addMinuteDelta(datetime1, 1440)
  equal(tz.format(fcUtil.unwrap(datetime2), '%FT%T%z'), '2017-11-06T00:00:00-0700')
  datetime1 = fcUtil.wrap('2017-03-13T00:00:00-06:00')
  datetime2 = fcUtil.addMinuteDelta(datetime1, -1440)
  equal(tz.format(fcUtil.unwrap(datetime2), '%FT%T%z'), '2017-03-12T00:00:00-0700')
})
