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

import _ from 'underscore'
import I18n from 'i18n!gradebooksharedMessageStudentsWhoHelper'

export function hasSubmitted(submission) {
  if (submission.excused) {
    return true
  } else if (submission.latePolicyStatus) {
    return submission.latePolicyStatus !== 'missing'
  }

  return !!(submission.submittedAt || submission.submitted_at)
}

export function hasSubmission(assignment) {
  const submissionTypes = getSubmissionTypes(assignment)
  if (submissionTypes.length === 0) return false

  return _.some(
    submissionTypes,
    submissionType => submissionType !== 'none' && submissionType !== 'on_paper'
  )
}

function getSubmissionTypes(assignment) {
  return assignment.submissionTypes || assignment.submission_types
}

function getCourseId(assignment) {
  return assignment.courseId || assignment.course_id
}

const MessageStudentsWhoHelper = {
  settings(assignment, students) {
    return {
      options: this.options(assignment),
      title: assignment.name,
      points_possible: assignment.points_possible,
      students,
      context_code: `course_${getCourseId(assignment)}`,
      callback: this.callbackFn.bind(this),
      subjectCallback: this.generateSubjectCallbackFn(assignment)
    }
  },

  options(assignment) {
    const options = this.allOptions()
    const noSubmissions = !this.hasSubmission(assignment)
    if (noSubmissions) options.splice(0, 1)
    return options
  },

  allOptions() {
    return [
      {
        text: I18n.t("Haven't submitted yet"),
        subjectFn: assignment =>
          I18n.t('No submission for %{assignment}', {assignment: assignment.name}),
        criteriaFn: student => !hasSubmitted(student)
      },
      {
        text: I18n.t("Haven't been graded"),
        subjectFn: assignment =>
          I18n.t('No grade for %{assignment}', {assignment: assignment.name}),
        criteriaFn: student => !this.exists(student.score)
      },
      {
        text: I18n.t('Scored less than'),
        cutoff: true,
        subjectFn: (assignment, cutoff) =>
          I18n.t('Scored less than %{cutoff} on %{assignment}', {
            assignment: assignment.name,
            cutoff: I18n.n(cutoff)
          }),
        criteriaFn: (student, cutoff) =>
          this.scoreWithCutoff(student, cutoff) && student.score < cutoff
      },
      {
        text: I18n.t('Scored more than'),
        cutoff: true,
        subjectFn: (assignment, cutoff) =>
          I18n.t('Scored more than %{cutoff} on %{assignment}', {
            assignment: assignment.name,
            cutoff: I18n.n(cutoff)
          }),
        criteriaFn: (student, cutoff) =>
          this.scoreWithCutoff(student, cutoff) && student.score > cutoff
      }
    ]
  },

  // implement this so it can be stubbed in tests
  hasSubmission(assignment) {
    return hasSubmission(assignment)
  },

  exists(value) {
    return value != null
  },

  scoreWithCutoff(student, cutoff) {
    return this.exists(student.score) && student.score !== '' && this.exists(cutoff)
  },

  callbackFn(selected, cutoff, students) {
    const criteriaFn = this.findOptionByText(selected).criteriaFn
    const studentsMatchingCriteria = _.filter(students, student =>
      criteriaFn(student.user_data, cutoff)
    )
    return _.map(studentsMatchingCriteria, student => student.user_data.id)
  },

  findOptionByText(text) {
    return _.find(this.allOptions(), option => option.text === text)
  },

  generateSubjectCallbackFn(assignment) {
    return (selected, cutoff) => {
      const cutoffString = cutoff || ''
      const subjectFn = this.findOptionByText(selected).subjectFn
      return subjectFn(assignment, cutoffString)
    }
  }
}
export default MessageStudentsWhoHelper
