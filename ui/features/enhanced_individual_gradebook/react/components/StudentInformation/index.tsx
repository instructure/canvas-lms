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

import React from 'react'
import {View} from '@instructure/ui-view'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {useScope as useI18nScope} from '@canvas/i18n'

import {
  GradebookOptions,
  GradebookStudentDetails,
  GradebookUserSubmissionDetails,
} from '../../../types'
import {AssignmentGroupCriteriaMap, SubmissionGradeCriteria} from '@canvas/grading/grading'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  student?: GradebookStudentDetails
  submissions?: GradebookUserSubmissionDetails[]
  assignmentGroupMap: AssignmentGroupCriteriaMap
  gradebookOptions: GradebookOptions // TODO: get this from gradebook settings
}

export default function StudentInformation({
  assignmentGroupMap,
  gradebookOptions,
  student,
  submissions,
}: Props) {
  if (!student || !submissions) {
    return (
      <View as="div">
        <View as="div" className="row-fluid">
          <View as="div" className="span4">
            <View as="h2">{I18n.t('Student Information')}</View>
          </View>
          <View as="div" className="span8 pad-box top-only">
            <View as="p" className="submission_selection">
              {I18n.t('Select a student to view additional information here.')}
            </View>
          </View>
        </View>
      </View>
    )
  }

  const gradeCriteriaSubmissions: SubmissionGradeCriteria[] = submissions.map(submission => {
    return {
      assignment_id: submission.assignmentId,
      excused: false,
      grade: submission.grade,
      score: submission.score,
      workflow_state: 'graded',
      id: submission.id,
    }
  })

  const scoreToPercentage = (score: number, possible: number, decimalPlaces = 2) => {
    const percent = (score / possible) * 100.0
    return percent % 1 === 0 ? percent : percent.toFixed(decimalPlaces)
  }

  // TODO: get weighting scheme from course & other options
  const {final, assignmentGroups, current} = CourseGradeCalculator.calculate(
    gradeCriteriaSubmissions,
    assignmentGroupMap,
    'points',
    true
  )
  const {includeUngradedAssignments} = gradebookOptions
  const gradeToDisplay = includeUngradedAssignments ? final : current
  const finalGradePercent = scoreToPercentage(gradeToDisplay.score, gradeToDisplay.possible)

  return (
    <View as="div">
      <View as="div" className="row-fluid">
        <View as="div" className="span4">
          <View as="h2">{I18n.t('Student Information')}</View>
        </View>
        <View as="div" className="span8">
          <View as="h3" className="student_selection">
            <a href="studentUrl"> {student.name}</a>
          </View>

          <View as="div">
            <View as="strong">
              {I18n.t('Secondary ID:')}
              <View as="span" className="secondary_id">
                {' '}
                {student.loginId}
              </View>
            </View>
          </View>
          <View as="div">
            <View as="strong">
              {I18n.t('Sections: ')}
              {student.enrollments.map(enrollment => enrollment.section.name).join(', ')}
            </View>
          </View>

          <View as="h4">{I18n.t('Grades')}</View>

          <View as="div" className="ic-Table-responsive-x-scroll">
            <table className="ic-Table">
              <thead>
                <tr>
                  <th scope="col">{I18n.t('Assignment Group')}</th>
                  <th scope="col">{I18n.t('Grade')}</th>
                  <th scope="col">{I18n.t('Letter Grade')}</th>
                  <th scope="col">{I18n.t('% of Grade')}</th>
                </tr>
              </thead>
              <tbody>
                {Object.keys(assignmentGroups).map(assignmentGroupId => {
                  const {name: groupName} = assignmentGroupMap[assignmentGroupId]
                  const {final: groupFinal, current: groupCurrent} =
                    assignmentGroups[assignmentGroupId]
                  const groupGradeToDisplay = includeUngradedAssignments ? groupFinal : groupCurrent

                  const percentScore = scoreToPercentage(
                    groupGradeToDisplay.score,
                    groupGradeToDisplay.possible,
                    1
                  )
                  const percentScoreText = Number.isNaN(Number(percentScore))
                    ? '-'
                    : `${percentScore}% (${groupGradeToDisplay.score} / ${groupGradeToDisplay.possible})`
                  return (
                    <tr key={`group_final_scores_${assignmentGroupId}`}>
                      <th>{groupName}</th>
                      <td>{percentScoreText}</td>
                      <td>-</td>
                      <td>-</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </View>

          <View as="h3">
            {I18n.t('Final Grade:')}
            <View as="span" className="total-grade">
              {' '}
              {finalGradePercent}% ({gradeToDisplay.score} / {gradeToDisplay.possible} points)
            </View>
          </View>
        </View>
      </View>
    </View>
  )
}
