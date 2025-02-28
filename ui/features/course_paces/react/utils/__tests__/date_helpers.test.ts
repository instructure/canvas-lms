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
  getEndDateValue,
  generateDatesCaptions,
} from '../date_stuff/date_helpers'
import { END_DATE_CAPTIONS, START_DATE_CAPTIONS } from '../../../constants'
import {
  PRIMARY_PACE,
  STUDENT_PACE,
} from '../../__tests__/fixtures'
import { ContextTypes, Pace } from '../../types'

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
        window.ENV.FEATURES ||= {}
        window.ENV.FEATURES.course_paces_skip_selected_days = skipSelectedDays
      })

      testCases.forEach(
        ({ description, start_date, daysToAdd, excludeWeekends, skipDays, blackouts, expected }) => {
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
        window.ENV.FEATURES ||= {}
        window.ENV.FEATURES.course_paces_skip_selected_days = skipSelectedDaysFeatureFlag
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

  describe('getEndDateValue', () => {
    const plannedEndDate = '2022-06-01T00:00:00-06:00'

    it('Student pace and course pace end date is not null', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_for_students = true

      const result = getEndDateValue(STUDENT_PACE, plannedEndDate)
      expect(result).toEqual(STUDENT_PACE.end_date)
    })

    it('Student pace and course pace end date is null', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_for_students = true

      const coursePace = {
        ...STUDENT_PACE,
        end_date: null
      }

      const result = getEndDateValue(coursePace, plannedEndDate)
      expect(result).toEqual(plannedEndDate)
    })

    it('Student pace and students flag is off', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_for_students = false

      const result = getEndDateValue(STUDENT_PACE, plannedEndDate)
      expect(result).toEqual(plannedEndDate)
    })

    it("Course Pace and end_date_context is 'hypothetical'", () => {
      const contextType : ContextTypes = 'hypothetical'
      const coursePace = {
        ...PRIMARY_PACE,
        end_date_context: contextType
      }
      const result = getEndDateValue(coursePace, plannedEndDate)
      expect(result).toEqual(plannedEndDate)
    })

    it("Course Pace and end_date_context is NOT 'hypothetical'", () => {
      const result = getEndDateValue(PRIMARY_PACE, plannedEndDate)
      expect(result).toEqual(PRIMARY_PACE.end_date)
    })
  })

  describe('generateDatesCaptions', () => {
    const appliedPace: Pace = {
      name: 'LS3432',
      type: 'Course',
      duration: 6,
      last_modified: '2022-10-17T23:12:24Z',
    }

    it('Course Pace whith course_pace_time_selection disabled', () => {
      window.ENV.FEATURES.course_pace_time_selection = false
      const captions = generateDatesCaptions(STUDENT_PACE, '2022-05-01T00:00:00-06:00', '2022-05-20T00:00:00-06:00', appliedPace)
      expect(captions.endDate).toEqual(END_DATE_CAPTIONS['course'])
      expect(captions.startDate).toEqual('Student enrollment date')
    })

    it('Student Pace whith course_pace_time_selection disabled', () => {
      window.ENV.FEATURES.course_pace_time_selection = false

      const pace = {
        ...appliedPace,
        type: 'Student'
      }
      const captions = generateDatesCaptions(STUDENT_PACE, '2022-05-01T00:00:00-06:00', '2022-05-20T00:00:00-06:00', pace)
      expect(captions.endDate).toEqual(END_DATE_CAPTIONS['default'])
      expect(captions.startDate).toEqual('Student enrollment date')
    })

    it('captions are returned for Course Pace"', () => {
      const captions = generateDatesCaptions(PRIMARY_PACE, '2022-05-01T00:00:00-06:00', '2022-05-20T00:00:00-06:00', appliedPace)
      expect(captions.endDate).toEqual(END_DATE_CAPTIONS['course'])
      expect(captions.startDate).toEqual(START_DATE_CAPTIONS['course'])
    })

    it('Student Pace with course_pace_time_selection is enabled', () => {
      window.ENV.FEATURES.course_pace_time_selection = true

      const pace = {
        ...appliedPace,
        type: 'Student'
      }
      const captions = generateDatesCaptions(STUDENT_PACE, '2022-05-01T00:00:00-06:00', '2022-05-20T00:00:00-06:00', pace)
      expect(captions.startDate).toEqual('Determined by student enrollment date')
    })
  })
})
