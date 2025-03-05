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
  calculatePaceDuration,
  calculatePaceItemDuration,
  calendarDaysToPaceDuration,
  getItemsDurationFromTimeToComplete,
  getTimeToCompleteCalendarDaysFromItemsDuration,
  isTimeToCompleteCalendarDaysValid,
  setItemsDurationFromWeightedAssignments
} from '../utils'
import { PACE_ITEM_1, PACE_ITEM_2, PACE_ITEM_3, PACE_ITEM_4, PACE_MODULE_1, PACE_MODULE_2, PRIMARY_PACE } from '../../__tests__/fixtures'
import { AssignmentWeightening, CoursePaceItem } from '../../types'

describe('utils', () => {
  const startDate = moment('2022-01-01')
  const endDate = moment('2022-01-10')

  const expectedDuration = { weeks: 1, days: 3 }

  describe('calculatePaceDuration', () => {
    it('should calculate the correct pace duration', () => {

      const result = calculatePaceDuration(startDate, endDate)
      expect(result).toEqual(expectedDuration)
    })
  })

  describe('calendarDaysToPaceDuration', () => {
    it('should convert calendar days to pace duration correctly', () => {
      const calendarDays = 10
      const expectedDuration = { weeks: 1, days: 3 }
      const result = calendarDaysToPaceDuration(calendarDays)
      expect(result).toEqual(expectedDuration)
    })
  })

  describe('calculatePaceItemDuration', () => {
    const assignmentWeightedDuration: AssignmentWeightening = {
      assignment: 2,
      discussion: 3,
      quiz: 4,
      page: 1
    }

    const coursePaceItem: CoursePaceItem[] = [
      {
        //assignment
        ...PACE_ITEM_1,
        module_item_type: 'Assignment',
        duration: 6
      },
      {
        //discussion
        ...PACE_ITEM_2,
        module_item_type: 'DiscussionTopic',
        duration: 6
      },
      {
        //quiz
        ...PACE_ITEM_3,
        module_item_type: 'Quizzes::Quiz',
        duration: 6
      },
      {
        //page
        ...PACE_ITEM_3,
        id: '54',
        module_item_type: 'Page',
        duration: 6
      },
    ]

    it('adds the right duration to the right item', () => {
      const result = calculatePaceItemDuration(coursePaceItem, assignmentWeightedDuration)

      expect(result[0].duration).toEqual(assignmentWeightedDuration.assignment)
      expect(result[1].duration).toEqual(assignmentWeightedDuration.discussion)
      expect(result[2].duration).toEqual(assignmentWeightedDuration.quiz)
      expect(result[3].duration).toEqual(assignmentWeightedDuration.page)
    })

    it('adds the right duration (no weighting duration for page)', () => {

      const newWeightedDuration = {
        ...assignmentWeightedDuration,
        page: undefined
      }

      const result = calculatePaceItemDuration(coursePaceItem, newWeightedDuration)

      expect(result[0].duration).toEqual(assignmentWeightedDuration.assignment)
      expect(result[1].duration).toEqual(assignmentWeightedDuration.discussion)
      expect(result[2].duration).toEqual(assignmentWeightedDuration.quiz)
      expect(result[3].duration).toEqual(0)
    })
  })

  describe('isTimeToCompleteCalendarDaysValid', () => {
    const coursePace = {
      ...PRIMARY_PACE,
      exclude_weekends: false,
      start_date: '2021-09-01',
      time_to_complete_calendar_days: 7,
    }

    const coursePaceItem: CoursePaceItem[] = [
      {
        ...PACE_ITEM_1,
        duration: 2,
      },
      {
        ...PACE_ITEM_2,
        duration: 2,
      },
      {
        ...PACE_ITEM_3,
        duration: 2,
      },
    ]

    it('returns true when calendar days are within the time to complete', () => {
      const result = isTimeToCompleteCalendarDaysValid(coursePace, coursePaceItem, [])
      expect(result).toBeTruthy()
    })

    it('returns false when calendar days exceed the time to complete', () => {
      const newCoursePace = {
        ...coursePace,
        time_to_complete_calendar_days: 4,
      }

      const result = isTimeToCompleteCalendarDaysValid(newCoursePace, coursePaceItem, [])
      expect(result).toBeFalsy()
    })

    it('takes into account weekends when exclude_weekends is true', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = false

      const newCoursePace = {
        ...coursePace,
        exclude_weekends: true,
      }

      const result = isTimeToCompleteCalendarDaysValid(newCoursePace, coursePaceItem, [])
      //Result is false because weekens are not included in paces due dates
      expect(result).toBeFalsy()
    })

    it('takes into account selected days to skip', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = true

      const newCoursePace = {
        ...coursePace,
        selected_days_to_skip: ['mon', 'tue'],
      }

      const result = isTimeToCompleteCalendarDaysValid(newCoursePace, coursePaceItem, [])
      //Result is false because Mondays and Tuesdays are not included in paces due dates
      expect(result).toBeFalsy()
    })

    it('takes into account blackout dates', () => {
      const blackoutDates = [
        {
          id: '30',
          course_id: PRIMARY_PACE.course_id,
          event_title: 'Spring break',
          start_date: moment('2021-09-02'),
          end_date: moment('2021-09-03'),
        },
      ]

      const result = isTimeToCompleteCalendarDaysValid(coursePace, coursePaceItem, blackoutDates)
      expect(result).toBeFalsy()
    })
  })

  describe('getTimeToCompleteCalendarDaysFromItemsDuration', () => {
    const coursePace = {
      ...PRIMARY_PACE,
      exclude_weekends: false,
      start_date: '2021-09-01',
      time_to_complete_calendar_days: 7,
    }

    const coursePaceItem: CoursePaceItem[] = [
      {
        ...PACE_ITEM_1,
        duration: 2,
      },
      {
        ...PACE_ITEM_2,
        duration: 2,
      },
      {
        ...PACE_ITEM_3,
        duration: 2,
      },
    ]

    const blackoutDates = [
      {
        id: '30',
        course_id: PRIMARY_PACE.course_id,
        event_title: 'Spring break',
        start_date: moment('2021-09-06'),
        end_date: moment('2021-09-08'),
      },
    ]

    it('calculates correctly time to complete calendar days', () => {
      const newCoursePace = {
        ...coursePace,
        exclude_weekends: false,
        selected_days_to_skip: [],
        modules: coursePace.modules.map((module) => {
          return {
            ...module,
            items: coursePaceItem
          }
        })
      }

      const result = getTimeToCompleteCalendarDaysFromItemsDuration(newCoursePace, [])
      expect(result).toEqual(12)
    })

    it('calculates correctly time to complete calendar days - exclude weekends', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = false

      const newCoursePace = {
        ...coursePace,
        exclude_weekends: true,
        selected_days_to_skip: [],
        modules: coursePace.modules.map((module) => {
          return {
            ...module,
            items: coursePaceItem
          }
        })
      }
      // Calculates calendar days from 2021-09-01 excluding weekends
      // pace durations is 13 days, and there are 2 weekends in that period
      // start date is ignored, so the result is 16

      const result = getTimeToCompleteCalendarDaysFromItemsDuration(newCoursePace, [])
      expect(result).toEqual(16)
    })

    it('calculates correctly time to complete calendar days - selected_days_to_skip', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = true

      const newCoursePace = {
        ...coursePace,
        exclude_weekends: false,
        selected_days_to_skip: ['sun', 'mon', 'fri'],
        modules: coursePace.modules.map((module) => {
          return {
            ...module,
            items: coursePaceItem
          }
        })
      }
      // Calculates calendar days from 2021-09-01 excluding Sundays, Mondays and Fridays
      // pace durations is 13 days, and there are 3 fridays, 3 sundays and 3 Mondays
      // start date is ignored, so the result is 21

      const result = getTimeToCompleteCalendarDaysFromItemsDuration(newCoursePace, [])
      expect(result).toEqual(21)
    })

    it('calculates correctly time to complete calendar days - black out days', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = false

      const newCoursePace = {
        ...coursePace,
        exclude_weekends: true,
        selected_days_to_skip: [],
        modules: coursePace.modules.map((module) => {
          return {
            ...module,
            items: coursePaceItem
          }
        })
      }
      // Calculates calendar days from 2021-09-01 excluding weekends
      // pace durations is 13 days, days from 2021-09-06 to 2021-09-08 are blacked out
      // and there are 3 weekends in that period, start date is ignored, so the result is 21

      const result = getTimeToCompleteCalendarDaysFromItemsDuration(newCoursePace, blackoutDates)
      expect(result).toEqual(21)
    })

    it('calculates correctly time to complete calendar days - black out days and skip selected days', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = true

      const newCoursePace = {
        ...coursePace,
        exclude_weekends: true,
        selected_days_to_skip: ['sun', 'mon', 'fri'],
        modules: coursePace.modules.map((module) => {
          return {
            ...module,
            items: coursePaceItem
          }
        })
      }
      // Calculates calendar days from 2021-09-01 excluding weekends
      // pace durations is 13 days, days from 2021-09-07 to 2021-09-08 are blacked out
      // and there are 4 fridays, 3 sundays and 3 Mondays, start date is ignored, so the result is 24

      const result = getTimeToCompleteCalendarDaysFromItemsDuration(newCoursePace, blackoutDates)
      expect(result).toEqual(24)
    })
  })

  describe('getItemsDurationFromTimeToComplete', () => {
    const coursePace = {
      ...PRIMARY_PACE,
      exclude_weekends: false,
      start_date: '2021-09-01',
      time_to_complete_calendar_days: 7,
    }

    it('durations are 0 because of negative calendarDays', () => {
      const newCoursePace = {
        ...coursePace,
        exclude_weekends: false,
        selected_days_to_skip: []
      }

      const result = getItemsDurationFromTimeToComplete(newCoursePace, [], -100, 4)
      expect(result.duration).toEqual(0)
      expect(result.remainder).toEqual(0)
    })

    it('return durations without blackout days, skipped days and exclude_weekends = false', () => {
      const newCoursePace = {
        ...coursePace,
        exclude_weekends: false,
        selected_days_to_skip: []
      }
      // Calendar days are 11 and Start date is ignored from calculation,
      // Then 10 / 3 = 3 and 10 % 3 = 1
      // Then, duration: 3, reminder: 1

      const result = getItemsDurationFromTimeToComplete(newCoursePace, [], 11, 3)
      expect(result.duration).toEqual(3)
      expect(result.remainder).toEqual(1)
    })

    it('return durations with skipped days', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = true

      const newCoursePace = {
        ...coursePace,
        exclude_weekends: false,
        selected_days_to_skip: ['sun', 'mon', 'fri']
      }
      // Start date is ignored from calculation,
      // Start date is 2021-09-01, Calendar days are 11, so end date is 2021-09-11
      // excluding Sundays, Mondays and Fridays
      // Total duration is 6 days, so 6 / 3 = 2
      // durations: 2, reminder: 0

      const result = getItemsDurationFromTimeToComplete(newCoursePace, [], 11, 3)
      expect(result.duration).toEqual(2)
      expect(result.remainder).toEqual(0)
    })

    it('last calendar day is an skipped day, so it is ignored', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = true

      const newCoursePace = {
        ...coursePace,
        exclude_weekends: false,
        selected_days_to_skip: ['sun', 'mon', 'fri']
      }
      // Start date is ignored from calculation,
      // excluding Sundays, Mondays and Fridays
      // Start date is 2021-09-01, Calendar days are 12, 
      // but end date is 2021-09-12 is sunday, an skipped day, so it is ignored
      // duration: 2, reminder: 0

      const result = getItemsDurationFromTimeToComplete(newCoursePace, [], 12, 3)
      expect(result.duration).toEqual(2)
      expect(result.remainder).toEqual(0)
    })

    it('return durations with exclude weekends', () => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_skip_selected_days = false

      const newCoursePace = {
        ...coursePace,
        exclude_weekends: true,
        selected_days_to_skip: []
      }
      // Start date is 2021-09-01 and is ignored from calculation,
      // Calendar days are 11, Then end date is 2021-09-11
      // excluding Sundays and Saturdays
      // Total duration is 7 days, so 7 / 3 = 2 and 7 % 3 = 1
      // duration: 2, reminder: 1

      const result = getItemsDurationFromTimeToComplete(newCoursePace, [], 11, 3)
      expect(result.duration).toEqual(2)
      expect(result.remainder).toEqual(1)
    })

    it('return durations with blackout dates', () => {
      const newCoursePace = {
        ...coursePace,
        exclude_weekends: false,
        selected_days_to_skip: []
      }

      const blackoutDates = [
        {
          id: '30',
          course_id: PRIMARY_PACE.course_id,
          event_title: 'Spring break',
          start_date: moment('2021-09-06'),
          end_date: moment('2021-09-08'),
        },
      ]
      // Start date is ignored from calculation,
      // Start date is 2021-09-01, Calendar days are 11, so end date is 2021-09-11
      // days from 2021-09-06 to 2021-09-08 are blacked out
      // Total duration is 8 days, so 8 / 3 = 2 and 8 % 3 = 2
      // duration: 2, reminder: 2

      const result = getItemsDurationFromTimeToComplete(newCoursePace, blackoutDates, 11, 3)
      expect(result.duration).toEqual(2)
      expect(result.remainder).toEqual(2)
    })
  })

  describe('setItemsDurationFromWeightedAssignments', () => {
    const coursePace = {
      ...PRIMARY_PACE,
      exclude_weekends: false,
      start_date: '2021-09-01',
      time_to_complete_calendar_days: 20,
      modules: [
        {
          ...PACE_MODULE_1,
          items: [
            {
              ...PACE_ITEM_1,
              module_item_type: 'Assignment',
            },
            {
              ...PACE_ITEM_2,
              module_item_type: 'DiscussionTopic',
            }
          ]
        },
        {
          ...PACE_MODULE_2,
          items: [
            {
              ...PACE_ITEM_3,
              module_item_type: 'Quizzes::Quiz',
            },
            {
              ...PACE_ITEM_4,
              module_item_type: 'Page',
            },
          ]
        },
      ]
    }

    const assignmentWeightedDuration: AssignmentWeightening = {
      assignment: 2,
      discussion: 3,
      quiz: 4,
      page: 1
    }

    it('set item durations from weighted assignments', () => {
      const modules = setItemsDurationFromWeightedAssignments(coursePace, [], assignmentWeightedDuration)
      const items = modules.flatMap((module) => module.items)

      expect(items[0].duration).toEqual(assignmentWeightedDuration.assignment)
      expect(items[1].duration).toEqual(assignmentWeightedDuration.discussion)
      expect(items[2].duration).toEqual(assignmentWeightedDuration.quiz)
      expect(items[3].duration).toEqual(assignmentWeightedDuration.page)
    })

    it('set item durations from weighted assignments, no weighteds for page or quiz', () => {
      const newAssignmentDurations: AssignmentWeightening = {
        assignment: 2,
        discussion: 3
      }

      const modules = setItemsDurationFromWeightedAssignments(coursePace, [], newAssignmentDurations)
      const items = modules.flatMap((module) => module.items)

      // There is not weighted for quiz and page, then the duration for
      // those items is calculated with the remaining days from time to complete
      // time_to_complete_calendar_days is 20, and the duration for assignment and discussion is 5
      // Start date is ignored so there are 14 days remaining
      // then the duration for quiz and page is 7 .
      expect(items[0].duration).toEqual(assignmentWeightedDuration.assignment)
      expect(items[1].duration).toEqual(assignmentWeightedDuration.discussion)
      expect(items[2].duration).toEqual(7)
      expect(items[3].duration).toEqual(7)
    })

    it('set item durations from weighted assignments, blackout days', () => {
      const newAssignmentDurations: AssignmentWeightening = {
        assignment: 2,
        discussion: 3
      }

      const blackoutDates = [
        {
          id: '30',
          course_id: PRIMARY_PACE.course_id,
          event_title: 'Spring break',
          start_date: moment('2021-09-06'),
          end_date: moment('2021-09-07'),
        },
      ]

      const modules = setItemsDurationFromWeightedAssignments(coursePace, blackoutDates, newAssignmentDurations)
      const items = modules.flatMap((module) => module.items)

      // There is not weighted for quiz and page, then the duration for
      // those items is calculated with the remaining days from time to complete.
      // time_to_complete_calendar_days is 20, and the duration for assignment and discussion is 5
      // There are 2 blackout days, so remaining days are 13
      // then the duration for quiz and page is 6 respectively.

      expect(items[0].duration).toEqual(assignmentWeightedDuration.assignment)
      expect(items[1].duration).toEqual(assignmentWeightedDuration.discussion)
      expect(items[2].duration).toEqual(7)
      expect(items[3].duration).toEqual(6)
    })
  })
})
