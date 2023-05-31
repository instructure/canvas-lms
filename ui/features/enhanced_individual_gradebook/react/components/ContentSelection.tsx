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
import {useScope as useI18nScope} from '@canvas/i18n'

import {GradebookOptions, SortableAssignment, UserConnection} from '../../types'
import {View} from '@instructure/ui-view'
import {sortAssignments} from '../../utils/gradebookUtils'

const I18n = useI18nScope('enhanced_individual_gradebook')

type Props = {
  assignments: SortableAssignment[]
  students: UserConnection[]
  selectedStudentId?: string | null
  selectedAssignmentId?: string | null
  gradebookOptions: GradebookOptions
  onStudentChange: (studentId?: string) => void
  onAssignmentChange: (assignmentId?: string) => void
}

type DropDownOption<T> = {
  id: string
  name: string
  data?: T
}

type StudentDropdownOption = DropDownOption<UserConnection>[]
type AssignmentDropdownOption = DropDownOption<SortableAssignment>[]

const DEFAULT_STUDENT_DROPDOWN_TEXT = I18n.t('No Student Selected')
const DEFAULT_ASSIGNMENT_DROPDOWN_TEXT = I18n.t('No Assignment Selected')

const defaultStudentDropdownOptions = {id: '-1', name: DEFAULT_STUDENT_DROPDOWN_TEXT}
const defaultAssignmentDropdownOptions = {id: '-1', name: DEFAULT_ASSIGNMENT_DROPDOWN_TEXT}

export default function ContentSelection({
  students,
  assignments,
  selectedAssignmentId,
  selectedStudentId,
  gradebookOptions,
  onAssignmentChange,
  onStudentChange,
}: Props) {
  const [studentDropdownOptions, setStudentDropdownOptions] = useState<StudentDropdownOption>([])
  const [assignmentDropdownOptions, setAssignmentDropdownOptions] =
    useState<AssignmentDropdownOption>([])
  const [selectedStudentIndex, setSelectedStudentIndex] = useState<number>(0)
  const [selectedAssignmentIndex, setSelectedAssignmentIndex] = useState<number>(0)

  const {sortOrder} = gradebookOptions

  // TOOD: might be ablet to refactor to make simpler
  useEffect(() => {
    const studentOptions: StudentDropdownOption = [
      defaultStudentDropdownOptions,
      ...students.map(student => ({id: student.id, name: student.sortableName, data: student})),
    ]
    setStudentDropdownOptions(studentOptions)

    if (selectedStudentId) {
      const studentIndex = studentOptions.findIndex(
        studentOption => studentOption.id === selectedStudentId
      )

      if (studentIndex !== -1) {
        setSelectedStudentIndex(studentIndex)
      }
    }

    const sortedAssignments = sortAssignments(assignments, sortOrder)

    const assignmentOptions: AssignmentDropdownOption = [
      defaultAssignmentDropdownOptions,
      ...sortedAssignments.map(assignment => ({
        id: assignment.id,
        name: assignment.name,
        data: assignment,
      })),
    ]
    setAssignmentDropdownOptions(assignmentOptions)

    if (selectedAssignmentId) {
      const assignmentIndex = assignmentOptions.findIndex(
        assignmentOption => assignmentOption.id === selectedAssignmentId
      )

      if (assignmentIndex >= 0) {
        setSelectedAssignmentIndex(assignmentIndex)
      }
    }
  }, [students, assignments, selectedStudentId, selectedAssignmentId, sortOrder])

  const handleChangeStudent = (event?: React.ChangeEvent<HTMLSelectElement>, newIndex?: number) => {
    const selectedIndex = (event ? event.target.selectedIndex : newIndex) ?? 0
    setSelectedStudentIndex(selectedIndex)
    const selectedStudent = studentDropdownOptions[selectedIndex]?.data
    onStudentChange(selectedStudent?.id)
  }

  const handleChangeAssignment = (
    event?: React.ChangeEvent<HTMLSelectElement>,
    newIndex?: number
  ) => {
    const selectedIndex = (event ? event.target.selectedIndex : newIndex) ?? 0
    setSelectedAssignmentIndex(selectedIndex)
    const selectedAssignment = assignmentDropdownOptions[selectedIndex]?.data
    onAssignmentChange(selectedAssignment?.id)
  }

  return (
    <>
      <View as="div" className="row-fluid">
        <View as="div" className="span12">
          <View as="h2">{I18n.t('Content Selection')}</View>
        </View>
      </View>

      <View as="div" className="row-fluid pad-box bottom-only">
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
          >
            {studentDropdownOptions.map(option => (
              <option key={option.id} value={option.id}>
                {option.name}
              </option>
            ))}
          </select>
          <View as="div" className="row-fluid pad-box bottom-only student_navigation">
            <View as="div" className="span4">
              <button
                type="button"
                className="btn btn-block next_object"
                disabled={selectedStudentIndex <= 1}
                onClick={() => handleChangeStudent(undefined, selectedStudentIndex - 1)}
              >
                {I18n.t('Previous Student')}
              </button>
            </View>
            <View as="div" className="span4">
              <button
                type="button"
                className="btn btn-block next_object"
                disabled={selectedStudentIndex >= studentDropdownOptions.length - 1}
                onClick={() => handleChangeStudent(undefined, selectedStudentIndex + 1)}
              >
                {I18n.t('Next Student')}
              </button>
            </View>
          </View>
        </View>
      </View>

      <View as="div" className="row-fluid pad-box bottom-only">
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
                type="button"
                className="btn btn-block next_object"
                disabled={selectedAssignmentIndex <= 1}
                onClick={() => handleChangeAssignment(undefined, selectedAssignmentIndex - 1)}
              >
                {I18n.t('Previous Assignment')}
              </button>
            </View>
            <View as="div" className="span4">
              <button
                type="button"
                className="btn btn-block next_object"
                disabled={selectedAssignmentIndex >= assignmentDropdownOptions.length - 1}
                onClick={() => handleChangeAssignment(undefined, selectedAssignmentIndex + 1)}
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
