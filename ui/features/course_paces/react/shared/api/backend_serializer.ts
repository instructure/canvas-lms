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

moment.locale(window.ENV.MOMENT_LOCALE) // Set the locale globally

export const coursePaceTimezone =
  window.ENV?.CONTEXT_TIMEZONE ||
  window.ENV?.TIMEZONE ||
  Intl.DateTimeFormat().resolvedOptions().timeZone

// Set the timezone globally
moment.tz.setDefault(coursePaceTimezone)

// 2018-01-06 was a Saturday and 2018-01-07 was a Sunday. This is necessary because different
// locales use different weekday integers, so we need to determine what the current values
// would be so that the DatePicker knows to disable the right weekend days.
export const saturdayWeekdayInteger = moment('2018-01-06').weekday()
export const sundayWeekdayInteger = moment('2018-01-07').weekday()
export const weekendIntegers = [sundayWeekdayInteger, saturdayWeekdayInteger]

export const coursePaceDateFormatter = (locale = ENV.LOCALE) =>
  new Intl.DateTimeFormat(locale, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    timeZone: coursePaceTimezone,
  }).format

export const coursePaceDateShortFormatter = (locale = ENV.LOCALE) =>
  new Intl.DateTimeFormat(locale, {
    month: 'numeric',
    day: 'numeric',
    year: '2-digit',
    timeZone: coursePaceTimezone,
  }).format
