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

import React, {useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'

import type {GradebookOptions, SortableAssignment, SortableStudent} from '../../../types'
import {View} from '@instructure/ui-view'
import {useCurrentStudentInfo} from '../../hooks/useCurrentStudentInfo'
import {
  useAssignmentDropdownOptions,
  useUserDropdownOptions,
} from '../../hooks/useContentDropdownOptions'
import {studentDisplayName} from '../../../utils/gradebookUtils'

const I18n = useI18nScope('enhanced_individual_gradebook')

export type ContentSelectionComponentProps = {
  courseId: string
  assignments?: SortableAssignment[]
  students?: SortableStudent[]
  selectedStudentId?: string | null
  selectedAssignmentId?: string | null
  gradebookOptions: GradebookOptions
  onStudentChange: (studentId?: string) => void
  onAssignmentChange: (assignmentId?: string) => void
}

export default function ContentSelection({
  courseId,
  students,
  assignments,
  selectedAssignmentId,
  selectedStudentId,
  gradebookOptions,
  onAssignmentChange,
  onStudentChange,
}: ContentSelectionComponentProps) {
  const [selectedStudentIndex, setSelectedStudentIndex] = useState<number>(0)
  const [selectedAssignmentIndex, setSelectedAssignmentIndex] = useState<number>(0)
  const {studentSubmissions} = useCurrentStudentInfo(courseId, selectedStudentId)
  const nextAssignmentRef = useRef<HTMLButtonElement>(null)
  const nextStudentRef = useRef<HTMLButtonElement>(null)
  const previousAssignmentRef = useRef<HTMLButtonElement>(null)
  const previousStudentRef = useRef<HTMLButtonElement>(null)

  const {
    sortOrder,
    selectedGradingPeriodId,
    selectedSection,
    customOptions: {showConcludedEnrollments},
  } = gradebookOptions
  const {studentDropdownOptions} = useUserDropdownOptions({
    students,
    selectedSection,
    showConcludedEnrollments,
  })
  const {assignmentDropdownOptions} = useAssignmentDropdownOptions({
    assignments,
    sortOrder,
    studentSubmissions,
    selectedStudentId,
    selectedGradingPeriodId,
  })

  useEffect(() => {
    if (!studentDropdownOptions) {
      return
    }

    if (selectedStudentId) {
      const studentIndex = studentDropdownOptions.findIndex(
        studentOption => studentOption.id === selectedStudentId
      )

      if (studentIndex !== -1) {
        setSelectedStudentIndex(studentIndex)
      } else {
        // if the student is not in the dropdown, reset the student dropdown
        setSelectedStudentIndex(0)
        onStudentChange(undefined)
      }
    }
  }, [selectedStudentId, studentDropdownOptions, setSelectedStudentIndex, onStudentChange])

  useEffect(() => {
    if (!assignmentDropdownOptions) {
      return
    }

    if (selectedAssignmentId) {
      const assignmentIndex = assignmentDropdownOptions.findIndex(
        assignmentOption => assignmentOption.id === selectedAssignmentId
      )

      if (assignmentIndex >= 0) {
        setSelectedAssignmentIndex(assignmentIndex)
      } else {
        // if the assignment is not in the dropdown, reset the assignment dropdown
        setSelectedAssignmentIndex(0)
        onAssignmentChange(undefined)
      }
    }
  }, [
    assignmentDropdownOptions,
    selectedAssignmentId,
    onAssignmentChange,
    setSelectedAssignmentIndex,
  ])

  if (!studentDropdownOptions || !assignmentDropdownOptions) {
    return <LoadingIndicator />
  }

  const handleChangeStudent = (event?: React.ChangeEvent<HTMLSelectElement>, newIndex?: number) => {
    const selectedIndex = (event ? event.target.selectedIndex : newIndex) ?? 0
    setSelectedStudentIndex(selectedIndex)
    const selectedStudent = studentDropdownOptions[selectedIndex]?.data
    onStudentChange(selectedStudent?.id)

    if (selectedIndex <= 0) {
      nextStudentRef.current?.focus()
    } else if (selectedIndex >= studentDropdownOptions.length - 1) {
      previousStudentRef.current?.focus()
    }
  }

  const handleChangeAssignment = (
    event?: React.ChangeEvent<HTMLSelectElement>,
    newIndex?: number
  ) => {
    const selectedIndex = (event ? event.target.selectedIndex : newIndex) ?? 0
    setSelectedAssignmentIndex(selectedIndex)
    const selectedAssignment = assignmentDropdownOptions[selectedIndex]?.data
    onAssignmentChange(selectedAssignment?.id)

    if (selectedIndex <= 0) {
      nextAssignmentRef.current?.focus()
    }
    if (selectedIndex >= assignmentDropdownOptions.length - 1) {
      previousAssignmentRef.current?.focus()
    }
  }
  const {hideStudentNames} = gradebookOptions.customOptions

  return (
    <>
      <View as="div" className="row-fluid">
        <View as="div" className="span12">
          <View as="h2">{I18n.t('Content Selection')}</View>
        </View>
      </View>

      <View
        as="div"
        className="row-fluid pad-box bottom-only"
        data-testid="content-selection-student"
      >
        <View as="div" className="span4 text-right-responsive">
          <label htmlFor="student_select" style={{textAlign: 'right', display: 'block'}}>
            {I18n.t('Select a student')}
          </label>
        </View>
        <View as="div" className="span8">
          <select
            className="student_select"
            onChange={handleChangeStudent}
            value={studentDropdownOptions[selectedStudentIndex]?.id}
            data-testid="content-selection-student-select"
          >
            {studentDropdownOptions.map(option => (
              <option key={option.id} value={option.id}>
                {option.data
                  ? studentDisplayName(option.data, hideStudentNames)
                  : option.sortableName}
              </option>
            ))}
          </select>
          <View as="div" className="row-fluid pad-box bottom-only student_navigation">
            <View as="div" className="span4">
              <button
                data-testid="previous-student-button"
                type="button"
                className="btn btn-block next_object"
                disabled={selectedStudentIndex <= 0}
                onClick={() => handleChangeStudent(undefined, selectedStudentIndex - 1)}
                ref={previousStudentRef}
              >
                {I18n.t('Previous Student')}
              </button>
            </View>
            <View as="div" className="span4">
              <button
                data-testid="next-student-button"
                type="button"
                className="btn btn-block next_object"
                disabled={selectedStudentIndex >= studentDropdownOptions.length - 1}
                onClick={() => handleChangeStudent(undefined, selectedStudentIndex + 1)}
                ref={nextStudentRef}
              >
                {I18n.t('Next Student')}
              </button>
            </View>
          </View>
        </View>
      </View>

      <View
        as="div"
        className="row-fluid pad-box bottom-only"
        data-testid="content-selection-assignment"
      >
        <View as="div" className="span4 text-right-responsive">
          <label htmlFor="assignment_select" style={{textAlign: 'right', display: 'block'}}>
            {I18n.t('Select an assignment')}
          </label>
        </View>
        <View as="div" className="span8">
          <select
            className="assignment_select"
            onChange={handleChangeAssignment}
            value={assignmentDropdownOptions[selectedAssignmentIndex]?.id}
            data-testid="content-selection-assignment-select"
          >
            {assignmentDropdownOptions.map(option => (
              <option key={option.id} value={option.id}>
                {option.name}
              </option>
            ))}
          </select>
          <View as="div" className="row-fluid pad-box bottom-only assignment_navigation">
            <View as="div" className="span4">
              <button
                data-testid="previous-assignment-button"
                type="button"
                className="btn btn-block next_object"
                disabled={selectedAssignmentIndex <= 0}
                onClick={() => handleChangeAssignment(undefined, selectedAssignmentIndex - 1)}
                ref={previousAssignmentRef}
              >
                {I18n.t('Previous Assignment')}
              </button>
            </View>
            <View as="div" className="span4">
              <button
                data-testid="next-assignment-button"
                type="button"
                className="btn btn-block next_object"
                disabled={selectedAssignmentIndex >= assignmentDropdownOptions.length - 1}
                onClick={() => handleChangeAssignment(undefined, selectedAssignmentIndex + 1)}
                ref={nextAssignmentRef}
              >
                {I18n.t('Next Assignment')}
              </button>
            </View>
          </View>
        </View>
      </View>
    </>
  )
}
