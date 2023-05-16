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

import React, {useEffect, useState} from 'react'
import {useQuery} from 'react-apollo'
import {View} from '@instructure/ui-view'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {useScope as useI18nScope} from '@canvas/i18n'

import {
  GradebookStudentDetails,
  GradebookStudentQueryResponse,
  GradebookUserSubmissionDetails,
} from '../types'
import {GRADEBOOK_STUDENT_QUERY} from '../queries/Queries'
import {AssignmentGroupCriteriaMap, SubmissionGradeCriteria} from '@canvas/grading/grading'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  courseId: string
  studentId?: string | null
  assignmentGroupMap: AssignmentGroupCriteriaMap
}

export default function StudentInformation({courseId, studentId, assignmentGroupMap}: Props) {
  const [selectedStudent, setSelectedStudent] = useState<GradebookStudentDetails>()
  const [studentSubmissions, setStudentSubmissions] = useState<GradebookUserSubmissionDetails[]>([])
  const {data, error} = useQuery<GradebookStudentQueryResponse>(GRADEBOOK_STUDENT_QUERY, {
    variables: {courseId, userIds: studentId},
    fetchPolicy: 'cache-and-network',
    skip: !studentId,
  })

  useEffect(() => {
    if (error) {
      // TODO: handle error
    }

    if (data?.course) {
      setSelectedStudent(data.course.usersConnection.nodes[0])
      setStudentSubmissions(data.course.submissionsConnection.nodes)
    }
  }, [data, error])

  if (!selectedStudent) {
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

  const submissions: SubmissionGradeCriteria[] = studentSubmissions.map(submission => {
    return {
      assignment_id: submission.assignmentId,
      excused: false,
      grade: submission.grade,
      score: submission.score,
      workflow_state: 'graded',
      id: submission.id,
    }
  })
  CourseGradeCalculator.calculate(submissions, assignmentGroupMap, 'points', true)

  return (
    <div id="student_information">
      <div className="row-fluid">
        <div className="span4">
          <h2>Student Information</h2>
        </div>
        <div className="span8">
          <h3 className="student_selection">
            <a href="studentUrl"> {selectedStudent.name}</a>
          </h3>

          <div>
            <strong>
              Secondary ID:
              <span className="secondary_id"> {selectedStudent.loginId}</span>
            </strong>
          </div>
          <div>
            <strong>
              Sections:{' '}
              {selectedStudent.enrollments.map(enrollment => enrollment.section.name).join(', ')}
            </strong>
          </div>

          <h4>Grades</h4>

          <div className="ic-Table-responsive-x-scroll">
            <table className="ic-Table">
              <thead>
                <tr>
                  {/* {{#if subtotal_by_period}}
                      <th scope="col">{{#t}}Grading Period{</th>
                    {{else}}
                      <th scope="col">{{#t}}Assignment Group{</th>
                    {{/if}} */}
                  <th scope="col">Assignment Group</th>
                  <th scope="col">Grade</th>
                  <th scope="col">Letter Grade</th>
                  <th scope="col">% of Grade</th>
                </tr>
              </thead>
              <tbody>
                {/* {{#each assignment_subtotal in assignment_subtotals}}
                      {{
                        assignment-subtotal-grades
                        subtotal=assignment_subtotal
                        student=selectedStudent
                        weightingScheme=weightingScheme
                        gradingStandard=ENV.GRADEBOOK_OPTIONS.grading_standard
                      }}
                    {{/each}} */}
              </tbody>
            </table>
          </div>

          <h3>
            Final Grade:
            <span className="total-grade">
              &nbsp;{selectedStudent.enrollments[0].grades.unpostedCurrentScore}% (
              {studentSubmissions.reduce((a, b) => a + b.score ?? 0, 0)} / )
            </span>
          </h3>

          {/* {{partial "student_information/assignment_subtotals"}} */}
        </div>
      </div>
    </div>
  )
}
