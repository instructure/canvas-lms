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

const MINS = 60 * 1000

function formatObject(tz) {
  return {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
    timeZone: tz
  }
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
  const hereDate = new Date(jsDate.toLocaleString('en-US', formatObject(hereTZ)))
  const utcDate = new Date(jsDate.toLocaleString('en-US', formatObject('Etc/UTC')))
  return hereDate.getTime() - utcDate.getTime()
}

//
// Takes a Date object and a timezone, and returns the date offset in days
// from UTC for that timezone. Can only result in -1, 0, or 1
//
function utcDateOffset(date, hereTZ) {
  const jsDate = date instanceof Date ? date : new Date(date)
  const here = jsDate.toLocaleString('en-US', {day: 'numeric', timeZone: hereTZ})
  const utc = jsDate.toLocaleString('en-US', {day: 'numeric', timeZone: 'Etc/UTC'})
  return parseInt(utc, 10) - parseInt(here, 10)
}

export {changeTimezone, utcTimeOffset, utcDateOffset}
