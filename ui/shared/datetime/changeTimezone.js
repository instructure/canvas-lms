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
import moment from 'moment-timezone'

const MINS = 60 * 1000

function formatObject(tz) {
  return {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
    timeZone: tz,
  }
}

// PRIVATE: Takes a Date object and a timezone, and constructs a string that
// represents the given Date, represented in the given timezone, that we
// know new Date() will be able to handle, of the form: YYYY-MM-DDThh:mm:ss
function parseableDateString(date, tz) {
  // in case Intl has been polyfilled, we'll need the native one here because
  // @formatjs does not provide formatToParts()
  const DTF = Intl.NativeDateTimeFormat || Intl.DateTimeFormat
  const fmtr = new DTF('en-US', formatObject(tz))
  const r = fmtr
    .formatToParts(date)
    .reduce((acc, obj) => Object.assign(acc, {[obj.type]: obj.value}), {})
  let iso = `${r.year}-${r.month}-${r.day}T${r.hour}:${r.minute}:${r.second}`
  if (iso.length < 19) iso = '0' + iso // in case of a year before 1000
  return iso
}

//
// Takes a Date object and an object with two optional properties,
//    originTZ:  an origin timezone
//    desiredTZ:  a timezone we are shiftint to
// and returns a new Date object representing the given date in
// the origin timezone shifted to the desired timezone
//
// If either timezone is unspecified or null, the browser's local
// timezone is used
//
function changeTimezone(date, {originTZ = null, desiredTZ = null}) {
  const localTz = originTZ || Intl.DateTimeFormat().resolvedOptions().timeZone
  const originTZOffset = moment.tz(localTz).utcOffset()
  const desiredTZOffset = moment.tz(desiredTZ).utcOffset()
  // let's bypass getTimezoneOffset if the desired timezone is equal or behind
  // the user TZ, this fixes some bugs when shifting in or out of DST
  if (originTZOffset >= desiredTZOffset) {
    originTZ = localTz
  }
  const originOffset = utcTimeOffset(date, originTZ)
  const desiredOffset = utcTimeOffset(date, desiredTZ)
  return new Date(date.getTime() + originOffset - desiredOffset)
}

//
// Takes a Date object and a timezone, and returns the offset from UTC
// for that timezone on that date. If no timezone is specified, the browser's
// timezone is used
//
function utcTimeOffset(date, hereTZ = null) {
  if (hereTZ === null) {
    // getTimezoneOffset returns minutes and has the "wrong" sign, sigh
    return -date.getTimezoneOffset() * MINS
  }
  const jsDate = date instanceof Date ? date : new Date(date)
  const hereDate = new Date(parseableDateString(jsDate, hereTZ))
  const utcDate = new Date(parseableDateString(jsDate, 'Etc/UTC'))
  return hereDate.getTime() - utcDate.getTime()
}

//
// Takes a Date object and a timezone, and returns the date offset in days
// from UTC for that timezone. Can only result in -1, 0, or 1
//
function utcDateOffset(date, hereTZ) {
  const jsDate = date instanceof Date ? date : new Date(date)
  const dayOfMonth = timeZone => {
    const DTF = Intl.NativeDateTimeFormat || Intl.DateTimeFormat
    const fmtr = new DTF('en-US', {day: 'numeric', timeZone})
    return parseInt(fmtr.format(jsDate), 10)
  }
  const here = dayOfMonth(hereTZ)
  const utc = dayOfMonth('Etc/UTC')
  let diff = utc - here
  if (diff < -1) diff = 1 // crossed a month going forwards
  if (diff > 1) diff = -1 // crossed a month going backwards
  return diff
}

export {changeTimezone, utcTimeOffset, utcDateOffset}
