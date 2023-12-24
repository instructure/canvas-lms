/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import _ from 'lodash'
import * as timezone from '@canvas/datetime'
import GradingPeriodsHelper from './GradingPeriodsHelper'
import type {CamelizedGradingPeriod} from './grading.d'
import type {Submission, DueDate, UserDueDateMap, AssignmentUserDueDateMap} from '../../api.d'

export function scopeToUser(
  dueDateDataByAssignmentId: AssignmentUserDueDateMap,
  userId: string
): UserDueDateMap {
  const scopedData: {
    [assignmentId: string]: DueDate
  } = {}
  _.forEach(
    dueDateDataByAssignmentId,
    (dueDateDataByUserId: UserDueDateMap, assignmentId: string) => {
      if (dueDateDataByUserId[userId]) {
        scopedData[assignmentId] = dueDateDataByUserId[userId]
      }
    }
  )
  return scopedData
}

export function updateWithSubmissions(
  effectiveDueDates: AssignmentUserDueDateMap,
  submissions: Pick<Submission, 'cached_due_date' | 'assignment_id' | 'user_id'>[],
  gradingPeriods: CamelizedGradingPeriod[] = []
): AssignmentUserDueDateMap {
  const helper = new GradingPeriodsHelper(gradingPeriods)
  const sortedPeriods: CamelizedGradingPeriod[] = _.sortBy<CamelizedGradingPeriod>(
    gradingPeriods,
    'startDate'
  )

  submissions.forEach(submission => {
    const dueDate: Date | null = timezone.parse(submission.cached_due_date)

    let gradingPeriod: null | CamelizedGradingPeriod = null
    if (gradingPeriods.length > 0) {
      if (dueDate) {
        gradingPeriod = helper.gradingPeriodForDueAt(dueDate)
      } else {
        gradingPeriod = sortedPeriods[sortedPeriods.length - 1]
      }
    }

    const assignmentDueDates: UserDueDateMap = effectiveDueDates[submission.assignment_id] || {}
    assignmentDueDates[submission.user_id] = {
      due_at: submission.cached_due_date,
      grading_period_id: gradingPeriod ? gradingPeriod.id : null,
      in_closed_grading_period: gradingPeriod ? gradingPeriod.isClosed : false,
    }

    effectiveDueDates[submission.assignment_id] = assignmentDueDates
  })

  return effectiveDueDates
}
