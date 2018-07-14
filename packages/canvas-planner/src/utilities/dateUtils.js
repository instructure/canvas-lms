/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import moment from 'moment-timezone';
import formatMessage from '../format-message';

// NOTE: Canvas monkey-patches the timezone package to support the Canvas localized formats, and
// we're counting on that behavior in this file. The version of the timezone package that planner
// has in its package.json must stay in sync with package.json in Canvas so we don't lose the
// monkey-patch. The reason we're doing this is because moment.js doesn't support the format that we
// want to use in the todo sidebar, and Intl.DateTimeFormat doesn't support timezones in IE11. Using
// the formatter from Canvas seemed like the best remaining option.
import tz from 'timezone';

function getTodaysDetails () {
  const today = moment();
  const yesterday = today.clone().subtract(1, 'days');
  const tomorrow = today.clone().add(1, 'days');

  return { today, yesterday, tomorrow };
}

function isSpecialDay (date) {
  const { today, yesterday, tomorrow } = getTodaysDetails();
  const momentizedDate = new moment(date);

  const specialDates = [today, yesterday, tomorrow];
  return specialDates.some(sd => sd.isSame(momentizedDate, 'day'));
}

export function isToday (date, today = moment()) {
  const momentizedDate = new moment(date);
  return today.isSame(momentizedDate, 'day');
}

export function isInFuture (date, today = moment()) {
  const momentizedDate = new moment(date);
  return momentizedDate.isAfter(today, 'day');
}

export function isTodayOrBefore (date, today = moment()) {
  const momentizedDate = new moment(date);
  return momentizedDate.isBefore(today, 'day') || momentizedDate.isSame(today, 'day');
  // moment.isSameOrBefore isn't available until moment 2.11, but until we get off
  // all of ui-core, it ends up pulling in an earlier version.
  //return momentizedDate.isSameOrBefore(today, 'day');
}

// determines if the checkMoment falls on or inbetween the firstMoment and the lastMoment
export function isInMomentRange (checkMoment, firstMoment, lastMoment) {
  const isOnOrAfterFirst = checkMoment.isAfter(firstMoment) || checkMoment.isSame(firstMoment);
  const isOnOrBeforeLast = checkMoment.isBefore(lastMoment) || checkMoment.isSame(lastMoment);
  return isOnOrAfterFirst && isOnOrBeforeLast;
}

/**
* Given a date (in any format that moment will digest)
* it will return a string indicating Today, Tomorrow, Yesterday
* or the day of the week if it doesn't fit in any of those categories
*/
export function getFriendlyDate (date) {
  const { today, yesterday, tomorrow } = getTodaysDetails();
  const momentizedDate = new moment(date);

  if (isToday(date, today)) {
    return formatMessage('Today');
  } else if (yesterday.isSame(momentizedDate, 'day')) {
    return formatMessage('Yesterday');
  } else if (tomorrow.isSame(momentizedDate, 'day')) {
    return formatMessage('Tomorrow');
  } else {
    return momentizedDate.format('dddd');
  }
}


export function getFullDate (date) {
  if (isSpecialDay(date)) {
    return moment(date).format('dddd, MMMM D');
  } else {
    return moment(date).format('MMMM D, YYYY');
  }
}

export function getShortDate (date) {
  return moment(date).format('MMMM D');
}

export function getFullDateAndTime (date) {
  const { today, yesterday, tomorrow } = getTodaysDetails();
  const momentizedDate = new moment(date);

  if (isToday(date, today)) {
    return formatMessage('Today at {date}', {date: momentizedDate.format('LT')});
  } else if (yesterday.isSame(momentizedDate, 'day')) {
    return formatMessage('Yesterday at {date}', {date: momentizedDate.format('LT')});
  } else if (tomorrow.isSame(momentizedDate, 'day')) {
    return formatMessage('Tomorrow at {date}', {date: momentizedDate.format('LT')});
  } else {
    return formatMessage('{date} at {time}', {date: momentizedDate.format('LL'), time: momentizedDate.format('LT')});
  }
}

    // NOTE: this is where we're using a canvas specific format from the monkey-patched timezone
    // package. See comment above on the timezone package import.
export function formatDateAtTimeWithoutYear (date, timeZone) {
  // fancy conversion so we can support both Date and moment objects
  date = new Date(date.toISOString());

  // If  we're not in canvas, then there's no monkey-patch. Use a fallback in the test environment.
  if (process.env.NODE_ENV === 'test' && !tz.format) {
    return moment(date).format('lll') // includes the year, unfortunately
  } else {
    return tz.format(date, 'date.formats.date_at_time', timeZone);
  }
}

export function formatDayKey (date) {
  return moment(date, moment.ISO_8601).format('YYYY-MM-DD');
}

export function getFirstLoadedMoment (days, timeZone) {
  if (!days.length) return moment().tz(timeZone).startOf('day');
  const firstLoadedDay = days[0];
  const firstLoadedItem = firstLoadedDay[1][0];
  if (firstLoadedItem) return firstLoadedItem.dateBucketMoment.clone();
  return moment.tz(firstLoadedDay[0], timeZone).startOf('day');
}

export function getLastLoadedMoment (days, timeZone) {
  if (!days.length) return moment().tz(timeZone).startOf('day');
  const lastLoadedDay = days[days.length-1];
  const loadedItem = lastLoadedDay[1][0];
  if (loadedItem) return loadedItem.dateBucketMoment.clone();
  return moment.tz(lastLoadedDay[0], timeZone).startOf('day');
}

// datetime: iso8601 string or moment
// timeZone: user's timeZone
// returns: true if datetime is at midnight in the timeZone
export function isMidnight(datetime, timeZone) {
  if (typeof(datetime) === 'string') datetime = moment(datetime);
  const localDay = moment(datetime).tz(timeZone);
  return localDay.hours() === 0 &&
         localDay.minutes() === 0 &&
         localDay.seconds() === 0;
}

// if incoming datetime is at midnight user's time, convert to 11:59pm
// datetime: moment or iso8601 string
// timeZone: user's timeZone
// returns: moment of the result
export function makeEndOfDayIfMidnight(datetime, timeZone) {
  datetime = moment(datetime);
  if (isMidnight(datetime, timeZone)) {
    return moment(datetime).tz(timeZone).endOf('day');
  }
  return datetime;
}
