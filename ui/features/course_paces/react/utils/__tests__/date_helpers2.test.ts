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
import {inBlackoutDate, getEndDateValue, generateDatesCaptions} from '../date_stuff/date_helpers'
import {END_DATE_CAPTIONS, START_DATE_CAPTIONS} from '../../../constants'
import {PRIMARY_PACE, STUDENT_PACE} from '../../__tests__/fixtures'
import {ContextTypes, Pace} from '../../types'
import fakeENV from '@canvas/test-utils/fakeENV'

moment.tz.setDefault('America/Denver')

describe('date_helpers', () => {
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

    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {},
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('Student pace and course pace end date is not null', () => {
      const result = getEndDateValue(STUDENT_PACE, plannedEndDate)
      expect(result).toEqual(STUDENT_PACE.end_date)
    })

    it('Student pace and course pace end date is null', () => {
      const coursePace = {
        ...STUDENT_PACE,
        end_date: null,
      }

      const result = getEndDateValue(coursePace, plannedEndDate)
      expect(result).toEqual(plannedEndDate)
    })

    it("Course Pace and end_date_context is 'hypothetical'", () => {
      const contextType: ContextTypes = 'hypothetical'
      const coursePace = {
        ...PRIMARY_PACE,
        end_date_context: contextType,
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

    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {},
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('Course Pace whith course_pace_time_selection disabled', () => {
      fakeENV.setup({
        FEATURES: {
          course_pace_time_selection: false,
        },
      })
      const captions = generateDatesCaptions(
        STUDENT_PACE,
        '2022-05-01T00:00:00-06:00',
        '2022-05-20T00:00:00-06:00',
        appliedPace,
      )
      expect(captions.endDate).toEqual(END_DATE_CAPTIONS['course'])
      expect(captions.startDate).toEqual('Student enrollment date')
    })

    it('Student Pace whith course_pace_time_selection disabled', () => {
      fakeENV.setup({
        FEATURES: {
          course_pace_time_selection: false,
        },
      })

      const pace = {
        ...appliedPace,
        type: 'Student',
      }
      const captions = generateDatesCaptions(
        STUDENT_PACE,
        '2022-05-01T00:00:00-06:00',
        '2022-05-20T00:00:00-06:00',
        pace,
      )
      expect(captions.endDate).toEqual(END_DATE_CAPTIONS['default'])
      expect(captions.startDate).toEqual('Student enrollment date')
    })

    it('captions are returned for Course Pace"', () => {
      const captions = generateDatesCaptions(
        PRIMARY_PACE,
        '2022-05-01T00:00:00-06:00',
        '2022-05-20T00:00:00-06:00',
        appliedPace,
      )
      expect(captions.endDate).toEqual(END_DATE_CAPTIONS['course'])
      expect(captions.startDate).toEqual(START_DATE_CAPTIONS['course'])
    })

    it('Student Pace with course_pace_time_selection is enabled', () => {
      fakeENV.setup({
        FEATURES: {
          course_pace_time_selection: true,
        },
      })

      const pace = {
        ...appliedPace,
        type: 'Student',
      }
      const captions = generateDatesCaptions(
        STUDENT_PACE,
        '2022-05-01T00:00:00-06:00',
        '2022-05-20T00:00:00-06:00',
        pace,
      )
      expect(captions.startDate).toEqual('Determined by student enrollment date')
    })
  })
})
