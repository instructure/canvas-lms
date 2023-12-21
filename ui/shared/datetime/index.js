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

import {parse, format} from 'datetime'

export {hasMeridiem as hasMeridian} from 'datetime'

export function isMidnight(date) {
  if (date === null) {
    return false
  }
  return format(date, '%R') === '00:00'
}

export function changeToTheSecondBeforeMidnight(date) {
  return parse(format(date, '%F 23:59:59'))
}

export function setToEndOfMinute(date) {
  return parse(format(date, '%F %R:59'))
}

// finds the given time of day on the given date ignoring dst conversion and such.
// e.g. if time is 2016-05-20 14:00:00 and date is 2016-03-17 23:59:59, the result will
// be 2016-03-17 14:00:00
export function mergeTimeAndDate(time, date) {
  return parse(format(date, '%F ') + format(time, '%T'))
}
