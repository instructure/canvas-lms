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
import {Text} from '@instructure/ui-text'
import gradingHelpers from '@canvas/grading/AssignmentGroupGradeCalculator'

import type {AssignmentGroupCriteriaMap} from '../../../../shared/grading/grading.d'
import AssignmentInformation from './AssignmentInformation'
import ContentSelection from './ContentSelection'
import GlobalSettings from './GlobalSettings'
import GradingResults from './GradingResults'
import StudentInformation from './StudentInformation'
import type {
  AssignmentSubmissionsMap,
  CustomOptions,
  GradebookOptions,
  GradebookQueryResponse,
  GradebookUserSubmissionDetails,
  SectionConnection,
  SortableAssignment,
  SortableStudent,
  SubmissionGradeChange,
  TeacherNotes,
  CustomColumn,
} from '../../types'
import {GRADEBOOK_QUERY} from '../../queries/Queries'
import {
  gradebookOptionsSetup,
  mapAssignmentGroupQueryResults,
  mapAssignmentSubmissions,
  mapEnrollmentsToSortableStudents,
} from '../../utils/gradebookUtils'
import {useCurrentStudentInfo} from '../hooks/useCurrentStudentInfo'
import {useCustomColumns} from '../hooks/useCustomColumns'

const I18n = useI18nScope('enhanced_individual_gradebook')

const STUDENT_SEARCH_PARAM = 'student'
const ASSIGNMENT_SEARCH_PARAM = 'assignment'

