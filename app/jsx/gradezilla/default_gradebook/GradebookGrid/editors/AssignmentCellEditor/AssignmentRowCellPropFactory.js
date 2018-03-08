/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

function isTrayOpen(gradebook, student, assignment) {
  const {open, studentId, assignmentId} = gradebook.getSubmissionTrayState()
  return open && studentId === student.id && assignmentId === assignment.id
}

export default class AssignmentRowCellPropFactory {
  constructor(gradebook) {
    this.gradebook = gradebook
  }

  getProps(editorOptions) {
    const student = editorOptions.item
    const assignment = this.gradebook.getAssignment(editorOptions.column.assignmentId)
    const submission = this.gradebook.getSubmission(student.id, assignment.id)

    const cleanSubmission = {
      assignmentId: assignment.id,
      enteredGrade: submission.entered_grade,
      enteredScore: submission.entered_score,
      excused: !!submission.excused,
      id: submission.id,
      userId: student.id
    }

    const pendingGradeInfo = this.gradebook.getPendingGradeInfo(cleanSubmission)

    return {
      assignment: {
        id: assignment.id,
        pointsPossible: assignment.points_possible
      },

      enterGradesAs: this.gradebook.getEnterGradesAsSetting(assignment.id),
      gradingScheme: this.gradebook.getAssignmentGradingScheme(assignment.id).data,
      isSubmissionTrayOpen: isTrayOpen(this.gradebook, student, assignment),

      onToggleSubmissionTrayOpen: () => {
        this.gradebook.toggleSubmissionTrayOpen(student.id, assignment.id)
      },

      onGradeSubmission: this.gradebook.gradeSubmission,
      pendingGradeInfo,
      submission: cleanSubmission,
      submissionIsUpdating: !!pendingGradeInfo && pendingGradeInfo.valid
    }
  }
}
