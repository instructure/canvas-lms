// @ts-nocheck
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

import {extractSimilarityInfo} from '@canvas/grading/SubmissionHelper'
import type Gradebook from '../../../Gradebook'

function isTrayOpen(gradebook: Gradebook, student, assignment) {
  const {open, studentId, assignmentId} = gradebook.getSubmissionTrayState()
  return open && studentId === student.id && assignmentId === assignment.id
}

function similarityInfoToShow(submission) {
  const allSimilarityInfo = extractSimilarityInfo(submission)

  if (allSimilarityInfo && allSimilarityInfo.entries?.length > 0) {
    const {similarity_score, status} = allSimilarityInfo.entries[0].data

    return {
      similarityScore: similarity_score,
      status,
    }
  }

  return null
}

export default class AssignmentRowCellPropFactory {
  gradebook: Gradebook

  constructor(gradebook: Gradebook) {
    this.gradebook = gradebook
  }

  getProps(editorOptions) {
    const student = this.gradebook.student(editorOptions.item.id)
    const assignment = this.gradebook.getAssignment(editorOptions.column.assignmentId)
    const submission = this.gradebook.getSubmission(student.id, assignment.id)

    let similarityInfo: {
      similarityScore: number
      status: string
    } | null = null
    if (this.gradebook.showSimilarityScore()) {
      similarityInfo = similarityInfoToShow(submission)
    }

    const cleanSubmission = {
      assignmentId: assignment.id,
      enteredGrade: submission?.entered_grade,
      enteredScore: submission?.entered_score,
      excused: Boolean(submission?.excused),
      late_policy_status: submission?.late_policy_status,
      grade: submission?.grade,
      id: submission?.id,
      rawGrade: submission?.rawGrade,
      score: submission?.score,
      similarityInfo,
      userId: student.id,
    }

    const pendingGradeInfo = this.gradebook.getPendingGradeInfo(cleanSubmission)

    return {
      assignment: {
        id: assignment.id,
        pointsPossible: assignment.points_possible,
      },

      enterGradesAs: this.gradebook.getEnterGradesAsSetting(assignment.id),
      gradeIsEditable: this.gradebook.isGradeEditable(student.id, assignment.id),
      gradeIsVisible: this.gradebook.isGradeVisible(student.id, assignment.id),
      gradingScheme: this.gradebook.getAssignmentGradingScheme(assignment.id)?.data,
      isSubmissionTrayOpen: isTrayOpen(this.gradebook, student, assignment),

      onToggleSubmissionTrayOpen: () => {
        this.gradebook.toggleSubmissionTrayOpen(student.id, assignment.id)
      },

      onGradeSubmission: this.gradebook.gradeSubmission,
      pendingGradeInfo,
      student,
      submission: cleanSubmission,
      submissionIsUpdating: !!pendingGradeInfo && pendingGradeInfo.valid,
    }
  }
}
