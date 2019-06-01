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
import I18n from 'i18n!sharedMessageStudentsWhoHelper'

const MessageStudentsWhoHelper = {
  settings(assignment, students) {
    return {
      options: this.options(assignment),
      title: assignment.name,
      points_possible: assignment.points_possible,
      students,
      context_code: `course_${assignment.course_id}`,
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
        text: I18n.t('students_who.havent_submitted_yet', "Haven't submitted yet"),
        subjectFn: assignment =>
          I18n.t('students_who.no_submission_for', 'No submission for %{assignment}', {
            assignment: assignment.name
          }),
        criteriaFn: student => !student.submitted_at
      },
      {
        text: I18n.t('students_who.havent_been_graded', "Haven't been graded"),
        subjectFn: assignment =>
          I18n.t('students_who.no_grade_for', 'No grade for %{assignment}', {
            assignment: assignment.name
          }),
        criteriaFn: student => !this.exists(student.score)
      },
      {
        text: I18n.t('students_who.scored_less_than', 'Scored less than'),
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
        text: I18n.t('students_who.scored_more_than', 'Scored more than'),
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

  hasSubmission(assignment) {
    const submissionTypes = assignment.submission_types
    if (submissionTypes.length === 0) return false

    return _.any(
      submissionTypes,
      submissionType => submissionType !== 'none' && submissionType !== 'on_paper'
    )
  },

  exists(value) {
    return !_.isUndefined(value) && !_.isNull(value)
  },

  scoreWithCutoff(student, cutoff) {
    return this.exists(student.score) && student.score !== '' && this.exists(cutoff)
  },

  callbackFn(selected, cutoff, students) {
    const criteriaFn = this.findOptionByText(selected).criteriaFn
    const filteredStudents = _.filter(students, student => criteriaFn(student.user_data, cutoff))
    return _.map(filteredStudents, student => student.user_data.id)
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
