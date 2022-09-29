/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
  addDays,
  rawDaysBetweenInclusive,
  inBlackoutDate,
  daysBetween,
} from '../date_stuff/date_helpers'

moment.tz.setDefault('America/Denver')

describe('date_helpers', () => {
  describe('addDays', () => {
    it('add days to the given start', () => {
      const start = moment('2022-05-02T00:00:00')
      const end = addDays(start, 4, false)
      expect(end).toEqual('2022-05-06T00:00:00.000-06:00')
    })

    it('skips weekends', () => {
      // a Friday
      const start = moment('2022-04-29T00:00:00')
      const end = addDays(start, 4, true)
      // the following thrusday
      expect(end).toEqual('2022-05-05T00:00:00.000-06:00')
    })

    it('skips weekends when they fall on teh start date', () => {
      // a Saturday
      const start = moment('2022-04-30T00:00:00')
      const end = addDays(start, 4, true)
      // the following Friday
      expect(end).toEqual('2022-05-06T00:00:00.000-06:00')
    })

    it('skips blackout dates', () => {
      const blackouts = [
        {
          event_title: 'Tues and Wed',
          start_date: moment('2022-05-03T00:00:00'), // Tues
          end_date: moment('2022-05-04T00:00:00'), // Wed
        },
      ]
      const start = moment('2022-05-02T00:00:00') // Mon
      const end = addDays(start, 4, false, blackouts)
      expect(end).toEqual('2022-05-08T00:00:00.000-06:00')
    })

    it('skips weekends and blackout dates', () => {
      const blackouts = [
        {
          event_title: 'Tues and Wed',
          start_date: moment('2022-05-03T00:00:00'), // Tues
          end_date: moment('2022-05-04T00:00:00'), // Wed
        },
      ]
      const start = moment('2022-05-02T00:00:00') // Mon
      const end = addDays(start, 4, true, blackouts)
      expect(end).toEqual('2022-05-10T00:00:00.000-06:00')
    })

    it('skips single-day blackout dates', () => {
      const blackouts = [
        {
          event_title: 'Tues',
          start_date: moment('2022-05-03T00:00:00'), // Tues
          end_date: moment('2022-05-03T00:00:00'),
        },
      ]
      const start = moment('2022-05-02T00:00:00') // Mon
      const end = addDays(start, 4, false, blackouts)
      expect(end).toEqual('2022-05-07T00:00:00.000-06:00')
    })

    it('skips blackout dates that cover the start', () => {
      const blackouts = [
        {
          event_title: 'Tues and Wed',
          start_date: moment('2022-04-30T00:00:00'), // Sat before
          end_date: moment('2022-05-04T00:00:00'), // Wed after start
        },
      ]
      const start = moment('2022-05-02T00:00:00') // Mon
      const end = addDays(start, 4, false, blackouts)
      expect(end).toEqual('2022-05-09T00:00:00.000-06:00')
    })
  })

  describe('daysBetween', () => {
    it('counts unskipped days, inclusive', () => {
      const count = daysBetween(
        moment('2022-05-16T00:00:00-06:00'),
        moment('2022-05-20T00:00:00-06:00'),
        false,
        [],
        true
      )
      expect(count).toEqual(5)
    })

    it('counts unskipped days, exclusive', () => {
      const count = daysBetween(
        moment('2022-05-16T00:00:00-06:00'),
        moment('2022-05-20T00:00:00-06:00'),
        false,
        [],
        false
      )
      expect(count).toEqual(4)
    })

    it('skips weekends', () => {
      const count = daysBetween(
        moment('2022-05-13T00:00:00-06:00'),
        moment('2022-05-20T00:00:00-06:00'),
        true,
        [],
        true
      )
      expect(count).toEqual(6)
    })

    it('skips blackout dates', () => {
      const blackouts = [
        {
          event_title: 'Tues and Wed',
          start_date: moment('2022-05-03T00:00:00').endOf('day'), // Tues
          end_date: moment('2022-05-04T00:00:00').endOf('day'), // Wed
        },
      ]
      const count = daysBetween(
        moment('2022-05-02T00:00:00-06:00'),
        moment('2022-05-06T00:00:00-06:00'),
        true,
        blackouts,
        true
      )
      expect(count).toEqual(3)
    })

    it('skips blackout dates and weekends', () => {
      const blackouts = [
        {
          event_title: 'Tues and Wed',
          start_date: moment('2022-05-06T00:00:00').endOf('day'), // Fri
          end_date: moment('2022-05-10T00:00:00').endOf('day'), // tues
        },
      ]
      const count = daysBetween(
        moment('2022-05-05T00:00:00-06:00'), // thurs
        moment('2022-05-13T00:00:00-06:00'), // fri
        true,
        blackouts,
        true
      )
      expect(count).toEqual(4)
    })
  })

  describe('rawDaysBetweenInclusive', () => {
    it('counts days', () => {
      const count = rawDaysBetweenInclusive(
        moment('2022-05-16T00:00:00-06:00'), // monday
        moment('2022-05-20T00:00:00-06:00') // friday
      )
      expect(count).toEqual(5)
    })

    it('handles start == end', () => {
      const count = rawDaysBetweenInclusive(
        moment('2022-05-16T00:00:00-06:00'), // monday
        moment('2022-05-16T00:00:00-06:00') // friday
      )
      expect(count).toEqual(1)
    })
  })

  describe('inBlackoutDate', () => {
    it('can say no', () => {
      const blackouts = [
        {
          event_title: 'Tues and Wed',
          start_date: moment('2022-05-03T00:00:00'), // Tues
          end_date: moment('2022-05-04T00:00:00'), // Wed
        },
      ]
      expect(inBlackoutDate('2022-05-16T00:00:00-06:00', blackouts)).toBeFalsy()
    })

    it('can say yes', () => {
      const blackouts = [
        {
          event_title: 'Tues and Wed',
          start_date: moment('2022-05-03T00:00:00'), // Tues
          end_date: moment('2022-05-04T00:00:00'), // Wed
        },
      ]
      expect(inBlackoutDate('2022-05-03T00:00:00-06:00', blackouts)).toBeTruthy()
    })
  })
})
