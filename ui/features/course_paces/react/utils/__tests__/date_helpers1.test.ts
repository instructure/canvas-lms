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
import {addDays, rawDaysBetweenInclusive, daysBetween} from '../date_stuff/date_helpers'
import fakeENV from '@canvas/test-utils/fakeENV'

moment.tz.setDefault('America/Denver')

describe('date_helpers', () => {
  describe('addDays', () => {
    const testCases = [
      {
        description: 'add days to the given start_date - No days skipped',
        start_date: '2022-05-02T00:00:00',
        daysToAdd: 4,
        excludeWeekends: false,
        skipDays: [],
        blackouts: [],
        expected: '2022-05-06T00:00:00.000-06:00',
      },
      {
        description: 'weekend days selected to be skipped',
        start_date: '2022-04-29T00:00:00',
        daysToAdd: 4,
        excludeWeekends: true,
        skipDays: ['sat', 'sun'],
        blackouts: [],
        expected: '2022-05-05T00:00:00.000-06:00',
      },
      {
        description: 'weekend days selected to be skipped when they fall on the start_date date',
        start_date: '2022-04-30T00:00:00',
        daysToAdd: 4,
        excludeWeekends: true,
        skipDays: ['sat', 'sun'],
        blackouts: [],
        expected: '2022-05-06T00:00:00.000-06:00',
      },
      {
        description: 'skips blackout dates',
        start_date: '2022-05-02T00:00:00',
        daysToAdd: 4,
        excludeWeekends: false,
        skipDays: [],
        blackouts: [
          {
            event_title: 'Tues and Wed',
            start_date: moment('2022-05-03T00:00:00'),
            end_date: moment('2022-05-04T00:00:00'),
          },
        ],
        expected: '2022-05-08T00:00:00.000-06:00',
      },
      {
        description: 'weekend days selected to be skipped and blackout dates',
        start_date: '2022-05-02T00:00:00',
        daysToAdd: 4,
        excludeWeekends: true,
        skipDays: ['sat', 'sun'],
        blackouts: [
          {
            event_title: 'Tues and Wed',
            start_date: moment('2022-05-03T00:00:00'),
            end_date: moment('2022-05-04T00:00:00'),
          },
        ],
        expected: '2022-05-10T00:00:00.000-06:00',
      },
      {
        description: 'skips single-day blackout dates',
        start_date: '2022-05-02T00:00:00',
        daysToAdd: 4,
        excludeWeekends: false,
        skipDays: [],
        blackouts: [
          {
            event_title: 'Tues',
            start_date: moment('2022-05-03T00:00:00'),
            end_date: moment('2022-05-03T00:00:00'),
          },
        ],
        expected: '2022-05-07T00:00:00.000-06:00',
      },
      {
        description: 'skips blackout dates that cover the start_date',
        start_date: '2022-05-02T00:00:00',
        daysToAdd: 4,
        excludeWeekends: false,
        skipDays: [],
        blackouts: [
          {
            event_title: 'Tues and Wed',
            start_date: moment('2022-04-30T00:00:00'),
            end_date: moment('2022-05-04T00:00:00'),
          },
        ],
        expected: '2022-05-09T00:00:00.000-06:00',
      },
    ]

    const runTests = (skipSelectedDays: boolean) => {
      beforeAll(() => {
        fakeENV.setup({
          FEATURES: {
            course_paces_skip_selected_days: skipSelectedDays,
          },
        })
      })

      afterAll(() => {
        fakeENV.teardown()
      })

      testCases.forEach(
        ({description, start_date, daysToAdd, excludeWeekends, skipDays, blackouts, expected}) => {
          it(description, () => {
            const end = addDays(moment(start_date), daysToAdd, excludeWeekends, skipDays, blackouts)
            expect(end).toEqual(expected)
          })
        },
      )
    }

    describe('course_paces_skip_selected_days = false', () => {
      runTests(false)
    })

    describe('course_paces_skip_selected_days = true', () => {
      runTests(true)
    })
  })

  describe('daysBetween', () => {
    const testCases = [
      {
        description: 'counts unskipped days, inclusive',
        start_date: '2022-05-16T00:00:00',
        end_date: '2022-05-20T00:00:00',
        excludeWeekends: false,
        skipDays: [],
        blackouts: [],
        inclusive: true,
        expected: 5,
      },
      {
        description: 'counts unskipped days, exclusive',
        start_date: '2022-05-16T00:00:00',
        end_date: '2022-05-20T00:00:00',
        excludeWeekends: false,
        skipDays: [],
        blackouts: [],
        inclusive: false,
        expected: 4,
      },
      {
        description: 'skips weekends',
        start_date: '2022-05-13T00:00:00',
        end_date: '2022-05-20T00:00:00',
        excludeWeekends: true,
        skipDays: ['sat', 'sun'],
        blackouts: [],
        inclusive: true,
        expected: 6,
      },
      {
        description: 'skips blackout dates',
        start_date: '2022-05-02T00:00:00',
        end_date: '2022-05-06T00:00:00',
        excludeWeekends: true,
        skipDays: ['sat', 'sun'],
        blackouts: [
          {
            event_title: 'Tues and Wed',
            start_date: moment('2022-05-03T00:00:00').endOf('day'),
            end_date: moment('2022-05-04T00:00:00').endOf('day'),
          },
        ],
        inclusive: true,
        expected: 3,
      },
      {
        description: 'skips blackout dates and weekends',
        start_date: '2022-05-05T00:00:00',
        end_date: '2022-05-13T00:00:00',
        excludeWeekends: true,
        skipDays: ['sat', 'sun'],
        blackouts: [
          {
            event_title: 'Tues and Wed',
            start_date: moment('2022-05-06T00:00:00').endOf('day'),
            end_date: moment('2022-05-10T00:00:00').endOf('day'),
          },
        ],
        inclusive: true,
        expected: 4,
      },
    ]

    const runTests = (skipSelectedDaysFeatureFlag: boolean) => {
      beforeAll(() => {
        fakeENV.setup({
          FEATURES: {
            course_paces_skip_selected_days: skipSelectedDaysFeatureFlag,
          },
        })
      })

      afterAll(() => {
        fakeENV.teardown()
      })

      testCases.forEach(
        ({
          description,
          start_date,
          end_date,
          excludeWeekends,
          skipDays,
          blackouts,
          inclusive,
          expected,
        }) => {
          it(description, () => {
            const count = daysBetween(
              moment(start_date),
              moment(end_date),
              excludeWeekends,
              skipDays,
              blackouts,
              inclusive,
            )
            expect(count).toEqual(expected)
          })
        },
      )
    }

    describe('course_paces_skip_selected_days = false', () => {
      runTests(false)
    })

    describe('course_paces_skip_selected_days = true', () => {
      runTests(true)
    })
  })

  describe('rawDaysBetweenInclusive', () => {
    it('counts days', () => {
      const count = rawDaysBetweenInclusive(
        moment('2022-05-16T00:00:00-06:00'), // monday
        moment('2022-05-20T00:00:00-06:00'), // friday
      )
      expect(count).toEqual(5)
    })

    it('handles start == end', () => {
      const count = rawDaysBetweenInclusive(
        moment('2022-05-16T00:00:00-06:00'), // monday
        moment('2022-05-16T00:00:00-06:00'), // friday
      )
      expect(count).toEqual(1)
    })
  })
})
