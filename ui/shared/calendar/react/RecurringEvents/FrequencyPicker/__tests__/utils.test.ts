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

import moment, {type Moment} from 'moment'
import {
  generateFrequencyOptions,
  generateFrequencyRRULE,
  RRULEToFrequencyOptionValue,
  updateRRuleForNewDate,
} from '../utils'

const defaultTZ = 'America/New_York'
moment.tz.setDefault(defaultTZ)

describe('generateFrequencyOptions()', () => {
  it('returns labels', () => {
    const datetime = moment.tz('2001-04-12', defaultTZ)
    const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
    expect(result).toEqual([
      {id: 'not-repeat', label: 'Does not repeat'},
      {id: 'daily', label: 'Daily'},
      {id: 'weekly-day', label: 'Weekly on Thursday'},
      {id: 'monthly-nth-day', label: 'Monthly on the second Thursday'},
      {id: 'annually', label: 'Annually on April 12'},
      {id: 'every-weekday', label: 'Every weekday (Monday to Friday)'},
      {id: 'custom', label: 'Custom...'},
    ])
  })

  describe('returns when four weekdays in month', () => {
    it('first', () => {
      const datetime = moment.tz('2023-07-05', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the first Wednesday')
    })

    it('second', () => {
      const datetime = moment.tz('2023-07-12', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the second Wednesday')
    })

    it('third', () => {
      const datetime = moment.tz('2023-07-19', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the third Wednesday')
    })

    it('last', () => {
      const datetime = moment.tz('2023-07-26', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the last Wednesday')
    })
  })

  describe('returns when five weekdays in month', () => {
    it('first', () => {
      const datetime = moment.tz('2023-07-01', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the first Saturday')
    })

    it('second', () => {
      const datetime = moment.tz('2023-07-08', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the second Saturday')
    })

    it('third', () => {
      const datetime = moment.tz('2023-07-15', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the third Saturday')
    })

    it('fourth', () => {
      const datetime = moment.tz('2023-07-22', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the fourth Saturday')
    })

    it('last', () => {
      const datetime = moment.tz('2023-07-29', defaultTZ)
      const result = generateFrequencyOptions(datetime, 'en', defaultTZ, null)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on the last Saturday')
    })
  })

  describe('updates the custom label when the reference date changes', () => {
    it('for an annual event', () => {
      const rrule = 'FREQ=YEARLY;INTERVAL=1;BYMONTH=7;BYMONTHDAY=21;COUNT=2'
      const eventStart = moment.tz('2023-07-21', defaultTZ)

      let result = generateFrequencyOptions(eventStart, 'en', defaultTZ, rrule)
      expect(result[6].label).toEqual('Annually on Jul 21, 2 times')

      eventStart.add(1, 'day')
      result = generateFrequencyOptions(eventStart, 'en', defaultTZ, rrule)
      expect(result[6].label).toEqual('Annually on Jul 22, 2 times')
    })

    it('for a monthly by date event', () => {
      const rrule = 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=21;COUNT=2'
      const eventStart = moment.tz('2023-07-21', defaultTZ)

      let result = generateFrequencyOptions(eventStart, 'en', defaultTZ, rrule)
      expect(result[6].label).toEqual('Monthly on day 21, 2 times')

      eventStart.add(1, 'day')
      result = generateFrequencyOptions(eventStart, 'en', defaultTZ, rrule)
      expect(result[6].label).toEqual('Monthly on day 22, 2 times')
    })

    it('for a monthly by weekday event', () => {
      const rrule = 'FREQ=MONTHLY;INTERVAL=1;BYDAY=FR;BYSETPOS=3;COUNT=2'
      const eventStart = moment.tz('2023-07-21', defaultTZ)

      let result = generateFrequencyOptions(eventStart, 'en', defaultTZ, rrule)
      expect(result[6].label).toEqual('Monthly on the third Fri, 2 times')

      eventStart.add(8, 'days')
      result = generateFrequencyOptions(eventStart, 'en', defaultTZ, rrule)
      expect(result[6].label).toEqual('Monthly on the last Sat, 2 times')
    })
  })
})

describe('generateFrequencyRRULE', () => {
  describe('for a digit date & month', () => {
    let datetime: Moment

    beforeAll(() => {
      datetime = moment.tz('1997-04-05', defaultTZ)
    })

    it('not-repeated event', () => {
      const result = generateFrequencyRRULE('not-repeat', datetime)
      expect(result).toEqual(null)
    })

    it('daily event', () => {
      const result = generateFrequencyRRULE('daily', datetime)
      expect(result).toEqual('FREQ=DAILY;INTERVAL=1;COUNT=365')
    })

    it('weekly event', () => {
      const result = generateFrequencyRRULE('weekly-day', datetime)
      expect(result).toEqual('FREQ=WEEKLY;BYDAY=SA;INTERVAL=1;COUNT=52')
    })

    it('monthly last day event', () => {
      const result = generateFrequencyRRULE('monthly-nth-day', datetime)
      expect(result).toEqual('FREQ=MONTHLY;BYSETPOS=1;BYDAY=SA;INTERVAL=1;COUNT=12')
    })

    it('annually event', () => {
      const result = generateFrequencyRRULE('annually', datetime)
      expect(result).toEqual('FREQ=YEARLY;BYMONTH=04;BYMONTHDAY=05;INTERVAL=1;COUNT=5')
    })

    it('every-weekday event', () => {
      const result = generateFrequencyRRULE('every-weekday', datetime)
      expect(result).toEqual('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;INTERVAL=1;COUNT=260')
    })

    it('custom event', () => {
      const result = generateFrequencyRRULE('custom', datetime)
      expect(result).toEqual(null)
    })
  })

  describe('for two-digit date & month and', () => {
    let datetime: Moment

    beforeAll(() => {
      datetime = moment.tz('1997-12-25', defaultTZ)
    })

    it('a not-repeated event', () => {
      const result = generateFrequencyRRULE('not-repeat', datetime)
      expect(result).toEqual(null)
    })

    it('a daily event', () => {
      const result = generateFrequencyRRULE('daily', datetime)
      expect(result).toEqual('FREQ=DAILY;INTERVAL=1;COUNT=365')
    })

    it('a weekly event', () => {
      const result = generateFrequencyRRULE('weekly-day', datetime)
      expect(result).toEqual('FREQ=WEEKLY;BYDAY=TH;INTERVAL=1;COUNT=52')
    })

    it('a monthly last day event', () => {
      const result = generateFrequencyRRULE('monthly-nth-day', datetime)
      expect(result).toEqual('FREQ=MONTHLY;BYSETPOS=-1;BYDAY=TH;INTERVAL=1;COUNT=12')
    })

    it('an annually event', () => {
      const result = generateFrequencyRRULE('annually', datetime)
      expect(result).toEqual('FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=25;INTERVAL=1;COUNT=5')
    })

    it('a every-weekday event', () => {
      const result = generateFrequencyRRULE('every-weekday', datetime)
      expect(result).toEqual('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;INTERVAL=1;COUNT=260')
    })

    it('custom', () => {
      const result = generateFrequencyRRULE('custom', datetime)
      expect(result).toEqual(null)
    })
  })
})

describe('RRULEToFrequencyOptionValue', () => {
  it('returns daily for a matching rrule', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=DAILY;INTERVAL=1;COUNT=365'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('daily')
  })

  it('returns weekly-day for a matching rrule', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO;COUNT=52'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('weekly-day')
  })

  it('returns monthly-nth-day for an matching rrule for nth weekday of the month', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=MONTHLY;INTERVAL=1;BYDAY=MO;BYSETPOS=3;COUNT=12'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('monthly-nth-day')
  })

  it('returns monthly-nth-day for an matching rrule for last week day of the month', () => {
    const eventStart = moment.tz('2023-07-25T00:00:00', defaultTZ)
    const rrule = 'FREQ=MONTHLY;INTERVAL=1;BYDAY=TU;BYSETPOS=-1;COUNT=12'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('monthly-nth-day')
  })

  it('returns annually for a matching rrule', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=YEARLY;INTERVAL=1;BYMONTH=7;BYMONTHDAY=17;COUNT=5'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('annually')
  })

  it('returns every-weekday for a matching rrule', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;COUNT=260'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('every-weekday')
  })

  it('returns custom for an rrule with interval not 1', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=DAILY;INTERVAL=2;COUNT=365'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('saved-custom')
  })

  it('returns custom for an rrule not on the right day of the week', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=MONTHLY;INTERVAL=1;BYDAY=TU;BYSETPOS=3;COUNT=12'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('saved-custom')
  })

  it('returns custom for an rrule not in the right month', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=YEARLY;INTERVAL=1;BYMONTH=6;BYMONTHDAY=17;COUNT=5'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('saved-custom')
  })

  it('returns custom for an rrule not on the right day of the month', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = 'FREQ=YEARLY;INTERVAL=1;BYMONTH=7;BYMONTHDAY=18;COUNT=5'
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('saved-custom')
  })

  it('returns custom for an empty rrule', () => {
    const eventStart = moment.tz('2023-07-17T00:00:00', defaultTZ)
    const rrule = ''
    expect(RRULEToFrequencyOptionValue(eventStart, rrule)).toEqual('custom')
  })
})