export default function EnhancedIndividualGradebook() {
  const [sections, setSections] = useState<SectionConnection[]>([])
  const [assignmentSubmissionsMap, setAssignmentSubmissionsMap] =
    useState<AssignmentSubmissionsMap>({})
  const [students, setStudents] = useState<SortableStudent[]>()
  const [assignments, setAssignments] = useState<SortableAssignment[]>()
  const [assignmentDropped, setAssignmentDropped] = useState<boolean>(false)

  const courseId = ENV.GRADEBOOK_OPTIONS?.context_id || ''
  const [searchParams, setSearchParams] = useSearchParams()
  const studentIdQueryParam = searchParams.get(STUDENT_SEARCH_PARAM)
  const [selectedStudentId, setSelectedStudentId] = useState<string | null | undefined>(
    studentIdQueryParam
  )
  const {currentStudent, studentSubmissions, updateSubmissionDetails, loadingStudent} =
    useCurrentStudentInfo(courseId, selectedStudentId)

  const [assignmentGroupMap, setAssignmentGroupMap] = useState<AssignmentGroupCriteriaMap>({})

  const assignmentIdQueryParam = searchParams.get(ASSIGNMENT_SEARCH_PARAM)
  const [selectedAssignmentId, setSelectedAssignmentId] = useState<string | null | undefined>(
    assignmentIdQueryParam
  )

  const selectedAssignment = assignments?.find(assignment => assignment.id === selectedAssignmentId)
  const submissionsMap = selectedAssignment ? assignmentSubmissionsMap[selectedAssignment.id] : {}
  const submissionsForSelectedAssignment = Object.values(submissionsMap ?? {})

  const [gradebookOptions, setGradebookOptions] = useState<GradebookOptions>(
    gradebookOptionsSetup(ENV)
  )

  const {data, error} = useQuery<GradebookQueryResponse>(GRADEBOOK_QUERY, {
    variables: {courseId},
    fetchPolicy: 'no-cache',
    skip: !courseId,
  })

  const {customColumnsUrl} = gradebookOptions

  const {customColumns} = useCustomColumns(customColumnsUrl)
  const studentNotesColumnId = customColumns?.find(
    (column: CustomColumn) => column.teacher_notes
  )?.id

  const [currentStudentHiddenName, setCurrentStudentHiddenName] = useState<string>('')
  useEffect(() => {
    if (!currentStudent || !students) {
      return
    }
    const hiddenName = students?.find(s => s.id === currentStudent.id)?.hiddenName
    setCurrentStudentHiddenName(hiddenName ?? I18n.t('Student'))
  }, [currentStudent, students])

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

      const {assignmentGradingPeriodMap, assignmentSubmissionsMap} = mapAssignmentSubmissions(
        submissionsConnection.nodes
      )
      setAssignmentSubmissionsMap(assignmentSubmissionsMap)

      const {mappedAssignmentGroupMap, mappedAssignments} = mapAssignmentGroupQueryResults(
        assignmentGroupsConnection.nodes,
        assignmentGradingPeriodMap
      )

      setAssignmentGroupMap(mappedAssignmentGroupMap)
      setAssignments(mappedAssignments)
      setSections(sectionsConnection.nodes)

      const sortableStudents = mapEnrollmentsToSortableStudents(enrollmentsConnection.nodes)
      const sortedStudents = sortableStudents.sort((a, b) => {
        return a.sortableName.localeCompare(b.sortableName)
      })
      sortedStudents.forEach(
        (student, index) => (student.hiddenName = I18n.t('Student %{id}', {id: index + 1}))
      )
      setStudents(sortedStudents)
    }
  }, [data, error])

  useEffect(() => {
    if (!selectedAssignment || !assignments || !studentSubmissions || !assignmentGroupMap) {
      return
    }
    const assignmentGroup = assignmentGroupMap[selectedAssignment?.assignmentGroupId ?? '']

    const relevantSubmissions = studentSubmissions.filter(submission => {
      const submissionAssignment = assignments?.find(a => a.id === submission.assignmentId)
      if (
        assignmentGroup?.assignments
          .map(assignment => assignment.id)
          .includes(submissionAssignment?.id || '') &&
        !!submission.grade
      ) {
        return submission
      }
      return null
    })

    const droppableSubmissions = relevantSubmissions.map(submission => {
      const submissionAssignment = assignments?.find(a => a.id === submission.assignmentId)
      return {
        score: submission.score,
        grade: submission.grade,
        total: submissionAssignment?.pointsPossible || 0,
        assignment_id: submissionAssignment?.id,
        workflow_state: submissionAssignment?.workflowState,
        excused: submission.excused,
        id: submission.id,
        submission: {assignment_id: submissionAssignment?.id},
      }
    })

    const assignmentIdsToKeep = gradingHelpers
      .dropAssignments(droppableSubmissions, assignmentGroup?.rules)
      .map(s => s.assignment_id)
    const droppedAssignmentIds: (string | undefined)[] = droppableSubmissions
      .filter(s => !assignmentIdsToKeep.includes(s.assignment_id))
      .map(s => s.assignment_id)
    setAssignmentDropped(droppedAssignmentIds.includes(selectedAssignment.id))
  }, [selectedAssignment, assignments, studentSubmissions, assignmentGroupMap])

  const invalidAssignmentGroups = Object.keys(assignmentGroupMap).reduce((invalidKeys, groupId) => {
    const {invalid, name, gradingPeriodsIds} = assignmentGroupMap[groupId]
    const {selectedGradingPeriodId} = gradebookOptions
    if (
      invalid ||
      (selectedGradingPeriodId && !gradingPeriodsIds?.includes(selectedGradingPeriodId))
    ) {
      invalidKeys[groupId] = name
    }

    return invalidKeys
  }, {} as Record<string, string>)

  const selectedAssignmentGroupInvalid = selectedAssignment?.assignmentGroupId
    ? !!invalidAssignmentGroups[selectedAssignment?.assignmentGroupId]
    : false

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
      setAssignmentSubmissionsMap(prevAssignmentSubmissions => {
        const {assignmentId, id: submissionId} = newSubmission
        prevAssignmentSubmissions[assignmentId][submissionId] = newSubmission
        return {...prevAssignmentSubmissions}
      })

      updateSubmissionDetails(newSubmission)
    },
    [updateSubmissionDetails, setAssignmentSubmissionsMap]
  )

  const handleSetGrades = useCallback(
    (updatedSubmissions: SubmissionGradeChange[]) => {
      setAssignmentSubmissionsMap(prevAssignmentSubmissions => {
        updatedSubmissions.forEach(submission => {
          const {assignmentId, id: submissionId} = submission
          const existingSubmission = prevAssignmentSubmissions[assignmentId][submissionId]
          if (existingSubmission) {
            prevAssignmentSubmissions[assignmentId][submissionId] = {
              ...existingSubmission,
              ...submission,
            }
          }
        })
        return {...prevAssignmentSubmissions}
      })

      const submissionForUser = updatedSubmissions.find(s => s.userId === selectedStudentId)

      if (submissionForUser) {
        updateSubmissionDetails(submissionForUser)
      }
    },
    [selectedStudentId, updateSubmissionDetails]
  )

  return (
    <>
      {/* EVAL-3711 Remove ICE Feature Flag */}
      <View as="div" margin={window.ENV.FEATURES.instui_nav ? 'small 0 large 0' : '0'}>
        {!window.ENV.FEATURES.instui_nav && (
          <View as="h1">{I18n.t('Gradebook: Individual View')}</View>
        )}
        {/* Was not able to manually change lineHeight in View so used div to modify lineHeight */}
        <div style={{lineHeight: 1.25}}>
          <Text size={window.ENV.FEATURES.instui_nav ? 'large' : 'medium'}>
            {I18n.t(
              'Note: Grades and notes will be saved automatically after moving out of the field.'
            )}
          </Text>
        </div>
      </View>

      <View as="div">
        <GlobalSettings
          sections={sections}
          gradebookOptions={gradebookOptions}
          customColumns={customColumns}
          onSortChange={sortType => {
            userSettings.contextSet('sort_grade_columns_by', {sortType})
            const newGradebookOptions = {...gradebookOptions, sortOrder: sortType}
            setGradebookOptions(newGradebookOptions)
          }}
          onSectionChange={sectionId => {
            const newGradebookOptions = {...gradebookOptions, selectedSection: sectionId}
            setGradebookOptions(newGradebookOptions)
          }}
          onGradingPeriodChange={gradingPeriodId => {
            userSettings.contextSet('gradebook_current_grading_period', gradingPeriodId)
            const newGradebookOptions = {
              ...gradebookOptions,
              selectedGradingPeriodId: gradingPeriodId,
            }
            setGradebookOptions(newGradebookOptions)
          }}
          handleCheckboxChange={(key: keyof CustomOptions, value: boolean) => {
            setGradebookOptions(prevGradebookOptions => {
              const newCustomOptions = {...prevGradebookOptions.customOptions, [key]: value}
              return {...prevGradebookOptions, customOptions: newCustomOptions}
            })
          }}
          onTeacherNotesCreation={(teacherNotes: TeacherNotes) => {
            setGradebookOptions(prevGradebookOptions => {
              return {...prevGradebookOptions, teacherNotes}
            })
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
          currentStudent={currentStudent}
          studentSubmissions={studentSubmissions}
          gradebookOptions={gradebookOptions}
          loadingStudent={loadingStudent}
          onSubmissionSaved={handleSubmissionSaved}
          currentStudentHiddenName={currentStudentHiddenName}
          dropped={assignmentDropped}
        />

        <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

        <StudentInformation
          assignmentGroupMap={assignmentGroupMap}
          gradebookOptions={gradebookOptions}
          invalidAssignmentGroups={invalidAssignmentGroups}
          student={currentStudent}
          studentNotesColumnId={studentNotesColumnId}
          currentStudentHiddenName={currentStudentHiddenName}
          submissions={studentSubmissions}
        />

        <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

        <AssignmentInformation
          assignment={selectedAssignment}
          assignmentGroupInvalid={selectedAssignmentGroupInvalid}
          gradebookOptions={gradebookOptions}
          students={students}
          submissions={submissionsForSelectedAssignment}
          handleSetGrades={handleSetGrades}
        />

        <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />
      </View>
    </>
  )
}
