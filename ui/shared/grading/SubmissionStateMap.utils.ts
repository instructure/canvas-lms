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

import GradingPeriodsHelper from './GradingPeriodsHelper'
import type {Assignment, MissingSubmission, Student, Submission} from '../../api.d'

export type Cell = {
  locked: boolean
  hideGrade: boolean
  inNoGradingPeriod?: boolean
  inOtherGradingPeriod?: boolean
  inClosedGradingPeriod?: boolean
}

export type StudentSubmissionCellMap = {[studentId: string]: SubmissionCellMap}

export type AssignmentSubmissionMap = {[studentId: string]: Submission | MissingSubmission}

export type SubmissionCellMap = {[assignmentId: string]: Cell}

export type StudentSubmissionMap = {
  [assignmentId: string]: Submission | MissingSubmission
}

export function submissionGradingPeriodInformation(assignment: Assignment, student: Student) {
  const submissionInfo: {
    grading_period_id?: null | string
    in_closed_grading_period?: boolean
  } = assignment.effectiveDueDates?.[student.id] || {}
  return {
    gradingPeriodID: submissionInfo.grading_period_id,
    inClosedGradingPeriod: submissionInfo.in_closed_grading_period,
  }
}

export function isHiddenFromStudent(assignment: Assignment, student: Student) {
  if (assignment.only_visible_to_overrides) {
    return !(assignment.assignment_visibility || []).includes(student.id)
  }
  return false
}

export function gradingPeriodInfoForCell(
  assignment: Assignment,
  student: Student,
  selectedGradingPeriodID: string
) {
  const specificPeriodSelected = !GradingPeriodsHelper.isAllGradingPeriods(selectedGradingPeriodID)
  const {gradingPeriodID, inClosedGradingPeriod} = submissionGradingPeriodInformation(
    assignment,
    student
  )
  const inNoGradingPeriod = !gradingPeriodID
  const inOtherGradingPeriod =
    !!gradingPeriodID && specificPeriodSelected && selectedGradingPeriodID !== gradingPeriodID

  return {
    inNoGradingPeriod,
    inOtherGradingPeriod,
    inClosedGradingPeriod,
  }
}

export function cellMappingsForMultipleGradingPeriods(
  assignment: Assignment,
  student: Student,
  selectedGradingPeriodID: string,
  isAdmin: boolean
) {
  const specificPeriodSelected = !GradingPeriodsHelper.isAllGradingPeriods(selectedGradingPeriodID)
  const {gradingPeriodID, inClosedGradingPeriod} = submissionGradingPeriodInformation(
    assignment,
    student
  )
  const gradingPeriodInfo = gradingPeriodInfoForCell(assignment, student, selectedGradingPeriodID)
  let cellMapping

  if (specificPeriodSelected && (!gradingPeriodID || selectedGradingPeriodID !== gradingPeriodID)) {
    cellMapping = {locked: true, hideGrade: true}
  } else if (!isAdmin && inClosedGradingPeriod) {
    cellMapping = {locked: true, hideGrade: false}
  } else {
    cellMapping = {locked: false, hideGrade: false}
  }

  return {...cellMapping, ...gradingPeriodInfo}
}

export function cellMapForSubmission(
  assignment: Assignment,
  student: Student,
  hasGradingPeriods: boolean,
  selectedGradingPeriodID: string,
  isAdmin: boolean
): Cell {
  if (!assignment.published || assignment.anonymize_students) {
    return {locked: true, hideGrade: true}
  } else if (assignment.moderated_grading && !assignment.grades_published) {
    return {locked: true, hideGrade: false}
  } else if (isHiddenFromStudent(assignment, student)) {
    return {locked: true, hideGrade: true}
  } else if (hasGradingPeriods) {
    return cellMappingsForMultipleGradingPeriods(
      assignment,
      student,
      selectedGradingPeriodID,
      isAdmin
    )
  } else {
    return {locked: false, hideGrade: false}
  }
}

export function missingSubmission(student: Student, assignment: Assignment): MissingSubmission {
  const submission: MissingSubmission = {
    assignment_id: assignment.id,
    user_id: student.id,
    excused: false,
    late: false,
    missing: false,
    seconds_late: 0,
  }
  const dueDates: {
    due_at?: null | string
  } = assignment.effectiveDueDates?.[student.id] || {}
  if (dueDates.due_at != null && new Date(dueDates.due_at) < new Date()) {
    submission.missing = true
  }
  return submission
}
