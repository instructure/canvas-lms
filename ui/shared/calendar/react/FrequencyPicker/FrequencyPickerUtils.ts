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

import {Moment} from 'moment-timezone'
import {useScope} from '@canvas/i18n'
import RRuleHelper, {RRuleHelperSpec} from '../RecurringEvents/RRuleHelper'
import {AllRRULEDayValues} from '../RecurringEvents/types'
import {cardinalDayInMonth} from '../RecurringEvents/RepeatPicker/RepeatPicker'

export type FrequencyOptionValue =
  | 'not-repeat'
  | 'daily'
  | 'weekly-day'
  | 'monthly-nth-day'
  | 'annually'
  | 'every-weekday'
  | 'custom'
export type FrequencyOption = {id: FrequencyOptionValue; label: string}
export type FrequencyOptionsArray = FrequencyOption[]

const I18n = useScope('calendar_frequency_picker')
const dayRRULEValues = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA']

// Gets the index of the weekday of the month of the given moment.
// If is the last -1 is returned.
const weekdayInMonth = (referenceDate: Moment): number => {
  let day = referenceDate.clone().startOf('month').day(referenceDate.day())
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

  let index = days.findIndex(d => d.date() === referenceDate.date())
  if (index + 1 >= days.length) {
    index = -1
  }

  return index
}

export const generateFrequencyOptions = (
  referenceDate: Moment,
  locale: string = 'en'
): FrequencyOptionsArray => {
  const momentLocale = referenceDate.locale(locale)
  const day = I18n.lookup('date.day_names').at(momentLocale.day())
  const month = I18n.lookup('date.month_names').at(momentLocale.month() + 1)
  const date = momentLocale.date()
  const weekdayIndex = weekdayInMonth(momentLocale)
  const weekNumber = [
    I18n.t('first', 'first'),
    I18n.t('second', 'second'),
    I18n.t('third', 'third'),
    I18n.t('fourth', 'fourth'),
    I18n.t('last', 'last'),
  ].at(weekdayIndex)
  return [
    {id: 'not-repeat', label: I18n.t('not_repeat', 'Does not repeat')},
    {id: 'daily', label: I18n.t('daily', 'Daily')},
    {
      id: 'weekly-day',
      label: I18n.t('weekly_day', 'Weekly on %{day}', {day}),
    },
    {
      id: 'monthly-nth-day',
      label: I18n.t('monthly_last_day', 'Monthly on %{weekNumber} %{day}', {weekNumber, day}),
    },
    {
      id: 'annually',
      label: I18n.t('annually', 'Annually on %{month} %{date}', {month, date}),
    },
    {
      id: 'every-weekday',
      label: I18n.t('every_weekday', 'Every weekday (Monday to Friday)'),
    },
    {
      id: 'custom',
      label: I18n.t('custom', 'Custom...'),
    },
  ]
}

export const generateFrequencyRRule = (
  id: FrequencyOptionValue,
  momentLocale: Moment
): string | null => {
  /*
  We are using UTC time instead of local time or local time + zone reference.
  https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.5
  https://www.rfc-editor.org/rfc/rfc5545#section-3.3.5
   */
  const utcMoment = momentLocale.utc()
  let weekdayIndex = weekdayInMonth(momentLocale)

  if (weekdayIndex >= 0) {
    weekdayIndex++
  }

  switch (id) {
    case 'not-repeat':
      return null
    // COUNT = Backend maximum is 200
    case 'daily':
      return 'FREQ=DAILY;INTERVAL=1;COUNT=200'
    case 'weekly-day':
      // COUNT = Average weeks in a year
      return `FREQ=WEEKLY;BYDAY=${dayRRULEValues.at(utcMoment.day())};INTERVAL=1;COUNT=52`
    case 'monthly-nth-day':
      // COUNT = Months in a year
      return `FREQ=MONTHLY;BYSETPOS=${weekdayIndex};BYDAY=${dayRRULEValues.at(
        utcMoment.day()
      )};INTERVAL=1;COUNT=12`
    case 'annually': {
      const month = utcMoment.format('MM')
      const date = utcMoment.format('DD')
      // COUNT = The event will occur for five years
      return `FREQ=YEARLY;BYMONTH=${month};BYMONTHDAY=${date};INTERVAL=1;COUNT=5`
    }
    case 'every-weekday':
      // COUNT = Average weeks in a year
      return 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;INTERVAL=1;COUNT=52'
    default:
      // Custom option should open another modal selecting dates
      return null
  }
}

export const rruleToFrequencyOptionValue = (
  eventStart: Moment,
  rrule: string
): FrequencyOptionValue => {
  if (rrule.length === 0) return 'custom'

  const spec: RRuleHelperSpec = RRuleHelper.parseString(rrule)

  if (spec.interval !== 1) return 'custom'

  if (spec.freq === 'DAILY') {
    return 'daily'
  }

  if (
    spec.freq === 'WEEKLY' &&
    Array.isArray(spec.weekdays) &&
    spec.weekdays.length === 1 &&
    AllRRULEDayValues[eventStart.weekday()] === spec.weekdays[0]
  ) {
    return 'weekly-day'
  }
  if (
    spec.freq === 'MONTHLY' &&
    !Number.isNaN(spec.pos) &&
    Array.isArray(spec.weekdays) &&
    spec.weekdays.length === 1 &&
    AllRRULEDayValues[eventStart.weekday()] === spec.weekdays[0]
  ) {
    const nthday = cardinalDayInMonth(eventStart)
    if (nthday.cardinal === spec.pos || (nthday.last && spec.pos === -1)) {
      return 'monthly-nth-day'
    }
  }
  if (
    spec.freq === 'YEARLY' &&
    eventStart.month() + 1 === spec.month &&
    eventStart.date() === spec.monthdate
  ) {
    return 'annually'
  }
  if (
    spec.freq === 'WEEKLY' &&
    spec.weekdays?.toString() === ['MO', 'TU', 'WE', 'TH', 'FR'].toString()
  ) {
    return 'every-weekday'
  }
  return 'custom'
}
