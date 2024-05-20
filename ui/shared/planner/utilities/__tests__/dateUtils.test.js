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
import moment from 'moment-timezone'
import {
  dateRangeString,
  dateTimeString,
  formatDayKey,
  getDynamicFullDate,
  getDynamicFullDateAndTime,
  getFirstLoadedMoment,
  getFriendlyDate,
  getFullDateAndTime,
  getLastLoadedMoment,
  isInFuture,
  isThisWeek,
  isToday,
  timeString,
  isInMomentRange,
} from '../dateUtils'

const TZ = 'Asia/Tokyo'

describe('isToday', () => {
  it('returns true when the date passed in is the current date', () => {
    const date = moment()
    expect(isToday(date)).toBeTruthy()
  })

  it('returns true when the current date is passed in as a string', () => {
    const date = '2017-04-25'
    const fakeToday = moment(date)
    expect(isToday(date, fakeToday)).toBeTruthy()
  })

  it('returns false when the date passed in is not today', () => {
    const date = '2016-04-25'
    expect(isToday(date)).toBeFalsy()
  })
})

describe('getFriendlyDate', () => {
  it('returns "Today" when the date given is today', () => {
    const date = moment()
    expect(getFriendlyDate(date)).toBe('Today')
  })

  it('returns "Yesterday" when the date given is yesterday', () => {
    const date = moment().subtract(1, 'days')
    expect(getFriendlyDate(date)).toBe('Yesterday')
  })

  it('returns "Tomorrow" when the date given is tomorrow', () => {
    const date = moment().add(1, 'days')
    expect(getFriendlyDate(date)).toBe('Tomorrow')
  })

  it('returns the day of the week for any other date', () => {
    const date = moment().add(3, 'days')
    expect(getFriendlyDate(date)).toBe(date.format('dddd'))
  })

  it('allows using a custom today', () => {
    const date = moment().tz(TZ).add(3, 'days')
    const today = date.clone().add(1, 'day')

    expect(getFriendlyDate(date, today)).toBe('Yesterday')
  })
})

describe('getDynamicFullDate', () => {
  it('returns the format month day if in the current year', () => {
    const date = moment().tz(TZ)
    expect(getDynamicFullDate(date, TZ)).toEqual(date.format('MMMM D'))
  })

  it('returns the format month day year if in a past year', () => {
    const date = moment().tz(TZ).subtract(1, 'years')
    expect(getDynamicFullDate(date, TZ)).toEqual(date.format('MMMM D, YYYY'))
  })

  it('returns the format month day year if in a future year', () => {
    const date = moment().tz(TZ).add(1, 'years')
    expect(getDynamicFullDate(date, TZ)).toEqual(date.format('MMMM D, YYYY'))
  })
})

describe('getDynamicFullDateAndTime', () => {
  it('returns the format month day time if in the current year', () => {
    const date = moment().tz(TZ)
    expect(getDynamicFullDateAndTime(date, TZ)).toEqual(
      `${date.format('MMM D')} at ${date.format('LT')}`
    )
  })

  it('returns the format month day year time if in a past year', () => {
    const date = moment().tz(TZ).subtract(1, 'years')
    expect(getDynamicFullDateAndTime(date, TZ)).toEqual(
      `${date.format('MMM D, YYYY')} at ${date.format('LT')}`
    )
  })

  it('returns the format month day year time if in a future year', () => {
    const date = moment().tz(TZ).add(1, 'years')
    expect(getDynamicFullDateAndTime(date, TZ)).toEqual(
      `${date.format('MMM D, YYYY')} at ${date.format('LT')}`
    )
  })
})

describe('getFullDateAndTime', () => {
  it('returns the friendly day and formatted time', () => {
    const today = moment()
    expect(getFullDateAndTime(today)).toEqual(`Today at ${today.format('LT')}`)
    const yesterday = moment().add(-1, 'days')
    expect(getFullDateAndTime(yesterday)).toEqual(`Yesterday at ${yesterday.format('LT')}`)
    const tomorrow = moment().add(1, 'days')
    expect(getFullDateAndTime(tomorrow)).toEqual(`Tomorrow at ${tomorrow.format('LT')}`)
  })
})

describe('isInFuture', () => {
  it('returns true when the date is after today', () => {
    const date = moment().add(1, 'days')
    expect(isInFuture(date)).toBeTruthy()
  })

  it('returns false when the date is today', () => {
    const date = moment()
    expect(isInFuture(date)).toBeFalsy()
  })

  it('returns false when the date is before today', () => {
    const date = moment().subtract(1, 'days')
    expect(isInFuture(date)).toBeFalsy()
  })
})

