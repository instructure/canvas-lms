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

import React, {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import CanvasMultiSelect from '@canvas/multi-select'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {debounce} from '@instructure/debounce'
import {IconSearchLine} from '@instructure/ui-icons'
import {Tag} from '@instructure/ui-tag'
import {studentsQuery, Student} from '../queries/studentsQuery'
import {useQuery} from '@tanstack/react-query'

const {Option: CanvasMultiSelectOption} = CanvasMultiSelect as any

const I18n = createI18nScope('student_groups')

const VISIBLE_USERS_COUNT = 15
const SEARCH_DELAY_MS = 300
const SEARCH_TEXT_MIN_LENGTH = 2

interface StudentMultiSelectProps {
  selectedOptionIds: string[]
  onSelect: (selectedIds: string[]) => void
}

const StudentMultiSelect: React.FC<StudentMultiSelectProps> = ({
  selectedOptionIds,
  onSelect,
}: StudentMultiSelectProps) => {
  const [searchText, setSearchText] = useState('')
  const [students, setStudents] = useState<Student[]>([])
  const loadedStudents = useRef<Student[]>([])

  const useStudentsQuery = useQuery({
    queryKey: ['courses', {courseId: ENV.course_id!, searchText}],
    queryFn: studentsQuery,
  })

  const onSearch = debounce((searchText: string) => {
    // currently the api has limitation on search text length
    // the length can be empty or greater than 1 (SearchTermHelper::MIN_SEARCH_TERM_LENGTH)
    if (searchText.trim() === '' || searchText.trim().length >= SEARCH_TEXT_MIN_LENGTH) {
      setSearchText(searchText.trim())
    }
  }, SEARCH_DELAY_MS)

  const options = students
    ?.filter(student => student.id !== ENV.current_user_id)
    .filter(student => !selectedOptionIds?.includes(student.id))
    .slice(0, VISIBLE_USERS_COUNT)

  useEffect(() => {
    const data = useStudentsQuery.data || []
    setStudents(data)

    if (useStudentsQuery.isLoading) return

    const combinedLoadedOptions = [...loadedStudents.current, ...(data || [])]
    loadedStudents.current = [
      ...new Map([...combinedLoadedOptions].map(item => [item.id, item])).values(),
    ]
  }, [useStudentsQuery.data, useStudentsQuery.isLoading])

  const optionMatcher = (): boolean => {
    return (
      options?.some(student => student.name.toLowerCase().includes(searchText.toLowerCase())) ||
      false
    )
  }

  const onOptionSelect = (selectedIds: string[]) => {
    onSelect(selectedIds)
    resetSearch()
  }

  const resetSearch = () => {
    setSearchText('')
  }

  const dismissTag = (event: React.MouseEvent, id: string, label: string) => {
    event.stopPropagation()
    event.preventDefault()
    showFlashAlert({message: I18n.t('%{label} removed.', {label}), srOnly: true})
    onOptionSelect(selectedOptionIds.filter(selectedId => selectedId !== id))
  }

  const renderSelectedOptions = (): JSX.Element[] => {
    return selectedOptionIds
      .map(id => {
        const student = loadedStudents.current?.find(student => student.id === id)
        if (!student) return null
        return (
          <Tag
            dismissible={true}
            key={student.id}
            text={student.name}
            title={I18n.t('Remove %{label}', {label: student.name})}
            margin="0 xxx-small"
            test-id={`selected-student-tag-${student.id}`}
            onClick={(event: React.MouseEvent) => dismissTag(event, id, student.name)}
          />
        )
      })
      .filter(element => element !== null)
  }

  const renderBeforeInput = () => {
    return [<IconSearchLine key="search-icon" />, ...renderSelectedOptions()]
  }

  return (
    <CanvasMultiSelect
      id="invite-filter"
      label={I18n.t('Invite Students')}
      placeholder={I18n.t('Search')}
      selectedOptionIds={selectedOptionIds}
      onChange={onOptionSelect}
      customRenderBeforeInput={renderBeforeInput}
      isLoading={useStudentsQuery.isLoading}
      customOnInputChange={value => onSearch(value)}
      customMatcher={optionMatcher}
      customOnBlur={resetSearch}
    >
      {!useStudentsQuery.isLoading &&
        options?.map(student => (
          <CanvasMultiSelectOption
            id={student.id}
            key={student.id}
            value={student.id}
            tagText={student.name}
          >
            {student.name}
          </CanvasMultiSelectOption>
        ))}
    </CanvasMultiSelect>
  )
}

export default StudentMultiSelect
