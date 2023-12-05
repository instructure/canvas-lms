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

import moment from 'moment'
import type {Moment} from 'moment-timezone'
import {
  AllRRULEDayValues,
  type FrequencyValue,
  type MonthlyModeValue,
  type SelectedDaysArray,
} from './types'

type CardinalDayInMonth = {
  cardinal: number
  last: boolean
  dayOfWeek: number // 0-6, Sunday-Saturday
}

export const weekdaysFromMoment = (m: moment.Moment): SelectedDaysArray => [
  AllRRULEDayValues[m.day()],
]

export const cardinalDayInMonth = (m: moment.Moment): CardinalDayInMonth => {
  let last = false
  const n = Math.ceil(m.date() / 7)
  if (n >= 4 && m.clone().add(1, 'week').month() !== m.month()) {
    last = true
  }
  return {cardinal: n, last, dayOfWeek: m.day()}
}

export const getWeekdayName = (
  datetime: moment.Moment,
  locale: string,
  timezone: string
): string => {
  return new Intl.DateTimeFormat(locale, {weekday: 'long', timeZone: timezone}).format(
    datetime.toDate()
  )
}

export const isLastWeekdayInMonth = (m: moment.Moment): boolean => {
  const n = Math.ceil(m.date() / 7)
  return n >= 4 && m.clone().add(1, 'week').month() !== m.month()
}

// Gets the index of the weekday of the month of the given moment.
// If is the last -1 is returned.
export const weekdayInMonth = (eventStart: Moment): number => {
  let day = eventStart.clone().startOf('month').day(eventStart.day())
  const days = []

  // Sometimes it can return a weekday of previous month
  if (day.date() > 7) {
    day.add(7, 'd')
  }

  const month = day.month()
  while (month === day.month()) {
    days.push(day)
    day = day.clone().add(7, 'd')
  }

  let index = days.findIndex(d => d.date() === eventStart.date())
  if (index + 1 >= days.length) {
    index = -1
  }

  return index
}

export const getSelectTextWidth = (strings: string[]) => {
  const testdiv = document.createElement('div')
  testdiv.setAttribute('style', 'position: absolute; left: -9999px; visibility: hidden;')
  testdiv.innerHTML = `<div><div>${strings.join('</div><div>')}</div></div>`
  document.body.appendChild(testdiv)
  const w = `${testdiv.getBoundingClientRect().width + 24 + 12 + 14 + 2}px`
  testdiv.remove()
  return w
}

export const getMonthlyMode = (
  freq: FrequencyValue,
  weekdays?: SelectedDaysArray,
  pos?: number
): MonthlyModeValue => {
  if (freq === 'MONTHLY' && Array.isArray(weekdays) && typeof pos === 'number') {
    if (pos >= 0) {
      return 'BYMONTHDAY'
    } else {
      return 'BYLASTMONTHDAY'
    }
  }
  return 'BYMONTHDATE'
}