describe('updateRRuleForNewDate', () => {
  it('reutrns null when the rrule is  null', () => {
    expect(updateRRuleForNewDate(moment.tz('2023-07-17T00:00:00', defaultTZ), null)).toBeNull()
  })

  it('updates a weekly rrule to match the all days of the week', () => {
    const rrule = 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;COUNT=260'
    const newDate = moment.tz('2023-07-18T00:00:00', defaultTZ)
    expect(updateRRuleForNewDate(newDate, rrule)).toEqual(
      'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;COUNT=260'
    )
  })

  it('updates a weekly rrule to match the new day of the week', () => {
    const rrule = 'FREQ=WEEKLY;INTERVAL=1;BYDAY=MO;COUNT=52'
    const newDate = moment.tz('2023-07-18T00:00:00', defaultTZ)
    expect(updateRRuleForNewDate(newDate, rrule)).toEqual(
      'FREQ=WEEKLY;INTERVAL=1;BYDAY=TU;COUNT=52'
    )
  })

  it('updates a monthly rrule to match the neew day of the week', () => {
    const rrule = 'FREQ=MONTHLY;INTERVAL=1;BYDAY=MO;BYSETPOS=3;COUNT=12'
    const newDate = moment.tz('2023-07-18T00:00:00', defaultTZ)
    expect(updateRRuleForNewDate(newDate, rrule)).toEqual(
      'FREQ=MONTHLY;INTERVAL=1;BYDAY=TU;BYSETPOS=3;COUNT=12'
    )
  })

  it('updates a monthly rrule to match the new day of the month', () => {
    const rrule = 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=17;COUNT=12'
    const newDate = moment.tz('2023-07-18T00:00:00', defaultTZ)
    expect(updateRRuleForNewDate(newDate, rrule)).toEqual(
      'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=18;COUNT=12'
    )
  })

  it('updates a yearly rrule to match the new date', () => {
    const rrule = 'FREQ=YEARLY;INTERVAL=1;BYMONTH=7;BYMONTHDAY=17;COUNT=5'
    const newDate = moment.tz('2023-07-18T00:00:00', defaultTZ)
    expect(updateRRuleForNewDate(newDate, rrule)).toEqual(
      'FREQ=YEARLY;INTERVAL=1;BYMONTH=7;BYMONTHDAY=18;COUNT=5'
    )
  })
})
