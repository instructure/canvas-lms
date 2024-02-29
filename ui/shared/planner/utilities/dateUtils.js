/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

/* eslint-disable new-cap */

import moment from 'moment-timezone'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('planner')

let dateTimeFormatters = {}

export function initializeDateTimeFormatters(formatters) {
  dateTimeFormatters = formatters
}

function getTodaysDetails(today = moment()) {
  const yesterday = today.clone().subtract(1, 'days')
  const tomorrow = today.clone().add(1, 'days')

  return {today, yesterday, tomorrow}
}

export function isToday(date, today = moment()) {
  const momentizedDate = new moment(date)
  return today.isSame(momentizedDate, 'day')
}

export function isInFuture(date, today = moment()) {
  const momentizedDate = new moment(date)
  return momentizedDate.isAfter(today, 'day')
}

export function isTodayOrBefore(date, today = moment()) {
  const momentizedDate = new moment(date)
  return momentizedDate.isBefore(today, 'day') || momentizedDate.isSame(today, 'day')
  // moment.isSameOrBefore isn't available until moment 2.11, but until we get off
  // all of ui-core, it ends up pulling in an earlier version.
  // return momentizedDate.isSameOrBefore(today, 'day');
}

export function isDay(date, target) {
  const momentizedDate = new moment(date)
  const momentizedTarget = new moment(target)
  return momentizedDate.isSame(momentizedTarget, 'day')
}

export function isThisWeek(day) {
  const thisWeekStart = new moment().startOf('week')
  const thisWeekEnd = new moment().endOf('week')
  return isInMomentRange(new moment(day), thisWeekStart, thisWeekEnd)
}

// determines if the checkMoment falls on or inbetween the firstMoment and the lastMoment
export function isInMomentRange(checkMoment, firstMoment, lastMoment) {
  const isOnOrAfterFirst = checkMoment.isAfter(firstMoment) || checkMoment.isSame(firstMoment)
  const isOnOrBeforeLast =
    checkMoment.isBefore(lastMoment) || checkMoment.isSame(lastMoment) || !lastMoment
  return isOnOrAfterFirst && isOnOrBeforeLast
}

/**
 * Given a date (in any format that moment will digest)
 * it will return a string indicating Today, Tomorrow, Yesterday
 * or the day of the week if it doesn't fit in any of those categories
 */
export function getFriendlyDate(date, today = moment()) {
  const {yesterday, tomorrow} = getTodaysDetails(today)
  const momentizedDate = new moment(date)

  if (isToday(date, today)) {
    return I18n.t('Today')
  } else if (yesterday.isSame(momentizedDate, 'day')) {
    return I18n.t('Yesterday')
  } else if (tomorrow.isSame(momentizedDate, 'day')) {
    return I18n.t('Tomorrow')
  } else {
    return momentizedDate.format('dddd')
  }
}

export function getDynamicFullDate(date, timeZone) {
  const today = moment().tz(timeZone)
  const momentizedDate = moment(date)
  return new Intl.DateTimeFormat(moment.locale(), {
    year: date.isSame(today, 'year') ? undefined : 'numeric',
    month: 'long',
    day: 'numeric',
    timeZone,
  }).format(momentizedDate.toDate())
}

export function getFullDate(date) {
  return moment(date).format('MMMM D, YYYY')
}

export function getShortDate(date) {
  return moment(date).format('MMMM D')
}

export function getDynamicFullDateAndTime(date, timeZone) {
  const today = moment().tz(timeZone)
  const momentizedDate = moment(date)
  const dateFormatter = new Intl.DateTimeFormat(moment.locale(), {
    year: date.isSame(today, 'year') ? undefined : 'numeric',
    month: 'short',
    day: 'numeric',
    timeZone,
  })
  return I18n.t('%{date} at %{time}', {
    date: dateFormatter.format(momentizedDate.toDate()),
    time: momentizedDate.format('LT'),
  })
}

export function getFullDateAndTime(date) {
  const {today, yesterday, tomorrow} = getTodaysDetails()
  const momentizedDate = moment(date)

  if (isToday(date, today)) {
    return I18n.t('Today at %{date}', {date: momentizedDate.format('LT')})
  } else if (yesterday.isSame(momentizedDate, 'day')) {
    return I18n.t('Yesterday at %{date}', {date: momentizedDate.format('LT')})
  } else if (tomorrow.isSame(momentizedDate, 'day')) {
    return I18n.t('Tomorrow at %{date}', {date: momentizedDate.format('LT')})
  } else {
    return I18n.t('%{date} at %{time}', {
      date: momentizedDate.format('LL'),
      time: momentizedDate.format('LT'),
    })
  }
}

export function dateString(date, timeZone) {
  if (dateTimeFormatters.dateString) {
    return dateTimeFormatters.dateString(date.toISOString(), {timezone: timeZone})
  } else {
    return date.format('ll') // always includes year
  }
}

export function timeString(date, timeZone) {
  if (dateTimeFormatters.timeString) {
    return dateTimeFormatters.timeString(date.toISOString(), {timezone: timeZone})
  } else {
    return date.format('LT')
  }
}

export function dateTimeString(date, timeZone) {
  if (dateTimeFormatters.datetimeString) {
    return dateTimeFormatters.datetimeString(date.toISOString(), {timezone: timeZone})
  } else {
    return date.format('lll') // always includes year
  }
}

export function dateRangeString(startDate, endDate, timeZone) {
  if (startDate.isSame(endDate)) {
    return dateTimeString(startDate, timeZone)
  } else if (startDate.dayOfYear() === endDate.dayOfYear()) {
    return I18n.t('%{startDateTime} - %{endTime}', {
      startDateTime: dateTimeString(startDate, timeZone),
      endTime: timeString(endDate, timeZone),
    })
  } else {
    return I18n.t('%{startDateTime} - %{endDateTime}', {
      startDateTime: dateTimeString(startDate, timeZone),
      endDateTime: dateTimeString(endDate, timeZone),
    })
  }
}

export function formatDayKey(date) {
  return moment(date, moment.ISO_8601).format('YYYY-MM-DD')
}

export function getFirstLoadedMoment(days, timeZone) {
  if (!days.length) return moment().tz(timeZone).startOf('day')
  const firstLoadedDay = days[0]
  const firstLoadedItem = firstLoadedDay[1][0]
  if (firstLoadedItem) return firstLoadedItem.dateBucketMoment.clone()
  return moment.tz(firstLoadedDay[0], timeZone).startOf('day')
}

export function getLastLoadedMoment(days, timeZone) {
  if (!days.length) return moment().tz(timeZone).startOf('day')
  const lastLoadedDay = days[days.length - 1]
  const loadedItem = lastLoadedDay[1][0]
  if (loadedItem) return loadedItem.dateBucketMoment.clone()
  return moment.tz(lastLoadedDay[0], timeZone).startOf('day')
}
