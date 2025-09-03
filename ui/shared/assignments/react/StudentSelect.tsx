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

import React, {useState, useEffect, useMemo} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Select} from '@instructure/ui-select'
import {Flex} from '@instructure/ui-flex'
import {FormMessage} from '@instructure/ui-form-field'
import {useAssignedStudents, CourseStudent} from '../graphql/hooks/useAssignedStudents'
import {Spinner} from '@instructure/ui-spinner'
import {debounce} from 'lodash'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('peer_review_student_select')

interface StudentSelectProps {
  label: string
  errors: FormMessage[]
  initialSelected?: CourseStudent | null
  assignmentId?: string
  courseId?: string
  filterStudents: Set<CourseStudent>
  onOptionSelect: (student: CourseStudent) => void
  handleInputRef: (ref: HTMLElement | null) => void
  clearErrors: () => void
  delay?: number
}

const StudentSelect = ({
  label,
  errors,
  initialSelected = null,
  assignmentId = '',
  courseId = '',
  filterStudents,
  onOptionSelect,
  handleInputRef,
  clearErrors,
  delay = 300,
}: StudentSelectProps) => {
  const [inputValue, setInputValue] = useState(initialSelected ? initialSelected.name : '')
  const [searchTerm, setSearchTerm] = useState(inputValue)
  const [showOptions, setShowOptions] = useState(false)
  const [highlightIndex, setHighlightIndex] = useState<number | null>(null)
  const [selectedStudent, setSelectedStudent] = useState<CourseStudent | null>(initialSelected)
  const [inputErrors, setInputErrors] = useState<FormMessage[]>(errors)
  const {students, loading, error} = useAssignedStudents(
    assignmentId,
    assignmentId ? '' : courseId,
    searchTerm,
  )

  useEffect(() => {
    setInputErrors(errors)
  }, [errors])

  const debouncedSearch = useMemo(
    () =>
      debounce((value: string) => {
        if (value.length === 1) {
          setInputErrors(prev => [
            ...prev,
            {text: I18n.t('Search term must be at least 2 characters long'), type: 'error'},
          ])
        } else {
          setSearchTerm(value)
        }
      }, delay),
    [setSearchTerm, delay],
  )

  useEffect(() => {
    debouncedSearch(inputValue)
    return () => {
      debouncedSearch.cancel()
    }
  }, [inputValue, debouncedSearch])

  const clearInputErrors = () => {
    clearErrors()
    setInputErrors([])
  }

  const handleInputChange = (value: string) => {
    if (!loading && value.length !== 1) {
      setShowOptions(true)
      if (highlightIndex === null) {
        setHighlightIndex(0)
      }
    } else {
      setShowOptions(false)
    }
    clearInputErrors()
    setInputValue(value)
  }

  const handleSelection = (id: string) => {
    const selectedStudent = students.find(student => student._id === id)
    if (selectedStudent) {
      onOptionSelect(selectedStudent)
      setSelectedStudent(selectedStudent)
      setInputValue(selectedStudent?.name || '')
      setShowOptions(false)
    }
  }

  const handleArrowKeys = (event: React.KeyboardEvent) => {
    if (showOptions) {
      if (event.key === 'ArrowDown') {
        if (highlightIndex == students.length - 1) {
          setHighlightIndex(0)
        } else {
          setHighlightIndex(prev => (prev !== null ? prev + 1 : 0))
        }
      } else if (event.key === 'ArrowUp') {
        if (highlightIndex == 0) {
          setHighlightIndex(students.length - 1)
        } else {
          setHighlightIndex(prev => (prev !== null ? prev - 1 : students.length - 1))
        }
      }
    }
  }

  const handleBlur = (_event: React.FocusEvent<HTMLInputElement>) => {
    setShowOptions(false)
    if (!selectedStudent) {
      setHighlightIndex(null)
    }
  }

  const renderStudentOption = (student: CourseStudent, index: number) => {
    if (!filterStudents.has(student)) {
      return (
        <Select.Option id={student._id} key={student._id} isHighlighted={highlightIndex == index}>
          {student.name}
        </Select.Option>
      )
    }
  }

  const loadingOption = (
    <Select.Option id="loading-option" key="loading-option">
      <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
    </Select.Option>
  )

  const emptyOption = (
    <Select.Option id="empty-option" key="empty-option">
      {I18n.t('No results')}
    </Select.Option>
  )

  return (
    <Flex as="div" direction="column">
      {error && (
        <Alert
          variant="error"
          renderCloseButtonLabel={I18n.t('Close error alert for %{label} search input', {
            label: label,
          })}
          margin="0 0 medium 0"
          variantScreenReaderLabel={I18n.t('Error, ')}
        >
          {I18n.t('An error occurred while searching for %{label}', {label: label})}
        </Alert>
      )}
      <Select
        isRequired={true}
        renderLabel={label}
        inputRef={ref => handleInputRef(ref)}
        inputValue={inputValue}
        isShowingOptions={error ? false : showOptions}
        onInputChange={(_event: React.ChangeEvent<HTMLInputElement>, value: string) =>
          handleInputChange(value)
        }
        onRequestSelectOption={(_event: React.SyntheticEvent, {id}) => {
          if (id) handleSelection(id)
        }}
        onBlur={handleBlur}
        onKeyDown={handleArrowKeys}
        messages={inputErrors}
      >
        {loading
          ? loadingOption
          : students.length > 0 && inputValue === searchTerm
            ? students.map((student, index) => renderStudentOption(student, index))
            : inputValue.length > 1
              ? emptyOption
              : null}
      </Select>
    </Flex>
  )
}

export default StudentSelect
