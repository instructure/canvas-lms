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
import {
  formatDayKey,
  isToday, isInFuture,
  getFriendlyDate, getFullDate,
  getFirstLoadedMoment, getLastLoadedMoment,
  getFullDateAndTime,
  isMidnight, makeEndOfDayIfMidnight,
} from '../dateUtils';

describe('isToday', () => {
  it('returns true when the date passed in is the current date', () => {
    const date = moment();
    expect(isToday(date)).toBeTruthy();
  });

  it('returns true when the current date is passed in as a string', () => {
    const date = '2017-04-25';
    const fakeToday = moment(date);
    expect(isToday(date, fakeToday)).toBeTruthy();
  });

  it('returns false when the date passed in is not today', () => {
    const date = '2016-04-25';
    expect(isToday(date)).toBeFalsy();
  });
});

describe('getFriendlyDate', () => {
  it('returns "Today" when the date given is today', () => {
    const date = moment();
    expect(getFriendlyDate(date)).toBe('Today');
  });

  it('returns "Yesterday" when the date given is yesterday', () => {
    const date = moment().subtract(1, 'days');
    expect(getFriendlyDate(date)).toBe('Yesterday');
  });

  it('returns "Tomorrow" when the date given is tomorrow', () => {
    const date = moment().add(1, 'days');
    expect(getFriendlyDate(date)).toBe('Tomorrow');
  });

  it('returns the day of the week for any other date', () => {
    const date = moment().add(3, 'days');
    expect(getFriendlyDate(date)).toBe(date.format('dddd'));
  });
});

describe('getFullDate', () => {
  it('returns the day of the week month and day for special days', () => {
    const date = moment();
    expect(getFullDate(date)).toEqual(date.format('dddd, MMMM D'));
  });

  it('returns the format month day year when not a special day', () => {
    const date = moment().add(3, 'days');
    expect(getFullDate(date)).toEqual(date.format('MMMM D, YYYY'));
  });
});

describe('getFullDateAndTime', () => {
  it('returns the friendly day and formatted time', () => {
    const today = moment();
    expect(getFullDateAndTime(today)).toEqual(`Today at ${today.format('LT')}`);
    const yesterday = moment().add(-1, 'days');
    expect(getFullDateAndTime(yesterday)).toEqual(`Yesterday at ${yesterday.format('LT')}`);
    const tomorrow = moment().add(1, 'days');
    expect(getFullDateAndTime(tomorrow)).toEqual(`Tomorrow at ${tomorrow.format('LT')}`);
  });
});

describe('isInFuture', () => {
  it('returns true when the date is after today', () => {
    const date = moment().add(1, 'days');
    expect(isInFuture(date)).toBeTruthy();
  });

  it('returns false when the date is today', () => {
    const date = moment();
    expect(isInFuture(date)).toBeFalsy();
  });

  it('returns false when the date is before today', () => {
    const date = moment().subtract(1, 'days');
    expect(isInFuture(date)).toBeFalsy();
  });
});

describe('getFirstLoadedMoment', () => {
  it('returns today when there are no days loaded', () => {
    const today = moment.tz('Asia/Tokyo').startOf('day');
    const result = getFirstLoadedMoment([], 'Asia/Tokyo');
    expect(result.isSame(today)).toBeTruthy();
  });

  it('returns the dateBucketMoment of the first time of the first day', () => {
    const expected = moment().tz('Asia/Tokyo').startOf('day');
    const result = getFirstLoadedMoment([
      ['some date', [{dateBucketMoment: expected}]],
    ], 'Asia/Tokyo');
    expect(result.isSame(expected)).toBeTruthy();
  });

  it('uses the day key if the first day has no items', () => {
    const expected = moment().tz('Asia/Tokyo').startOf('day');
    const formattedDate = formatDayKey(expected);
    const result = getFirstLoadedMoment([
      [formattedDate, []],
    ], 'Asia/Tokyo');
    expect(result.isSame(expected)).toBeTruthy();
  });

  it('returns a clone', () => {
    const expected = moment.tz('Asia/Tokyo').startOf('day');
    const result = getFirstLoadedMoment(
      [['some date', [{dateBucketMoment: expected}]]],
      'Asia/Tokyo');
    expect(result === expected).toBeFalsy();
  });
});

describe('getLastLoadedMoment', () => {
  it('returns today when there are no days loaded', () => {
    const today = moment.tz('Asia/Tokyo').startOf('day');
    const result = getLastLoadedMoment([], 'Asia/Tokyo');
    expect(result.isSame(today)).toBeTruthy();
  });

  it('returns the dateBucketMoment of the first time of the last day', () => {
    const expected = moment().tz('Asia/Tokyo').startOf('day');
    const result = getLastLoadedMoment([
      ['some date', [{dateBucketMoment: expected}]],
    ], 'Asia/Tokyo');
    expect(result.isSame(expected)).toBeTruthy();
  });

  it('uses the day key if the last day has no items', () => {
    const expected = moment().tz('Asia/Tokyo').startOf('day');
    const formattedDate = formatDayKey(expected);
    const result = getLastLoadedMoment([
      [formattedDate, []],
    ], 'Asia/Tokyo');
    expect(result.isSame(expected)).toBeTruthy();
  });

  it('returns a clone', () => {
    const expected = moment.tz('Asia/Tokyo').startOf('day');
    const result = getLastLoadedMoment([
      ['some date', [{dateBucketMoment: expected}]],
    ], 'Asia/Tokyo');
    expect(result === expected).toBeFalsy();
  });

  it('returns true if at midnight, false if not', () => {
    const TZ = 'Asia/Tokyo';
    const midnight = moment.tz(TZ).startOf('day');
    expect(isMidnight(midnight, TZ)).toBeTruthy();
    const now = moment.tz(TZ).seconds(1); // just in case the test runs exactly at midnight
    expect(isMidnight(now, TZ)).toBeFalsy();
  });

  it('sets time to 11:59pm if at midnight', () => {
    const TZ = 'Asia/Tokyo';
    const now = moment.tz(TZ).seconds(1);
    let result = makeEndOfDayIfMidnight(now, TZ);
    expect(result).toEqual(now);
    const midnight = moment.tz(TZ).startOf('day');
    result = makeEndOfDayIfMidnight(midnight, TZ);
    expect(result.hours()).toEqual(23);
    expect(result.minutes()).toEqual(59);
  });
});
