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
import round from '@canvas/round'
import tz from '@canvas/timezone'
import _ from 'lodash'

import {
  AssignmentConnection,
  AssignmentDetailCalculationText,
  AssignmentGroupConnection,
  EnrollmentConnection,
  GradebookSortOrder,
  GradebookUserSubmissionDetails,
  SortableAssignment,
  SortableStudent,
} from '../types'
import {Submission} from '../../../api.d'
import {AssignmentGroupCriteriaMap} from '../../../shared/grading/grading.d'

export function mapAssignmentGroupQueryResults(assignmentGroup: AssignmentGroupConnection[]): {
  mappedAssignments: SortableAssignment[]
  mappedAssignmentGroupMap: AssignmentGroupCriteriaMap
} {
  return assignmentGroup.reduce(
    (prev, curr) => {
      const assignments = curr.assignmentsConnection.nodes
      const mappedAssignments: SortableAssignment[] = assignments.map(assignment =>
        mapToSortableAssignment(assignment, curr.position)
      )
      prev.mappedAssignments.push(...mappedAssignments)

      prev.mappedAssignmentGroupMap[curr.id] = {
        name: curr.name,
        assignments: curr.assignmentsConnection.nodes.map(assignment => {
          return {
            id: assignment.id,
            name: assignment.name,
            points_possible: assignment.pointsPossible,
            submission_types: assignment.submissionTypes,
            anonymize_students: assignment.anonymizeStudents,
            omit_from_final_grade: assignment.omitFromFinalGrade,
            workflow_state: assignment.workflowState,
          }
        }),
        group_weight: curr.groupWeight,
        rules: curr.rules,
        id: curr.id,
        position: curr.position,
        integration_data: {}, // TODO: Get Data
        sis_source_id: null, // TODO: Get data
      }

      return prev
    },
    {
      mappedAssignments: [] as SortableAssignment[],
      mappedAssignmentGroupMap: {} as AssignmentGroupCriteriaMap,
    }
  )
}

export function mapEnrollmentsToSortableStudents(
  enrollments: EnrollmentConnection[]
): SortableStudent[] {
  const mappedEnrollments = enrollments.reduce((prev, enrollment) => {
    const {user, courseSectionId} = enrollment
    if (!prev[user.id]) {
      prev[user.id] = {
        ...user,
        sections: [courseSectionId],
      }
    } else {
      prev[user.id].sections.push(courseSectionId)
    }

    return prev
  }, {} as {[key: string]: SortableStudent})

  return Object.values(mappedEnrollments)
}

export function sortAssignments(
  assignments: SortableAssignment[],
  sortOrder: GradebookSortOrder
): SortableAssignment[] {
  switch (sortOrder) {
    case GradebookSortOrder.Alphabetical:
      return _.sortBy(assignments, 'sortableName')
    case GradebookSortOrder.DueDate:
      return _.sortBy(assignments, ['sortableDueDate', 'sortableName'])
    case GradebookSortOrder.AssignmentGroup:
      return _.sortBy(assignments, ['assignmentGroupPosition', 'sortableName'])
    default:
      return assignments
  }
}

export function filterAssignmentsByStudent(
  assignments: SortableAssignment[],
  submissions: GradebookUserSubmissionDetails[]
) {
  const assignmentIdMap = submissions.reduce((prev, curr) => {
    prev[curr.assignmentId] = true
    return prev
  }, {} as {[key: string]: boolean})
  return assignments.filter(assignment => assignmentIdMap[assignment.id])
}

// This logic was taken directly from ui/features/screenreader_gradebook/jquery/AssignmentDetailsDialog.js
export function computeAssignmentDetailText(
  assignment: AssignmentConnection,
  scores: number[]
): AssignmentDetailCalculationText {
  return {
    max: nonNumericGuard(Math.max(...scores)),
    min: nonNumericGuard(Math.min(...scores)),
    pointsPossible: nonNumericGuard(assignment.pointsPossible, 'N/A'),
    average: nonNumericGuard(round(scores.reduce((a, b) => a + b, 0) / scores.length, 2)),
    median: nonNumericGuard(percentile(scores, 0.5)),
    lowerQuartile: nonNumericGuard(percentile(scores, 0.25)),
    upperQuartile: nonNumericGuard(percentile(scores, 0.75)),
  }
}

export function mapUnderscoreSubmission(submission: Submission): GradebookUserSubmissionDetails {
  return {
    assignmentId: submission.assignment_id,
    enteredScore: submission.entered_score,
    excused: submission.excused,
    grade: submission.grade,
    id: submission.id,
    late: submission.late,
    missing: submission.missing,
    score: submission.score,
    submittedAt: submission.submitted_at,
    userId: submission.user_id,
    submissionType: submission.submission_type,
    state: submission.workflow_state,
  }
}

function nonNumericGuard(value: number, message = 'No graded submissions'): string {
  return Number.isFinite(value) && !Number.isNaN(value) ? value.toString() : message
}

function percentile(values: number[], percentileValue: number): number {
  const k = Math.floor(percentileValue * (values.length - 1) + 1) - 1
  const f = (percentileValue * (values.length - 1) + 1) % 1

  return values[k] + f * (values[k + 1] - values[k])
}

function mapToSortableAssignment(
  assignment: AssignmentConnection,
  assignmentGroupPosition: number
): SortableAssignment {
  // Used sort date logic from screenreader_gradebook_controller.js
  const sortableDueDate = assignment.dueAt ? +tz.parse(assignment.dueAt) / 1000 : Number.MAX_VALUE
  return {
    ...assignment,
    sortableName: assignment.name.toLowerCase(),
    sortableDueDate,
    assignmentGroupPosition,
  }
}
