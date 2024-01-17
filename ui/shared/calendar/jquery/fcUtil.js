/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import * as tz from '@canvas/datetime'
import 'fullcalendar'
import '@canvas/datetime/jquery'

// expects a date (unfudged), and returns a fullcalendar moment
// (fudged) appropriate for passing to fullcalendar methods
const wrap = function (date) {
  if (!date) {
    return null
  }
  return $.fullCalendar.moment($.fudgeDateForProfileTimezone(date))
}

// expects a fullcalendar moment (fudged) from a fullcalendar
// callback or as intended for a fullcalendar method, and returns
// the actual date (unfudged)
const unwrap = function (date) {
  if (!date) {
    return null
  }
  // sometimes date will have zone information, but sometimes it doesn't.
  // if it does, we can just use .toDate() to get the Date object in the
  // fudged timezone that the fullcalendar was working in, then unfudge it.
  // but if not, the .format() will return it in ISO8601 but without zone
  // information, and we assume its representing a time in the fudged zone.
  // so just parsing it from there is the same as unfudging it. we can't
  // use toDate() in that case as it would act as a UTC time there.
  if (date.hasZone()) {
    return $.unfudgeDateForProfileTimezone(date.toDate())
  } else {
    return tz.parse(date.format())
  }
}

// returns a fullcalendar moment (fudged) representing now
const now = function () {
  return wrap(new Date())
}

// returns a new moment with same values as the last
const clone = function (moment) {
  return $.fullCalendar.moment(moment)
}

// compensates for intervals spanning DST changes
const addMinuteDelta = function (moment, minuteDelta) {
  let date
  // eslint-disable-next-line no-bitwise
  const dayDelta = (minuteDelta / 1440) | 0
  minuteDelta %= 1440
  date = unwrap(moment)
  date = tz.shift(date, (dayDelta < 0 ? '' : '+') + dayDelta + ' days')
  date = tz.shift(date, (minuteDelta < 0 ? '' : '+') + minuteDelta + ' minutes')
  return wrap(date)
}

export default {
  wrap,
  unwrap,
  now,
  clone,
  addMinuteDelta,
}
