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
import {useSearchParams} from 'react-router-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'

import {AssignmentGroupCriteriaMap} from '../../../shared/grading/grading.d'
import AssignmentInformation from './AssignmentInformation'
import ContentSelection from './ContentSelection'
import GlobalSettings from './GlobalSettings'
import GradingResults from './GradingResults'
import StudentInformation from './StudentInformation'
import {
  AssignmentConnection,
  GradebookQueryResponse,
  SubmissionConnectionResponse,
  UserConnectionResponse,
} from '../types'
import {GRADEBOOK_QUERY} from '../queries/Queries'

const I18n = useI18nScope('enhanced_individual_gradebook')

const STUDENT_SEARCH_PARAM = 'student'
const ASSIGNMENT_SEARCH_PARAM = 'assignment'

export default function EnhancedIndividualGradebook() {
  const [submissions, setSubmissions] = useState<SubmissionConnectionResponse[]>([])
  const [students, setStudents] = useState<UserConnectionResponse[]>([])
  const [assignments, setAssignments] = useState<AssignmentConnection[]>([])

  const [selectedAssignment, setSelectedAssignment] = useState<AssignmentConnection>()
  const [selectedSubmissions, setSelectedSubmissions] = useState<SubmissionConnectionResponse[]>([])

  const courseId = ENV.GRADEBOOK_OPTIONS?.context_id || '' // TODO: get from somewhere else?
  const [searchParams, setSearhParams] = useSearchParams()
  const studentIdQueryParam = searchParams.get(STUDENT_SEARCH_PARAM)
  const [selectedStudentId, setSelectedStudentId] = useState<string | null | undefined>(
    studentIdQueryParam
  )

  const [assignmentGroupMap, setAssignmentGroupMap] = useState<AssignmentGroupCriteriaMap>({})

  const selectedAssignmentId = searchParams.get(ASSIGNMENT_SEARCH_PARAM)

  const {data, error} = useQuery<GradebookQueryResponse>(GRADEBOOK_QUERY, {
    variables: {courseId},
    fetchPolicy: 'cache-and-network',
    skip: !courseId,
  })

  useEffect(() => {
    if (error) {
      // TODO: handle error
    }

    if (data?.course) {
      const {assignmentGroupsConnection, enrollmentsConnection, submissionsConnection} = data.course

      const {assignments, assignmentGroupMap} = assignmentGroupsConnection.nodes.reduce(
        (prev, curr) => {
          prev.assignments.push(...curr.assignmentsConnection.nodes)

          prev.assignmentGroupMap[curr.id] = {
            name: curr.name,
            assignments: curr.assignmentsConnection.nodes.map(assignment => {
              return {
                id: assignment.id,
                name: assignment.name,
                points_possible: assignment.pointsPossible,
                submission_types: assignment.submissionTypes,
                anonymize_students: assignment.anonymizeStudents,
                omit_from_final_grade: assignment.omitFromFinalGrade,
                workflow_state: assignment.workflowState,
              }
            }),
            group_weight: curr.groupWeight,
            rules: curr.rules,
            id: curr.id,
            position: curr.position,
            integration_data: {},
            sis_source_id: null,
          }

          return prev
        },
        {
          assignments: [] as AssignmentConnection[],
          assignmentGroupMap: {} as AssignmentGroupCriteriaMap,
        }
      )

      setAssignmentGroupMap(assignmentGroupMap)
      setAssignments(assignments)
      setSubmissions(submissionsConnection.nodes)

      const studentEnrollments = enrollmentsConnection.nodes.map(enrollment => enrollment.user)
      const sortableStudents = studentEnrollments.sort((a, b) => {
        return a.sortableName.localeCompare(b.sortableName)
      })
      setStudents(sortableStudents)
    }
  }, [data, error])

  const handleStudentChange = (studentId?: string) => {
    setSelectedStudentId(studentId)
    if (studentId) {
      searchParams.set(STUDENT_SEARCH_PARAM, studentId)
      setSearhParams(searchParams)
    } else {
      searchParams.delete(STUDENT_SEARCH_PARAM)
    }
  }

  const handleAssignmentChange = (assignment?: AssignmentConnection) => {
    setSelectedAssignment(assignment)
    setSelectedSubmissions(submissions.filter(s => s.assignment.id === assignment?.id))
    if (assignment) {
      searchParams.set(ASSIGNMENT_SEARCH_PARAM, assignment?.id)
      setSearhParams(searchParams)
    } else {
      searchParams.delete(ASSIGNMENT_SEARCH_PARAM)
    }
  }

  return (
    <View as="div">
      <View as="div" className="row-fluid">
        <View as="div" className="span12">
          <View as="h1">{I18n.t('Gradebook: Enhanced Individual View')}</View>
          {I18n.t(
            'Note: Grades and notes will be saved automatically after moving out of the field.'
          )}
        </View>
      </View>

      <GlobalSettings />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <ContentSelection
        assignments={assignments}
        students={students}
        selectedStudentId={selectedStudentId}
        selectedAssignmentId={selectedAssignmentId}
        onStudentChange={handleStudentChange}
        onAssignmentChange={handleAssignmentChange}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <GradingResults />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <StudentInformation
        courseId={courseId}
        studentId={selectedStudentId}
        assignmentGroupMap={assignmentGroupMap}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <AssignmentInformation assignment={selectedAssignment} submissions={selectedSubmissions} />
    </View>
  )
}
