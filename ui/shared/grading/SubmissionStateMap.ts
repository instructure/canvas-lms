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

import type {Assignment, AssignmentMap, MissingSubmission, Student, Submission} from '../../api.d'
import {cellMapForSubmission, missingSubmission} from './SubmissionStateMap.utils'
import type {
  AssignmentSubmissionMap,
  StudentSubmissionCellMap,
  StudentSubmissionMap,
} from './SubmissionStateMap.utils'

class SubmissionStateMap {
  hasGradingPeriods: boolean

  isAdmin: boolean

  studentSubmissionMap: {[studentId: string]: StudentSubmissionMap} = {}

  assignmentStudentSubmissionMap: {[assignmentId: string]: AssignmentSubmissionMap} = {}

  selectedGradingPeriodID?: string

  submissionCellMap: StudentSubmissionCellMap = {}

  constructor({
    hasGradingPeriods,
    selectedGradingPeriodID,
    isAdmin,
  }: {
    hasGradingPeriods: boolean
    selectedGradingPeriodID?: string
    isAdmin: boolean
  }) {
    this.hasGradingPeriods = hasGradingPeriods
    this.selectedGradingPeriodID = selectedGradingPeriodID
    this.isAdmin = isAdmin

    this.getSubmissionsByStudentAndAssignmentIds =
      this.getSubmissionsByStudentAndAssignmentIds.bind(this)
  }

  setup(students: Student[], assignments: AssignmentMap) {
    Object.values(assignments).forEach(assignment => {
      this.assignmentStudentSubmissionMap[assignment.id] ||= {}
    })

    for (const student of students) {
      this.submissionCellMap[student.id] = {}
      this.studentSubmissionMap[student.id] = {}
      Object.values(assignments).forEach(assignment => {
        // @ts-expect-error
        const submission = student[`assignment_${assignment.id}`] as Submission
        this.setSubmissionCellState(student, assignment, submission)
      })
    }
  }

  setSubmissionCellState(student: Student, assignment: Assignment, submission?: Submission) {
    const sub = submission || missingSubmission(student, assignment)
    this.studentSubmissionMap[student.id][assignment.id] = sub
    this.assignmentStudentSubmissionMap[assignment.id][student.id] = sub

    if (!this.selectedGradingPeriodID) {
      throw new Error('selectedGradingPeriodID is required')
    }

    this.submissionCellMap[student.id][assignment.id] = cellMapForSubmission(
      assignment,
      student,
      this.hasGradingPeriods,
      this.selectedGradingPeriodID,
      this.isAdmin
    )
  }

  getSubmission(userId: string, assignmentId: string): Submission | MissingSubmission | undefined {
    return (this.assignmentStudentSubmissionMap[assignmentId] || {})[userId]
  }

  getSubmissionsByAssignment(assignmentId: string) {
    return Object.values(this.assignmentStudentSubmissionMap[assignmentId] || {})
  }

  getSubmissionsByStudentAndAssignmentIds(userId: string, assignmentIds: string[]) {
    return assignmentIds
      .map(assignmentId => this.getSubmission(userId, assignmentId))
      .filter(s => s) as (Submission | MissingSubmission)[]
  }

  getSubmissionState({
    user_id: userId,
    assignment_id: assignmentId,
  }: {
    user_id: string
    assignment_id: string
  }) {
    return (this.submissionCellMap[userId] || {})[assignmentId]
  }
}

export default SubmissionStateMap
