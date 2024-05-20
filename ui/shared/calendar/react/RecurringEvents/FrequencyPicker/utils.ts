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

import type {Moment} from 'moment-timezone'
import {useScope} from '@canvas/i18n'
import RRuleHelper, {type RRuleHelperSpec} from '../RRuleHelper'
import {AllRRULEDayValues, RRULEWeekDayValues, type FrequencyOptionValue} from '../types'
import {cardinalDayInMonth, weekdayInMonth} from '../utils'
import RRuleToNaturalLanguage from '../RRuleNaturalLanguage'
import type {FrequencyOption} from './FrequencyPicker'

const FrequencyCounts = {
  daily: 365, // days in a year
  'weekly-day': 52, // weeks in a year
  'monthly-nth-day': 12, // Months in a year
  annually: 5, // The event will occur for five years
  'every-weekday': 52 * 5, // weeks in a year * weekdays
}

const I18n = useScope('calendar_frequency_picker')

export const generateFrequencyOptions = (
  eventStart: Moment,
  locale: string = 'en',
  timezone: string,
  rrule: string | null
): FrequencyOption[] => {
  const day = I18n.lookup('date.day_names').at(eventStart.day())
  const month = I18n.lookup('date.month_names').at(eventStart.month() + 1)
  const date = eventStart.date()
  const weekdayIndex = weekdayInMonth(eventStart)
  const weekNumber = [
    I18n.t('first', 'first'),
    I18n.t('second', 'second'),
    I18n.t('third', 'third'),
    I18n.t('fourth', 'fourth'),
    I18n.t('last', 'last'),
  ].at(weekdayIndex)
  const opts: FrequencyOption[] = [
    {id: 'not-repeat', label: I18n.t('not_repeat', 'Does not repeat')},
    {id: 'daily', label: I18n.t('daily', 'Daily')},
    {
      id: 'weekly-day',
      label: I18n.t('weekly_day', 'Weekly on %{day}', {day}),
    },
    {
      id: 'monthly-nth-day',
      label: I18n.t('monthly_last_day', 'Monthly on the %{weekNumber} %{day}', {weekNumber, day}),
    },
    {
      id: 'annually',
      label: I18n.t('annually', 'Annually on %{month} %{date}', {month, date}),
    },
    {
      id: 'every-weekday',
      label: I18n.t('every_weekday', 'Every weekday (Monday to Friday)'),
    },
  ]
  let updatedRRule = rrule
  if (updatedRRule) {
    // fix it up if the date changed
    const spec = RRuleHelper.parseString(updatedRRule)
    if (spec.freq === 'YEARLY') {
      if (spec.month !== eventStart.month() + 1) {
        spec.month = eventStart.month() + 1
      }
      if (spec.monthdate !== eventStart.date()) {
        spec.monthdate = eventStart.date()
      }
    } else if (spec.freq === 'MONTHLY') {
      if (spec.month !== undefined && spec.month !== eventStart.month() + 1) {
        spec.month = eventStart.month() + 1
      }
      if (spec.monthdate !== undefined && spec.monthdate !== eventStart.date()) {
        spec.monthdate = eventStart.date()
      }
      if (spec.pos !== undefined && spec.weekdays !== undefined) {
        const dcim = cardinalDayInMonth(eventStart)
        spec.pos = dcim.last ? -1 : dcim.cardinal
        spec.weekdays = [AllRRULEDayValues[dcim.dayOfWeek]]
      }
    }
    updatedRRule = new RRuleHelper(spec).toString()
    opts.push({
      id: 'saved-custom',
      label: RRuleToNaturalLanguage(updatedRRule, locale, timezone),
    })
  }
  opts.push({
    id: 'custom',
    label: I18n.t('custom', 'Custom...'),
  })
  return opts
}

