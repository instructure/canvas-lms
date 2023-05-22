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
  SubmissionConnection,
  UserConnection,
} from '../types'
import {GRADEBOOK_QUERY} from '../queries/Queries'
import {mapAssignmentGroupQueryResults} from '../utils/gradebookUtils'

const I18n = useI18nScope('enhanced_individual_gradebook')

const STUDENT_SEARCH_PARAM = 'student'
const ASSIGNMENT_SEARCH_PARAM = 'assignment'

export default function EnhancedIndividualGradebook() {
  const [submissions, setSubmissions] = useState<SubmissionConnection[]>([])
  const [students, setStudents] = useState<UserConnection[]>([])
  const [assignments, setAssignments] = useState<AssignmentConnection[]>([])

  const courseId = ENV.GRADEBOOK_OPTIONS?.context_id || '' // TODO: get from somewhere else?
  const [searchParams, setSearchParams] = useSearchParams()
  const studentIdQueryParam = searchParams.get(STUDENT_SEARCH_PARAM)
  const [selectedStudentId, setSelectedStudentId] = useState<string | null | undefined>(
    studentIdQueryParam
  )

  const [assignmentGroupMap, setAssignmentGroupMap] = useState<AssignmentGroupCriteriaMap>({})

  const assignmentIdQueryParam = searchParams.get(ASSIGNMENT_SEARCH_PARAM)
  const [selectedAssignmentId, setSelectedAssignmentId] = useState<string | null | undefined>(
    assignmentIdQueryParam
  )
  const selectedAssignment = assignments.find(assignment => assignment.id === selectedAssignmentId)
  const submissionsForSelectedAssignment = submissions.filter(
    submission => submission.assignmentId === selectedAssignmentId
  )

  const {data, error} = useQuery<GradebookQueryResponse>(GRADEBOOK_QUERY, {
    variables: {courseId},
    fetchPolicy: 'no-cache',
    skip: !courseId,
  })

  useEffect(() => {
    if (error) {
      // TODO: handle error
    }

    if (data?.course) {
      const {assignmentGroupsConnection, enrollmentsConnection, submissionsConnection} = data.course

      const {mappedAssignmentGroupMap, mappedAssignments} = mapAssignmentGroupQueryResults(
        assignmentGroupsConnection.nodes
      )

      setAssignmentGroupMap(mappedAssignmentGroupMap)
      setAssignments(mappedAssignments)
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
    } else {
      searchParams.delete(STUDENT_SEARCH_PARAM)
    }
    setSearchParams(searchParams)
  }

  const handleAssignmentChange = (assignmentId?: string) => {
    setSelectedAssignmentId(assignmentId)
    if (assignmentId) {
      searchParams.set(ASSIGNMENT_SEARCH_PARAM, assignmentId)
    } else {
      searchParams.delete(ASSIGNMENT_SEARCH_PARAM)
    }
    setSearchParams(searchParams)
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
        gradebookOptions={{}} // TODO: Empty object for now for default functionality
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <AssignmentInformation
        assignment={selectedAssignment}
        gradebookOptions={{}}
        submissions={submissionsForSelectedAssignment}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />
    </View>
  )
}
