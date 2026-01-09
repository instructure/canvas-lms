/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useState, useEffect} from 'react'
import CanvasMultiSelect from '@canvas/multi-select'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconSearchLine} from '@instructure/ui-icons'
import {debounce} from 'es-toolkit/compat'
import {Student} from '@canvas/outcomes/react/types/rollup'
import {useStudents} from '../../hooks/useStudents'

const I18n = createI18nScope('LearningMasteryGradebook')

interface StudentSearchProps {
  courseId: string
  selectedUserIds: number[]
  onSelectedUserIdsChange: (userIds: number[]) => void
}

export const StudentSearch: React.FC<StudentSearchProps> = ({
  selectedUserIds,
  courseId,
  onSelectedUserIdsChange,
}) => {
  const [students, setStudents] = useState<Student[]>([])
  const [searchTerm, setSearchTerm] = useState<string>('')
  const {students: initialStudents, isLoading} = useStudents(courseId, searchTerm)

  useEffect(() => {
    if (initialStudents.length > 0) {
      setStudents(prevStudents => {
        // Keep previously selected students that are still selected
        // Convert string IDs to numbers for comparison
        const prevSelected = prevStudents.filter(s => selectedUserIds.includes(Number(s.id)))

        // Merge with new results, avoiding duplicates
        const newStudentIds = new Set(initialStudents.map(s => s.id))
        const selectedNotInResults = prevSelected.filter(s => !newStudentIds.has(s.id))

        return [...selectedNotInResults, ...initialStudents]
      })
    }
  }, [initialStudents, selectedUserIds])

  const handleSelectedUsersChange = (selectedIds: string[]) => {
    onSelectedUserIdsChange(selectedIds.map(id => Number(id)))
    setSearchTerm('')
  }

  const handleInputChange = debounce(async (searchTerm: string) => {
    if (searchTerm.length > 0 && searchTerm.length < 2) return

    setSearchTerm(searchTerm)
  }, 500)

  return (
    <CanvasMultiSelect
      label={I18n.t('Student Names')}
      onChange={handleSelectedUsersChange}
      placeholder={I18n.t('Search Students')}
      selectedOptionIds={selectedUserIds.map(id => String(id))}
      customRenderBeforeInput={tags => [<IconSearchLine key="search-icon" />].concat(tags || [])}
      customOnInputChange={handleInputChange}
      isLoading={isLoading}
    >
      {students.map(student => (
        <CanvasMultiSelect.Option
          key={student.id}
          id={student.id}
          label={student.name}
          value={student.id}
        >
          {student.name}
        </CanvasMultiSelect.Option>
      ))}
    </CanvasMultiSelect>
  )
}
