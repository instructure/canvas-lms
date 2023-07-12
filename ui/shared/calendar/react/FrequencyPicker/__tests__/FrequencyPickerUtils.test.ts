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

import moment, {Moment} from 'moment'
import {generateFrequencyOptions, generateFrequencyRRule} from '../FrequencyPickerUtils'

describe('generateFrequencyOptions()', () => {
  it('returns labels', () => {
    const datetime = moment('2001-04-12')
    const result = generateFrequencyOptions(datetime)
    expect(result).toEqual([
      {id: 'not-repeat', label: 'Does not repeat'},
      {id: 'daily', label: 'Daily'},
      {id: 'weekly-day', label: 'Weekly on Thursday'},
      {id: 'monthly-nth-day', label: 'Monthly on second Thursday'},
      {id: 'annually', label: 'Annually on April 12'},
      {id: 'every-weekday', label: 'Every weekday (Monday to Friday)'},
      {id: 'custom', label: 'Custom...'},
    ])
  })

  describe('returns when four weekdays in month', () => {
    it('first', () => {
      const datetime = moment('2023-07-05')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on first Wednesday')
    })

    it('second', () => {
      const datetime = moment('2023-07-12')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on second Wednesday')
    })

    it('third', () => {
      const datetime = moment('2023-07-19')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on third Wednesday')
    })

    it('last', () => {
      const datetime = moment('2023-07-26')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on last Wednesday')
    })
  })

  describe('returns when five weekdays in month', () => {
    it('first', () => {
      const datetime = moment('2023-07-01')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on first Saturday')
    })

    it('second', () => {
      const datetime = moment('2023-07-08')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on second Saturday')
    })

    it('third', () => {
      const datetime = moment('2023-07-15')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on third Saturday')
    })

    it('fourth', () => {
      const datetime = moment('2023-07-22')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on fourth Saturday')
    })

    it('last', () => {
      const datetime = moment('2023-07-29')
      const result = generateFrequencyOptions(datetime)
      const nthString = result[3].label
      expect(nthString).toEqual('Monthly on last Saturday')
    })
  })
})

describe('generateFrequencyRRule()', () => {
  describe('for a digit date & month', () => {
    let datetime: Moment

    beforeAll(() => {
      datetime = moment('1997-04-05')
    })

    it('not-repeated event', () => {
      const result = generateFrequencyRRule('not-repeat', datetime)
      expect(result).toEqual(null)
    })

    it('daily event', () => {
      const result = generateFrequencyRRule('daily', datetime)
      expect(result).toEqual('FREQ=DAILY;INTERVAL=1;COUNT=200')
    })

    it('weekly event', () => {
      const result = generateFrequencyRRule('weekly-day', datetime)
      expect(result).toEqual('FREQ=WEEKLY;BYDAY=SA;INTERVAL=1;COUNT=52')
    })

    it('monthly last day event', () => {
      const result = generateFrequencyRRule('monthly-nth-day', datetime)
      expect(result).toEqual('FREQ=MONTHLY;BYSETPOS=1;BYDAY=SA;INTERVAL=1;COUNT=12')
    })

    it('annually event', () => {
      const result = generateFrequencyRRule('annually', datetime)
      expect(result).toEqual('FREQ=YEARLY;BYMONTH=04;BYMONTHDAY=05;INTERVAL=1;COUNT=5')
    })

    it('every-weekday event', () => {
      const result = generateFrequencyRRule('every-weekday', datetime)
      expect(result).toEqual('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;INTERVAL=1;COUNT=52')
    })

    it('custom event', () => {
      const result = generateFrequencyRRule('custom', datetime)
      expect(result).toEqual(null)
    })
  })

  describe('for two-digit date & month and', () => {
    let datetime: Moment

    beforeAll(() => {
      datetime = moment('1997-12-25')
    })

    it('a not-repeated event', () => {
      const result = generateFrequencyRRule('not-repeat', datetime)
      expect(result).toEqual(null)
    })

    it('a daily event', () => {
      const result = generateFrequencyRRule('daily', datetime)
      expect(result).toEqual('FREQ=DAILY;INTERVAL=1;COUNT=200')
    })

    it('a weekly event', () => {
      const result = generateFrequencyRRule('weekly-day', datetime)
      expect(result).toEqual('FREQ=WEEKLY;BYDAY=TH;INTERVAL=1;COUNT=52')
    })

    it('a monthly last day event', () => {
      const result = generateFrequencyRRule('monthly-nth-day', datetime)
      expect(result).toEqual('FREQ=MONTHLY;BYSETPOS=-1;BYDAY=TH;INTERVAL=1;COUNT=12')
    })

    it('an annually event', () => {
      const result = generateFrequencyRRule('annually', datetime)
      expect(result).toEqual('FREQ=YEARLY;BYMONTH=12;BYMONTHDAY=25;INTERVAL=1;COUNT=5')
    })

    it('a every-weekday event', () => {
      const result = generateFrequencyRRule('every-weekday', datetime)
      expect(result).toEqual('FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR;INTERVAL=1;COUNT=52')
    })

    it('custom', () => {
      const result = generateFrequencyRRule('custom', datetime)
      expect(result).toEqual(null)
    })
  })
})
