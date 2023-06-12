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

import {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'

import {
  GradebookSortOrder,
  GradebookUserSubmissionDetails,
  SortableAssignment,
  SortableStudent,
} from '../../types'
import {filterAssignmentsByStudent, sortAssignments} from '../../utils/gradebookUtils'

const I18n = useI18nScope('enhanced_individual_gradebook_content_selection')

type DropDownOption<T> = {
  id: string
  name: string
  data?: T
}

type StudentDropdownOption = DropDownOption<SortableStudent>[]
type AssignmentDropdownOption = DropDownOption<SortableAssignment>[]

const DEFAULT_STUDENT_DROPDOWN_TEXT = I18n.t('No Student Selected')
const DEFAULT_ASSIGNMENT_DROPDOWN_TEXT = I18n.t('No Assignment Selected')

const defaultStudentDropdownOptions = {id: '-1', name: DEFAULT_STUDENT_DROPDOWN_TEXT}
const defaultAssignmentDropdownOptions = {id: '-1', name: DEFAULT_ASSIGNMENT_DROPDOWN_TEXT}

type UserDropdownProps = {
  students?: SortableStudent[]
  selectedSection?: string | null
}

type UserDropdownResponse = {
  studentDropdownOptions?: StudentDropdownOption
}

export const useUserDropdownOptions = ({
  students,
  selectedSection,
}: UserDropdownProps): UserDropdownResponse => {
  const [studentDropdownOptions, setStudentDropdownOptions] = useState<StudentDropdownOption>()

  useEffect(() => {
    if (!students) {
      return
    }

    const filteredStudents = selectedSection
      ? students.filter(student => student.sections.includes(selectedSection))
      : students
    const studentOptions: StudentDropdownOption = [
      defaultStudentDropdownOptions,
      ...filteredStudents.map(student => ({
        id: student.id,
        name: student.sortableName,
        data: student,
      })),
    ]
    setStudentDropdownOptions(studentOptions)
  }, [students, selectedSection, setStudentDropdownOptions])

  return {studentDropdownOptions}
}

type AssignmentDropdownProps = {
  assignments?: SortableAssignment[]
  sortOrder: GradebookSortOrder
  selectedStudentId?: string | null
  studentSubmissions?: GradebookUserSubmissionDetails[]
}

type AssignmentDropdownResponse = {
  assignmentDropdownOptions?: AssignmentDropdownOption
}

export const useAssignmentDropdownOptions = ({
  assignments,
  sortOrder,
  selectedStudentId,
  studentSubmissions,
}: AssignmentDropdownProps): AssignmentDropdownResponse => {
  const [assignmentDropdownOptions, setAssignmentDropdownOptions] =
    useState<AssignmentDropdownOption>()

  useEffect(() => {
    if (!assignments) {
      return
    }

    const sortedAssignments = sortAssignments(assignments, sortOrder)
    const filteredAssignments =
      selectedStudentId && studentSubmissions
        ? filterAssignmentsByStudent(sortedAssignments, studentSubmissions)
        : sortedAssignments

    const assignmentOptions: AssignmentDropdownOption = [
      defaultAssignmentDropdownOptions,
      ...filteredAssignments.map(assignment => ({
        id: assignment.id,
        name: assignment.name,
        data: assignment,
      })),
    ]
    setAssignmentDropdownOptions(assignmentOptions)
  }, [assignments, sortOrder, selectedStudentId, studentSubmissions, setAssignmentDropdownOptions])

  return {assignmentDropdownOptions}
}
