// @ts-nocheck
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

import {BlackoutDate} from '../../shared/types'
import {weekendIntegers} from '../../shared/api/backend_serializer'
import * as tz from '@canvas/datetime'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('course_paces_app')

/*
 * Any date manipulation should be consolidated into helper functions in this file
 */

// Takes a date string and formats it in iso8601 in the course pace timezone
export const formatDate = (date: string | moment.Moment): string => {
  return moment(date).toISOString(true)
}

// Calculates the days between the start and end dates.
// Skips weekends if excludeWeekends is true, and includes
// the end date if inclusiveEnd is true.
// Note: before evaluating, start and end are converted to end of day
//       to keep from being surprised, blackoutDates should also be
//       set to end of day.
export const daysBetween = (
  start: string | moment.Moment,
  end: string | moment.Moment,
  excludeWeekends: boolean,
  blackoutDates: BlackoutDate[] = [],
  inclusiveEnd = true
): number => {
  const startDate = moment(start).endOf('day')
  const endDate = moment(end).endOf('day')

  if (inclusiveEnd) {
    endDate.endOf('day').add(1, 'day')
  }

  const fullDiff = endDate.diff(startDate, 'days')

  if (fullDiff === 0) {
    return fullDiff
  }

  const smallerDate = fullDiff > 0 ? startDate : endDate
  const sign: 'plus' | 'minus' = fullDiff > 0 ? 'plus' : 'minus'

  const countingDate = smallerDate.clone()
  let count = 0

  for (let i = 0; i < Math.abs(fullDiff); i++) {
    if (!dayIsDisabled(countingDate, excludeWeekends, blackoutDates)) {
      count = sign === 'plus' ? count + 1 : count - 1
    }
    countingDate.add(1, 'day')
  }

  return count
}

// Modifies a starting date string by numberOfDays. Doesn't include the start in that calculation.
// e.g., 2018-01-01 + 2 would equal 2018-01-03. (So make sure to subtract a day from start if you want
// the starting day included.) Skips blackout days if they are provided.
export const addDays = (
  start: string | moment.Moment,
  numberOfDays: number,
  excludeWeekends: boolean,
  blackoutDates: BlackoutDate[] = []
): string => {
  const date = moment(start)

  while (dayIsDisabled(date, excludeWeekends, blackoutDates)) {
    date.add(1, 'day')
  }

  while (numberOfDays > 0) {
    date.add(1, 'days')

    if (!dayIsDisabled(date, excludeWeekends, blackoutDates)) {
      numberOfDays--
    }
  }

  return formatDate(date.startOf('day'))
}

const msInADay = 1000 * 60 * 60 * 24
export const rawDaysBetweenInclusive = (
  start_date: moment.Moment,
  end_date: moment.Moment
): number => Math.round(end_date.diff(start_date) / msInADay) + 1

export const stripTimezone = (date: string): string => {
  return date.split('T')[0]
}

export const inBlackoutDate = (
  date: moment.Moment | string,
  blackoutDates: BlackoutDate[]
): boolean => {
  date = moment(date)

  return blackoutDates.some(blackoutDate => {
    const blackoutStart = blackoutDate.start_date
    const blackoutEnd = blackoutDate.end_date
    return date >= blackoutStart && date <= blackoutEnd
  })
}

/* Non exported helper functions */

const dayIsDisabled = (
  date: moment.Moment,
  excludeWeekends: boolean,
  blackoutDates: BlackoutDate[]
) => {
  return (
    (excludeWeekends && weekendIntegers.includes(date.weekday())) ||
    inBlackoutDate(date, blackoutDates)
  )
}

export const formatTimeAgoDate = date => {
  if (typeof date === 'string') {
    date = Date.parse(date)
  }
  const MINUTE = 60 * 1000
  const now = new Date()
  const diff = Math.abs(now.valueOf() - date)
  const minutes = Math.round(diff / MINUTE)
  const hours = Math.round(minutes / 60)
  const days = Math.round(hours / 24)
  const weeks = Math.round(days / 7)

  if (minutes < 5) {
    return I18n.t('Just Now')
  }
  if (minutes < 60) {
    return I18n.t('%{count} minutes ago', {count: minutes})
  }
  if (hours < 24) {
    return I18n.t({one: '1 hour ago', other: '%{count} hours ago'}, {count: hours})
  }
  if (days < 7) {
    return I18n.t({one: '1 day ago', other: '%{count} days ago'}, {count: days})
  }
  if (weeks < 4) {
    return I18n.t({one: '1 week ago', other: '%{count} weeks ago'}, {count: weeks})
  }
  return tz.format(date, 'date.formats.long')
}
