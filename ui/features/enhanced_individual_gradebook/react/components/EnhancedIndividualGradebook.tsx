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

import React, {useCallback, useEffect, useState} from 'react'
import {useQuery} from 'react-apollo'
import {useSearchParams} from 'react-router-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import userSettings from '@canvas/user-settings'
import {View} from '@instructure/ui-view'

import {AssignmentGroupCriteriaMap} from '../../../../shared/grading/grading.d'
import AssignmentInformation from './AssignmentInformation'
import ContentSelection from './ContentSelection'
import GlobalSettings from './GlobalSettings'
import GradingResults from './GradingResults'
import StudentInformation from './StudentInformation'
import {
  AssignmentSortContext,
  GradebookOptions,
  GradebookQueryResponse,
  GradebookSortOrder,
  GradebookUserSubmissionDetails,
  SectionConnection,
  SortableAssignment,
  SortableStudent,
  SubmissionConnection,
} from '../../types'
import {GRADEBOOK_QUERY} from '../../queries/Queries'
import {
  mapAssignmentGroupQueryResults,
  mapEnrollmentsToSortableStudents,
} from '../../utils/gradebookUtils'
import {useCurrentStudentInfo} from '../hooks/useCurrentStudentInfo'

const I18n = useI18nScope('enhanced_individual_gradebook')

const STUDENT_SEARCH_PARAM = 'student'
const ASSIGNMENT_SEARCH_PARAM = 'assignment'

export default function EnhancedIndividualGradebook() {
  const [sections, setSections] = useState<SectionConnection[]>([])
  const [submissions, setSubmissions] = useState<SubmissionConnection[]>([])
  const [students, setStudents] = useState<SortableStudent[]>()
  const [assignments, setAssignments] = useState<SortableAssignment[]>()

  const courseId = ENV.GRADEBOOK_OPTIONS?.context_id || '' // TODO: get from somewhere else?
  const [searchParams, setSearchParams] = useSearchParams()
  const studentIdQueryParam = searchParams.get(STUDENT_SEARCH_PARAM)
  const [selectedStudentId, setSelectedStudentId] = useState<string | null | undefined>(
    studentIdQueryParam
  )
  const {currentStudent, studentSubmissions, updateSubmissionDetails} = useCurrentStudentInfo(
    courseId,
    selectedStudentId
  )

  const [assignmentGroupMap, setAssignmentGroupMap] = useState<AssignmentGroupCriteriaMap>({})

  const assignmentIdQueryParam = searchParams.get(ASSIGNMENT_SEARCH_PARAM)
  const [selectedAssignmentId, setSelectedAssignmentId] = useState<string | null | undefined>(
    assignmentIdQueryParam
  )
  const selectedAssignment = assignments?.find(assignment => assignment.id === selectedAssignmentId)
  const submissionsForSelectedAssignment = submissions.filter(
    submission => submission.assignmentId === selectedAssignmentId
  )

  const defaultAssignmentSort: GradebookSortOrder =
    userSettings.contextGet<AssignmentSortContext>('sort_grade_columns_by')?.sortType ??
    GradebookSortOrder.Alphabetical
  const defaultGradebookOptions: GradebookOptions = {
    sortOrder: defaultAssignmentSort,
  }
  const [gradebookOptions, setGradebookOptions] =
    useState<GradebookOptions>(defaultGradebookOptions)

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
      const {
        assignmentGroupsConnection,
        enrollmentsConnection,
        sectionsConnection,
        submissionsConnection,
      } = data.course

      const {mappedAssignmentGroupMap, mappedAssignments} = mapAssignmentGroupQueryResults(
        assignmentGroupsConnection.nodes
      )

      setAssignmentGroupMap(mappedAssignmentGroupMap)
      setAssignments(mappedAssignments)
      setSubmissions(submissionsConnection.nodes)
      setSections(sectionsConnection.nodes)

      const mappedEnrollments = mapEnrollmentsToSortableStudents(enrollmentsConnection.nodes)
      const sortableStudents = mappedEnrollments.sort((a, b) => {
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

  const handleSubmissionSaved = useCallback(
    (newSubmission: GradebookUserSubmissionDetails) => {
      setSubmissions(prevSubmissions => {
        const index = prevSubmissions.findIndex(s => s.id === newSubmission.id)
        if (index > -1) {
          prevSubmissions[index] = newSubmission
        } else {
          prevSubmissions.push(newSubmission)
        }
        return [...prevSubmissions]
      })

      updateSubmissionDetails(newSubmission)
    },
    [updateSubmissionDetails]
  )

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

      <GlobalSettings
        sections={sections}
        gradebookOptions={gradebookOptions}
        onSortChange={sortType => {
          userSettings.contextSet('sort_grade_columns_by', {sortType})
          const newGradebookOptions = {...gradebookOptions, sortOrder: sortType}
          setGradebookOptions(newGradebookOptions)
        }}
        onSectionChange={sectionId => {
          const newGradebookOptions = {...gradebookOptions, selectedSection: sectionId}
          setGradebookOptions(newGradebookOptions)
        }}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <ContentSelection
        courseId={courseId}
        assignments={assignments}
        students={students}
        selectedStudentId={selectedStudentId}
        selectedAssignmentId={selectedAssignmentId}
        gradebookOptions={gradebookOptions}
        onStudentChange={handleStudentChange}
        onAssignmentChange={handleAssignmentChange}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <GradingResults
        assignment={selectedAssignment}
        courseId={courseId}
        studentId={selectedStudentId}
        gradebookOptions={gradebookOptions}
        onSubmissionSaved={handleSubmissionSaved}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <StudentInformation
        student={currentStudent}
        submissions={studentSubmissions}
        assignmentGroupMap={assignmentGroupMap}
        gradebookOptions={gradebookOptions}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <AssignmentInformation
        assignment={selectedAssignment}
        gradebookOptions={gradebookOptions}
        submissions={submissionsForSelectedAssignment}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />
    </View>
  )
}
