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
import React from 'react'
import PropTypes from 'prop-types'
import ModerationActions from './actions/ModerationActions'
import Constants from './constants'
import I18n from 'i18n!moderated_grading'

// CONSTANTS
const PG_ONE_INDEX = 0
const PG_TWO_INDEX = 1
const PG_THREE_INDEX = 2

const StudentName = React.createClass({
  propTypes: {
    course_id: PropTypes.string.isRequired,
    student_id: PropTypes.string.isRequired,
    children: PropTypes.node
  },

  getDefaultProps() {
    return {
      children: []
    }
  },

  render() {
    if (ENV.STUDENT_CONTEXT_CARDS_ENABLED) {
      return (
        <a
          href="#"
          className="student_context_card_trigger"
          data-course_id={this.props.course_id}
          data-student_id={this.props.student_id}
        >
          {this.props.children}
        </a>
      )
    }

    return <span>{this.props.children}</span>
  }
})

export default React.createClass({
  displayName: 'ModeratedStudentList',

  propTypes: {
    studentList: PropTypes.object.isRequired,
    assignment: PropTypes.object.isRequired,
    handleCheckbox: PropTypes.func.isRequired,
    includeModerationSetColumns: PropTypes.bool,
    urls: PropTypes.object.isRequired,
    onSelectProvisionalGrade: PropTypes.func.isRequired
  },

  generateSpeedgraderUrl(baseSpeedgraderUrl, student) {
    const encoded = window.encodeURI(`{"student_id":${student.id},"add_review":true}`)
    return `${baseSpeedgraderUrl}#${encoded}`
  },

  isProvisionalGradeChecked(provisionalGradeId, student) {
    return student.selected_provisional_grade_id === provisionalGradeId
  },

  renderStudentMark(student, markIndex) {
    // Set up previousIndex reference
    let previousMarkIndex = 0

    if (markIndex > 0) {
      previousMarkIndex = markIndex - 1
    }

    if (student.provisional_grades && student.provisional_grades[markIndex]) {
      const formattedScore = I18n.n(student.provisional_grades[markIndex].score)
      if (this.props.includeModerationSetColumns) {
        const provisionalGradeId = student.provisional_grades[markIndex].provisional_grade_id
        return (
          <td className="ModeratedAssignmentList__Mark">
            {student.provisional_grades.length > 1 && (
              <input
                type="radio"
                name={`mark_${student.id}`}
                disabled={this.props.assignment.published}
                onChange={this.props.onSelectProvisionalGrade.bind(this, provisionalGradeId)}
                checked={this.isProvisionalGradeChecked(provisionalGradeId, student)}
              />
            )}
            <a
              target="_blank"
              rel="noopener noreferrer"
              href={student.provisional_grades[markIndex].speedgrader_url}
            >
              <span
                aria-label={I18n.t('Score of %{score}. View in SpeedGrader', {
                  score: formattedScore
                })}
              >
                {formattedScore}
              </span>
            </a>
          </td>
        )
      }

      return (
        <td className="AssignmentList__Mark">
          <a
            target="_blank"
            rel="noopener noreferrer"
            href={student.provisional_grades[markIndex].speedgrader_url}
          >
            <span
              aria-label={I18n.t('Score of %{score}. View in SpeedGrader', {score: formattedScore})}
            >
              {formattedScore}
            </span>
          </a>
        </td>
      )
    }

    if (
      student.in_moderation_set &&
      (student.provisional_grades[previousMarkIndex] || markIndex == 0)
    ) {
      return (
        <td className="ModeratedAssignmentList__Mark">
          <a
            target="_blank"
            rel="noopener noreferrer"
            href={this.generateSpeedgraderUrl(this.props.urls.assignment_speedgrader_url, student)}
          >
            {I18n.t('SpeedGrader™')}
          </a>
        </td>
      )
    }

    return (
      <td className="AssignmentList__Mark">
        <span aria-label={I18n.t('None')}>-</span>
      </td>
    )
  },

  renderFinalGrade(student) {
    if (
      student.selected_provisional_grade_id ||
      (student.provisional_grades && student.provisional_grades.length === 1)
    ) {
      let grade
      // If they only have one provisional grade show that as the grade
      if (student.provisional_grades.length === 1) {
        grade = student.provisional_grades[0]
      } else {
        grade = _.find(
          student.provisional_grades,
          pg => pg.provisional_grade_id === student.selected_provisional_grade_id
        )
      }
      const formattedScore = grade.score ? I18n.n(grade.score) : I18n.t('Not available')
      return <td className="AssignmentList_Grade">{formattedScore}</td>
    }

    return (
      <td className="AssignmentList_Grade">
        <span aria-label={I18n.t('None')}>-</span>
      </td>
    )
  },

  render() {
    return (
      <tbody>
        {this.props.studentList.students.map(student => {
          if (this.props.includeModerationSetColumns) {
            return (
              <tr key={student.id} className="ModeratedAssignmentList__Item">
                <td className="ModeratedAssignmentList__Selector">
                  <input
                    id={`select_student_${student.id}`}
                    checked={
                      student.on_moderation_stage || student.in_moderation_set || student.isChecked
                    }
                    disabled={student.in_moderation_set || this.props.assignment.published}
                    type="checkbox"
                    onChange={this.props.handleCheckbox.bind(null, student)}
                    aria-label={I18n.t('Select %{studentName}', {
                      studentName: student.display_name
                    })}
                  />
                </td>
                <th scope="row" className="ModeratedAssignmentList__StudentInfo">
                  <img
                    className="img-circle AssignmentList_StudentPhoto"
                    src={student.avatar_image_url}
                    alt={I18n.t('Avatar for %{studentName}', {studentName: student.display_name})}
                    aria-hidden="true"
                  />
                  <StudentName
                    course_id={String(this.props.assignment.course_id)}
                    student_id={String(student.id)}
                  >
                    {student.display_name}
                  </StudentName>
                </th>

                {this.renderStudentMark(student, PG_ONE_INDEX)}
                {this.renderStudentMark(student, PG_TWO_INDEX)}
                {this.renderStudentMark(student, PG_THREE_INDEX)}
                {this.renderFinalGrade(student)}
              </tr>
            )
          }

          return (
            <tr key={student.id} className="AssignmentList__Item">
              <td className="AssignmentList__Selector">
                <input
                  id={`select_student_${student.id}`}
                  checked={
                    student.on_moderation_stage || student.in_moderation_set || student.isChecked
                  }
                  disabled={student.in_moderation_set || this.props.assignment.published}
                  type="checkbox"
                  onChange={this.props.handleCheckbox.bind(null, student)}
                  aria-label={I18n.t('Select %{studentName}', {studentName: student.display_name})}
                />
              </td>
              <th scope="row" className="AssignmentList__StudentInfo">
                <img
                  className="img-circle AssignmentList_StudentPhoto"
                  src={student.avatar_image_url}
                  alt={I18n.t('Avatar for %{studentName}', {studentName: student.display_name})}
                  aria-hidden="true"
                />
                <StudentName
                  course_id={String(this.props.assignment.course_id)}
                  student_id={String(student.id)}
                >
                  {student.display_name}
                </StudentName>
              </th>

              {this.renderStudentMark(student, PG_ONE_INDEX)}
            </tr>
          )
        })}
      </tbody>
    )
  }
})
