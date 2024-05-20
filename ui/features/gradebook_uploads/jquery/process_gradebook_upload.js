/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import $ from 'jquery'
import _, {isEmpty} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.ajaxJSON'

const I18n = useI18nScope('gradebook_upload')

const successMessage = I18n.t(
  'You will be redirected to Gradebook while your file is being uploaded. ' +
    'If you have a large CSV file, your changes may take a few minutes to update. ' +
    'To prevent overwriting any data, please confirm the upload has completed and ' +
    'Gradebook is correct before making additional changes.'
)

function overrideScoreHasChanged(score) {
  const currentScore = Number.parseFloat(score.current_score)
  const newScore = Number.parseFloat(score.new_score)

  if (Number.isNaN(currentScore) && Number.isNaN(newScore)) {
    return false
  }

  return currentScore !== newScore
}

function overrideStatusHasChanged(status) {
  return status.new_grade_status?.toLowerCase() !== status.current_grade_status?.toLowerCase()
}

const ProcessGradebookUpload = {
  upload(gradebook) {
    if (gradebook == null || gradebook.students == null || gradebook.students.length === 0) {
      return
    }

    // Between assignment creation, score updates, custom column updates, and
    // override score updates, we very possibly have multiple requests to send
    // off. Make sure they've all returned (even if just returning a Progress
    // object) before we direct the user back to Gradebook.
    let uploadingBulkData = false
    const deferreds = []
    if (gradebook.custom_columns && gradebook.custom_columns.length > 0) {
      const deferred = this.uploadCustomColumnData(gradebook)
      if (deferred != null) {
        uploadingBulkData = true
        deferreds.push(deferred)
      }
    }

    const overrideScoresOrStatusesExist = gradebook.students.some(
      student => student.override_scores?.length > 0 || student.override_statuses?.length > 0
    )

    if (overrideScoresOrStatusesExist && ENV.bulk_update_override_scores_path != null) {
      const updateRequests = this.createOverrideUpdateRequests(gradebook)
      if (updateRequests.length > 0) {
        uploadingBulkData = true
        deferreds.push(...updateRequests)
      }
    }

    const createAssignmentsDfds = this.createAssignments(gradebook)
    const uploadGradeDataDfd = $.Deferred()
    $.when(...createAssignmentsDfds).then((...responses) => {
      const uploadRequest = this.uploadGradeData(gradebook, responses)
      if (uploadRequest != null) {
        uploadingBulkData = true
        $.when(uploadRequest).then(_response => {
          uploadGradeDataDfd.resolve()
        })
      } else {
        uploadGradeDataDfd.resolve()
      }
    })
    deferreds.push(...createAssignmentsDfds, uploadGradeDataDfd)

    return $.when(...deferreds).then(() => {
      if (uploadingBulkData) {
        alert(successMessage) // eslint-disable-line no-alert
      }
      this.goToGradebook()
    })
  },

  uploadCustomColumnData(gradebook) {
    const customColumnData = gradebook.students.reduce((accumulator, student) => {
      const student_id = Number.parseInt(student.id, 10)
      if (!(student_id in accumulator)) {
        accumulator[student_id] = student.custom_column_data
      }
      return accumulator
    }, {})

    if (!_.isEmpty(customColumnData)) {
      const parsedData = this.parseCustomColumnData(customColumnData)
      return this.submitCustomColumnData(parsedData)
    }
  },

  parseCustomColumnData(customColumnData) {
    const data = []
    Object.keys(customColumnData).forEach(studentId => {
      customColumnData[studentId].forEach(column => {
        data.push({
          column_id: Number.parseInt(column.column_id, 10),
          user_id: studentId,
          content: column.new_content,
        })
      })
    })
    return data
  },

  submitCustomColumnData(data) {
    return $.ajaxJSON(
      ENV.bulk_update_custom_columns_path,
      'PUT',
      JSON.stringify({column_data: data}),
      null,
      null,
      {contentType: 'application/json'}
    )
  },

  createOverrideUpdateRequests(gradebook) {
    const changedOverrideScores = gradebook.students
      .map(student => {
        const overrideScores = (student.override_scores || []).reduce((accumulator, score) => {
          if (overrideScoreHasChanged(score)) {
            accumulator[score.grading_period_id || '0'] = {...score, student_id: student.id}
          }
          return accumulator
        }, {})
        student.override_statuses?.forEach(status => {
          if (!overrideStatusHasChanged(status)) {
            return
          }
          const currentScore = overrideScores[status.grading_period_id || '0'] || {}
          overrideScores[status.grading_period_id || '0'] = {
            ...currentScore,
            student_id: student.id,
            grading_period_id: status.grading_period_id,
            current_grade_status: status.current_grade_status,
            new_grade_status: status.new_grade_status,
          }
        })
        return Object.values(overrideScores)
      })
      .flat()

    // If we have updates for multiple grading periods--which will never happen
    // with the default gradebook export but could happen if someone uploads a
    // CSV with multiple "Override Score" columns--send off one request to the
    // endpoint for each grading period.
    const scoresByGradingPeriod = _.groupBy(
      changedOverrideScores,
      score => score.grading_period_id || 'course'
    )
    const customStatuses = ENV.custom_grade_statuses ?? []
    const customStatusesMap = customStatuses.reduce((accumulator, status) => {
      accumulator[status.name.toLowerCase()] = status.id
      return accumulator
    }, {})
    return Object.entries(scoresByGradingPeriod).map(([gradingPeriodId, scores]) => {
      const submittableScores = scores.map(score => {
        let customStatusId
        if (score.new_grade_status === null) {
          customStatusId = null
        } else if (score.new_grade_status?.toLowerCase() in customStatusesMap) {
          customStatusId = customStatusesMap[score.new_grade_status?.toLowerCase()]
        }
        const submittedScore = {
          student_id: score.student_id,
        }
        if (score.new_score !== undefined && overrideScoreHasChanged(score)) {
          submittedScore.override_score = score.new_score
        }
        if (overrideStatusHasChanged(score) && customStatusId !== undefined) {
          submittedScore.override_status_id = customStatusId
        }
        return submittedScore
      })
      return this.createOverrideScoreRequest(gradingPeriodId, submittableScores)
    })
  },

  createOverrideScoreRequest(gradingPeriodId, scores) {
    const params = {override_scores: scores}
    if (gradingPeriodId !== 'course') {
      params.grading_period_id = gradingPeriodId
    }

    return $.ajaxJSON(
      ENV.bulk_update_override_scores_path,
      'PUT',
      JSON.stringify(params),
      null,
      null,
      {contentType: 'application/json'}
    )
  },

  createAssignments(gradebook) {
    const newAssignments = this.getNewAssignmentsFromGradebook(gradebook)
    return newAssignments.map(assignment => this.createIndividualAssignment(assignment))
  },

  getNewAssignmentsFromGradebook(gradebook) {
    return gradebook.assignments.filter(a => a.id != null && a.id <= 0)
  },

  createIndividualAssignment(assignment) {
    return $.ajaxJSON(
      ENV.create_assignment_path,
      'POST',
      JSON.stringify({
        assignment: {
          name: assignment.title,
          points_possible: assignment.points_possible,
          published: true,
        },
        calculate_grades: false,
      }),
      null,
      null,
      {contentType: 'application/json'}
    )
  },

  uploadGradeData(gradebook, responses) {
    const gradeData = this.populateGradeData(gradebook, responses)

    return isEmpty(gradeData) ? null : this.submitGradeData(gradeData)
  },

  populateGradeData(gradebook, responses) {
    const assignmentMap = this.mapLocalAssignmentsToDatabaseAssignments(gradebook, responses)

    const gradeData = {}
    gradebook.students.forEach(student =>
      this.populateGradeDataPerStudent(student, assignmentMap, gradeData)
    )
    return gradeData
  },

  mapLocalAssignmentsToDatabaseAssignments(gradebook, responses) {
    const newAssignments = this.getNewAssignmentsFromGradebook(gradebook)
    let responsesLists = responses

    if (newAssignments.length === 1) {
      responsesLists = [responses]
    }

    const assignmentMap = {}

    _(newAssignments)
      .zip(responsesLists)
      .forEach(fakeAndCreated => {
        const [assignmentStub, response] = fakeAndCreated
        const [createdAssignment] = response
        assignmentMap[assignmentStub.id] = createdAssignment.id
      })

    return assignmentMap
  },

  populateGradeDataPerStudent(student, assignmentMap, gradeData) {
    student.submissions.forEach(submission => {
      this.populateGradeDataPerSubmission(submission, student.previous_id, assignmentMap, gradeData)
    })
  },

  populateGradeDataPerSubmission(submission, studentId, assignmentMap, gradeData) {
    const assignmentId = assignmentMap[submission.assignment_id] || submission.assignment_id

    if (assignmentId <= 0) return // unrecognized and ignored assignments
    if (submission.original_grade === submission.grade) return // no change

    gradeData[assignmentId] = gradeData[assignmentId] || {}

    const normalizedGrade = String(submission.grade || '').toUpperCase()
    if (normalizedGrade === 'EX' || normalizedGrade === 'EXCUSED') {
      gradeData[assignmentId][studentId] = {excuse: true}
    } else {
      gradeData[assignmentId][studentId] = {
        posted_grade: submission.grade,
      }
    }
  },

  submitGradeData(gradeData) {
    return $.ajaxJSON(
      ENV.bulk_update_path,
      'POST',
      JSON.stringify({grade_data: gradeData}),
      null,
      null,
      {contentType: 'application/json'}
    )
  },

  goToGradebook() {
    $('#gradebook_grid_form').text(I18n.t('Done.'))
    window.location = ENV.gradebook_path
  },
}

export default ProcessGradebookUpload
