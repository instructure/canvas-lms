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

import type {APIPaceContextTypes, AssignmentWeightening, CoursePace, CoursePaceItem, PaceContext, PaceContextTypes, PaceDuration} from '../types'
import * as DateHelpers from '../utils/date_stuff/date_helpers'
import moment, {type Moment} from 'moment-timezone'
import * as PaceDueDatesCalculator from './date_stuff/pace_due_dates_calculator'
import { BlackoutDate } from '../shared/types'

export const generateModalLauncherId = (paceContext: PaceContext) =>
  `pace-modal-launcher-${paceContext.type}-${paceContext.item_id}`

export const API_CONTEXT_TYPE_MAP: {[k in APIPaceContextTypes]: PaceContextTypes} = {
  course: 'Course',
  section: 'Section',
  student_enrollment: 'Enrollment',
  bulk_enrollment: 'BulkEnrollment'
}

export const CONTEXT_TYPE_MAP: {[k: string]: PaceContextTypes} = {
  Course: 'Course',
  CourseSection: 'Section',
  StudentEnrollment: 'Enrollment',
}

export const calculatePaceDuration = (startDate: Moment, endDate: Moment): PaceDuration => {
  const planDays = DateHelpers.rawDaysBetweenInclusive(startDate, endDate)
  return calendarDaysToPaceDuration(planDays)
}

export const calendarDaysToPaceDuration = (calendarDays: number): PaceDuration => {
  return { weeks: Math.floor(calendarDays / 7), days: calendarDays % 7 }
}

export const calculatePaceItemDuration = (
  coursePaceItem: CoursePaceItem[],
  assignmentWeightedDuration: AssignmentWeightening
): CoursePaceItem[] => {
  const getDuration = (itemType: string): number | undefined => {
    switch (itemType) {
      case 'Assignment':
        return assignmentWeightedDuration.assignment
      case 'DiscussionTopic':
        return assignmentWeightedDuration.discussion
      case 'Quizzes::Quiz':
        return assignmentWeightedDuration.quiz
      case 'Page':
        return assignmentWeightedDuration.page
      default:
        return undefined
    }
  }

  return coursePaceItem.map(item => {
    const duration = getDuration(item.module_item_type) || item.duration
    return { ...item, duration }
  })
}

export const isTimeToCompleteCalendarDaysValid = (
  coursePace: CoursePace,
  coursePaceItem: CoursePaceItem[],
  blackoutDates: BlackoutDate[]
): boolean => {
  const paceDueDates = PaceDueDatesCalculator.getDueDates(
    coursePaceItem,
    coursePace.exclude_weekends,
    coursePace.selected_days_to_skip,
    blackoutDates,
    coursePace.start_date
  )

  const endDateValue = moment.max(Object.values(paceDueDates).map((x) => moment(x)))
  const startDateMoment = moment(coursePace.start_date).startOf('day')
  const calendarDays = DateHelpers.rawDaysBetweenInclusive(startDateMoment, endDateValue)

  return calendarDays <= coursePace.time_to_complete_calendar_days
}
