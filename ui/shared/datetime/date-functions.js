/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import I18n from 'i18n!instructure_date_and_time'
import tz from '@canvas/timezone'

// fudgeDateForProfileTimezone is used to apply an offset to the date which represents the
// difference between the user's configured timezone in their profile, and the timezone
// of the browser. We want to display times in the timezone of their profile. Use
// unfudgeDateForProfileTimezone to remove the correction before sending dates back to the server.
export function fudgeDateForProfileTimezone(date) {
  date = tz.parse(date)
  if (!date) return null
  let year = tz.format(date, '%Y')
  while (year.length < 4) year = '0' + year

  const formatted = tz.format(date, year + '-%m-%d %T')
  let fudgedDate = new Date(formatted)

  // In Safari, the return value from new Date(<string>) might be `Invalid Date`.
  // this is because, according to this note on:
  // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date#Timestamp_string
  // "Support for RFC 2822 format strings is by convention only."
  // So for those cases, we fall back on date.js's monkeypatched version of Date.parse,
  // which is what this method has always historically used before the speed optimization of using new Date()
  // eslint-disable-next-line no-restricted-globals
  if (isNaN(fudgedDate)) {
    // checking for isNaN(<date>) is how you check for `Invalid Date`
    fudgedDate = Date.parse(formatted)
  }

  return fudgedDate
}

export function unfudgeDateForProfileTimezone(date) {
  date = tz.parse(date)
  if (!date) return null
  // format fudged date into browser timezone without tz-info, then parse in
  // profile timezone. then, as desired:
  // tz.format(output, '%Y-%m-%d %H:%M:%S') == input.toString('yyyy-MM-dd hh:mm:ss')
  return tz.parse(date.toString('yyyy-MM-dd HH:mm:ss'))
}

// this batch of methods assumes *real* dates passed in (or, really, anything
// tz.parse() can recognize. so timestamps are cool, too. but not fudged dates).
// use accordingly
export function sameYear(d1, d2) {
  return tz.format(d1, '%Y') === tz.format(d2, '%Y')
}
export function sameDate(d1, d2) {
  return tz.format(d1, '%F') === tz.format(d2, '%F')
}
export function dateString(date, options) {
  if (date == null) return ''
  const timezone = options && options.timezone
  let format = options && options.format

  if (format === 'full') {
    format = 'date.formats.full'
  } else if (format !== 'medium' && sameYear(date, new Date())) {
    format = 'date.formats.short'
  } else {
    format = 'date.formats.medium'
  }

  if (typeof timezone === 'string' || timezone instanceof String) {
    return tz.format(date, format, timezone) || ''
  } else {
    return tz.format(date, format) || ''
  }
}

export function timeString(date, options) {
  if (date == null) return ''
  const timezone = options && options.timezone

  if (typeof timezone === 'string' || timezone instanceof String) {
    // match ruby-side short format on the hour, e.g. `1pm`
    // can't just check getMinutes, cuz not all timezone offsets are on the hour
    const format =
      tz.hasMeridian() && tz.format(date, '%M', timezone) === '00'
        ? 'time.formats.tiny_on_the_hour'
        : 'time.formats.tiny'
    return tz.format(date, format, timezone) || ''
  }

  // match ruby-side short format on the hour, e.g. `1pm`
  // can't just check getMinutes, cuz not all timezone offsets are on the hour
  const format =
    tz.hasMeridian() && tz.format(date, '%M') === '00'
      ? 'time.formats.tiny_on_the_hour'
      : 'time.formats.tiny'
  return tz.format(date, format) || ''
}

export function datetimeString(datetime, options) {
  datetime = tz.parse(datetime)
  if (datetime == null) return ''
  const dateValue = dateString(datetime, options)
  const timeValue = timeString(datetime, options)
  return I18n.t('#time.event', '%{date} at %{time}', {date: dateValue, time: timeValue})
}
// end batch

export function discussionsDatetimeString(datetime, options) {
  datetime = tz.parse(datetime)
  if (datetime == null) return ''
  const dateValue = dateString(datetime, options)
  const timeValue = timeString(datetime, options)
  return I18n.t('#timeValue.event', '%{dateValue} %{timeValue}', {dateValue, timeValue})
}

export function friendlyDate(datetime, perspective) {
  if (perspective == null) {
    perspective = 'past'
  }
  const today = Date.today()
  const date = datetime.clone().clearTime()
  if (Date.equals(date, today)) {
    return I18n.t('#date.days.today', 'Today')
  } else if (Date.equals(date, today.add(-1).days())) {
    return I18n.t('#date.days.yesterday', 'Yesterday')
  } else if (Date.equals(date, today.add(1).days())) {
    return I18n.t('#date.days.tomorrow', 'Tomorrow')
  } else if (perspective === 'past' && date < today && date >= today.add(-6).days()) {
    return I18n.l('#date.formats.weekday', date)
  } else if (perspective === 'future' && date < today.add(7).days() && date >= today) {
    return I18n.l('#date.formats.weekday', date)
  }
  return I18n.l('#date.formats.medium', date)
}

export function friendlyDatetime(datetime, perspective) {
  const today = Date.today()
  if (Date.equals(datetime.clone().clearTime(), today)) {
    return I18n.l('#time.formats.tiny', datetime)
  } else {
    return friendlyDate(datetime, perspective)
  }
}
