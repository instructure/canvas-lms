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
  AssignmentSubmissionsMap,
  CustomOptions,
  GradebookOptions,
  GradebookQueryResponse,
  GradebookSortOrder,
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
  const submissionsForSelectedAssignment = Object.values(submissionsMap)

  // TODO: move this into helper function
  const defaultAssignmentSort: GradebookSortOrder =
    userSettings.contextGet<AssignmentSortContext>('sort_grade_columns_by')?.sortType ??
    GradebookSortOrder.Alphabetical
  const defaultGradebookOptions: GradebookOptions = {
    sortOrder: defaultAssignmentSort,
    exportGradebookCsvUrl: ENV.GRADEBOOK_OPTIONS?.export_gradebook_csv_url,
    lastGeneratedCsvAttachmentUrl: ENV.GRADEBOOK_OPTIONS?.attachment_url,
    gradebookCsvProgress: ENV.GRADEBOOK_OPTIONS?.gradebook_csv_progress,
    contextUrl: ENV.GRADEBOOK_OPTIONS?.context_url,
    contextId: ENV.GRADEBOOK_OPTIONS?.context_id,
    userId: ENV.current_user_id,
    changeGradeUrl: ENV.GRADEBOOK_OPTIONS?.change_grade_url,
    customColumnDatumUrl: ENV.GRADEBOOK_OPTIONS?.custom_column_datum_url,
    customColumnDataUrl: ENV.GRADEBOOK_OPTIONS?.custom_column_data_url,
    customColumnUrl: ENV.GRADEBOOK_OPTIONS?.custom_column_url,
    customColumnsUrl: ENV.GRADEBOOK_OPTIONS?.custom_columns_url,
    gradesAreWeighted: ENV.GRADEBOOK_OPTIONS?.grades_are_weighted,
    finalGradeOverrideEnabled: ENV.GRADEBOOK_OPTIONS?.final_grade_override_enabled,
    reorderCustomColumnsUrl: ENV.GRADEBOOK_OPTIONS?.reorder_custom_columns_url,
    settingUpdateUrl: ENV.GRADEBOOK_OPTIONS?.setting_update_url,
    settingsUpdateUrl: ENV.GRADEBOOK_OPTIONS?.settings_update_url,
    teacherNotes: ENV.GRADEBOOK_OPTIONS?.teacher_notes,
    saveViewUngradedAsZeroToServer: ENV.GRADEBOOK_OPTIONS?.save_view_ungraded_as_zero_to_server,
    messageAttachmentUploadFolderId: ENV.GRADEBOOK_OPTIONS?.message_attachment_upload_folder_id,
    customOptions: {
      allowFinalGradeOverride:
        ENV.GRADEBOOK_OPTIONS?.course_settings.allow_final_grade_override ?? false,
      includeUngradedAssignments:
        ENV.GRADEBOOK_OPTIONS?.save_view_ungraded_as_zero_to_server &&
        ENV.GRADEBOOK_OPTIONS?.settings
          ? ENV.GRADEBOOK_OPTIONS.settings.view_ungraded_as_zero === 'true'
          : userSettings.contextGet('include_ungraded_assignments') || false,
      hideStudentNames: userSettings.contextGet('hide_student_names') || false,
      showConcludedEnrollments: ENV.GRADEBOOK_OPTIONS?.settings?.show_concluded_enrollments
        ? ENV.GRADEBOOK_OPTIONS.settings.show_concluded_enrollments === 'true'
        : false,
      showNotesColumn:
        ENV.GRADEBOOK_OPTIONS?.teacher_notes?.hidden !== undefined
          ? !ENV.GRADEBOOK_OPTIONS.teacher_notes.hidden
          : false,
      showTotalGradeAsPoints: ENV.GRADEBOOK_OPTIONS?.show_total_grade_as_points ?? false,
    },
  }
  const [gradebookOptions, setGradebookOptions] =
    useState<GradebookOptions>(defaultGradebookOptions)

  const {data, error} = useQuery<GradebookQueryResponse>(GRADEBOOK_QUERY, {
    variables: {courseId},
    fetchPolicy: 'no-cache',
    skip: !courseId,
  })

  const {customColumns} = useCustomColumns(gradebookOptions.customColumnsUrl)
  const studentNotesColumnId = customColumns?.find(
    (column: CustomColumn) => column.teacher_notes
  )?.id

  useEffect(() => {
    if (!currentStudent || !students) {
      return
    }
    const hiddenName = students?.find(s => s.id === currentStudent.id)?.hiddenName
    currentStudent.hiddenName = hiddenName ?? I18n.t('Student')
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

      const {mappedAssignmentGroupMap, mappedAssignments} = mapAssignmentGroupQueryResults(
        assignmentGroupsConnection.nodes
      )

      setAssignmentGroupMap(mappedAssignmentGroupMap)
      setAssignments(mappedAssignments)
      setAssignmentSubmissionsMap(mapAssignmentSubmissions(submissionsConnection.nodes))
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
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <StudentInformation
        student={currentStudent}
        submissions={studentSubmissions}
        assignmentGroupMap={assignmentGroupMap}
        gradebookOptions={gradebookOptions}
        studentNotesColumnId={studentNotesColumnId}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />

      <AssignmentInformation
        assignment={selectedAssignment}
        gradebookOptions={gradebookOptions}
        students={students}
        submissions={submissionsForSelectedAssignment}
        handleSetGrades={handleSetGrades}
      />

      <div className="hr" style={{margin: 10, padding: 10, borderBottom: '1px solid #eee'}} />
    </View>
  )
}
