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
      label: I18n.t('Weekly on %{day}', {day}),
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
    case 'daily':
      return 'FREQ=DAILY;INTERVAL=1'
    case 'weekly-day':
      return `FREQ=WEEKLY;BYDAY=${dayRRULEValues.at(utcMoment.day())};INTERVAL=1`
    case 'monthly-nth-day':
      return `FREQ=MONTHLY;BYSETPOS=${weekdayIndex};BYDAY=${dayRRULEValues.at(
        utcMoment.day()
      )};INTERVAL=1`
    case 'annually': {
      const month = utcMoment.format('MM')
      const date = utcMoment.format('DD')
      return `FREQ=YEARLY;BYMONTH=${month};BYMONTHDAY=${date}`
    }
    case 'every-weekday':
      return 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;INTERVAL=1'
    default:
      // Custom option should open another modal selecting dates
      return null
  }
}
