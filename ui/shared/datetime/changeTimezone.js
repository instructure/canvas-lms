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

// Takes a Date object and a timezone name, and returns a new Date object
// shifted from the browser's timezone to the specified one

function changeTimezone(hereDate, desiredTZ) {
  const thereDate = new Date(hereDate.toLocaleString('en-US', formatObject(desiredTZ)))
  const diff = hereDate.getTime() - thereDate.getTime()

  return new Date(hereDate.getTime() - diff) // needs to subtract
}

//
// Takes a Date object and a timezone, and returns the offset from UTC
// for that timezone on that date.
//
function utcTimeOffset(date, hereTZ) {
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