describe('getFirstLoadedMoment', () => {
  it('returns today when there are no days loaded', () => {
    const today = moment.tz(TZ).startOf('day')
    const result = getFirstLoadedMoment([], TZ)
    expect(result.isSame(today)).toBeTruthy()
  })

  it('returns the dateBucketMoment of the first time of the first day', () => {
    const expected = moment().tz(TZ).startOf('day')
    const result = getFirstLoadedMoment([['some date', [{dateBucketMoment: expected}]]], TZ)
    expect(result.isSame(expected)).toBeTruthy()
  })

  it('uses the day key if the first day has no items', () => {
    const expected = moment().tz(TZ).startOf('day')
    const formattedDate = formatDayKey(expected)
    const result = getFirstLoadedMoment([[formattedDate, []]], TZ)
    expect(result.isSame(expected)).toBeTruthy()
  })

  it('returns a clone', () => {
    const expected = moment.tz(TZ).startOf('day')
    const result = getFirstLoadedMoment([['some date', [{dateBucketMoment: expected}]]], TZ)
    expect(result === expected).toBeFalsy()
  })
})

describe('getLastLoadedMoment', () => {
  it('returns today when there are no days loaded', () => {
    const today = moment.tz(TZ).startOf('day')
    const result = getLastLoadedMoment([], TZ)
    expect(result.isSame(today)).toBeTruthy()
  })

  it('returns the dateBucketMoment of the first time of the last day', () => {
    const expected = moment().tz(TZ).startOf('day')
    const result = getLastLoadedMoment([['some date', [{dateBucketMoment: expected}]]], TZ)
    expect(result.isSame(expected)).toBeTruthy()
  })

  it('uses the day key if the last day has no items', () => {
    const expected = moment().tz(TZ).startOf('day')
    const formattedDate = formatDayKey(expected)
    const result = getLastLoadedMoment([[formattedDate, []]], TZ)
    expect(result.isSame(expected)).toBeTruthy()
  })

  it('returns a clone', () => {
    const expected = moment.tz(TZ).startOf('day')
    const result = getLastLoadedMoment([['some date', [{dateBucketMoment: expected}]]], TZ)
    expect(result === expected).toBeFalsy()
  })
})

describe('dateRangeString', () => {
  it('shows just the date if start == end', () => {
    const date = moment.tz('2018-10-04T12:42:00', 'UTC')
    const result = dateRangeString(date, date.clone(), 'UTC')
    expect(result).toBe(dateTimeString(date))
  })

  it('shows date t1 - t2 if dates are on the same day', () => {
    const start = moment.tz('2018-10-04T12:42:00', 'UTC')
    const end = start.clone().add(1, 'hour')
    const result = dateRangeString(start, end, 'UTC')
    expect(result).toBe(`${dateTimeString(start)} - ${timeString(end)}`)
  })

  it('shows full dates if start and end are on separate days', () => {
    const start = moment.tz('2018-10-04T12:42:00', 'UTC')
    const end = start.clone().add(1, 'day')
    const result = dateRangeString(start, end, 'UTC')
    expect(result).toBe(`${dateTimeString(start)} - ${dateTimeString(end)}`)
  })
})

describe('isThisWeek', () => {
  it('returns true when given day is during this week', () => {
    // eslint-disable-next-line new-cap
    const wednesday = new moment().startOf('week').add(3, 'days')
    expect(isThisWeek(wednesday)).toEqual(true)
  })
  it('return false when given day is not during this week', () => {
    // eslint-disable-next-line new-cap
    const lastFriday = new moment().startOf('week').add(-2, 'days')
    expect(isThisWeek(lastFriday)).toEqual(false)
  })
})

describe('isInMomentRange', () => {
  it('returns true when the date is within the range', () => {
    const date = moment()
    const start = date.clone().subtract(1, 'days')
    const end = date.clone().add(1, 'days')
    expect(isInMomentRange(date, start, end)).toBeTruthy()
  })
  it('returns false when the date is out of range', () => {
    const date = moment()
    const start = date.clone().add(2, 'days')
    const end = date.clone().add(4, 'days')
    expect(isInMomentRange(date, start, end)).toEqual(false)
  })
  it('returns true when the date is in range but end date is nil', () => {
    const date = moment()
    const start = date.clone().subtract(1, 'days')
    const end = null
    expect(isInMomentRange(date, start, end)).toBeTruthy()
  })
})