// Return the RRULE corresponding to the given frequency option
// Will return null if the frequency  is not one of the presets.
// This boils down to 3 cases:
// 1. The option is 'not-repeat'
// 2. The option is 'custom' or 'saved-custom'
// 3. The option is invalid
// The calling code needs to differenciate between 1 and 2.
export const generateFrequencyRRULE = (
  id: FrequencyOptionValue,
  eventStart: Moment
): string | null => {
  /*
  We are using UTC time instead of local time or local time + zone reference.
  https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.5
  https://www.rfc-editor.org/rfc/rfc5545#section-3.3.5
   */
  let weekdayIndex = weekdayInMonth(eventStart)

  if (weekdayIndex >= 0) {
    weekdayIndex++
  }

  switch (id) {
    case 'not-repeat':
      return null
    case 'daily':
      return `FREQ=DAILY;INTERVAL=1;COUNT=${FrequencyCounts.daily}`
    case 'weekly-day':
      return `FREQ=WEEKLY;BYDAY=${AllRRULEDayValues.at(eventStart.day())};INTERVAL=1;COUNT=${
        FrequencyCounts['weekly-day']
      }`
    case 'monthly-nth-day':
      return `FREQ=MONTHLY;BYSETPOS=${weekdayIndex};BYDAY=${AllRRULEDayValues.at(
        eventStart.day()
      )};INTERVAL=1;COUNT=${FrequencyCounts['monthly-nth-day']}`
    case 'annually': {
      const month = eventStart.format('MM')
      const date = eventStart.format('DD')
      return `FREQ=YEARLY;BYMONTH=${month};BYMONTHDAY=${date};INTERVAL=1;COUNT=${FrequencyCounts.annually}`
    }
    case 'every-weekday':
      // COUNT = Average weeks in a year
      return `FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;INTERVAL=1;COUNT=${FrequencyCounts['every-weekday']}`
    default:
      // Custom option should open another modal selecting dates
      return null
  }
}

export const RRULEToFrequencyOptionValue = (
  eventStart: Moment,
  rrule: string | null | undefined
): FrequencyOptionValue => {
  if (rrule === null || rrule === undefined) return 'not-repeat'
  if (rrule.length === 0) return 'custom'

  const spec: RRuleHelperSpec = RRuleHelper.parseString(rrule)

  if (spec.interval !== 1) return 'saved-custom'

  if (spec.freq === 'DAILY' && spec.count === FrequencyCounts.daily) {
    return 'daily'
  }

  if (
    spec.freq === 'WEEKLY' &&
    spec.count === FrequencyCounts['weekly-day'] &&
    Array.isArray(spec.weekdays) &&
    spec.weekdays.length === 1 &&
    AllRRULEDayValues[eventStart.weekday()] === spec.weekdays[0]
  ) {
    return 'weekly-day'
  }

  if (
    spec.freq === 'MONTHLY' &&
    !Number.isNaN(spec.pos) &&
    spec.count === FrequencyCounts['monthly-nth-day'] &&
    AllRRULEDayValues[eventStart.weekday()] === spec.weekdays?.[0]
  ) {
    const nthday = cardinalDayInMonth(eventStart)
    if (nthday.cardinal === spec.pos || (nthday.last && spec.pos === -1)) {
      return 'monthly-nth-day'
    }
  }

  if (
    spec.freq === 'YEARLY' &&
    spec.count === FrequencyCounts.annually &&
    eventStart.month() + 1 === spec.month &&
    eventStart.date() === spec.monthdate
  ) {
    return 'annually'
  }
  if (
    spec.freq === 'WEEKLY' &&
    spec.count === FrequencyCounts['every-weekday'] &&
    spec.weekdays?.toString() === RRULEWeekDayValues.toString()
  ) {
    return 'every-weekday'
  }
  return 'saved-custom'
}

export const updateRRuleForNewDate = (
  newEventStart: Moment,
  rrule: string | null
): string | null => {
  if (rrule === null || rrule === undefined) return null

  const spec: RRuleHelperSpec = RRuleHelper.parseString(rrule)

  if (spec.freq === 'YEARLY') {
    spec.month = newEventStart.month() + 1
    spec.monthdate = newEventStart.date()
  } else if (spec.freq === 'MONTHLY') {
    if (spec.month !== undefined) {
      spec.month = newEventStart.month() + 1
    }
    if (spec.monthdate !== undefined) {
      spec.monthdate = newEventStart.date()
    }
    if (spec.pos !== undefined && spec.weekdays !== undefined) {
      const cdim = cardinalDayInMonth(newEventStart)
      spec.pos = cdim.last ? -1 : cdim.cardinal
      spec.weekdays = [AllRRULEDayValues[cdim.dayOfWeek]]
    }
  } else if (spec.freq === 'WEEKLY') {
    if (
      spec.weekdays !== undefined &&
      !(
        spec.count === FrequencyCounts['every-weekday'] &&
        spec.weekdays?.toString() === RRULEWeekDayValues.toString()
      )
    ) {
      spec.weekdays = [AllRRULEDayValues[newEventStart.weekday()]]
    }
  }
  return new RRuleHelper(spec).toString()
}
